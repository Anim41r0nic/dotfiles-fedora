#!/bin/bash
# RICE — FASE 4: dependencias del escritorio "neon sunset" (GNOME 50 nativo)
# Ejecutar con: sudo bash ~/dotfiles/scripts/setup/rice-fase-4.sh
# Solo instala 4 paquetes de los repos oficiales de Fedora. No borra nada.
# Revertir: sudo dnf remove gnome-shell-extension-system-monitor adw-gtk3-theme \
#           jetbrains-mono-fonts fastfetch   (o snapper undochange del snapshot de abajo)
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }
step() { echo; echo "==> $*"; }

step "Snapshot de Snapper (punto de restauración del sistema)"
snapper -c root create --description "antes de rice-fase-4" --cleanup-algorithm number
snapper -c root list | tail -3

step "Instalando paquetes (todos de los repos fedora/updates)"
PKGS=(
    gnome-shell-extension-system-monitor  # monitor CPU/RAM/red del panel (extensión oficial de GNOME 50)
    adw-gtk3-theme                        # apps GTK3 con el mismo aspecto que libadwaita
    jetbrains-mono-fonts                  # fuente monoespaciada para la terminal
    fastfetch                             # info del sistema en la terminal (como en el vídeo)
)
dnf install -y "${PKGS[@]}"

step "Verificación"
rpm -q "${PKGS[@]}"
echo; echo "Listo. Vuelve a Claude Code y escribe: hecho"
