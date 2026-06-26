# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' mode disabled  # desactivar update checks para rapidez

# Estrategia de autosuggestions: history + completion
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Color de las sugerencias
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"
# Sugerencias asincronas (no bloquean el prompt)
ZSH_AUTOSUGGEST_USE_ASYNC=1
# No sugerir en buffers grandes (ej. al pegar)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
# Limpiar sugerencia al pegar texto
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
# zsh-autocomplete debe cargarse ANTES de oh-my-zsh.sh para
# manejar compinit correctamente. NO va en plugins=()
source "$ZSH/custom/plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Variables de entorno (adb, Android Studio, opencode, etc)
typeset -U path PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH=/home/james/.opencode/bin:$PATH
export PATH=/opt/platform-tools:$PATH
export PATH=/opt/android-studio/bin:$PATH

# Colores para archivos (estilo elementary theme)
# di=directorio azul, fi=archivo, ex=ejecutable verde
# *.sh=verde, *.md=amarillo, *.txt=blanco, *.zip=rojo, *.jpg=magenta
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

# Aliases
alias ls='lsd'
alias ll='lsd -l'
alias la='lsd -a'
alias lla='lsd -la'
alias lt='lsd --tree'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
