#!/bin/bash

# VideoTR - Lanzador Simple
# Versión rápida para usuarios avanzados

cd "$(dirname "$0")"

echo "🎥 Iniciando VideoTR..."

# Activar entorno virtual
source .venv/bin/activate

# Verificar dependencias con requirements.txt si existe
if [ -f "requirements.txt" ]; then
    echo "📋 Verificando requirements.txt..."
    python3 -c "
import pkg_resources
import sys
try:
    with open('requirements.txt', 'r') as f:
        requirements = f.read().strip().split('\n')
    for req in requirements:
        if req.strip() and not req.startswith('#'):
            pkg_resources.require(req)
    print('✅ Dependencias verificadas')
except Exception as e:
    print('❌ Error en dependencias:', str(e))
    sys.exit(1)
"
    [ $? -ne 0 ] && {
        echo "❌ Dependencias no coinciden. Usa VideoTR.command para instalación completa."
        exit 1
    }
else
    # Verificar dependencias básicas (fallback)
    python3 -c "import flask, whisper" 2>/dev/null || {
        echo "❌ Dependencias no instaladas. Usa VideoTR.command para instalación completa."
        exit 1
    }
fi

# Liberar puerto si está ocupado
lsof -ti:8000 | xargs kill -9 2>/dev/null

# Abrir navegador después de 2 segundos
(sleep 2 && open "http://localhost:8000") &

# Ejecutar aplicación
python3 app.py
