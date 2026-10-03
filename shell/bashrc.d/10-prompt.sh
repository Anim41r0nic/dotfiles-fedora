# Prompt limpio en dos líneas (colores de la paleta "Neon Sunset" de Ptyxis):
#   ╭─ ~/proyecto  main *+  (venv)
#   ╰─❯                        ← ❯ en rojo si el último comando falló
# user@host solo aparece por SSH. git-prompt.sh viene con el paquete git de Fedora.
if [ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]; then
    . /usr/share/git-core/contrib/completion/git-prompt.sh
    GIT_PS1_SHOWDIRTYSTATE=1      # * cambios sin añadir, + cambios en staging
    GIT_PS1_SHOWUNTRACKEDFILES=1  # % archivos sin seguimiento
    GIT_PS1_SHOWUPSTREAM=auto     # < > = respecto al remoto
fi
VIRTUAL_ENV_DISABLE_PROMPT=1      # el venv lo mostramos nosotros

__prompt() {
    local ok=$?
    local dim='\[\e[38;5;97m\]' path='\[\e[1;96m\]' git='\[\e[95m\]' venv='\[\e[93m\]'
    local arrow='\[\e[38;5;215m\]' bad='\[\e[91m\]' host='\[\e[92m\]' r='\[\e[0m\]'
    local top="${dim}╭─${r} "
    [ -n "$SSH_CONNECTION" ] && top+="${host}\u@\h${r} "
    top+="${path}\w${r}"
    if declare -F __git_ps1 >/dev/null; then
        top+="${git}$(__git_ps1 '  %s')${r}"
    fi
    [ -n "$VIRTUAL_ENV" ] && top+="  ${venv}(${VIRTUAL_ENV##*/})${r}"
    [ $ok -ne 0 ] && arrow=$bad
    PS1="\n${top}\n${dim}╰─${arrow}❯${r} "
}
PROMPT_COMMAND="__prompt${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
