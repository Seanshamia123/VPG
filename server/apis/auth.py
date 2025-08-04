from flask import request
from flask_restx import Namespace, Resource, fields
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime, timedelta
import jwt
import os
from models import User, Advertiser, AuthToken, db

api = Namespace('auth', description='Authentication operations')

# Input models for Swagger documentation
login_model = api.model('Login', {
    'email': fields.String(required=True, description='User email'),
    'password': fields.String(required=True, description='User password'),
    'user_type': fields.String(required=True, description='Type of user', enum=['user', 'advertiser'])
})

user_register_model = api.model('UserRegister', {
    'username': fields.String(required=True, description='Unique username'),
    'name': fields.String(required=True, description='User full name'),
    'email': fields.String(required=True, description='User email'),
    'password': fields.String(required=True, description='User password'),
    'phone_number': fields.String(required=True, description='Phone number'),
    'location': fields.String(required=True, description='User location'),
    'gender': fields.String(required=True, description='User gender', enum=['Male', 'Female', 'other'])
})

advertiser_register_model = api.model('AdvertiserRegister', {
    'username': fields.String(required=True, description='Unique username'),
    'name': fields.String(required=True, description='Advertiser name'),
    'email': fields.String(required=True, description='Advertiser email'),
    'password': fields.String(required=True, description='Advertiser password'),
    'phone_number': fields.String(required=True, description='Phone number'),
    'location': fields.String(required=True, description='Advertiser location'),
    'gender': fields.String(required=True, description='Gender', enum=['Male', 'Female', 'other']),
    'bio': fields.String(description='Advertiser bio')
})

# Response models
token_response_model = api.model('TokenResponse', {
    'access_token': fields.String(description='JWT access token'),
    'refresh_token': fields.String(description='JWT refresh token'),
    'user_id': fields.Integer(description='User ID'),
    'user_type': fields.String(description='Type of user'),
    'expires_in': fields.Integer(description='Token expiration time in seconds')
})

error_model = api.model('Error', {
    'error': fields.String(description='Error message')
})

def generate_tokens(user_id, user_type):
    """Generate access and refresh tokens"""
    try:
        secret_key = os.environ.get('SECRET_KEY', 'your-secret-key')
        print(f"Generating tokens for user_id: {user_id}, user_type: {user_type}")  # Debug
        
        # Access token (expires in 1 hour)
        access_payload = {
            'user_id': user_id,
            'user_type': user_type,
            'exp': datetime.utcnow() + timedelta(hours=1),
            'iat': datetime.utcnow()
        }
        access_token = jwt.encode(access_payload, secret_key, algorithm='HS256')
        # Ensure token is a string (some JWT versions return bytes)
        if isinstance(access_token, bytes):
            access_token = access_token.decode('utf-8')
        print(f"Access token generated: {access_token[:50]}...")  # Debug
        
        # Refresh token (expires in 30 days)
        refresh_payload = {
            'user_id': user_id,
            'user_type': user_type,
            'exp': datetime.utcnow() + timedelta(days=30),
            'iat': datetime.utcnow(),
            'type': 'refresh'
        }
        refresh_token = jwt.encode(refresh_payload, secret_key, algorithm='HS256')
        # Ensure token is a string (some JWT versions return bytes)
        if isinstance(refresh_token, bytes):
            refresh_token = refresh_token.decode('utf-8')
        print(f"Refresh token generated: {refresh_token[:50]}...")  # Debug
        
        return access_token, refresh_token
    except Exception as e:
        print(f"Error in generate_tokens: {str(e)}")  # Debug
        raise e

