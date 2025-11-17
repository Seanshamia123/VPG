import os
import uuid
import mimetypes
from werkzeug.utils import secure_filename
from PIL import Image
import io

# === CONFIGURATION ===
MEDIA_ROOT = os.path.join(os.getcwd(), "uploads")   # Base folder for uploads
MAX_FILE_SIZE_MB = 100                              # Max file size (MB)

# Get base URL from environment or use default
BASE_URL = 'https://vpg-9wlv.onrender.com'

# Allowed file extensions by category
ALLOWED_TYPES = {
    "image": ["jpg", "jpeg", "png", "gif", "webp"],
    "video": ["mp4", "mov", "avi", "mkv"],
    "audio": ["mp3", "wav", "ogg", "m4a"],
    "document": ["pdf", "docx", "xlsx", "txt", "csv"],
    "other": []
}


def ensure_media_dirs():
    """Ensure upload directories exist."""
    os.makedirs(MEDIA_ROOT, exist_ok=True)
    for cat in ALLOWED_TYPES:
        os.makedirs(os.path.join(MEDIA_ROOT, cat), exist_ok=True)
    # Create thumbnails directory
    os.makedirs(os.path.join(MEDIA_ROOT, "thumbnails"), exist_ok=True)


def get_media_category(file_ext):
    """Get category name based on file extension."""
    file_ext = file_ext.lower().lstrip(".")
    for cat, exts in ALLOWED_TYPES.items():
        if file_ext in exts:
            return cat
    return "other"


def validate_file(file_storage, expected_type=None):
    """
    Validate uploaded file for size and allowed type.
    """
    filename = secure_filename(file_storage.filename)
    ext = os.path.splitext(filename)[1].lower().lstrip(".")
    category = get_media_category(ext)

    if expected_type:
        if expected_type not in ALLOWED_TYPES:
            raise ValueError(f"Invalid message type: {expected_type}")
        if ext not in ALLOWED_TYPES[expected_type]:
            raise ValueError(f"File type '.{ext}' not allowed for {expected_type} messages. Allowed: {', '.join(ALLOWED_TYPES[expected_type])}")

    if category == "other" and ext not in ALLOWED_TYPES["other"]:
        raise ValueError(f"File type '.{ext}' not allowed")

    # Check file size
    file_storage.seek(0, os.SEEK_END)
    file_size = file_storage.tell()
    file_storage.seek(0)
    if file_size > MAX_FILE_SIZE_MB * 1024 * 1024:
        raise ValueError(f"File exceeds {MAX_FILE_SIZE_MB} MB limit")

    mime_type, _ = mimetypes.guess_type(filename)
    if not mime_type:
        mime_type = "application/octet-stream"

    return {
        "filename": filename,
        "extension": ext,
        "category": category,
        "mime_type": mime_type,
        "size_bytes": file_size
    }


def generate_image_thumbnail(image_path, thumbnail_path, size=(300, 300)):
    """Generate a thumbnail for an image."""
    try:
        with Image.open(image_path) as img:
            if img.mode in ('RGBA', 'LA', 'P'):
                background = Image.new('RGB', img.size, (255, 255, 255))
                if img.mode == 'P':
                    img = img.convert('RGBA')
                background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                img = background
            
            img.thumbnail(size, Image.Resampling.LANCZOS)
            img.save(thumbnail_path, 'JPEG', quality=85, optimize=True)
            print(f"[MediaUtils] Image thumbnail generated: {thumbnail_path}")
            return True
    except Exception as e:
        print(f"[MediaUtils] Error generating image thumbnail: {e}")
        return False


def generate_video_thumbnail(video_path, thumbnail_path):
    """Generate a thumbnail for a video using ffmpeg."""
    try:
        import subprocess
        import shutil
        
        # Check if ffmpeg exists
        if shutil.which('ffmpeg') is None:
            print("[MediaUtils] ffmpeg not found in PATH. Install with: sudo apt-get install ffmpeg")
            return False
        
        # Try to extract frame at 1 second
        result = subprocess.run(
            [
                'ffmpeg',
                '-i', video_path,
                '-ss', '00:00:01.000',
                '-vframes', '1',
                '-vf', 'scale=300:300:force_original_aspect_ratio=decrease',
                thumbnail_path,
                '-y',
                '-loglevel', 'error'
            ],
            capture_output=True,
            timeout=15,
            text=True
        )
        
        if result.returncode == 0 and os.path.exists(thumbnail_path) and os.path.getsize(thumbnail_path) > 0:
            print(f"[MediaUtils] Video thumbnail generated successfully: {thumbnail_path}")
            return True
        else:
            error_msg = result.stderr if result.stderr else "Unknown error"
            print(f"[MediaUtils] ffmpeg failed with return code {result.returncode}: {error_msg}")
            return False
            
    except FileNotFoundError:
        print("[MediaUtils] ffmpeg executable not found - install FFmpeg on your system")
        return False
    except subprocess.TimeoutExpired:
        print("[MediaUtils] ffmpeg timeout - video may be too long")
        return False
    except Exception as e:
        print(f"[MediaUtils] Error generating video thumbnail: {e}")
        return False


