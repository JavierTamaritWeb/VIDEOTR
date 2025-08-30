#!/bin/bash

# VideoTR - Script de Instalación
# Configura el entorno virtual y dependencias desde cero

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 VideoTR - Script de Instalación${NC}"
echo "================================="

# Verificar Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 no encontrado${NC}"
    echo -e "${YELLOW}💡 Instala Python 3 desde: https://www.python.org/downloads/${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Python 3 encontrado: $(python3 --version)${NC}"

# Crear entorno virtual si no existe
if [ ! -d ".venv" ]; then
    echo -e "${BLUE}🔧 Creando entorno virtual...${NC}"
    python3 -m venv .venv
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ Error al crear entorno virtual${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Entorno virtual creado${NC}"
else
    echo -e "${YELLOW}⚠️  Entorno virtual ya existe${NC}"
fi

# Activar entorno virtual
echo -e "${BLUE}🔄 Activando entorno virtual...${NC}"
source .venv/bin/activate

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Error al activar entorno virtual${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Entorno virtual activado${NC}"

# Actualizar pip
echo -e "${BLUE}📦 Actualizando pip...${NC}"
pip install --upgrade pip

# Instalar dependencias desde requirements.txt
if [ -f "requirements.txt" ]; then
    echo -e "${BLUE}📋 Instalando dependencias desde requirements.txt...${NC}"
    pip install -r requirements.txt
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Dependencias instaladas correctamente${NC}"
    else
        echo -e "${RED}❌ Error al instalar dependencias${NC}"
        echo -e "${YELLOW}💡 Intentando instalación manual...${NC}"
        
        # Instalación manual de dependencias críticas
        pip install flask openai-whisper ffmpeg-python
    fi
else
    echo -e "${YELLOW}⚠️  requirements.txt no encontrado${NC}"
    echo -e "${BLUE}📦 Instalando dependencias básicas...${NC}"
    
    pip install flask openai-whisper ffmpeg-python
fi

# Verificar FFmpeg
echo -e "${BLUE}🔍 Verificando FFmpeg...${NC}"
if command -v ffmpeg &> /dev/null; then
    echo -e "${GREEN}✅ FFmpeg encontrado: $(ffmpeg -version | head -1)${NC}"
else
    echo -e "${YELLOW}⚠️  FFmpeg no encontrado en el sistema${NC}"
    echo -e "${CYAN}💡 Instalación recomendada:${NC}"
    echo -e "${CYAN}   macOS: brew install ffmpeg${NC}"
    echo -e "${CYAN}   Ubuntu: sudo apt install ffmpeg${NC}"
    echo -e "${CYAN}   Windows: Descargar desde https://ffmpeg.org/${NC}"
fi

# Crear carpetas necesarias
echo -e "${BLUE}📁 Creando carpetas necesarias...${NC}"
mkdir -p uploads transcriptions static templates

# Verificar archivos principales
if [ ! -f "app.py" ]; then
    echo -e "${RED}❌ app.py no encontrado${NC}"
    echo -e "${YELLOW}💡 Asegúrate de estar en el directorio correcto de VideoTR${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Archivos principales verificados${NC}"

# Hacer ejecutables los scripts
chmod +x VideoTR.command run.sh start.sh 2>/dev/null

echo
echo -e "${GREEN}🎉 ¡Instalación completada!${NC}"
echo -e "${CYAN}📋 Para ejecutar VideoTR:${NC}"
echo -e "${CYAN}   • Doble clic en: VideoTR.command${NC}"
echo -e "${CYAN}   • Terminal rápido: ./run.sh${NC}"
echo -e "${CYAN}   • Terminal simple: ./start.sh${NC}"
echo

echo -e "${BLUE}📊 Resumen de la instalación:${NC}"
pip list | grep -E "(flask|whisper|ffmpeg)" || echo "Verificando dependencias..."

echo -e "${YELLOW}💡 Consejo: Usa VideoTR.command para un inicio automático completo${NC}"
