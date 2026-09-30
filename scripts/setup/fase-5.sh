#!/bin/bash
# FASE 5 — Desarrollo: C/C++, Python, bases de datos, contenedores, Java, IDEs (Firefox viene con Fedora)
# Ejecutar con: sudo bash ~/dotfiles/scripts/setup/fase-5.sh
# Solo instala paquetes de repos oficiales (Fedora, Microsoft y el COPR de
# PyCharm incluido en fedora-workstation-repositories). No borra datos.
set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "Ejecuta con sudo"; exit 1; }
step() { echo; echo "==> $*"; }
USERNAME="${SUDO_USER:-marc}"

step "Repositorio oficial de Visual Studio Code (Microsoft)"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

step "Instalando paquetes (dnf creará snapshots pre/post)"
PKGS=(
    # C/C++
    gcc gcc-c++ make cmake gdb valgrind clang-tools-extra
    # Python (venv viene con python3; pip solo se usa dentro de venvs)
    python3-pip python3-devel
    # Bases de datos
    postgresql-server postgresql-contrib sqlite
    # Contenedores (podman ya está instalado)
    podman-compose podman-docker
    # Java LTS disponible en Fedora 44
    java-25-openjdk-devel
    # IDEs y utilidades
    code pycharm-community gh
    lm_sensors fzf
)
dnf install -y "${PKGS[@]}"

step "PostgreSQL: inicializando el cluster (solo si no existe)"
if [[ ! -f /var/lib/pgsql/data/PG_VERSION ]]; then
    postgresql-setup --initdb
fi
# No se habilita al arranque para ahorrar RAM: arráncalo cuando lo necesites con
#   sudo systemctl start postgresql
# Por defecto solo escucha en localhost (listen_addresses = 'localhost').
systemctl start postgresql
sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='$USERNAME'" | grep -q 1 \
    || sudo -u postgres createuser --createdb "$USERNAME"
sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='$USERNAME'" | grep -q 1 \
    || sudo -u postgres createdb -O "$USERNAME" "$USERNAME"
systemctl stop postgresql
echo "PostgreSQL arranca y para correctamente (estado: $(systemctl is-active postgresql || true))"

step "Quitando VS Code Flatpak (sustituido por el RPM oficial; no tenía ajustes guardados)"
flatpak uninstall -y --system com.visualstudio.code || true

echo
echo "FASE 5 completada."
