"""
VideoTR Web App - Interfaz web para transcripción de videos
=========================================================

Aplicación Flask elegante e intuitiva para transcribir videos a texto
usando OpenAI Whisper.
"""

import os
import secrets
import uuid
import threading
import time
from datetime import datetime
from pathlib import Path
from flask import Flask, render_template, request, jsonify, send_file, redirect, url_for, flash
from werkzeug.utils import secure_filename
import warnings

# Importar nuestro módulo de transcripción
try:
    from audio_transcribe import extract_audio, transcribe_audio
except ImportError:
    import sys
    sys.path.append('.')
    from audio_transcribe import extract_audio, transcribe_audio

# Suprimir advertencias de Whisper
warnings.filterwarnings("ignore", category=UserWarning)

app = Flask(__name__)
# Clave de sesión: nunca en el código (el repo es público). Se toma del entorno
# o se genera una aleatoria en cada arranque (solo firma los mensajes flash).
app.secret_key = os.environ.get('VIDEOTR_SECRET_KEY') or secrets.token_hex(32)
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500MB max file size

# Configuración de carpetas
UPLOAD_FOLDER = Path(__file__).parent / 'uploads'
TRANSCRIPTIONS_FOLDER = Path(__file__).parent / 'transcriptions'
ALLOWED_EXTENSIONS = {'mp4', 'avi', 'mov', 'mkv', 'webm', 'm4v'}

def safe_transcription_path(filename):
    """Ruta de una transcripción solo si es un .txt dentro de TRANSCRIPTIONS_FOLDER."""
    base = TRANSCRIPTIONS_FOLDER.resolve()
    file_path = (base / filename).resolve()
    if file_path.parent != base or file_path.suffix != '.txt':
        return None
    return file_path

# Almacenamiento en memoria para el progreso de transcripciones
transcription_progress = {}

def allowed_file(filename):
    """Verifica si el archivo tiene una extensión permitida."""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_file_size_mb(filepath):
    """Obtiene el tamaño del archivo en MB."""
    return os.path.getsize(filepath) / (1024 * 1024)

def process_transcription(task_id, video_path, output_path, model_name):
    """
    Procesa la transcripción en un hilo separado y actualiza el progreso.
    """
    try:
        # Paso 1: Iniciando
        transcription_progress[task_id] = {
            'status': 'processing',
            'step': 'Iniciando procesamiento...',
            'progress': 5,
            'start_time': time.time(),
            'current_phase': 'init',
            'estimated_time': None
        }
        time.sleep(1)  # Simular tiempo de inicialización
        
        # Paso 2: Validando archivo
        transcription_progress[task_id].update({
            'step': 'Validando archivo de video...',
            'progress': 10,
            'current_phase': 'validation'
        })
        time.sleep(0.5)
        
        # Paso 3: Preparando extracción
        transcription_progress[task_id].update({
            'step': 'Preparando extracción de audio...',
            'progress': 15,
            'current_phase': 'preparation'
        })
        time.sleep(0.5)
        
        # Paso 4: Extrayendo audio
        transcription_progress[task_id].update({
            'step': 'Extrayendo audio del video...',
            'progress': 25,
            'current_phase': 'extraction'
        })
        
        # Crear archivo temporal para el audio
        temp_audio = UPLOAD_FOLDER / f"{task_id}_temp.wav"
        extract_audio(str(video_path), str(temp_audio))
        
        # Paso 5: Audio extraído
        transcription_progress[task_id].update({
            'step': 'Audio extraído correctamente',
            'progress': 40,
            'current_phase': 'extraction_complete'
        })
        time.sleep(0.5)
        
        # Paso 6: Cargando modelo IA
        transcription_progress[task_id].update({
            'step': f'Cargando modelo Whisper ({model_name})...',
            'progress': 45,
            'current_phase': 'model_loading'
        })
        time.sleep(1)
        
        # Paso 7: Iniciando transcripción
        transcription_progress[task_id].update({
            'step': 'Iniciando transcripción con IA...',
            'progress': 50,
            'current_phase': 'transcription_start'
        })
        
        # Paso 8: Transcribiendo (con progreso simulado)
        for i in range(50, 85, 5):
            transcription_progress[task_id].update({
                'step': f'Transcribiendo audio... ({i}%)',
                'progress': i,
                'current_phase': 'transcribing'
            })
            time.sleep(0.3)
        
        # Transcribir el audio
        text = transcribe_audio(str(temp_audio), model_name)
        
        # Paso 9: Procesando resultado
        transcription_progress[task_id].update({
            'step': 'Procesando resultado...',
            'progress': 88,
            'current_phase': 'processing_result'
        })
        time.sleep(0.5)
        
        # Paso 10: Guardando transcripción
        transcription_progress[task_id].update({
            'step': 'Guardando transcripción...',
            'progress': 92,
            'current_phase': 'saving'
        })
        
        # Guardar la transcripción
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(text)
        
        # Paso 11: Limpiando archivos temporales
        transcription_progress[task_id].update({
            'step': 'Limpiando archivos temporales...',
            'progress': 96,
            'current_phase': 'cleanup'
        })
        
        # Limpiar archivo temporal
        if temp_audio.exists():
            temp_audio.unlink()
        
        # Paso 12: Completado
        end_time = time.time()
        processing_time = round(end_time - transcription_progress[task_id]['start_time'], 1)
        
        transcription_progress[task_id].update({
            'status': 'completed',
            'step': '¡Transcripción completada exitosamente!',
            'progress': 100,
            'current_phase': 'completed',
            'result_file': output_path.name,
            'processing_time': processing_time,
            'text_preview': text[:200] + '...' if len(text) > 200 else text,
            'word_count': len(text.split()) if text else 0,
            'char_count': len(text) if text else 0
        })
        
    except Exception as e:
        transcription_progress[task_id] = {
            'status': 'error',
            'step': f'Error: {str(e)}',
            'progress': 0,
            'current_phase': 'error',
            'error': str(e),
            'error_details': f'Error durante el procesamiento: {str(e)}'
        }

