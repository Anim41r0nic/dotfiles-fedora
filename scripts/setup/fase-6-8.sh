#!/bin/bash
# FASES 6-8 (parte root) — Extensiones GNOME, zram con zstd y virtualización
# Ejecutar con: sudo bash ~/dotfiles/scripts/setup/fase-6-8.sh
# La configuración visual de GNOME es de usuario y la aplica Claude sin sudo.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }
step() { echo; echo "==> $*"; }
USERNAME="${SUDO_USER:-marc}"

step "FASE 6: extensiones de GNOME empaquetadas por Fedora (se actualizan con el sistema)"
dnf install -y gnome-tweaks gnome-extensions-app \
    gnome-shell-extension-dash-to-dock \
    gnome-shell-extension-appindicator \
    gnome-shell-extension-blur-my-shell

step "FASE 7: zram con compresión zstd"
# Fedora usa lzo-rle por defecto. zstd comprime bastante más (≈3:1 frente a ≈2:1)
# con un coste de CPU pequeño: con 8 GB de RAM eso es más memoria efectiva antes
# de que el sistema tenga que expulsar caché. Tamaño igual al de Fedora.
# Para revertir: sudo rm /etc/systemd/zram-generator.conf y reiniciar.
cat > /etc/systemd/zram-generator.conf <<'EOF'
# Override de /usr/lib/systemd/zram-generator.conf (ver LINUX_SETUP.md)
[zram0]
zram-size = min(ram, 8192)
compression-algorithm = zstd
EOF
echo "zram: se aplicará en el próximo reinicio."

step "FASE 8: virtualización (KVM/QEMU/libvirt/virt-manager)"
dnf install -y libvirt-daemon-kvm libvirt-daemon-config-network virt-manager virt-install
# Fedora usa los demonios modulares de libvirt (virtqemud, virtnetworkd...) activados por socket.
for d in qemu network nodedev storage secret interface; do
    systemctl enable --now "virt${d}d.socket" 2>/dev/null || true
done
usermod -aG libvirt "$USERNAME"
echo "Usuario $USERNAME añadido al grupo libvirt (efectivo tras cerrar sesión)."
virt-host-validate qemu || true

step "Extra: silenciar el aviso 'Emulate Docker CLI using podman'"
touch /etc/containers/nodocker

step "Verificación de PostgreSQL del sistema (arrancar, consultar como $USERNAME, parar)"
systemctl start postgresql
sudo -u "$USERNAME" psql -tAc "SELECT 'PostgreSQL OK como ' || current_user || ' en ' || current_database();"
systemctl stop postgresql
echo "postgresql: $(systemctl is-active postgresql || true) (no arranca al inicio; usa: sudo systemctl start postgresql)"

echo
echo "FASES 6-8 (root) completadas. Reinicia al final para aplicar zram y el grupo libvirt."
