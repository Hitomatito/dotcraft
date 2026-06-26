#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
#  setup-terminal.sh
#  Instalacion automatica: zsh + Oh My Zsh + plugins + p10k
#  Basado en la config de james@blackbox
#  - Migra config desde .bashrc existente
#  - Compatible con sudo
# ============================================================

LOG="$HOME/.setup-terminal.log"
ERROR_MSG=""
ERROR_FIX=""

BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'
RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'

> "$LOG"

log() { echo "[$(date '+%H:%M:%S')] $*" >> "$LOG"; }

ok()    { echo -e "  ${GREEN}✔${NC} $1"; }
fail()  { echo -e "  ${RED}✘${NC} $1"; }
bold()  { echo -e "${BOLD}$1${NC}"; }
header(){ echo ""; bold "  $1"; echo ""; }

run() {
  local desc="$1" cmd="$2" fix="${3:-}"
  printf "  ${CYAN}→${NC} %-54s " "$desc"
  log "[RUN] $desc -> $cmd"
  if eval "$cmd" >> "$LOG" 2>&1; then
    echo -e "\r  ${GREEN}✔${NC} ${desc}"
    log "[OK]  $desc"
  else
    local ec=$?
    echo -e "\r  ${RED}✘${NC} ${desc}"
    log "[ERR] $desc (exit $ec)"
    ERROR_MSG="$desc"
    ERROR_FIX="$fix"
    return 1
  fi
}

trap_error() {
  local ec=$?
  echo ""
  echo -e "  ${RED}${BOLD}✘ ERROR:${NC} Fallo: ${ERROR_MSG:-paso desconocido}"
  echo ""
  if [[ -n "$ERROR_FIX" ]]; then
    echo -e "  ${YELLOW}${BOLD}Solucion sugerida:${NC}"
    echo -e "  ${YELLOW}  $ERROR_FIX${NC}"
    echo ""
  fi
  echo -e "  ${YELLOW}Log completo:${NC} $LOG"
  echo -e "  ${YELLOW}Ultimas lineas:${NC}"
  tail -5 "$LOG" | sed 's/^/  /'
  echo ""
  exit $ec
}

trap trap_error ERR

# ============================================================
# 1. DETECTAR DISTRO
# ============================================================
detect_pkg_manager() {
  header "Detectando sistema"
  if   command -v apt &>/dev/null; then
    PKG="apt";     PKG_INSTALL="sudo apt install -y -qq"
    PKG_UPDATE="sudo apt update -qq"
  elif command -v dnf &>/dev/null; then
    PKG="dnf";    PKG_INSTALL="sudo dnf install -y -q"
    PKG_UPDATE="sudo dnf check-update -q || true"
  elif command -v pacman &>/dev/null; then
    PKG="pacman"; PKG_INSTALL="sudo pacman -S --noconfirm -q"
    PKG_UPDATE="sudo pacman -Sy --noconfirm -q"
  elif command -v zypper &>/dev/null; then
    PKG="zypper"; PKG_INSTALL="sudo zypper install -y -q"
    PKG_UPDATE="sudo zypper refresh -q"
  else
    fail "No se detecto apt/dnf/pacman/zypper"
    echo -e "  ${YELLOW}Edita el script y agrega tu gestor de paquetes${NC}"
    exit 1
  fi
  local distro=$(grep "^ID=" /etc/os-release 2>/dev/null | cut -d= -f2 || echo "$PKG")
  ok "Distro: $distro  |  Gestor: $PKG"
}

# ============================================================
# 2. INSTALAR ZSH + DEPENDENCIAS
# ============================================================
install_deps() {
  header "Instalando zsh y dependencias"

  if command -v zsh &>/dev/null; then
    ok "zsh ya instalado ($(zsh --version | head -1))"
  else
    run "Instalando zsh" "$PKG_INSTALL zsh" \
      "$PKG_INSTALL zsh"
  fi

  local base_pkgs="git curl wget gcc g++ cmake make"
  local extra_pkgs=""

  case "$PKG" in
    apt)   extra_pkgs="lsd" ;;
    dnf)   extra_pkgs="lsd glibc-static libstdc++-static" ;;
    pacman) extra_pkgs="lsd" ;;
    zypper) extra_pkgs="lsd" ;;
  esac

  run "Instalando paquetes base" "$PKG_INSTALL $base_pkgs $extra_pkgs" \
    "$PKG_INSTALL $base_pkgs $extra_pkgs"
}

