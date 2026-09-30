#!/bin/bash
# Aplica la configuración de GNOME (inspirada en macOS, sin romper GNOME).
# Uso: bash ~/dotfiles/gnome/apply-gnome.sh     (sin sudo)
# Requiere: gnome-shell-extension-{dash-to-dock,appindicator,blur-my-shell}
# Para volver atrás: dconf load / < ~/dotfiles/gnome/.dconf-antes-fase6.ini
set -euo pipefail

g() { gsettings set "$@"; }

# --- Extensiones (solo 3, empaquetadas por Fedora) ---------------------------
for ext in dash-to-dock@micxgx.gmail.com appindicatorsupport@rgcjonas.gmail.com blur-my-shell@aunetx; do
    gnome-extensions enable "$ext"
done
g org.gnome.shell disable-user-extensions false

# --- Ventanas ------------------------------------------------------------------
# Botones a la izquierda como en macOS (cerrar, minimizar, maximizar).
g org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu'
g org.gnome.mutter center-new-windows true
g org.gnome.mutter edge-tiling true

# --- Apariencia ----------------------------------------------------------------
g org.gnome.desktop.interface color-scheme 'prefer-dark'
g org.gnome.desktop.interface enable-animations true
g org.gnome.desktop.interface show-battery-percentage true
g org.gnome.desktop.interface clock-show-weekday true
g org.gnome.desktop.interface font-antialiasing 'rgba'

# --- Workspaces y gestos -------------------------------------------------------
# Gestos nativos de GNOME (Wayland): 3 dedos arriba = vista general,
# 3 dedos izquierda/derecha = cambiar de workspace. No necesitan extensión.
g org.gnome.mutter dynamic-workspaces true
g org.gnome.mutter workspaces-only-on-primary true
g org.gnome.desktop.wm.keybindings switch-to-workspace-left  "['<Super>Page_Up','<Control><Alt>Left']"
g org.gnome.desktop.wm.keybindings switch-to-workspace-right "['<Super>Page_Down','<Control><Alt>Right']"

# --- Touchpad ------------------------------------------------------------------
g org.gnome.desktop.peripherals.touchpad tap-to-click true
g org.gnome.desktop.peripherals.touchpad natural-scroll true
g org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
g org.gnome.desktop.peripherals.touchpad disable-while-typing true

# --- Dash to Dock: dock inferior, se oculta cuando una ventana lo tapa ---------
D=org.gnome.shell.extensions.dash-to-dock
g $D dock-position 'BOTTOM'
g $D dock-fixed false
g $D intellihide true
g $D extend-height false
g $D dash-max-icon-size 44
g $D show-trash false
g $D show-mounts false
g $D click-action 'minimize-or-previews'
g $D scroll-action 'cycle-windows'
g $D transparency-mode 'DYNAMIC'
g $D running-indicator-style 'DOTS'
g $D custom-theme-shrink true
g $D apply-custom-theme false

# --- Blur my Shell: transparencias moderadas -----------------------------------
# Desenfoque estático en panel y vista general (barato para la GPU integrada).
# Sin blur en ventanas de aplicaciones: coste de GPU/batería sin ganancia real.
B=org.gnome.shell.extensions.blur-my-shell
g $B.panel blur true
g $B.panel static-blur true
g $B.overview blur true
g $B.applications blur false
g $B.dash-to-dock blur false

# --- Apps favoritas en el dock -------------------------------------------------
g org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Ptyxis.desktop', 'com.microsoft.VSCode.desktop', 'pycharm-community.desktop', 'codeblocks.desktop', 'org.gnome.Settings.desktop']"

# --- Firefox como navegador por defecto ------------------------------------------
xdg-settings set default-web-browser org.mozilla.firefox.desktop

echo "GNOME configurado."