@api.route('/login')
class Login(Resource):
    def post(self):
        """User/Advertiser login"""
        try:
            # Get raw data first
            raw_data = request.get_data()
            print(f"Raw request data: {raw_data}")  # Debug log
            
            data = request.get_json(force=True)  # Force JSON parsing
            print(f"Login attempt - Data received: {data}")  # Debug log
            
            if not data:
                return {'error': 'No JSON data provided'}, 400
                
            email = data.get('email')
            password = data.get('password')
            user_type = data.get('user_type', 'user')
            
            print(f"Login attempt - Email: {email}, User type: {user_type}")  # Debug log
            
            if not email or not password:
                return {'error': 'Email and password are required'}, 400
            
            # Find user based on type (or auto-detect if not specified)
            user = None
            actual_user_type = user_type
            
            if user_type == 'advertiser':
                user = Advertiser.find_by_email(email)
                print(f"Advertiser lookup result: {user}")  # Debug log
            elif user_type == 'user':
                user = User.find_by_email(email)
                print(f"User lookup result: {user}")  # Debug log
            else:
                # Auto-detect: try both tables
                user = User.find_by_email(email)
                if user:
                    actual_user_type = 'user'
                    print(f"Found as User: {user}")  # Debug log
                else:
                    user = Advertiser.find_by_email(email)
                    if user:
                        actual_user_type = 'advertiser'
                        print(f"Found as Advertiser: {user}")  # Debug log
            
            # Check credentials
            if not user:
                print("User not found")  # Debug log
                return {'error': 'User not found'}, 401
                
            if not check_password_hash(user.password_hash, password):
                print("Password verification failed")  # Debug log
                return {'error': 'Invalid password'}, 401
            
            print("Login successful, generating tokens...")  # Debug log
            
            # Generate tokens with simplified approach
            secret_key = os.environ.get('SECRET_KEY', 'your-secret-key-fallback')
            
            # Create simple payload
            access_payload = {
                'user_id': int(user.id),  # Ensure it's an int
                'user_type': str(actual_user_type),  # Ensure it's a string
                'exp': int((datetime.utcnow() + timedelta(hours=1)).timestamp()),
                'iat': int(datetime.utcnow().timestamp())
            }
            
            refresh_payload = {
                'user_id': int(user.id),
                'user_type': str(actual_user_type),
                'exp': int((datetime.utcnow() + timedelta(days=30)).timestamp()),
                'iat': int(datetime.utcnow().timestamp()),
                'type': 'refresh'
            }
            
            access_token = jwt.encode(access_payload, secret_key, algorithm='HS256')
            refresh_token = jwt.encode(refresh_payload, secret_key, algorithm='HS256')
            
            # Ensure tokens are strings
            if isinstance(access_token, bytes):
                access_token = access_token.decode('utf-8')
            if isinstance(refresh_token, bytes):
                refresh_token = refresh_token.decode('utf-8')
                
            print(f"Tokens generated successfully")  # Debug log
            
            # Skip database storage for now to test if that's the issue
            print(f"Skipping database storage for testing")  # Debug log
            
            # Create simple response
            response_data = {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user_id': int(user.id),
                'user_type': str(actual_user_type),
                'expires_in': 3600
            }
            print(f"Response data prepared: {type(response_data)}")  # Debug log
            
            return response_data
            
        except Exception as e:
            print(f"Exception occurred: {type(e).__name__}: {str(e)}")  # Debug log
            import traceback
            traceback.print_exc()  # Print full traceback
            return {'error': f'Login failed: {str(e)}'}, 500

@api.route('/register/user')
class UserRegister(Resource):
    @api.expect(user_register_model)
    @api.doc('user_register')
    def post(self):
        """Register a new user"""
        try:
            data = request.get_json()
            
            if not data:
                return {'error': 'No JSON data provided'}, 400
            
            password = data.get('password')
            if not password:
                return {'error': 'Password is required'}, 400

            # Check if user already exists
            if User.find_by_email(data.get('email')):
                return {'error': 'User with this email already exists'}, 400
            
            # Validate required fields
            required_fields = ['username', 'name', 'email', 'phone_number', 'location', 'gender']
            for field in required_fields:
                if not data.get(field):
                    return {'error': f'{field} is required'}, 400
            
            # Create new user
            user = User(
                username=data['username'],
                name=data['name'],
                email=data['email'],
                phone_number=data['phone_number'],
                location=data['location'],
                gender=data['gender'],
                password_hash=generate_password_hash(data['password'])
            )
            
            try:
                user.save()
            except Exception as save_error:
                return {'error': f'Failed to save user: {str(save_error)}'}, 500
            
            # Generate tokens
            access_token, refresh_token = generate_tokens(user.id, 'user')
            
            # Store tokens
            auth_token = AuthToken(
                user_id=user.id,
                user_type='user',
                access_token=access_token,
                refresh_token=refresh_token,
                expires_at=datetime.utcnow() + timedelta(hours=1)
            )

            try:
                db.session.add(auth_token)
                db.session.commit()
            except Exception as db_error:
                db.session.rollback()
                return {'error': f'Database error: {str(db_error)}'}, 500
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user_id': user.id,
                'user_type': 'user',
                'expires_in': 3600
            }, 201
            
        except Exception as e:
            db.session.rollback()
            return {'error': f'Registration failed: {str(e)}'}, 500

