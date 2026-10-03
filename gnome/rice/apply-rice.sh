#!/bin/bash
# Escritorio "Neon Sunset" sobre GNOME 50 nativo (sin sudo).
# Uso: bash ~/dotfiles/gnome/rice/apply-rice.sh [dock|blur|tema|terminal|wallpaper|hanabi|cubo|todo]
# Requiere: rice-fase-4.sh (system-monitor, adw-gtk3, JetBrains Mono, fastfetch)
#           y Bibata-Modern-Ice en ~/.local/share/icons.
# Revertir: ver ~/dotfiles/backups/2026-10-03-pre-rice/RESTORE.md
set -euo pipefail

g() { gsettings set "$@"; }
DIR="$(cd "$(dirname "$0")" && pwd)"

dock() {
    local D=org.gnome.shell.extensions.dash-to-dock
    g $D dock-position 'BOTTOM'
    g $D extend-height false          # dock flotante, no barra de lado a lado
    g $D always-center-icons true
    g $D dash-max-icon-size 48
    g $D custom-theme-shrink true     # márgenes compactos alrededor de los iconos
    g $D apply-custom-theme false
    g $D apply-glossy-effect false
    # Fondo translúcido violeta oscuro (Blur my Shell añade el blur en la fase 7)
    g $D transparency-mode 'FIXED'
    g $D custom-background-color true
    g $D background-color '#1a0b2e'
    g $D background-opacity 0.35
    # Indicador de apps abiertas: puntos en color ámbar (acento naranja)
    g $D running-indicator-style 'DOTS'
    g $D custom-theme-customize-running-dots true
    g $D custom-theme-running-dots-color '#ffa348'
    g $D custom-theme-running-dots-border-width 0
    # Se esconde solo cuando una ventana lo tapa
    g $D dock-fixed false
    g $D autohide true
    g $D intellihide true
    g $D show-apps-at-top false       # botón de apps a la derecha, como en el vídeo
    g $D show-trash false
    g $D show-mounts false
}

blur() {
    local B=org.gnome.shell.extensions.blur-my-shell
    # Pipelines con blur ESTÁTICO (barato en la Iris Plus G7): radio moderado y
    # brillo ~0.6 para que el fondo se intuya pero el texto siga legible.
    g $B pipelines "{
      'pipeline_default': {'name': <'Default'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_000000000000'>, 'params': <{'radius': <30>, 'brightness': <0.6>}>}>]>},
      'pipeline_default_rounded': {'name': <'Default rounded'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_000000000001'>, 'params': <{'radius': <30>, 'brightness': <0.6>}>}>, <{'type': <'corner'>, 'id': <'effect_000000000002'>, 'params': <{'radius': <24>}>}>]>},
      'pipeline_panel': {'name': <'Panel'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_000000000003'>, 'params': <{'radius': <20>, 'brightness': <0.55>}>}>]>},
      'pipeline_dock': {'name': <'Dock'>, 'effects': <[<{'type': <'native_static_gaussian_blur'>, 'id': <'effect_000000000004'>, 'params': <{'radius': <24>, 'brightness': <0.65>}>}>, <{'type': <'corner'>, 'id': <'effect_000000000005'>, 'params': <{'radius': <20>}>}>]>}
    }"
    # Overview: fondo difuminado detrás de los workspaces
    g $B.overview blur true
    g $B.overview pipeline 'pipeline_default'
    # Carpetas de la cuadrícula de apps: translúcidas
    g $B.appfolder blur true
    # Panel: translúcido; transparente del todo dentro del Overview
    g $B.panel blur true
    g $B.panel pipeline 'pipeline_panel'
    g $B.panel static-blur true
    g $B.panel override-background true
    g $B.panel style-panel 0
    g $B.panel unblur-in-overview true
    # Dock: blur con esquinas redondeadas (sustituye el fondo de Dash to Dock)
    g $B.dash-to-dock blur true
    g $B.dash-to-dock pipeline 'pipeline_dock'
    g $B.dash-to-dock static-blur true
    g $B.dash-to-dock override-background true
    g $B.dash-to-dock style-dash-to-dock 0
    g $B.dash-to-dock unblur-in-overview true
    # Blur detrás de las ventanas: DESACTIVADO (es lo más costoso)
    g $B.applications blur false
}

tema() {
    local I=org.gnome.desktop.interface
    g $I color-scheme 'prefer-dark'
    g $I accent-color 'orange'               # ámbar, a juego con el atardecer
    g $I gtk-theme 'adw-gtk3-dark'           # apps GTK3 con aspecto libadwaita
    g $I icon-theme 'Adwaita'                # los del vídeo
    g $I cursor-theme 'Bibata-Modern-Ice'
    g $I cursor-size 24
    g $I font-name 'Adwaita Sans 11'
    g $I document-font-name 'Adwaita Sans 12'
    g $I monospace-font-name 'JetBrains Mono 11'
    # Monitor de CPU/RAM/red en el panel (extensión oficial de GNOME)
    gnome-extensions enable system-monitor@gnome-shell-extensions.gcampax.github.com 2>/dev/null ||
        g org.gnome.shell enabled-extensions "$(gsettings get org.gnome.shell enabled-extensions | sed "s/]$/, 'system-monitor@gnome-shell-extensions.gcampax.github.com']/")"
    local M=org.gnome.shell.extensions.system-monitor
    g $M show-cpu true
    g $M show-memory true
    g $M show-download true
    g $M show-upload false
    g $M show-swap false
}

