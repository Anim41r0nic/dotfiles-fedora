# dotfiles — marc-laptop (Fedora 44 Workstation)

Configuración personal reproducible. **Sin contraseñas, tokens ni claves.**
Documentación completa del sistema: `~/LINUX_SETUP.md`.

## Estructura

```
install.sh              restaura todo (enlaces simbólicos + GNOME), sin sudo
shell/bashrc.d/         prompt con Git, historial + fzf, aliases (se enlazan en ~/.bashrc.d)
git/gitconfig           ~/.gitconfig (nombre, email, opciones)
gnome/apply-gnome.sh    ajustes de GNOME y de las 3 extensiones
gnome/dconf/            volcados que genera backup-config
scripts/                update-system, system-info, backup-config, cleanup-system
scripts/setup/          scripts root usados para montar el sistema (fases 3-8)
```

## Restaurar en una instalación nueva de Fedora

```bash
# 1. Clonar (si está en GitHub) o copiar la carpeta desde tu backup
git clone <url-de-tu-repo> ~/dotfiles

# 2. Paquetes y configuración de sistema (revisa cada script antes; piden sudo)
sudo bash ~/dotfiles/scripts/setup/fase-3.sh     # snapper + hook dnf + actualización
sudo bash ~/dotfiles/scripts/setup/fase-4.sh     # firewall + fwupd
sudo bash ~/dotfiles/scripts/setup/fase-5.sh     # desarrollo, IDEs, PostgreSQL
sudo bash ~/dotfiles/scripts/setup/fase-6-8.sh   # extensiones, zram zstd, libvirt
# (reiniciar)

# 3. Configuración de usuario
bash ~/dotfiles/install.sh
```

> Nota: `fase-3.sh` también contiene pasos de limpieza propios de este equipo
> (Claude Desktop no oficial, repo de Chrome) que en un sistema nuevo no hacen nada.

## Uso diario

```bash
update-system     # actualizar (snapshot + dnf + flatpak + firmware), pide confirmación
system-info       # estado del sistema
backup-config     # guardar la config de GNOME y hacer commit
cleanup-system    # limpieza con confirmación paso a paso
```

## Subir a GitHub (opcional)

```bash
gh auth login
gh repo create dotfiles --private --source ~/dotfiles --push
```
Repo **privado** recomendado: `git/gitconfig` contiene tu email.
