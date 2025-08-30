#!/usr/bin/env python3
"""
VideoTR - Audio Transcription Module
Extrae audio de videos y los transcribe usando OpenAI Whisper
"""

import os
import sys
import tempfile
import subprocess
from pathlib import Path
import argparse
from typing import Optional, List
import time

# Importaciones con manejo de errores
try:
    import ffmpeg
except ImportError:
    print("❌ Error: ffmpeg-python no instalado")
    print("💡 Ejecuta: pip install ffmpeg-python")
    sys.exit(1)

def extract_audio(video_path: str, audio_path: str) -> bool:
    """
    Extrae el audio de un archivo de video usando FFmpeg
    
    Args:
        video_path: Ruta del video de entrada
        audio_path: Ruta del archivo de audio de salida
        
    Returns:
        bool: True si la extracción fue exitosa
    """
    try:
        # Verificar que el archivo de video existe
        if not os.path.exists(video_path):
            raise FileNotFoundError(f"Video no encontrado: {video_path}")
        
        # Configurar FFmpeg para extraer audio
        stream = ffmpeg.input(video_path)
        audio = stream.audio
        
        # Convertir a WAV con configuraciones específicas
        out = ffmpeg.output(
            audio, 
            audio_path,
            acodec='pcm_s16le',  # Codec de audio
            ac=1,                # Mono
            ar='16000'           # Sample rate 16kHz (óptimo para Whisper)
        )
        
        # Ejecutar la conversión
        ffmpeg.run(out, quiet=True, overwrite_output=True)
        
        # Verificar que el archivo se creó correctamente
        if os.path.exists(audio_path) and os.path.getsize(audio_path) > 0:
            return True
        else:
            return False
            
    except Exception as e:
        print(f"❌ Error extrayendo audio: {e}")
        return False


def transcribe_audio(audio_path: str, model_name: str = "base") -> Optional[str]:
    """
    Transcribe un archivo de audio usando OpenAI Whisper
    
    Args:
        audio_path: Ruta del archivo de audio
        model_name: Modelo de Whisper a usar (tiny, base, small, medium, large)
        
    Returns:
        str: Texto transcrito o None si hay error
    """
    try:
        # Importar Whisper con manejo de advertencias
        import warnings
        warnings.filterwarnings("ignore")
        
        import whisper  # type: ignore
        
        # Verificar que el archivo de audio existe
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio no encontrado: {audio_path}")
        
        # Cargar el modelo de Whisper
        print(f"🤖 Cargando modelo Whisper: {model_name}")
        model = whisper.load_model(model_name)
        
        # Transcribir el audio
        print("🎤 Transcribiendo audio...")
        result = model.transcribe(audio_path)
        
        # Extraer el texto transcrito
        transcribed_text = result["text"].strip()
        
        return transcribed_text if transcribed_text else None
        
    except Exception as e:
        print(f"❌ Error transcribiendo audio: {e}")
        return None


def process_video(video_path: str, output_path: str = None, model_name: str = "base") -> bool:
    """
    Procesa un video completo: extrae audio y transcribe
    
    Args:
        video_path: Ruta del video
        output_path: Ruta del archivo de salida (opcional)
        model_name: Modelo de Whisper
        
    Returns:
        bool: True si el proceso fue exitoso
    """
    try:
        # Crear archivo temporal para el audio
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_audio:
            temp_audio_path = temp_audio.name
        
        print(f"🎥 Procesando video: {video_path}")
        
        # Extraer audio
        print("🎵 Extrayendo audio...")
        if not extract_audio(video_path, temp_audio_path):
            return False
        
        # Transcribir audio
        text = transcribe_audio(temp_audio_path, model_name)
        
        # Limpiar archivo temporal
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)
        
        if text:
            # Guardar transcripción si se especifica ruta de salida
            if output_path:
                with open(output_path, 'w', encoding='utf-8') as f:
                    f.write(text)
                print(f"✅ Transcripción guardada: {output_path}")
            else:
                print(f"✅ Transcripción completada: {text[:100]}...")
            
            return True
        else:
            print("❌ No se pudo obtener transcripción")
            return False
            
    except Exception as e:
        print(f"❌ Error procesando video: {e}")
        return False


def find_videos(directory: Path) -> List[Path]:
    """Encuentra archivos de video en un directorio"""
    video_extensions = ['.mp4', '.avi', '.mov', '.mkv', '.wmv', '.MP4', '.AVI', '.MOV', '.MKV', '.WMV']
    videos = []
    
    for ext in video_extensions:
        videos.extend(directory.glob(f'*{ext}'))
    
    return sorted(videos)


