# cloudinary_service.py - Create this as a NEW FILE in your project
import cloudinary
import cloudinary.uploader
import cloudinary.api
from flask import current_app
import time

class CloudinaryService:
    def __init__(self):
        self.configure_cloudinary()
    
    def configure_cloudinary(self):
        """Configure Cloudinary with credentials"""
        cloudinary.config(
            cloud_name=current_app.config.get('CLOUDINARY_CLOUD_NAME'),
            api_key=current_app.config.get('CLOUDINARY_API_KEY'),
            api_secret=current_app.config.get('CLOUDINARY_API_SECRET')
        )
    
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
            upload_options = {
                'folder': folder,
                'upload_preset': current_app.config.get('CLOUDINARY_UPLOAD_PRESET'),
                'resource_type': 'image',
                'quality': 'auto',
                'fetch_format': 'auto'
            }
            
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
            if transformation:
                return cloudinary.CloudinaryImage(public_id).build_url(**transformation)
            else:
                return cloudinary.CloudinaryImage(public_id).build_url()
        except Exception as e:
            return None

# Initialize the service
cloudinary_service = CloudinaryService()