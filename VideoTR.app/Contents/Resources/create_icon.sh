#!/bin/bash

# Crear un icono básico usando sips (herramienta nativa de macOS)
ICON_PATH="$(dirname "$0")/AppIcon.icns"

# Si no hay icono personalizado, usar uno genérico
if [ ! -f "$ICON_PATH" ]; then
    # Copiar icono genérico de aplicación
    cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ExecutableBinaryIcon.icns" "$ICON_PATH" 2>/dev/null || true
fi
