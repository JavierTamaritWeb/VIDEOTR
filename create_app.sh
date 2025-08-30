#!/bin/bash

# VideoTR App Creator
# Crea una aplicación .app nativa de macOS

echo "🍎 Creando VideoTR.app para macOS..."

# Directorio actual del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="VideoTR.app"
APP_DIR="$PROJECT_DIR/$APP_NAME"

# Crear estructura de la aplicación macOS
echo "📁 Creando estructura de la aplicación..."

mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Crear Info.plist
echo "📋 Creando Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>VideoTR</string>
    <key>CFBundleIdentifier</key>
    <string>com.videotr.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>VideoTR</string>
    <key>CFBundleDisplayName</key>
    <string>VideoTR - Transcriptor de Videos</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>VTR1</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSUIElement</key>
    <false/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
    <key>UTImportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>public.movie</string>
            <key>UTTypeDescription</key>
            <string>Video File</string>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array>
                    <string>mp4</string>
                    <string>avi</string>
                    <string>mov</string>
                    <string>mkv</string>
                    <string>wmv</string>
                </array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF

# Crear el ejecutable principal
echo "⚙️ Creando ejecutable principal..."
cat > "$APP_DIR/Contents/MacOS/VideoTR" << 'EOF'
#!/bin/bash

# VideoTR Native macOS App
# Ejecutable principal de la aplicación

# Obtener el directorio de la aplicación
APP_PATH="$(dirname "$(dirname "$(dirname "${BASH_SOURCE[0]}")")")"
PROJECT_PATH="$(dirname "$APP_PATH")"

# Colores para terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Función para mostrar notificación nativa de macOS
show_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-Glass}"
    
    osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
}

# Función para mostrar diálogo de error
show_error() {
    local message="$1"
    osascript -e "display dialog \"$message\" with title \"VideoTR Error\" buttons {\"OK\"} default button \"OK\" with icon stop"
}

# Función para mostrar diálogo de información
show_info() {
    local message="$1"
    osascript -e "display dialog \"$message\" with title \"VideoTR\" buttons {\"OK\"} default button \"OK\" with icon note"
}

# Función para preguntar si abrir Terminal
ask_terminal() {
    local result=$(osascript -e 'display dialog "¿Quieres ver el progreso detallado en Terminal?" with title "VideoTR" buttons {"No", "Sí"} default button "Sí" with icon question')
    echo "$result" | grep -q "Sí"
}

# Cambiar al directorio del proyecto
cd "$PROJECT_PATH"

# Verificar que estamos en el directorio correcto
if [ ! -f "app.py" ] || [ ! -f "audio_transcribe.py" ]; then
    show_error "Error: No se encontraron los archivos del proyecto VideoTR.
    
Asegúrate de que VideoTR.app esté en la carpeta del proyecto."
    exit 1
fi

# Verificar Python 3
if ! command -v python3 &> /dev/null; then
    show_error "Error: Python 3 no está instalado.

Por favor instala Python 3 desde:
https://www.python.org/downloads/"
    exit 1
fi

# Verificar FFmpeg
if ! command -v ffmpeg &> /dev/null; then
    show_notification "VideoTR" "FFmpeg no encontrado. La transcripción puede fallar." "Basso"
fi

# Mostrar notificación de inicio
show_notification "VideoTR" "Iniciando aplicación..." "Glass"

# Preguntar si mostrar Terminal
if ask_terminal; then
    # Ejecutar con Terminal visible
    osascript << APPLESCRIPT
    tell application "Terminal"
        activate
        do script "cd '$PROJECT_PATH' && echo '🍎 VideoTR - Aplicación nativa de macOS' && echo '==========================================' && ./VideoTR.command"
    end tell
APPLESCRIPT
else
    # Ejecutar en segundo plano
    (
        # Verificar entorno virtual
        if [ ! -d ".venv" ]; then
            show_notification "VideoTR" "Creando entorno virtual..." "Blow"
            python3 -m venv .venv
        fi
        
        # Activar entorno
        source .venv/bin/activate
        
        # Instalar dependencias si es necesario
        if [ -f "requirements.txt" ]; then
            python -c "
import pkg_resources
import sys
try:
    with open('requirements.txt', 'r') as f:
        requirements = f.read().strip().split('\n')
    for req in requirements:
        if req.strip() and not req.startswith('#'):
            pkg_resources.require(req)
except:
    sys.exit(1)
" 2>/dev/null
            
            if [ $? -ne 0 ]; then
                show_notification "VideoTR" "Instalando dependencias..." "Blow"
                pip install -r requirements.txt
            fi
        fi
        
        # Liberar puerto si está ocupado
        lsof -ti:8000 | xargs kill -9 2>/dev/null
        
        # Mostrar notificación de que está listo
        show_notification "VideoTR" "¡Listo! Abriendo navegador..." "Glass"
        
        # Esperar un momento y abrir navegador
        sleep 2
        open "http://localhost:8000"
        
        # Ejecutar la aplicación
        python app.py
        
    ) &
    
    # Mostrar información al usuario
    show_info "VideoTR se está iniciando en segundo plano.

El navegador se abrirá automáticamente cuando esté listo.

Para detener la aplicación, cierra esta ventana o usa Activity Monitor."
fi
EOF

# Hacer ejecutable
chmod +x "$APP_DIR/Contents/MacOS/VideoTR"

# Crear icono básico (usando iconos del sistema)
echo "🎨 Configurando icono..."

# Intentar usar sf symbols o icono del sistema
cat > "$APP_DIR/Contents/Resources/create_icon.sh" << 'EOF'
#!/bin/bash

# Crear un icono básico usando sips (herramienta nativa de macOS)
ICON_PATH="$(dirname "$0")/AppIcon.icns"

# Si no hay icono personalizado, usar uno genérico
if [ ! -f "$ICON_PATH" ]; then
    # Copiar icono genérico de aplicación
    cp "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/ExecutableBinaryIcon.icns" "$ICON_PATH" 2>/dev/null || true
fi
EOF

chmod +x "$APP_DIR/Contents/Resources/create_icon.sh"
"$APP_DIR/Contents/Resources/create_icon.sh"

# Configurar atributos de macOS
echo "🔧 Configurando atributos de macOS..."

# Marcar como aplicación
xattr -w com.apple.FinderInfo "41 50 50 4C 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00" "$APP_DIR"

# Hacer ejecutable toda la aplicación
chmod -R +x "$APP_DIR/Contents/MacOS/"

echo "✅ ¡VideoTR.app creada exitosamente!"
echo "📱 Ubicación: $APP_DIR"
echo ""
echo "🚀 Para usar la aplicación:"
echo "   • Doble clic en VideoTR.app"
echo "   • O arrastra VideoTR.app a Applications"
echo ""
echo "💡 La aplicación se puede mover a /Applications para acceso global"

# Preguntar si mover a Applications
read -p "¿Mover VideoTR.app a Applications? (s/N): " move_to_apps
if [[ $move_to_apps =~ ^[Ss]$ ]]; then
    if [ -w "/Applications" ]; then
        cp -R "$APP_DIR" "/Applications/"
        echo "✅ VideoTR.app copiada a Applications"
        echo "🍎 Ahora puedes encontrar VideoTR en Launchpad"
    else
        echo "❌ No se puede escribir en Applications"
        echo "💡 Arrastra manualmente VideoTR.app a Applications"
    fi
fi

echo ""
echo "🎉 ¡Aplicación lista para usar!"
EOF
