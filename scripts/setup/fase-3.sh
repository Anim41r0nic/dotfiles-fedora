#!/bin/bash
# FASE 3 — Configuración base + Snapper + actualización del sistema
# Ejecutar con: sudo bash ~/dotfiles/scripts/setup/fase-3.sh
# No borra datos ni toca particiones ni el bootloader.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }
HERE="$(cd "$(dirname "$0")" && pwd)"
USERNAME="${SUDO_USER:-marc}"

step() { echo; echo "==> $*"; }

step "Hostname -> marc-laptop"
hostnamectl set-hostname marc-laptop

step "Instalando snapper y el plugin actions de dnf5"
dnf install -y snapper libdnf5-plugin-actions

step "Configurando Snapper para / (root) y /home"
# create-config crea el subvolumen .snapshots; solo si no existe ya la config.
snapper list-configs | grep -q '^root ' || snapper -c root create-config /
snapper list-configs | grep -q '^home ' || snapper -c home create-config /home

# Política de retención (sin quotas de Btrfs: penalizan el rendimiento).
# root: timeline moderado + hasta 10 snapshots "number" (pares pre/post de dnf).
snapper -c root set-config \
    TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes NUMBER_CLEANUP=yes \
    TIMELINE_MIN_AGE=1800 NUMBER_MIN_AGE=1800 \
    TIMELINE_LIMIT_HOURLY=5 TIMELINE_LIMIT_DAILY=7 TIMELINE_LIMIT_WEEKLY=2 \
    TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0 \
    NUMBER_LIMIT=10 NUMBER_LIMIT_IMPORTANT=5 \
    ALLOW_USERS="$USERNAME" SYNC_ACL=yes
# home: protege frente a borrados accidentales recientes (NO es un backup).
snapper -c home set-config \
    TIMELINE_CREATE=yes TIMELINE_CLEANUP=yes NUMBER_CLEANUP=yes \
    TIMELINE_MIN_AGE=1800 NUMBER_MIN_AGE=1800 \
    TIMELINE_LIMIT_HOURLY=4 TIMELINE_LIMIT_DAILY=5 TIMELINE_LIMIT_WEEKLY=0 \
    TIMELINE_LIMIT_MONTHLY=0 TIMELINE_LIMIT_YEARLY=0 \
    NUMBER_LIMIT=5 NUMBER_LIMIT_IMPORTANT=3 \
    ALLOW_USERS="$USERNAME" SYNC_ACL=yes

systemctl enable --now snapper-timeline.timer snapper-cleanup.timer

step "Instalando hook de snapshots pre/post para dnf"
install -m 0755 -o root -g root "$HERE/files/dnf-snapper-hook" /usr/local/sbin/dnf-snapper-hook
install -d -m 0755 /etc/dnf/libdnf5-plugins/actions.d
install -m 0644 -o root -g root "$HERE/files/snapper.actions" /etc/dnf/libdnf5-plugins/actions.d/snapper.actions
restorecon -v /usr/local/sbin/dnf-snapper-hook /etc/dnf/libdnf5-plugins/actions.d/snapper.actions

step "Snapshot manual del estado actual (importante)"
snapper -c root create -c number -u important=yes -d "Estado inicial antes de fase 3"
snapper -c home create -c number -u important=yes -d "Estado inicial antes de fase 3"

step "Eliminando Claude Desktop no oficial (paquete, repo, clave GPG y cachés)"
if rpm -q claude-desktop-unofficial >/dev/null 2>&1; then
    dnf remove -y claude-desktop-unofficial
fi
rm -f /etc/yum.repos.d/claude-desktop.repo
rpm -q gpg-pubkey --qf '%{NVR}\t%{SUMMARY}\n' \
    | awk -F'\t' '/Claude Desktop Debian/ {print $1}' | xargs -r rpm -e
rm -rf /var/cache/libdnf5/claude-desktop-*
# Restos no gestionados por rpm (si los hubiera)
rm -rf /usr/lib/claude-desktop-unofficial

step "Desactivando repo google-chrome (lo gestiona fedora-workstation-repositories)"
dnf config-manager setopt google-chrome.enabled=0

step "Actualizando el sistema (dnf creará snapshots pre/post automáticamente)"
dnf upgrade --refresh -y

step "Snapshots actuales de root"
snapper -c root list

echo
echo "FASE 3 completada. Reinicia el equipo para cargar el kernel/librerías nuevos."
