#!/bin/bash
# FASE 4 — Seguridad: firewall, firmware y verificación de snapshots
# Ejecutar con: sudo bash ~/dotfiles/scripts/setup/fase-4.sh
# No borra datos ni toca particiones ni el bootloader. Todo es reversible.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }
step() { echo; echo "==> $*"; }
ZONE=FedoraWorkstation

step "Snapshot previo"
snapper -c root create -c number -u important=yes -d "Antes de fase 4 (seguridad)"

step "Firewall: cerrando el rango abierto por defecto 1025-65535 en la zona $ZONE"
# Fedora Workstation abre todos los puertos altos para "comodidad". Lo quitamos
# y mantenemos solo lo necesario. Para revertir:
#   firewall-cmd --permanent --zone=$ZONE --add-port=1025-65535/tcp --add-port=1025-65535/udp
firewall-cmd --permanent --zone="$ZONE" --remove-port=1025-65535/tcp --remove-port=1025-65535/udp || true
# mDNS: descubrimiento de impresoras / dispositivos .local en la red local.
firewall-cmd --permanent --zone="$ZONE" --add-service=mdns
firewall-cmd --reload
firewall-cmd --zone="$ZONE" --list-all

step "Firmware: activando la comprobación periódica de metadatos de fwupd (no instala nada solo)"
systemctl enable --now fwupd-refresh.timer

step "Comprobaciones"
echo "SELinux: $(getenforce)"
echo "firewalld: $(systemctl is-active firewalld)"
echo "sshd: $(systemctl is-enabled sshd 2>/dev/null || echo 'no instalado/desactivado')"
btrfs subvolume list / | sed 's/^/  /'
snapper -c root list | tail -3

echo
echo "FASE 4 completada."