@app.route('/')
def index():
    """Página principal."""
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    """Maneja la subida de archivos y inicia la transcripción."""
    if 'file' not in request.files:
        return jsonify({'error': 'No se seleccionó ningún archivo'}), 400
    
    file = request.files['file']
    model = request.form.get('model', 'base')
    
    if file.filename == '':
        return jsonify({'error': 'No se seleccionó ningún archivo'}), 400
    
    if not allowed_file(file.filename):
        return jsonify({'error': 'Formato de archivo no válido. Use: MP4, AVI, MOV, MKV, WEBM, M4V'}), 400
    
    try:
        # Generar ID único para esta tarea
        task_id = str(uuid.uuid4())
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        # Guardar archivo subido
        filename = secure_filename(file.filename)
        video_path = UPLOAD_FOLDER / f"{timestamp}_{filename}"
        file.save(video_path)
        
        # Crear nombre para la transcripción
        output_filename = f"{timestamp}_{Path(filename).stem}.txt"
        output_path = TRANSCRIPTIONS_FOLDER / output_filename
        
        # Inicializar progreso
        transcription_progress[task_id] = {
            'status': 'starting',
            'step': 'Iniciando transcripción...',
            'progress': 0,
            'filename': filename,
            'model': model,
            'file_size': round(get_file_size_mb(video_path), 1)
        }
        
        # Iniciar procesamiento en hilo separado
        thread = threading.Thread(
            target=process_transcription,
            args=(task_id, video_path, output_path, model)
        )
        thread.daemon = True
        thread.start()
        
        return jsonify({
            'success': True,
            'task_id': task_id,
            'message': 'Transcripción iniciada'
        })
        
    except Exception as e:
        return jsonify({'error': f'Error al procesar archivo: {str(e)}'}), 500

@app.route('/progress/<task_id>')
def get_progress(task_id):
    """Obtiene el progreso de una transcripción específica."""
    if task_id in transcription_progress:
        return jsonify(transcription_progress[task_id])
    return jsonify({'error': 'Tarea no encontrada'}), 404

@app.route('/download/<filename>')
def download_file(filename):
    """Descarga un archivo de transcripción."""
    file_path = safe_transcription_path(filename)
    if file_path and file_path.exists():
        # Verificar si es una solicitud AJAX (para File System Access API)
        if request.headers.get('Accept') == 'application/json' or 'fetch' in request.headers.get('User-Agent', '').lower():
            # Devolver el contenido directamente para procesamiento en JavaScript
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            response = app.response_class(
                response=content,
                status=200,
                mimetype='text/plain; charset=utf-8'
            )
            return response
        else:
            # Descarga tradicional
            base_name = filename.replace('.txt', '')
            download_name = f"transcripcion_{base_name}.txt"
            
            return send_file(
                file_path, 
                as_attachment=True, 
                download_name=download_name,
                mimetype='text/plain; charset=utf-8'
            )
    return jsonify({'error': 'Archivo no encontrado'}), 404

@app.route('/history')
def history():
    """Muestra el historial de transcripciones."""
    transcriptions = []
    
    if TRANSCRIPTIONS_FOLDER.exists():
        for file_path in TRANSCRIPTIONS_FOLDER.glob('*.txt'):
            stat = file_path.stat()
            transcriptions.append({
                'filename': file_path.name,
                'size': round(stat.st_size / 1024, 1),  # KB
                'created': datetime.fromtimestamp(stat.st_ctime).strftime('%d/%m/%Y %H:%M'),
                'modified': datetime.fromtimestamp(stat.st_mtime).strftime('%d/%m/%Y %H:%M')
            })
    
    # Ordenar por fecha de creación (más recientes primero)
    transcriptions.sort(key=lambda x: x['created'], reverse=True)
    
    return render_template('history.html', transcriptions=transcriptions)

@app.route('/view/<filename>')
def view_transcription(filename):
    """Visualiza una transcripción específica."""
    file_path = safe_transcription_path(filename)
    if file_path and file_path.exists():
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            return render_template('view.html', filename=filename, content=content)
        except Exception as e:
            flash(f'Error al leer el archivo: {str(e)}', 'error')
            return redirect(url_for('history'))
    
    flash('Archivo no encontrado', 'error')
    return redirect(url_for('history'))

if __name__ == '__main__':
    # Crear directorios si no existen
    UPLOAD_FOLDER.mkdir(exist_ok=True)
    TRANSCRIPTIONS_FOLDER.mkdir(exist_ok=True)
    
    print("🎬 VideoTR Web App iniciándose...")
    print("📱 Accede a: http://localhost:8000")
    print("🛑 Presiona Ctrl+C para detener")
    
    # Solo en este equipo: la app no tiene login. Para abrirla a la red local
    # (bajo tu responsabilidad) exporta VIDEOTR_HOST=0.0.0.0.
    app.run(debug=False, host=os.environ.get('VIDEOTR_HOST', '127.0.0.1'), port=8000)
