#!/bin/bash

# VideoTR - Transcriptor de Videos
# Ejecutable para macOS

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
echo -e "${PURPLE}"
echo "╔══════════════════════════════════════════╗"
echo "║              🎥 VideoTR 🎥               ║"
echo "║        Transcriptor de Videos            ║"
echo "║           con Inteligencia               ║"
echo "║             Artificial                   ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Obtener el directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${CYAN}📂 Directorio de trabajo: ${SCRIPT_DIR}${NC}"
echo

# Verificar si existe el entorno virtual
if [ ! -d ".venv" ]; then
    echo -e "${RED}❌ Entorno virtual no encontrado${NC}"
    echo -e "${YELLOW}🔧 Creando entorno virtual...${NC}"
    python3 -m venv .venv
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error al crear el entorno virtual${NC}"
        echo -e "${YELLOW}💡 Asegúrate de tener Python 3 instalado${NC}"
        read -p "Presiona Enter para cerrar..."
        exit 1
    fi
    
    echo -e "${GREEN}✅ Entorno virtual creado${NC}"
fi

# Activar entorno virtual
echo -e "${BLUE}🔄 Activando entorno virtual...${NC}"
source .venv/bin/activate

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al activar el entorno virtual${NC}"
    read -p "Presiona Enter para cerrar..."
    exit 1
fi

echo -e "${GREEN}✅ Entorno virtual activado${NC}"

# Verificar dependencias
echo -e "${BLUE}🔍 Verificando dependencias...${NC}"

# Verificar si existe requirements.txt
if [ -f "requirements.txt" ]; then
    echo -e "${CYAN}📋 Archivo requirements.txt encontrado${NC}"
    
    # Verificar si las dependencias están instaladas
    python -c "
import pkg_resources
import sys

def check_requirements():
    with open('requirements.txt', 'r') as f:
        requirements = f.read().strip().split('\n')
    
    missing = []
    for req in requirements:
        if req.strip() and not req.startswith('#'):
            try:
                pkg_resources.require(req)
            except (pkg_resources.DistributionNotFound, pkg_resources.VersionConflict):
                missing.append(req)
    
    if missing:
        print('MISSING:', ','.join(missing))
        sys.exit(1)
    else:
        print('ALL_OK')

check_requirements()
" 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}📦 Instalando dependencias desde requirements.txt...${NC}"
        pip install -r requirements.txt
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Todas las dependencias instaladas correctamente${NC}"
        else
            echo -e "${RED}❌ Error al instalar dependencias${NC}"
            read -p "Presiona Enter para continuar de todos modos..."
        fi
    else
        echo -e "${GREEN}✅ Todas las dependencias ya están instaladas con las versiones correctas${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  requirements.txt no encontrado, verificando dependencias básicas...${NC}"
    
    # Función para verificar si un paquete está instalado
    check_package() {
        python -c "import $1" 2>/dev/null
        return $?
    }

    # Lista de dependencias
    PACKAGES_TO_CHECK=("flask" "whisper" "ffmpeg")
    PACKAGES_TO_INSTALL=()

    for package in "${PACKAGES_TO_CHECK[@]}"; do
        if check_package "$package"; then
            echo -e "${GREEN}✅ $package instalado${NC}"
        else
            echo -e "${YELLOW}⚠️  $package no encontrado${NC}"
            case $package in
                "flask")
                    PACKAGES_TO_INSTALL+=("flask")
                    ;;
                "whisper")
                    PACKAGES_TO_INSTALL+=("openai-whisper")
                    ;;
                "ffmpeg")
                    PACKAGES_TO_INSTALL+=("ffmpeg-python")
                    ;;
            esac
        fi
    done

    # Instalar dependencias faltantes
    if [ ${#PACKAGES_TO_INSTALL[@]} -gt 0 ]; then
        echo -e "${YELLOW}📦 Instalando dependencias faltantes...${NC}"
        for package in "${PACKAGES_TO_INSTALL[@]}"; do
            echo -e "${BLUE}📥 Instalando $package...${NC}"
            pip install "$package"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ $package instalado correctamente${NC}"
            else
                echo -e "${RED}❌ Error al instalar $package${NC}"
            fi
        done
    fi
fi

# Verificar FFmpeg en el sistema
echo -e "${BLUE}🔍 Verificando FFmpeg...${NC}"
if command -v ffmpeg &> /dev/null; then
    echo -e "${GREEN}✅ FFmpeg encontrado en el sistema${NC}"
else
    echo -e "${YELLOW}⚠️  FFmpeg no encontrado en el sistema${NC}"
    echo -e "${CYAN}💡 Instala FFmpeg con: brew install ffmpeg${NC}"
fi

# Verificar archivo principal
if [ ! -f "app.py" ]; then
    echo -e "${RED}❌ No se encontró app.py${NC}"
    read -p "Presiona Enter para cerrar..."
    exit 1
fi

echo -e "${GREEN}✅ Archivo principal encontrado${NC}"
echo

# Crear carpetas necesarias
mkdir -p uploads transcriptions static templates

echo -e "${BLUE}📁 Carpetas necesarias verificadas${NC}"
echo

# Verificar puerto disponible
PORT=8000
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo -e "${YELLOW}⚠️  Puerto $PORT ocupado, liberando...${NC}"
    lsof -ti:$PORT | xargs kill -9 2>/dev/null
    sleep 2
fi

echo -e "${GREEN}🚀 Iniciando VideoTR...${NC}"
echo -e "${CYAN}📱 La aplicación se abrirá en: http://localhost:$PORT${NC}"
echo -e "${PURPLE}🛑 Presiona Ctrl+C para detener${NC}"
echo
echo -e "${YELLOW}════════════════════════════════════════${NC}"

# Esperar un momento
sleep 2

# Abrir en el navegador después de 3 segundos en segundo plano
(sleep 3 && open "http://localhost:$PORT") &

# Ejecutar la aplicación
python app.py

# Al finalizar
echo
echo -e "${YELLOW}════════════════════════════════════════${NC}"
echo -e "${CYAN}👋 VideoTR terminado${NC}"
echo -e "${GREEN}✅ Sesión finalizada${NC}"

# Mantener terminal abierto si fue ejecutado desde Finder
if [ -t 0 ]; then
    echo
    read -p "Presiona Enter para cerrar..."
fi
