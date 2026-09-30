#!/bin/bash
# Restaura la configuración personal desde ~/dotfiles (sin sudo, idempotente).
# Los archivos existentes se guardan como *.bak antes de enlazarlos.
set -euo pipefail
DOT="$(cd "$(dirname "$0")" && pwd)"

link() {  # link <origen en dotfiles> <destino>
    local src="$DOT/$1" dst="$2"
    if [[ -e $dst && ! -L $dst ]]; then mv "$dst" "$dst.bak"; echo "  copia: $dst.bak"; fi
    ln -sfn "$src" "$dst"; echo "  $dst -> $src"
}

echo "==> Shell (bash)"
mkdir -p "$HOME/.bashrc.d"
for f in "$DOT"/shell/bashrc.d/*.sh; do link "shell/bashrc.d/$(basename "$f")" "$HOME/.bashrc.d/$(basename "$f")"; done

echo "==> Git"
link git/gitconfig "$HOME/.gitconfig"

echo "==> Carpetas de trabajo"
mkdir -p "$HOME/venvs"

echo "==> Scripts ejecutables"
chmod +x "$DOT"/scripts/{update-system,system-info,backup-config,cleanup-system}

if [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]]; then
    echo "==> GNOME"
    bash "$DOT/gnome/apply-gnome.sh"
fi
echo "Hecho. Abre una terminal nueva para cargar el shell."