# ============================================================
# 3. CAMBIAR SHELL A ZSH
# ============================================================
change_shell() {
  header "Configurando zsh como shell por defecto"

  if [[ "$SHELL" == *zsh ]]; then
    ok "zsh ya es el shell por defecto"
    return
  fi

  local zsh_path
  zsh_path=$(command -v zsh)

  if ! grep -q "^$zsh_path$" /etc/shells 2>/dev/null; then
    run "Agregando zsh a /etc/shells" "echo '$zsh_path' | sudo tee -a /etc/shells" \
      "echo '$zsh_path' | sudo tee -a /etc/shells"
  fi

  run "Cambiando shell de $USER a zsh" \
    "sudo chsh -s '$zsh_path' '$USER'" \
    "sudo chsh -s $(which zsh) $USER"

  echo -e "  ${YELLOW}⚠ IMPORTANTE:${NC} El cambio de shell requiere:"
  echo -e "  ${YELLOW}  • Cerrar sesion y volver a entrar, o${NC}"
  echo -e "  ${YELLOW}  • ${BOLD}Reiniciar la maquina${NC}${YELLOW} (recomendado)${NC}"
  echo -e "  ${YELLOW}  • Temporal: ejecuta '${BOLD}exec zsh${NC}${YELLOW}' en esta sesion${NC}"
}

# ============================================================
# 4. MIGRAR DESDE .bashrc
# ============================================================
migrate_bashrc() {
  header "Migrando configuracion desde .bashrc"
  local bashrc="$HOME/.bashrc"
  local bashrc_d="$HOME/.bashrc.d"
  local migrated="$HOME/.zshrc.migrated"

  > "$migrated"

  if [[ ! -f "$bashrc" ]]; then
    ok "No hay .bashrc para migrar"
    return
  fi

  local count=0

  # Migrar export PATH (excluyendo duplicados de $HOME/.local/bin y $HOME/bin)
  while IFS= read -r line; do
    local clean="${line#"${line%%[![:space:]]*}"}"
    if [[ "$clean" =~ ^export\ PATH= ]] && [[ "$clean" != *'$HOME/.local/bin'* ]]; then
      echo "$clean" >> "$migrated"
      count=$((count+1))
    fi
  done < "$bashrc"

  # Migrar alias (excluyendo los que ya vamos a definir: ls, ll, la, lla, lt)
  if grep -q "^alias " "$bashrc" 2>/dev/null; then
    while IFS= read -r line; do
      local clean="${line#"${line%%[![:space:]]*}"}"
      if [[ "$clean" =~ ^alias\ (ls|ll|la|lla|lt)= ]]; then
        continue
      fi
      if [[ "$clean" =~ ^alias\  ]]; then
        echo "$clean" >> "$migrated"
        count=$((count+1))
      fi
    done < "$bashrc"
  fi

  # Migrar source o . de archivos (ej: . "$HOME/.cargo/env")
  if grep -qE '^(\..*|source .*)' "$bashrc" 2>/dev/null; then
    while IFS= read -r line; do
      local clean="${line#"${line%%[![:space:]]*}"}"
      if [[ "$clean" =~ ^(\..*|source\ .*) ]] \
        && [[ "$clean" != *'/etc/bashrc'* ]] \
        && [[ "$clean" != *'bashrc.d/'* ]]; then
        echo "$clean" >> "$migrated"
        count=$((count+1))
      fi
    done < "$bashrc"
  fi

  # Migrar .bashrc.d/*
  if [[ -d "$bashrc_d" ]]; then
    for f in "$bashrc_d"/*; do
      if [[ -f "$f" ]]; then
        echo "# from ${f##*/}" >> "$migrated"
        cat "$f" >> "$migrated"
        echo "" >> "$migrated"
        count=$((count+1))
      fi
    done
  fi

  if (( count > 0 )); then
    ok "Migradas $count lineas desde .bashrc"
  else
    ok "No se encontraron alias/PATH/source para migrar"
  fi
}

# ============================================================
# 5. INSTALAR OH MY ZSH
# ============================================================
install_ohmyzsh() {
  header "Instalando Oh My Zsh"
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "Oh My Zsh ya instalado"
    return
  fi
  run "Descargando e instalando Oh My Zsh" \
    'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' \
    "Ejecuta: sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
}

