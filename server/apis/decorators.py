from functools import wraps
from flask import request, jsonify
import jwt
import os
from models import User, Advertiser


def token_required(f):
    """Decorator to require JWT token for API endpoints - Flask-RESTX compatible"""
    @wraps(f)
    def decorated(*args, **kwargs):
        print("=== TOKEN REQUIRED DEBUG START ===")
        print(f"DEBUG: args: {args}")
        print(f"DEBUG: kwargs: {kwargs}")
        
        token = None
        
        # Get token from header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            print(f"DEBUG: Auth header: {auth_header[:50]}...")
            try:
                token = auth_header.split(" ")[1]  # Bearer <token>
                print(f"DEBUG: Extracted token (first 20 chars): {token[:20]}...")
            except IndexError:
                print("DEBUG: Failed to extract token from header")
                return jsonify({'message': 'Invalid token format'}), 401
        else:
            print("DEBUG: No Authorization header found")
        
        if not token:
            print("DEBUG: Token is missing")
            return jsonify({'message': 'Token is missing'}), 401
        
        try:
            # Decode token
            secret_key = os.environ.get('SECRET_KEY', '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3')
            print(f"DEBUG: Using secret key: {secret_key}")
            
            data = jwt.decode(token, secret_key, algorithms=['HS256'])
            print(f"DEBUG: Successfully decoded token: {data}")
            
            # Get user based on type
            user_type = data.get('user_type', 'user')
            user_id = data.get('user_id')
            print(f"DEBUG: Looking for user_type: {user_type}, user_id: {user_id}")
            
            if user_type == 'advertiser':
                current_user = Advertiser.find_by_id(user_id)
                print(f"DEBUG: Searched for advertiser, found: {current_user}")
            else:
                current_user = User.find_by_id(user_id)
                print(f"DEBUG: Searched for user, found: {current_user}")
            
            if not current_user:
                print("DEBUG: User not found in database")
                return jsonify({'message': 'User not found'}), 401
            
            print(f"DEBUG: Authentication successful for user: {current_user.id if hasattr(current_user, 'id') else 'unknown'}")
            print("=== TOKEN REQUIRED DEBUG END ===")
            
            # For Flask-RESTX Resource methods, we need to pass current_user as the first argument after self
            # This handles both class methods (where args[0] is self) and function views
            if args and hasattr(args[0], '__class__') and 'Resource' in str(args[0].__class__.__bases__):
                # This is a Flask-RESTX Resource method
                # args[0] is self, so we insert current_user after it
                new_args = args[:1] + (current_user,) + args[1:]
                print(f"DEBUG: Flask-RESTX Resource detected, new args: {len(new_args)}")
                return f(*new_args, **kwargs)
            else:
                # This is a regular function, add current_user as first argument
                new_args = (current_user,) + args
                print(f"DEBUG: Regular function detected, new args: {len(new_args)}")
                return f(*new_args, **kwargs)
                
        except jwt.ExpiredSignatureError:
            print("DEBUG: Token has expired")
            return jsonify({'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError as e:
            print(f"DEBUG: Invalid token error: {e}")
            return jsonify({'message': 'Invalid token'}), 401
        except Exception as e:
            print(f"DEBUG: Unexpected exception: {type(e).__name__}: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({'message': f'Token validation failed: {str(e)}'}), 401
    
    return decorated

def advertiser_required(f):
    """Decorator to require advertiser role - Flask-RESTX compatible"""
    @wraps(f)
    def decorated(*args, **kwargs):
        print("=== ADVERTISER REQUIRED DEBUG START ===")
        token = None
        
        # Get token from header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            print(f"DEBUG: Auth header: {auth_header[:50]}...")
            try:
                token = auth_header.split(" ")[1]
                print(f"DEBUG: Extracted token (first 20 chars): {token[:20]}...")
            except IndexError:
                print("DEBUG: Failed to extract token from header")
                return jsonify({'message': 'Invalid token format'}), 401
        else:
            print("DEBUG: No Authorization header found")
        
        if not token:
            print("DEBUG: Token is missing")
            return jsonify({'message': 'Token is missing'}), 401
        
        try:
            # Decode token
            secret_key = os.environ.get('SECRET_KEY', '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3')
            print(f"DEBUG: Using secret key: {secret_key}")
            
            data = jwt.decode(token, secret_key, algorithms=['HS256'])
            print(f"DEBUG: Successfully decoded token: {data}")
            
            # Check if user is advertiser
            user_type = data.get('user_type')
            if user_type != 'advertiser':
                print(f"DEBUG: User type '{user_type}' is not advertiser")
                return jsonify({'message': 'Advertiser access required'}), 403
            
            user_id = data.get('user_id')
            current_advertiser = Advertiser.find_by_id(user_id)
            print(f"DEBUG: Searched for advertiser, found: {current_advertiser}")
            
            if not current_advertiser:
                print("DEBUG: Advertiser not found in database")
                return jsonify({'message': 'Advertiser not found'}), 401
            
            print(f"DEBUG: Advertiser authentication successful: {current_advertiser.id if hasattr(current_advertiser, 'id') else 'unknown'}")
            print("=== ADVERTISER REQUIRED DEBUG END ===")
            
            # Handle Flask-RESTX Resource methods
            if args and hasattr(args[0], '__class__') and 'Resource' in str(args[0].__class__.__bases__):
                # This is a Flask-RESTX Resource method
                new_args = args[:1] + (current_advertiser,) + args[1:]
                return f(*new_args, **kwargs)
            else:
                # This is a regular function
                new_args = (current_advertiser,) + args
                return f(*new_args, **kwargs)
                
        except jwt.ExpiredSignatureError:
            print("DEBUG: Token has expired")
            return jsonify({'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError as e:
            print(f"DEBUG: Invalid token error: {e}")
            return jsonify({'message': 'Invalid token'}), 401
        except Exception as e:
            print(f"DEBUG: Unexpected exception: {type(e).__name__}: {str(e)}")
            import traceback
            traceback.print_exc()
            return jsonify({'message': f'Token validation failed: {str(e)}'}), 401
        
        return f(current_advertiser, *args, **kwargs)
    
    return decorated

# Alternative approach - simpler decorator that works better with Flask-RESTX
def token_required_simple(f):
    """Simpler token decorator that handles Flask-RESTX Resource methods correctly"""
    @wraps(f)
    def decorated(self, *args, **kwargs):
        print("=== SIMPLE TOKEN REQUIRED DEBUG START ===")
        print(f"DEBUG: self: {self}, args: {args}, kwargs: {kwargs}")
        
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
            secret_key = os.environ.get('SECRET_KEY', '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3')
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
            
            print(f"DEBUG: Authentication successful for user: {current_user.id}")
            print("=== SIMPLE TOKEN REQUIRED DEBUG END ===")
            
            # Pass current_user as the first argument after self
            return f(self, current_user, *args, **kwargs)
                
        except jwt.ExpiredSignatureError:
            return jsonify({'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError as e:
            return jsonify({'message': 'Invalid token'}), 401
        except Exception as e:
            print(f"DEBUG: Exception: {e}")
            return jsonify({'message': f'Token validation failed: {str(e)}'}), 401
    
    return decorated

def advertiser_required(f):
    """Decorator to require advertiser role"""
    @wraps(f)
    def decorated(*args, **kwargs):
        print("=== ADVERTISER REQUIRED DEBUG START ===")
        token = None
        
        # Get token from header
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            print(f"DEBUG: Auth header: {auth_header}")
            try:
                token = auth_header.split(" ")[1]
                print(f"DEBUG: Extracted token (first 20 chars): {token[:20]}...")
            except IndexError:
                print("DEBUG: Failed to extract token from header")
                return jsonify({'message': 'Invalid token format'}), 401
        else:
            print("DEBUG: No Authorization header found")
        
        if not token:
            print("DEBUG: Token is missing")
            return jsonify({'message': 'Token is missing'}), 401
        
        try:
            # Decode token
            secret_key = os.environ.get('SECRET_KEY', '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3')
            print(f"DEBUG: Using secret key: {secret_key}")
            
            data = jwt.decode(token, secret_key, algorithms=['HS256'])
            print(f"DEBUG: Successfully decoded token: {data}")
            
            # Check if user is advertiser
            user_type = data.get('user_type')
            if user_type != 'advertiser':
                print(f"DEBUG: User type '{user_type}' is not advertiser")
                return jsonify({'message': 'Advertiser access required'}), 403
            
            user_id = data.get('user_id')
            current_advertiser = Advertiser.find_by_id(user_id)
            print(f"DEBUG: Searched for advertiser, found: {current_advertiser}")
            
            if not current_advertiser:
                print("DEBUG: Advertiser not found in database")
                return jsonify({'message': 'Advertiser not found'}), 401
            
            print(f"DEBUG: Advertiser authentication successful: {current_advertiser.id if hasattr(current_advertiser, 'id') else 'unknown'}")
            print("=== ADVERTISER REQUIRED DEBUG END ===")
                
        except jwt.ExpiredSignatureError:
            print("DEBUG: Token has expired")
            return jsonify({'message': 'Token has expired'}), 401
        except jwt.InvalidTokenError as e:
            print(f"DEBUG: Invalid token error: {e}")
            return jsonify({'message': 'Invalid token'}), 401
        except Exception as e:
            print(f"DEBUG: Unexpected exception: {type(e).__name__}: {str(e)}")
            return jsonify({'message': f'Token validation failed: {str(e)}'}), 401
        
        return f(current_advertiser, *args, **kwargs)
    
    return decorated