def get_media_metadata(file_path, category, file_size):
    """Extract metadata from media files."""
    metadata = {
        "size_bytes": file_size,
        "size_mb": round(file_size / (1024 * 1024), 2)
    }
    
    if category == "image":
        try:
            with Image.open(file_path) as img:
                metadata["width"] = img.width
                metadata["height"] = img.height
                metadata["format"] = img.format
        except Exception as e:
            print(f"[MediaUtils] Error extracting image metadata: {e}")
    
    elif category == "video":
        try:
            import subprocess
            import shutil
            
            if shutil.which('ffprobe') is None:
                print("[MediaUtils] ffprobe not found - cannot extract video duration")
                return metadata
            
            result = subprocess.run(
                [
                    'ffprobe',
                    '-v', 'error',
                    '-show_entries', 'format=duration',
                    '-of', 'default=noprint_wrappers=1:nokey=1',
                    file_path
                ],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0 and result.stdout.strip():
                duration = float(result.stdout.strip())
                metadata["duration"] = round(duration, 2)
        except Exception as e:
            print(f"[MediaUtils] Error extracting video metadata: {e}")
    
    elif category == "audio":
        try:
            import subprocess
            import shutil
            
            if shutil.which('ffprobe') is None:
                print("[MediaUtils] ffprobe not found - cannot extract audio duration")
                return metadata
            
            result = subprocess.run(
                [
                    'ffprobe',
                    '-v', 'error',
                    '-show_entries', 'format=duration',
                    '-of', 'default=noprint_wrappers=1:nokey=1',
                    file_path
                ],
                capture_output=True,
                text=True,
                timeout=5
            )
            
            if result.returncode == 0 and result.stdout.strip():
                duration = float(result.stdout.strip())
                metadata["duration"] = round(duration, 2)
        except Exception as e:
            print(f"[MediaUtils] Error extracting audio metadata: {e}")
    
    return metadata


def upload_media_file(file_storage, message_type=None):
    """Handles saving a Flask FileStorage object with thumbnail generation."""
    ensure_media_dirs()

    # Validate and extract metadata
    meta = validate_file(file_storage, expected_type=message_type)

    # Unique filename to avoid collisions
    unique_name = f"{uuid.uuid4().hex}.{meta['extension']}"
    save_dir = os.path.join(MEDIA_ROOT, meta["category"])
    save_path = os.path.join(save_dir, unique_name)

    # Save file locally
    file_storage.save(save_path)
    print(f"[MediaUtils] File saved: {save_path}")

    # Generate ABSOLUTE URL
    file_url = f"{BASE_URL}/media/{meta['category']}/{unique_name}"
    
    # Initialize result
    result = {
        "url": file_url,
        "thumbnail_url": None,
        "metadata": get_media_metadata(save_path, meta["category"], meta["size_bytes"])
    }

    # Generate thumbnails
    if meta["category"] == "image":
        thumbnail_name = f"{uuid.uuid4().hex}_thumb.jpg"
        thumbnail_path = os.path.join(MEDIA_ROOT, "thumbnails", thumbnail_name)
        
        if generate_image_thumbnail(save_path, thumbnail_path):
            result["thumbnail_url"] = f"{BASE_URL}/media/thumbnails/{thumbnail_name}"
    
    elif meta["category"] == "video":
        thumbnail_name = f"{uuid.uuid4().hex}_thumb.jpg"
        thumbnail_path = os.path.join(MEDIA_ROOT, "thumbnails", thumbnail_name)
        
        print(f"[MediaUtils] Attempting to generate video thumbnail...")
        if generate_video_thumbnail(save_path, thumbnail_path):
            result["thumbnail_url"] = f"{BASE_URL}/media/thumbnails/{thumbnail_name}"
        else:
            print(f"[MediaUtils] Warning: Could not generate video thumbnail. Client will show fallback.")

    print(f"[MediaUtils] Uploaded {meta['category']} file: {file_url}")

    return result