# Aliases útiles (sencillos, sin ocultar comandos peligrosos).
alias ll='ls -lh --group-directories-first --color=auto'
alias la='ls -lhA --group-directories-first --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias df='df -h -x tmpfs -x devtmpfs'
alias free='free -h'
alias ports='ss -tulnp'            # puertos en escucha

# Git
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gd='git diff'

# C++: compilar rápido con avisos y depuración.  Uso: cpp main.cpp  -> ./main
cpp() { local src="$1"; shift; g++ -std=c++20 -Wall -Wextra -g "$src" -o "${src%.*}" "$@"; }

# Python: crear/activar entornos en ~/venvs.  Uso: mkvenv nombre / venv nombre
mkvenv() { python3 -m venv "$HOME/venvs/$1" && . "$HOME/venvs/$1/bin/activate"; }
venv()   { . "$HOME/venvs/$1/bin/activate"; }

# PostgreSQL del sistema (no arranca al inicio para ahorrar RAM)
alias pg-start='sudo systemctl start postgresql'
alias pg-stop='sudo systemctl stop postgresql'

# Scripts de mantenimiento (~/dotfiles/scripts)
export PATH="$HOME/dotfiles/scripts:$PATH"
