#!/bin/bash
# RICE — CUBO: programas del Gist (cava, cmatrix, cool-retro-term) + Extension Manager
# Ejecutar con: sudo bash ~/dotfiles/scripts/setup/rice-cubo.sh
# Solo instala desde los repos oficiales de Fedora y Flathub. No borra nada.
# Revertir: sudo dnf remove cava cmatrix cool-retro-term
#           sudo flatpak uninstall com.mattjakeman.ExtensionManager
#           (o snapper undochange del snapshot "antes de cubo")
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }
step() { echo; echo "==> $*"; }

step "Snapshot de Snapper (punto de restauración del sistema)"
snapper -c root create --description "antes de cubo" --cleanup-algorithm number
snapper -c root list | tail -2

step "Instalando cava, cmatrix y cool-retro-term (repos de Fedora)"
dnf install -y cava cmatrix cool-retro-term

step "Instalando Extension Manager (Flatpak de Flathub)"
flatpak install -y --noninteractive flathub com.mattjakeman.ExtensionManager

step "Verificación"
rpm -q cava cmatrix cool-retro-term
flatpak info com.mattjakeman.ExtensionManager | grep -E 'ID|Versión|Version'
echo; echo "Listo. Vuelve a Claude Code y escribe: hecho"
