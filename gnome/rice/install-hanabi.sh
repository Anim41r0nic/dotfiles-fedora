#!/bin/bash
# Instala Hanabi (fondo de pantalla animado) en el usuario, SIN sudo ni meson.
# Fuente: https://github.com/jeffshee/gnome-ext-hanabi  rama "javascript"
#   (GNOME 45–50), commit fijado a5c0272973 — código revisado: sin red, solo
#   lanza su propio renderer (renderer/renderer.js) para reproducir el vídeo.
# Uso:      bash ~/dotfiles/gnome/rice/install-hanabi.sh /ruta/al/codigo-fuente
# Revertir: gnome-extensions disable hanabi-extension@jeffshee.github.io
#           rm -rf ~/.local/share/gnome-shell/extensions/hanabi-extension@jeffshee.github.io
set -euo pipefail

SRC="${1:?Indica la carpeta con el código de Hanabi}/src"
UUID=hanabi-extension@jeffshee.github.io
SCHEMA=io.github.jeffshee.hanabi-extension
DEST=~/.local/share/gnome-shell/extensions/$UUID

[ -f "$SRC/extension.js" ] || { echo "No encuentro $SRC/extension.js"; exit 1; }
rm -rf "$DEST"
mkdir -p "$DEST/renderer" "$DEST/schemas"

# Mismos archivos que instala su meson.build
cp "$SRC"/{autoPause,constants,dbus,extension,gnomeShellOverride,launcher,logger,panelMenu,playbackState,prefs,roundedCornersEffect,wallpaper,windowManager}.js "$DEST/"
cp "$SRC/../LICENSE" "$SRC/assets/hanabi-symbolic.svg" "$DEST/"
cp "$SRC/renderer/renderer.js" "$SRC/renderer/stylesheet.css" "$DEST/renderer/"
chmod +x "$DEST/renderer/renderer.js"

# metadata.json (equivalente al configure_file de meson)
sed -e "s/@uuid@/$UUID/g" -e "s/@settings_schema@/$SCHEMA/" -e "s/@version@/1/" \
    "$SRC/metadata.json.in" > "$DEST/metadata.json"

# Esquema de ajustes dentro de la propia extensión
cp "$SRC/schemas/$SCHEMA.gschema.xml" "$DEST/schemas/"
glib-compile-schemas "$DEST/schemas"

# Traducción al español
mkdir -p "$DEST/locale/es/LC_MESSAGES"
msgfmt -o "$DEST/locale/es/LC_MESSAGES/$UUID.mo" "$SRC/po/es.po"

echo "Instalado en $DEST"
