# dotcraft

Configuración automatizada de terminal: zsh + Oh My Zsh + Powerlevel10k + plugins.

## Instalación

```bash
./setup-terminal.sh
```

El script detecta la distro (apt/dnf/pacman/zypper), instala dependencias, configura zsh como shell por defecto, migra alias/PATH desde `.bashrc`, instala Oh My Zsh con plugins y genera el tema Powerlevel10k.

## Contenido

| Archivo | Descripción |
|---|---|
| `setup-terminal.sh` | Instalador portable |
| `.zshrc` | Configuración de zsh |
| `.p10k.zsh` | Tema Powerlevel10k (Pure-style, transient prompt) |
| `.zshenv` | Carga de `$HOME/.cargo/env` |

## Plugins

- **zsh-autosuggestions** — sugerencias basadas en historial
- **zsh-syntax-highlighting** — resaltado de sintaxis
- **zsh-autocomplete** — autocompletado interactivo
- **Powerlevel10k** — prompt rápido con gitstatusd

## Requisitos

- Linux (apt/dnf/pacman/zypper)
- curl, git
- sudo para instalar paquetes y cambiar shell
