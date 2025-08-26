# cloudinary_service.py - Fixed version
import cloudinary
import cloudinary.uploader
import cloudinary.api
from flask import current_app
import time
import os

class CloudinaryService:
    def __init__(self):
        self._configured = False
    
    def configure_cloudinary(self):
        """Configure Cloudinary with credentials"""
        try:
            # Use environment variables directly if current_app is not available
            cloud_name = None
            api_key = None
            api_secret = None
            
            try:
                # Try to get from Flask config first
                cloud_name = current_app.config.get('CLOUDINARY_CLOUD_NAME')
                api_key = current_app.config.get('CLOUDINARY_API_KEY')
                api_secret = current_app.config.get('CLOUDINARY_API_SECRET')
            except RuntimeError:
                # Fall back to environment variables if no app context
                cloud_name = os.environ.get('CLOUDINARY_CLOUD_NAME')
                api_key = os.environ.get('CLOUDINARY_API_KEY')
                api_secret = os.environ.get('CLOUDINARY_API_SECRET')
            
            cloudinary.config(
                cloud_name=cloud_name,
                api_key=api_key,
                api_secret=api_secret
            )
            self._configured = True
            
        except Exception as e:
            print(f"Warning: Cloudinary configuration failed: {e}")
            self._configured = False
    
    def init_app(self, app):
        """Initialize with Flask app"""
        with app.app_context():
            self.configure_cloudinary()
    
    def _ensure_configured(self):
        """Ensure Cloudinary is configured before operations"""
        if not self._configured:
            self.configure_cloudinary()
    
    def upload_image(self, image_data, folder="vpg/posts", public_id=None):
        """
        Upload image to Cloudinary
        
        Args:
            image_data: Can be file path, base64 string, or file-like object
            folder: Cloudinary folder path (default: vpg/posts)
            public_id: Custom public ID (optional)
        
        Returns:
            dict: Cloudinary upload response
        """
        try:
            self._ensure_configured()
            
            upload_options = {
                'folder': folder,
                'resource_type': 'image',
                'quality': 'auto',
                'fetch_format': 'auto'
            }
            
            # Try to get upload preset from config
            try:
                upload_preset = current_app.config.get('CLOUDINARY_UPLOAD_PRESET')
                if upload_preset:
                    upload_options['upload_preset'] = upload_preset
            except RuntimeError:
                # No app context, skip upload preset
                pass
            
            if public_id:
                upload_options['public_id'] = public_id
            
            # Handle base64 data
            if isinstance(image_data, str) and image_data.startswith('data:image'):
                result = cloudinary.uploader.upload(image_data, **upload_options)
            else:
                result = cloudinary.uploader.upload(image_data, **upload_options)
            
            return {
                'success': True,
                'public_id': result['public_id'],
                'secure_url': result['secure_url'],
                'url': result['url'],
                'format': result['format'],
                'width': result['width'],
                'height': result['height'],
                'bytes': result['bytes']
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def upload_base64_image(self, base64_string, folder="vpg/posts", public_id=None):
        """
        Upload base64 encoded image to Cloudinary
        
        Args:
            base64_string: Base64 encoded image data
            folder: Cloudinary folder path
            public_id: Custom public ID (optional)
        
        Returns:
            dict: Upload result
        """
        try:
            # If base64_string doesn't have data URL prefix, add it
            if not base64_string.startswith('data:image'):
                base64_string = f"data:image/jpeg;base64,{base64_string}"
            
            return self.upload_image(base64_string, folder, public_id)
            
        except Exception as e:
            return {
                'success': False,
                'error': f"Base64 upload failed: {str(e)}"
            }
    
    def delete_image(self, public_id):
        """
        Delete image from Cloudinary
        
        Args:
            public_id: Cloudinary public ID of the image
        
        Returns:
            dict: Deletion result
        """
        try:
            self._ensure_configured()
            result = cloudinary.uploader.destroy(public_id)
            return {
                'success': result.get('result') == 'ok',
                'result': result
            }
        except Exception as e:
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_image_url(self, public_id, transformation=None):
        """
        Generate Cloudinary URL for an image
        
        Args:
            public_id: Cloudinary public ID
            transformation: Transformation options (dict)
        
        Returns:
            str: Generated URL
        """
        try:
            self._ensure_configured()
            if transformation:
                return cloudinary.CloudinaryImage(public_id).build_url(**transformation)
            else:
                return cloudinary.CloudinaryImage(public_id).build_url()
        except Exception as e:
            return None

# Global service instance
_service = None

def get_service():
    """Get the global CloudinaryService instance"""
    global _service
    if _service is None:
        _service = CloudinaryService()
        # Try to initialize with current app if available
        try:
            _service.init_app(current_app)
        except RuntimeError:
            # No app context available yet, will configure later
            pass
    return _service

# Create instance but don't configure yet
cloudinary_service = CloudinaryService()