# ============================================================
# 6. INSTALAR PLUGINS
# ============================================================
install_plugins() {
  header "Instalando plugins y tema"
  ZC="$HOME/.oh-my-zsh/custom"

  if [[ -d "$ZC/plugins/zsh-autosuggestions" ]]; then
    ok "zsh-autosuggestions"
  else
    run "Instalando zsh-autosuggestions" \
      "git clone --depth=1 -q https://github.com/zsh-users/zsh-autosuggestions.git \"$ZC/plugins/zsh-autosuggestions\"" \
      "git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git $ZC/plugins/zsh-autosuggestions"
  fi

  if [[ -d "$ZC/plugins/zsh-syntax-highlighting" ]]; then
    ok "zsh-syntax-highlighting"
  else
    run "Instalando zsh-syntax-highlighting" \
      "git clone --depth=1 -q https://github.com/zsh-users/zsh-syntax-highlighting.git \"$ZC/plugins/zsh-syntax-highlighting\"" \
      "git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZC/plugins/zsh-syntax-highlighting"
  fi

  if [[ -d "$ZC/plugins/zsh-autocomplete" ]]; then
    ok "zsh-autocomplete"
  else
    run "Instalando zsh-autocomplete" \
      "git clone --depth=1 -q https://github.com/marlonrichert/zsh-autocomplete.git \"$ZC/plugins/zsh-autocomplete\"" \
      "git clone --depth=1 https://github.com/marlonrichert/zsh-autocomplete.git $ZC/plugins/zsh-autocomplete"
  fi

  if [[ -d "$ZC/themes/powerlevel10k" ]]; then
    ok "Powerlevel10k"
  else
    run "Instalando Powerlevel10k" \
      "git clone --depth=1 -q https://github.com/romkatv/powerlevel10k.git \"$ZC/themes/powerlevel10k\"" \
      "git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZC/themes/powerlevel10k"
  fi

  # gitstatusd
  local gs="$ZC/themes/powerlevel10k/gitstatus"
  if [[ -f "$gs/usrbin/gitstatusd" ]]; then
    ok "gitstatusd compilado"
  else
    run "Compilando gitstatusd" \
      "mkdir -p \"$gs/deps\" && cd \"$gs\" && ./build -w" \
      "cd $ZC/themes/powerlevel10k/gitstatus && mkdir -p deps && ./build -w"
  fi
}

# ============================================================
# 7. GENERAR CONFIGURACIONES
# ============================================================
write_zshenv() {
  header "Generando archivos de configuracion"
  cat > "$HOME/.zshenv" << 'ZSHEOF'
. "$HOME/.cargo/env"
ZSHEOF
  ok "~/.zshenv generado (cargo env)"
}

write_zshrc() {
  local migrated="$HOME/.zshrc.migrated"

  cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
zstyle ':omz:update' mode disabled

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

source "$ZSH/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

typeset -U path PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# ---- Migrado desde .bashrc ----
ZSHRC_EOF

  # Insertar config migrada si existe
  if [[ -s "$migrated" ]]; then
    cat "$migrated" >> "$HOME/.zshrc"
    rm -f "$migrated"
    ok "Configuracion de .bashrc importada"
  else
    rm -f "$migrated"
  fi

  cat >> "$HOME/.zshrc" << 'ZSHRC_EOF'
# ---- LS_COLORS ----
LS_COLORS="di=01;34:fi=00:ex=01;32:ln=01;36:"
LS_COLORS+="*.sh=01;32:*.bash=01;32:*.zsh=01;32:*.fish=01;32:"
LS_COLORS+="*.md=01;33:*.txt=00;37:"
LS_COLORS+="*.zip=01;31:*.tar=01;31:*.gz=01;31:*.xz=01;31:*.bz2=01;31:*.7z=01;31:*.rar=01;31:"
LS_COLORS+="*.jpg=01;35:*.jpeg=01;35:*.png=01;35:*.gif=01;35:*.svg=01;35:"
LS_COLORS+="*.mp4=01;35:*.mkv=01;35:*.mov=01;35:"
LS_COLORS+="*.mp3=01;36:*.flac=01;36:*.wav=01;36:*.ogg=01;36:"
LS_COLORS+="*.pdf=01;31:*.deb=01;31:*.rpm=01;31:"
LS_COLORS+="*.c=01;33:*.cpp=01;33:*.h=01;33:*.py=01;33:*.js=01;33:*.ts=01;33:*.html=01;33:*.css=01;33:*.json=01;33:*.yaml=01;33:*.yml=01;33:"
export LS_COLORS

alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -a'
alias lla='lsd -la'
alias lt='lsd --tree'

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
ZSHRC_EOF

  ok "~/.zshrc generado"
}

