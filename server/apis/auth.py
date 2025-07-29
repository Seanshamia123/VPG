from flask import request, jsonify
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

def generate_tokens(user_id, user_type):
    """Generate access and refresh tokens"""
    secret_key = os.environ.get('SECRET_KEY', 'your-secret-key')
    
    # Access token (expires in 1 hour)
    access_payload = {
        'user_id': user_id,
        'user_type': user_type,
        'exp': datetime.utcnow() + timedelta(hours=1),
        'iat': datetime.utcnow()
    }
    access_token = jwt.encode(access_payload, secret_key, algorithm='HS256')
    
    # Refresh token (expires in 30 days)
    refresh_payload = {
        'user_id': user_id,
        'user_type': user_type,
        'exp': datetime.utcnow() + timedelta(days=30),
        'iat': datetime.utcnow(),
        'type': 'refresh'
    }
    refresh_token = jwt.encode(refresh_payload, secret_key, algorithm='HS256')
    
    return access_token, refresh_token

@api.route('/login')
class Login(Resource):
    @api.expect(login_model)
    @api.marshal_with(token_response_model)
    @api.doc('user_login')
    def post(self):
        """User/Advertiser login"""
        try:
            data = request.get_json()
            email = data.get('email')
            password = data.get('password')
            user_type = data.get('user_type', 'user')
            
            if not email or not password:
                api.abort(400, 'Email and password are required')
            
            # Find user based on type
            if user_type == 'advertiser':
                user = Advertiser.find_by_email(email)
            else:
                user = User.find_by_email(email)
            
            if not user or not check_password_hash(user.password_hash, password):
                api.abort(401, 'Invalid email or password')
            
            # Generate tokens
            access_token, refresh_token = generate_tokens(user.id, user_type)
            
            # Store tokens in database
            auth_token = AuthToken(
                user_id=user.id,
                access_token=access_token,
                refresh_token=refresh_token,
                user_agent=request.headers.get('User-Agent'),
                ip_address=request.remote_addr,
                expires_at=datetime.utcnow() + timedelta(hours=1)
            )
            db.session.add(auth_token)
            db.session.commit()
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user_id': user.id,
                'user_type': user_type,
                'expires_in': 3600
            }
            
        except Exception as e:
            api.abort(500, f'Login failed: {str(e)}')

@api.route('/register/user')
class UserRegister(Resource):
    @api.expect(user_register_model)
    @api.marshal_with(token_response_model)
    @api.doc('user_register')
    def post(self):
        """Register a new user"""
        try:
            data = request.get_json()
            
            # Check if user already exists
            if User.find_by_email(data['email']):
                api.abort(400, 'User with this email already exists')
            
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
            
            user.save()
            
            # Generate tokens
            access_token, refresh_token = generate_tokens(user.id, 'user')
            
            # Store tokens
            auth_token = AuthToken(
                user_id=user.id,
                access_token=access_token,
                refresh_token=refresh_token,
                user_agent=request.headers.get('User-Agent'),
                ip_address=request.remote_addr,
                expires_at=datetime.utcnow() + timedelta(hours=1)
            )
            db.session.add(auth_token)
            db.session.commit()
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user_id': user.id,
                'user_type': 'user',
                'expires_in': 3600
            }
            
        except Exception as e:
            api.abort(500, f'Registration failed: {str(e)}')

@api.route('/register/advertiser')
class AdvertiserRegister(Resource):
    @api.expect(advertiser_register_model)
    @api.marshal_with(token_response_model)
    @api.doc('advertiser_register')
    def post(self):
        """Register a new advertiser"""
        try:
            data = request.get_json()
            
            # Check if advertiser already exists
            if Advertiser.find_by_email(data['email']):
                api.abort(400, 'Advertiser with this email already exists')
            
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
            
            advertiser.save()
            
            # Generate tokens
            access_token, refresh_token = generate_tokens(advertiser.id, 'advertiser')
            
            # Store tokens
            auth_token = AuthToken(
                user_id=advertiser.id,
                access_token=access_token,
                refresh_token=refresh_token,
                user_agent=request.headers.get('User-Agent'),
                ip_address=request.remote_addr,
                expires_at=datetime.utcnow() + timedelta(hours=1)
            )
            db.session.add(auth_token)
            db.session.commit()
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user_id': advertiser.id,
                'user_type': 'advertiser',
                'expires_in': 3600
            }
            
        except Exception as e:
            api.abort(500, f'Registration failed: {str(e)}')

@api.route('/refresh')
class RefreshToken(Resource):
    @api.doc('refresh_token')
    def post(self):
        """Refresh access token using refresh token"""
        try:
            data = request.get_json()
            refresh_token = data.get('refresh_token')
            
            if not refresh_token:
                api.abort(400, 'Refresh token is required')
            
            # Decode refresh token
            secret_key = os.environ.get('SECRET_KEY', 'your-secret-key')
            payload = jwt.decode(refresh_token, secret_key, algorithms=['HS256'])
            
            if payload.get('type') != 'refresh':
                api.abort(400, 'Invalid token type')
            
            # Generate new access token
            access_token, _ = generate_tokens(payload['user_id'], payload['user_type'])
            
            return {
                'access_token': access_token,
                'expires_in': 3600
            }
            
        except jwt.ExpiredSignatureError:
            api.abort(401, 'Refresh token has expired')
        except jwt.InvalidTokenError:
            api.abort(401, 'Invalid refresh token')
        except Exception as e:
            api.abort(500, f'Token refresh failed: {str(e)}')

@api.route('/logout')
class Logout(Resource):
    @api.doc('logout')
    def post(self):
        """Logout user and invalidate tokens"""
        try:
            # Get token from header
            auth_header = request.headers.get('Authorization')
            if not auth_header or not auth_header.startswith('Bearer '):
                api.abort(401, 'Authorization token required')
            
            token = auth_header.split(' ')[1]
            
            # Find and delete token from database
            auth_token = AuthToken.query.filter_by(access_token=token).first()
            if auth_token:
                db.session.delete(auth_token)
                db.session.commit()
            
            return {'message': 'Successfully logged out'}
            
        except Exception as e:
            api.abort(500, f'Logout failed: {str(e)}')