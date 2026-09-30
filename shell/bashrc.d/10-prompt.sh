# Prompt limpio con rama de Git:  marc@marc-laptop ~/proyecto (main *+) $
# git-prompt.sh viene con el paquete git de Fedora.
if [ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]; then
    . /usr/share/git-core/contrib/completion/git-prompt.sh
    GIT_PS1_SHOWDIRTYSTATE=1      # * cambios sin añadir, + cambios en staging
    GIT_PS1_SHOWUNTRACKEDFILES=1  # % archivos sin seguimiento
    GIT_PS1_SHOWUPSTREAM=auto     # < > = respecto al remoto
    PS1='\[\e[1;32m\]\u@\h\[\e[0m\] \[\e[1;34m\]\w\[\e[0m\]\[\e[33m\]$(__git_ps1 " (%s)")\[\e[0m\] \$ '
fi