write_p10k() {
  cat > "$HOME/.p10k.zsh" << 'P10K_EOF'
# Generated by Powerlevel10k. Options: nerdfont-v3 + powerline,
# small icons, pure, 2 lines, sparse, transient_prompt, instant_prompt=verbose.

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'
() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'
  [[ $ZSH_VERSION == (5.<1->*|<6->.*) ]] || return
  local grey='242' red='1' yellow='3' blue='4' magenta='5' cyan='6' white='7'
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs command_execution_time newline virtualenv prompt_char)
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(newline)
  typeset -g POWERLEVEL9K_BACKGROUND=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$magenta
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='❮'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OVERWRITE_STATE=false
  typeset -g POWERLEVEL9K_VIRTUALENV_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
  typeset -g POWERLEVEL9K_VIRTUALENV_{LEFT,RIGHT}_DELIMITER=
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE="%F{$white}%n%f%F{$grey}@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE="%F{$grey}%n@%m%f"
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION=
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_THRESHOLD=5
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_PRECISION=0
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FORMAT='d h m s'
  typeset -g POWERLEVEL9K_COMMAND_EXECUTION_TIME_FOREGROUND=$yellow
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_VCS_LOADING_TEXT=
  typeset -g POWERLEVEL9K_VCS_MAX_SYNC_LATENCY_SECONDS=0
  typeset -g POWERLEVEL9K_VCS_{INCOMING,OUTGOING}_CHANGESFORMAT_FOREGROUND=$cyan
  typeset -g POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-aheadbehind)
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON=
  typeset -g POWERLEVEL9K_VCS_COMMIT_ICON='@'
  typeset -g POWERLEVEL9K_VCS_{STAGED,UNSTAGED,UNTRACKED}_ICON=
  typeset -g POWERLEVEL9K_VCS_DIRTY_ICON='*'
  typeset -g POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=':⇣'
  typeset -g POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=':⇡'
  typeset -g POWERLEVEL9K_VCS_{COMMITS_AHEAD,COMMITS_BEHIND}_MAX_NUM=1
  typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='${${${P9K_CONTENT/⇣* :⇡/⇣⇡}// }//:/ }'
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=$grey
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true
  (( ! $+functions[p10k] )) || p10k reload
}
typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
P10K_EOF
  ok "~/.p10k.zsh generado"
}

# ============================================================
# 8. RESUMEN
# ============================================================
print_summary() {
  echo ""
  echo -e "  ${GREEN}${BOLD}╔════════════════════════════════════════════════════╗${NC}"
  echo -e "  ${GREEN}${BOLD}║       INSTALACION COMPLETADA                       ║${NC}"
  echo -e "  ${GREEN}${BOLD}╚════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${GREEN}✔${NC} zsh ($(zsh --version 2>/dev/null | head -1 | cut -d' ' -f1-2))"
  echo -e "  ${GREEN}✔${NC} Oh My Zsh + plugins (autosuggestions, highlight, autocomplete)"
  echo -e "  ${GREEN}✔${NC} Powerlevel10k + gitstatusd"
  echo -e "  ${GREEN}✔${NC} lsd + aliases (ls, ll, la, lla, lt)"
  if [[ -f "$HOME/.zshrc.migrated" ]] || grep -q "Migrado desde" "$HOME/.zshrc" 2>/dev/null; then
    echo -e "  ${GREEN}✔${NC} Configuracion existente migrada (.bashrc → .zshrc)"
  fi
  echo ""
  echo -e "  ${BOLD}⚠ PASOS FINALES (OBLIGATORIO):${NC}"
  echo -e "  ${YELLOW}  El cambio de shell NO se aplica hasta que:${NC}"
  echo -e "  ${YELLOW}  • Cierres sesion y vuelvas a entrar, o${NC}"
  echo -e "  ${YELLOW}  • ${BOLD}Reinicies la maquina${NC}${YELLOW} (recomendado)${NC}"
  echo ""
  echo -e "  ${BOLD}Opcional:${NC}"
  echo -e "  • Para probar sin reiniciar: ${YELLOW}exec zsh${NC}"
  echo -e "  • Instala una ${BOLD}Nerd Font${NC} en tu terminal:"
  echo -e "    https://www.nerdfonts.com/font-downloads"
  echo -e "  • Para reconfigurar el prompt: ${YELLOW}p10k configure${NC}"
  echo ""
  echo -e "  ${CYAN}Log:${NC} $LOG"
  echo ""
}

# ============================================================
# MAIN
# ============================================================
echo ""
echo -e "  ${BOLD}╔════════════════════════════════════════════════════╗${NC}"
echo -e "  ${BOLD}║          Terminal Setup - james@blackbox          ║${NC}"
echo -e "  ${BOLD}╚════════════════════════════════════════════════════╝${NC}"
echo ""

detect_pkg_manager
install_deps
change_shell
migrate_bashrc
install_ohmyzsh
install_plugins
write_zshenv
write_zshrc
write_p10k
print_summary