terminal() {
    # Paleta propia (el prompt está en ~/dotfiles/shell/bashrc.d/10-prompt.sh)
    mkdir -p ~/.local/share/org.gnome.Ptyxis/palettes
    ln -sf "$DIR/ptyxis/neon-sunset.palette" ~/.local/share/org.gnome.Ptyxis/palettes/neon-sunset.palette
    local uuid; uuid=$(gsettings get org.gnome.Ptyxis default-profile-uuid | tr -d "'")
    local P="org.gnome.Ptyxis.Profile:/org/gnome/Ptyxis/Profiles/$uuid/"
    g "$P" palette 'neon-sunset'
    g "$P" opacity 0.9
    g org.gnome.Ptyxis use-system-font true   # = monospace-font-name (JetBrains Mono 11)
}

wallpaper() {
    local out=~/.local/share/backgrounds/neon-sunset.png
    mkdir -p "${out%/*}"
    [ -f "$out" ] || python3 "$DIR/../wallpaper/neon-sunset.py" "$out"
    g org.gnome.desktop.background picture-uri "file://$out"
    g org.gnome.desktop.background picture-uri-dark "file://$out"
    g org.gnome.desktop.background picture-options 'zoom'
    g org.gnome.desktop.screensaver picture-uri "file://$out"
}

hanabi() {
    # Fondo animado (requiere install-hanabi.sh). La imagen fija de wallpaper()
    # se mantiene como respaldo y para el blur de Blur my Shell.
    local UUID=hanabi-extension@jeffshee.github.io
    local SD=~/.local/share/gnome-shell/extensions/$UUID/schemas H=io.github.jeffshee.hanabi-extension
    local out=~/.local/share/backgrounds/neon-sunset.webm
    [ -f "$out" ] || python3 "$DIR/../wallpaper/neon-sunset-anim.py" "$out"
    hset() { gsettings --schemadir "$SD" set "$H" "$@"; }
    hset video-path "$out"
    hset mute true
    hset enable-va true                      # decodificación por hardware (VA-API)
    hset pause-on-maximize-or-fullscreen 1   # pausa con ventana maximizada/pantalla completa
    hset pause-on-battery 1                  # pausa con batería baja
    hset low-battery-threshold 25
    hset show-panel-menu false
    gnome-extensions enable $UUID 2>/dev/null ||
        g org.gnome.shell enabled-extensions "$(gsettings get org.gnome.shell enabled-extensions | sed "s/]$/, '$UUID']/")"
}

cubo() {
    # Cubo 3D + efectos de ventana del Gist (extensiones de extensions.gnome.org)
    local E=~/.local/share/gnome-shell/extensions
    xset() { local u=$1 id=$2; shift 2; gsettings --schemadir "$E/$u/schemas" set "$id" "$@"; }
    local C=desktop-cube@schneegans.github.com
    xset $C org.gnome.shell.extensions.desktop-cube do-explode true          # caras separadas = escritorios "flotantes"
    xset $C org.gnome.shell.extensions.desktop-cube workpace-separation 100
    xset $C org.gnome.shell.extensions.desktop-cube window-parallax 0.5      # profundidad de las ventanas
    xset $C org.gnome.shell.extensions.desktop-cube inactive-workpace-opacity 200
    local W=compiz-windows-effect@hermes83.github.com                        # ventanas "gelatina" (valores por defecto: suaves)
    xset $W org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect maximize-effect true
    xset $W org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect resize-effect false
    local L=compiz-alike-magic-lamp-effect@hermes83.github.com
    xset $L org.gnome.shell.extensions.com.github.hermes83.compiz-alike-magic-lamp-effect duration 350.0
    g org.gnome.desktop.interface cursor-theme 'WhiteSur-cursors'
    local cur; cur=$(gsettings get org.gnome.shell enabled-extensions)
    for u in $C $W $L; do
        [[ $cur == *"$u"* ]] || cur=${cur%]}", '$u']"
    done
    g org.gnome.shell enabled-extensions "$cur"
}

case "${1:-}" in
    dock) dock ;;
    blur) blur ;;
    tema) tema ;;
    terminal) terminal ;;
    wallpaper) wallpaper ;;
    hanabi) hanabi ;;
    cubo) cubo ;;
    todo) dock; blur; tema; terminal; wallpaper; hanabi; cubo ;;
    *) echo "Uso: $0 [dock|blur|tema|terminal|wallpaper|hanabi|cubo|todo]"; exit 1 ;;
esac
