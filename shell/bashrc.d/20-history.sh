# Historial grande, sin duplicados y compartido entre terminales.
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T  '
shopt -s histappend
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# fzf: Ctrl+R busca en el historial, Ctrl+T busca archivos, Alt+C cambia de carpeta.
[ -f /usr/share/fzf/shell/key-bindings.bash ] && . /usr/share/fzf/shell/key-bindings.bash

# Pequeñas comodidades
shopt -s autocd cdspell checkwinsize globstar