@api.route('/register/advertiser')
class AdvertiserRegister(Resource):
    @api.expect(advertiser_register_model)
    @api.doc('advertiser_register')
    def post(self):
        """Register a new advertiser"""
        try:
            data = request.get_json()
            
            if not data:
                return {'error': 'No JSON data provided'}, 400
            
            # Check if advertiser already exists
            if Advertiser.find_by_email(data.get('email')):
                return {'error': 'Advertiser with this email already exists'}, 400
            
            # Validate required fields
            required_fields = ['username', 'name', 'email', 'password', 'phone_number', 'location', 'gender']
            for field in required_fields:
                if not data.get(field):
                    return {'error': f'{field} is required'}, 400
            
            # Create new advertiser
            advertiser = Advertiser(
                username=data['username'],
                name=data['name'],
                email=data['email'],
                phone_number=data['phone_number'],
                location=data['location'],
                gender=data['gender'],
                bio=data.get('bio'),
                password_hash=generate_password_hash(data['password'])
            )
            
            try:
                advertiser.save()
            except Exception as save_error:
                return {'error': f'Failed to save advertiser: {str(save_error)}'}, 500
            
            # Generate tokens
            access_token, refresh_token = generate_tokens(advertiser.id, 'advertiser')
            
            # Store tokens
            auth_token = AuthToken(
                user_id=advertiser.id,
                user_type='advertiser',
                access_token=access_token,
                refresh_token=refresh_token,
                expires_at=datetime.utcnow() + timedelta(hours=1)
            )
            
            try:
                db.session.add(auth_token)
                db.session.commit()
            except Exception as db_error:
                db.session.rollback()
                return {'error': f'Database error: {str(db_error)}'}, 500
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user_id': advertiser.id,
                'user_type': 'advertiser',
                'expires_in': 3600
            }, 201
            
        except Exception as e:
            db.session.rollback()
            return {'error': f'Registration failed: {str(e)}'}, 500

@api.route('/refresh')
class RefreshToken(Resource):
    @api.doc('refresh_token')
    def post(self):
        """Refresh access token using refresh token"""
        try:
            data = request.get_json()
            
            if not data:
                return {'error': 'No JSON data provided'}, 400
                
            refresh_token = data.get('refresh_token')
            
            if not refresh_token:
                return {'error': 'Refresh token is required'}, 400
            
            # Decode refresh token
            secret_key = os.environ.get('SECRET_KEY', 'your-secret-key')
            try:
                payload = jwt.decode(refresh_token, secret_key, algorithms=['HS256'])
            except jwt.ExpiredSignatureError:
                return {'error': 'Refresh token has expired'}, 401
            except jwt.InvalidTokenError:
                return {'error': 'Invalid refresh token'}, 401
            
            if payload.get('type') != 'refresh':
                return {'error': 'Invalid token type'}, 400
            
            # Generate new access token
            access_token, _ = generate_tokens(payload['user_id'], payload['user_type'])
            
            return {
                'access_token': access_token,
                'expires_in': 3600
            }, 200
            
        except Exception as e:
            return {'error': f'Token refresh failed: {str(e)}'}, 500

@api.route('/logout')
class Logout(Resource):
    @api.doc('logout')
    def post(self):
        """Logout user and invalidate tokens"""
        try:
            # Get token from header
            auth_header = request.headers.get('Authorization')
            if not auth_header or not auth_header.startswith('Bearer '):
                return {'error': 'Authorization token required'}, 401
            
            token = auth_header.split(' ')[1]
            
            # Find and delete token from database
            try:
                auth_token = AuthToken.query.filter_by(access_token=token).first()
                if auth_token:
                    db.session.delete(auth_token)
                    db.session.commit()
            except Exception as db_error:
                db.session.rollback()
                return {'error': f'Database error: {str(db_error)}'}, 500
            
            return {'message': 'Successfully logged out'}, 200
            
        except Exception as e:
            return {'error': f'Logout failed: {str(e)}'}, 500