# VideoTR - Transcriptor de Videos

Una aplicación web elegante e intuitiva para transcribir videos usando inteligencia artificial.

## 🚀 Características

- **Interfaz web moderna** con diseño glassmorphism
- **Arrastrar y soltar** archivos de video
- **Progreso en tiempo real** con 12 pasos de seguimiento
- **Transcripción con IA** usando OpenAI Whisper
- **Descarga inteligente** con selector de carpetas (compatible con navegadores modernos)
- **Historial de transcripciones**
- **Multiplataforma** - funciona en Windows, macOS y Linux

## 📋 Requisitos

- Python 3.8+
- FFmpeg
- OpenAI Whisper

## 🛠️ Instalación

### Instalación Automática (Recomendada)

**Ejecución con dependencias automáticas**:

```bash
./install.sh  # Configura todo desde cero
```

### Instalación Manual

1. **Clonar o descargar** el proyecto
2. **Entrar a la carpeta** del proyecto
3. **Crear entorno virtual**:

   ```bash
   python -m venv .venv
   source .venv/bin/activate  # En Windows: .venv\Scripts\activate
   ```

4. **Instalar dependencias exactas**:

   ```bash
   pip install -r requirements.txt
   ```

   O instalación básica:

   ```bash
   pip install flask openai-whisper ffmpeg-python
   ```

## 🔒 Gestión de Dependencias

- **`requirements.txt`**: Versiones exactas de todas las librerías
- **Entorno virtual aislado**: Independiente del sistema
- **Verificación automática**: Los scripts comprueban versiones
- **Instalación reproducible**: Mismas versiones en cualquier sistema

## 🎬 Uso

### 🍎 Opción 1: Aplicación Nativa de macOS (Más Fácil)

**Doble clic** en `VideoTR.app` para:

- ✨ Interfaz nativa de macOS
- 🔔 Notificaciones del sistema
- 🎯 Opción de ejecutar con/sin Terminal
- 📱 Disponible en Launchpad y Applications
- 🚀 Instalación automática de dependencias

### 🖥️ Opción 2: Ejecutable de Terminal (Recomendado)

**Doble clic** en `VideoTR.command` para:

- Instalación automática de dependencias
- Verificación del sistema
- Apertura automática del navegador

### ⚡ Opción 3: Script rápido

```bash
./run.sh
```

### 🔧 Opción 4: Manual

1. **Ejecutar la aplicación**:

   ```bash
   ./start.sh  # O: python app.py
   ```

2. **Abrir el navegador** en: <http://localhost:8000>

3. **Subir un video** y esperar la transcripción

> **Seguridad:** la app no tiene login, así que por defecto solo escucha en este equipo
> (`127.0.0.1`). Para abrirla a la red local: `VIDEOTR_HOST=0.0.0.0 python app.py`.
> La clave de sesión se genera al arrancar; para fijarla usa `VIDEOTR_SECRET_KEY`.

### 📱 Crear la Aplicación .app

```bash
./create_app.sh  # Crea VideoTR.app nativa
```

## 📁 Estructura del Proyecto

```text
VideoTR/
├── app.py                 # Aplicación Flask principal
├── start.sh              # Script de inicio
├── static/               # Archivos CSS/JS
├── templates/            # Plantillas HTML
├── transcriptions/       # Transcripciones generadas
├── uploads/             # Videos subidos temporalmente
└── .venv/               # Entorno virtual Python
```

## 🎯 Formatos Soportados

- **Video**: MP4, AVI, MOV, MKV, WMV
- **Salida**: TXT (texto plano)

## 🔧 Configuración

La aplicación usa el modelo **base** de Whisper por defecto. Para mejor calidad, puedes modificar `app.py` y cambiar a:

- `small` - Más rápido
- `medium` - Equilibrio calidad/velocidad
- `large` - Mejor calidad

---

*VideoTR - Transcripción de videos simplificada con IA* 🎥✨
# VIDEOTR