def interactive_video_selector() -> Optional[Path]:
    """Selector interactivo de videos"""
    # Buscar archivos MP4 en el escritorio y carpeta actual
    search_paths = []
    
    # Buscar en el escritorio
    desktop_path = Path.home() / "Desktop"
    if desktop_path.exists():
        search_paths.append(desktop_path)
    
    # Buscar en la carpeta actual
    current_path = Path.cwd()
    search_paths.append(current_path)
    
    print("🔍 Buscando videos...")
    all_videos = []
    
    for path in search_paths:
        videos = find_videos(path)
        for video in videos:
            file_size = video.stat().st_size / (1024 * 1024)  # Tamaño en MB
            all_videos.append((video, file_size))
    
    if not all_videos:
        print("❌ No se encontraron archivos de video")
        return None
    
    # Mostrar opciones
    print("\n📋 Videos encontrados:")
    for i, (video, size) in enumerate(all_videos, 1):
        print(f"  {i}. {video.name} ({size:.1f} MB)")
    
    # Selección del usuario
    while True:
        try:
            choice = input(f"\n🎯 Elige un video (1-{len(all_videos)}) o 'q' para salir: ").strip()
            if choice.lower() == 'q':
                return None
            
            index = int(choice) - 1
            if 0 <= index < len(all_videos):
                return all_videos[index][0]
            else:
                print(f"❌ Selección inválida. Elige entre 1 y {len(all_videos)}")
        except ValueError:
            print("❌ Por favor ingresa un número válido")


def setup_output_config():
    """Configuración interactiva de salida"""
    print("\n📁 Configuración de carpeta de salida:")
    
    # Opciones de carpeta
    folders = {
        '1': Path.cwd(),
        '2': Path.home() / "Desktop",
        '3': Path.home() / "Documents"
    }
    
    print("  1. Carpeta actual")
    print("  2. Escritorio")
    print("  3. Documentos")
    print("  4. Otra ubicación")
    
    while True:
        choice = input("🎯 Elige carpeta de salida (1-4): ").strip()
        if choice in ['1', '2', '3']:
            output_dir = folders[choice]
            break
        elif choice == '4':
            custom_path = input("📂 Ingresa la ruta completa: ").strip()
            output_dir = Path(custom_path)
            if not output_dir.exists():
                print("❌ Ruta no válida")
                continue
            break
        else:
            print("❌ Selección inválida")
    
    print(f"📁 Carpeta seleccionada: {output_dir}")
    
    # Configuración del nombre de archivo
    print("\n📝 Configuración del nombre de archivo:")
    print("  1. Nombre automático (basado en el video)")
    print("  2. Nombre personalizado")
    
    while True:
        choice = input("🎯 Elige opción (1-2): ").strip()
        if choice == '1':
            filename = None  # Se generará automáticamente
            break
        elif choice == '2':
            filename = input("📝 Ingresa el nombre (sin extensión): ").strip()
            if filename:
                # Asegurar extensión .txt
                if not filename.endswith('.txt'):
                    filename += '.txt'
                break
            else:
                print("❌ Nombre no válido")
        else:
            print("❌ Selección inválida")
    
    return output_dir, filename


def main():
    """Función principal para uso desde línea de comandos"""
    parser = argparse.ArgumentParser(description="VideoTR - Transcriptor de Videos")
    parser.add_argument("video", nargs="?", help="Ruta del archivo de video")
    parser.add_argument("-o", "--output", help="Archivo de salida")
    parser.add_argument("-m", "--model", default="base", 
                       choices=["tiny", "base", "small", "medium", "large"],
                       help="Modelo de Whisper a usar")
    
    args = parser.parse_args()
    
    # Si no se proporciona argumento, mostrar selector interactivo
    if not args.video:
        print("🎥 VideoTR - Transcriptor de Videos con IA")
        print("=" * 45)
        
        # Seleccionar video
        video_path = interactive_video_selector()
        if not video_path:
            print("👋 Cancelado por el usuario")
            return
        
        # Configurar carpeta y nombre de salida
        output_dir, filename = setup_output_config()
        
        # Generar nombre de archivo si no se especificó
        if not filename:
            base_name = video_path.stem
            filename = f"{base_name}_transcripcion.txt"
        
        output_path = output_dir / filename
    else:
        # En modo directo, usar configuración tradicional o preguntar
        video_path = Path(args.video)
        if not video_path.exists():
            print(f"❌ Video no encontrado: {video_path}")
            return
        
        if args.output:
            output_path = Path(args.output)
        else:
            # Generar nombre automático
            output_path = video_path.with_suffix('.txt')
    
    # Modelo de Whisper a utilizar
    model = args.model
    
    print(f"\n🎬 Video: {video_path.name}")
    print(f"📄 Salida: {output_path}")
    print(f"🤖 Modelo: {model}")
    print()
    
    # Procesar el video
    success = process_video(str(video_path), str(output_path), model)
    
    if success:
        print(f"\n🎉 ¡Transcripción completada!")
        print(f"📄 Archivo guardado: {output_path}")
        
        # Preguntar si quiere abrir el archivo
        if input("\n📖 ¿Abrir el archivo? (s/N): ").lower().startswith('s'):
            os.system(f'open "{output_path}"')
    else:
        print("\n❌ Error en la transcripción")


if __name__ == "__main__":
    main()
