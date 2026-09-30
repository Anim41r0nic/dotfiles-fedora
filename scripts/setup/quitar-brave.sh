#!/bin/bash
# Desinstala Brave, su repositorio y su clave GPG (Firefox pasa a ser el navegador).
# Ejecutar con: sudo bash ~/dotfiles/scripts/setup/quitar-brave.sh
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }

echo "==> Desinstalando Brave (dnf creará snapshots pre/post)"
rpm -q brave-browser >/dev/null && dnf remove -y brave-browser

echo "==> Quitando el repositorio y la clave de Brave"
rm -f /etc/yum.repos.d/brave-browser.repo
rpm -q gpg-pubkey --qf '%{NVR}\t%{SUMMARY}\n' | awk -F'\t' '/Brave/ {print $1}' | xargs -r rpm -e
rm -rf /var/cache/libdnf5/brave-browser-*

echo "==> Comprobación"
rpm -q brave-browser || true
dnf repolist | grep -i brave || echo "Repo de Brave eliminado."
echo "Hecho."
