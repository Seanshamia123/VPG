from functools import wraps
from flask import request, jsonify
import jwt
import os
from models import User, Advertiser

def token_required(f):
    """Decorator to require JWT token for API endpoints"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(" ")[1]  # Bearer <token>
            except IndexError:
                return jsonify({'message': 'Invalid token format'}), 401
        
        if not token:
            return jsonify({'message': 'Token is missing'}), 401
        
        try:
            # Decode token
            secret_key = os.environ.get('SECRET_KEY', 'your-secret-key')
            data = jwt.decode(token, secret_key, algorithms=['HS256'])
            
            # Get user based on type
            user_type = data.get('user_type', 'user')
            user_id = data.get('user_id')
            
            if user_type == 'advertiser':
                current_user = Advertiser.find_by_id(user_id)
            else:
                current_user = User.find_by_id(user_id)
            
            if not current_user:
                return jsonify({'message': 'User not found'}), 401
                
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Invalid token'}), 401
        except Exception as e:
            return jsonify({'message': f'Token validation failed: {str(e)}'}), 401
        
        return f(current_user, *args, **kwargs)
    
    return decorated

def advertiser_required(f):
    """Decorator to require advertiser role"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(" ")[1]
            except IndexError:
                return jsonify({'message': 'Invalid token format'}), 401
        
        if not token:
            return jsonify({'message': 'Token is missing'}), 401
        
        try:
            # Decode token
            secret_key = os.environ.get('SECRET_KEY', 'your-secret-key')
            data = jwt.decode(token, secret_key, algorithms=['HS256'])
            
            # Check if user is advertiser
            user_type = data.get('user_type')
            if user_type != 'advertiser':
                return jsonify({'message': 'Advertiser access required'}), 403
            
            user_id = data.get('user_id')
            current_advertiser = Advertiser.find_by_id(user_id)
            
            if not current_advertiser:
                return jsonify({'message': 'Advertiser not found'}), 401
                
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'message': 'Invalid token'}), 401
        except Exception as e:
            return jsonify({'message': f'Token validation failed: {str(e)}'}), 401
        
        return f(current_advertiser, *args, **kwargs)
    
    return decorated