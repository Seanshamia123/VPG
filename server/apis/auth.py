from flask import request
from flask_restx import Namespace, Resource, fields
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime, timedelta
import jwt
import os
from models import User, Advertiser, AuthToken, Subscription, db

api = Namespace('auth', description='Authentication operations')

# ============================================
# DEVELOPMENT MODE FLAG
# ============================================
DEVELOPMENT_MODE = False # Set to False to re-enable subscription checks
# ============================================

# Configuration
ACCESS_TOKEN_EXPIRES_HOURS = 24
REFRESH_TOKEN_EXPIRES_DAYS = 30

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
    'expires_in': fields.Integer(description='Token expiration time in seconds'),
    'expires_at': fields.String(description='Token expiration datetime (ISO format)'),
    'subscription_required': fields.Boolean(description='Whether subscription is required'),
    'subscription_status': fields.String(description='Current subscription status')
})

error_model = api.model('Error', {
    'error': fields.String(description='Error message')
})

def check_advertiser_subscription(advertiser_id):
    """
    Check if advertiser has an active subscription
    Returns: (has_active_subscription: bool, subscription_info: dict)
    """
    # DEVELOPMENT MODE: Skip subscription checks
    if DEVELOPMENT_MODE:
        print("⚠️  DEVELOPMENT MODE: Skipping subscription check - allowing login")
        return True, {
            'has_subscription': True,
            'subscription_id': 0,
            'plan_name': 'Development Mode - No Subscription Required',
            'status': 'active',
            'end_date': (datetime.utcnow() + timedelta(days=365)).isoformat(),
            'days_remaining': 365,
            'payment_status': 'dev_mode',
            'development_mode': True
        }
    
    try:
        # Get the most recent subscription for this advertiser
        subscription = Subscription.query.filter_by(
            user_id=advertiser_id,
            status='active'
        ).order_by(Subscription.end_date.desc()).first()
        
        if not subscription:
            return False, {
                'has_subscription': False,
                'message': 'No active subscription found. Please subscribe to continue.',
                'status': 'no_subscription'
            }
        
        # Check if subscription is still valid
        now = datetime.utcnow()
        if subscription.end_date and subscription.end_date < now:
            # Subscription has expired
            subscription.status = 'expired'
            db.session.commit()
            
            return False, {
                'has_subscription': False,
                'message': 'Your subscription has expired. Please renew to continue.',
                'expired_at': subscription.end_date.isoformat(),
                'status': 'expired'
            }
        
        # Subscription is active and valid
        days_remaining = (subscription.end_date - now).days if subscription.end_date else None
        
        return True, {
            'has_subscription': True,
            'subscription_id': subscription.id,
            'plan_name': subscription.plan_name,
            'status': subscription.status,
            'end_date': subscription.end_date.isoformat() if subscription.end_date else None,
            'days_remaining': days_remaining,
            'payment_status': subscription.payment_status
        }
        
    except Exception as e:
        print(f"Error checking subscription: {str(e)}")
        return False, {
            'has_subscription': False,
            'message': 'Error checking subscription status',
            'status': 'error'
        }

def generate_tokens(user_id, user_type):
    """Generate access and refresh tokens with consistent expiration times"""
    try:
        secret_key = os.environ.get('SECRET_KEY', '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3')
        print(f"Generating tokens for user_id: {user_id}, user_type: {user_type}")
        
        now = datetime.utcnow()
        
        # Access token
        access_expires = now + timedelta(hours=ACCESS_TOKEN_EXPIRES_HOURS)
        access_payload = {
            'user_id': int(user_id),
            'user_type': str(user_type),
            'exp': int(access_expires.timestamp()),
            'iat': int(now.timestamp()),
            'type': 'access'
        }
        access_token = jwt.encode(access_payload, secret_key, algorithm='HS256')
        
        # Refresh token
        refresh_expires = now + timedelta(days=REFRESH_TOKEN_EXPIRES_DAYS)
        refresh_payload = {
            'user_id': int(user_id),
            'user_type': str(user_type),
            'exp': int(refresh_expires.timestamp()),
            'iat': int(now.timestamp()),
            'type': 'refresh'
        }
        refresh_token = jwt.encode(refresh_payload, secret_key, algorithm='HS256')
        
        if isinstance(access_token, bytes):
            access_token = access_token.decode('utf-8')
        if isinstance(refresh_token, bytes):
            refresh_token = refresh_token.decode('utf-8')
        
        print(f"Tokens generated - Access expires: {access_expires}, Refresh expires: {refresh_expires}")
        
        return access_token, refresh_token, access_expires
        
    except Exception as e:
        print(f"Error in generate_tokens: {str(e)}")
        raise e

@api.route('/login')
class Login(Resource):
    @api.expect(login_model)
    @api.marshal_with(token_response_model)
    def post(self):
        """User/Advertiser login with subscription check for advertisers"""
        try:
            data = request.get_json(force=True)
            print(f"Login attempt - Data received: {data}")
            
            if not data:
                api.abort(400, 'No JSON data provided')
                
            email = data.get('email')
            password = data.get('password')
            user_type = data.get('user_type', 'user')
            
            print(f"Login attempt - Email: {email}, User type: {user_type}")
            
            if not email or not password:
                api.abort(400, 'Email and password are required')
            
            # Find user based on type
            user = None
            actual_user_type = user_type
            
            if user_type == 'advertiser':
                user = Advertiser.find_by_email(email)
                print(f"Advertiser lookup result: {user}")
            elif user_type == 'user':
                user = User.find_by_email(email)
                print(f"User lookup result: {user}")
            else:
                # Auto-detect
                user = User.find_by_email(email)
                if user:
                    actual_user_type = 'user'
                    print(f"Found as User: {user}")
                else:
                    user = Advertiser.find_by_email(email)
                    if user:
                        actual_user_type = 'advertiser'
                        print(f"Found as Advertiser: {user}")
            
            # Check credentials
            if not user:
                print("User not found")
                api.abort(401, 'Invalid credentials')
                
            if not check_password_hash(user.password_hash, password):
                print("Password verification failed")
                api.abort(401, 'Invalid credentials')
            
            print("Credentials verified successfully")
            
            # CRITICAL: Check subscription status for advertisers (unless DEVELOPMENT_MODE)
            subscription_info = None
            if actual_user_type == 'advertiser':
                has_active_sub, subscription_info = check_advertiser_subscription(user.id)
                
                print(f"=== ADVERTISER SUBSCRIPTION CHECK ===")
                print(f"Development Mode: {DEVELOPMENT_MODE}")
                print(f"Has active subscription: {has_active_sub}")
                print(f"Subscription info: {subscription_info}")
                print("=====================================")
                
                if not has_active_sub and not DEVELOPMENT_MODE:
                    # Block login if no active subscription (only when not in dev mode)
                    error_message = subscription_info.get(
                        'message', 
                        'Active subscription required. Please subscribe to continue.'
                    )
                    
                    return {
                        'error': error_message,
                        'subscription_required': True,
                        'subscription_status': subscription_info.get('status', 'no_subscription'),
                        'user_id': user.id,
                        'user_type': actual_user_type
                    }, 403  # 403 Forbidden - subscription required
            
            print("Login successful, generating tokens...")
            
            # Generate tokens
            access_token, refresh_token, expires_at = generate_tokens(user.id, actual_user_type)
            
            print(f"Tokens generated successfully")
            
            # Store tokens in database
            try:
                AuthToken.query.filter_by(
                    user_id=user.id, 
                    user_type=actual_user_type
                ).delete()
                
                auth_token = AuthToken(
                    user_id=user.id,
                    user_type=actual_user_type,
                    access_token=access_token,
                    refresh_token=refresh_token,
                    expires_at=expires_at
                )
                
                db.session.add(auth_token)
                db.session.commit()
                print("Tokens stored in database")
                
            except Exception as db_error:
                print(f"Database storage failed (non-critical): {db_error}")
                db.session.rollback()
            
            # Create response
            response_data = {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user_id': int(user.id),
                'user_type': str(actual_user_type),
                'expires_in': ACCESS_TOKEN_EXPIRES_HOURS * 3600,
                'expires_at': expires_at.isoformat(),
                'subscription_required': False
            }
            
            # Add subscription info for advertisers
            if actual_user_type == 'advertiser' and subscription_info:
                response_data['subscription_status'] = subscription_info.get('status', 'active')
                response_data['subscription_info'] = subscription_info
                if DEVELOPMENT_MODE:
                    response_data['development_mode'] = True
            
            print(f"Login successful for user {user.id}")
            return response_data
            
        except Exception as e:
            print(f"Exception in login: {type(e).__name__}: {str(e)}")
            import traceback
            traceback.print_exc()
            api.abort(500, f'Login failed: {str(e)}')

@api.route('/register/user')
class UserRegister(Resource):
    @api.expect(user_register_model)
    @api.marshal_with(token_response_model)
    def post(self):
        """Register a new user"""
        try:
            data = request.get_json()
            
            if not data:
                api.abort(400, 'No JSON data provided')
            
            password = data.get('password')
            if not password:
                api.abort(400, 'Password is required')

            if User.find_by_email(data.get('email')):
                api.abort(400, 'User with this email already exists')
            
            required_fields = ['username', 'name', 'email', 'phone_number', 'location', 'gender']
            for field in required_fields:
                if not data.get(field):
                    api.abort(400, f'{field} is required')
            
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
            
            access_token, refresh_token, expires_at = generate_tokens(user.id, 'user')
            
            auth_token = AuthToken(
                user_id=user.id,
                user_type='user',
                access_token=access_token,
                refresh_token=refresh_token,
                expires_at=expires_at
            )

            db.session.add(auth_token)
            db.session.commit()
            
            return {
                'access_token': access_token,
                'refresh_token': refresh_token,
                'user_id': user.id,
                'user_type': 'user',
                'expires_in': ACCESS_TOKEN_EXPIRES_HOURS * 3600,
                'expires_at': expires_at.isoformat(),
                'subscription_required': False
            }, 201
            
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Registration failed: {str(e)}')

@api.route('/register/advertiser')
class AdvertiserRegister(Resource):
    @api.expect(advertiser_register_model)
    def post(self):
        """
        Register a new advertiser
        DEVELOPMENT MODE: Returns tokens immediately for auto-login
        PRODUCTION MODE: Requires subscription payment before login
        """
        try:
            data = request.get_json()
            
            if not data:
                api.abort(400, 'No JSON data provided')
            
            if Advertiser.find_by_email(data.get('email')):
                api.abort(400, 'Advertiser with this email already exists')
            
            required_fields = ['username', 'name', 'email', 'password', 'phone_number', 'location', 'gender']
            for field in required_fields:
                if not data.get(field):
                    api.abort(400, f'{field} is required')
            
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
            
            # DEVELOPMENT MODE: Return tokens for immediate login
            if DEVELOPMENT_MODE:
                print("⚠️  DEVELOPMENT MODE: Auto-generating tokens for advertiser registration")
                
                access_token, refresh_token, expires_at = generate_tokens(advertiser.id, 'advertiser')
                
                auth_token = AuthToken(
                    user_id=advertiser.id,
                    user_type='advertiser',
                    access_token=access_token,
                    refresh_token=refresh_token,
                    expires_at=expires_at
                )
                
                db.session.add(auth_token)
                db.session.commit()
                
                return {
                    'success': True,
                    'message': 'Advertiser account created successfully (Development Mode - No subscription required)',
                    'access_token': access_token,
                    'refresh_token': refresh_token,
                    'user_id': advertiser.id,
                    'user_type': 'advertiser',
                    'expires_in': ACCESS_TOKEN_EXPIRES_HOURS * 3600,
                    'expires_at': expires_at.isoformat(),
                    'subscription_required': False,
                    'development_mode': True,
                    'auto_login': True
                }, 201
            
            # PRODUCTION MODE: Require subscription payment
            return {
                'success': True,
                'message': 'Advertiser account created successfully. Please complete subscription payment to activate your account.',
                'user_id': advertiser.id,
                'user_type': 'advertiser',
                'email': advertiser.email,
                'subscription_required': True,
                'next_step': 'payment'
            }, 201
            
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Registration failed: {str(e)}')

@api.route('/refresh')
class RefreshToken(Resource):
    @api.doc('refresh_token')
    def post(self):
        """Refresh access token using refresh token"""
        try:
            data = request.get_json()
            
            if not data:
                api.abort(400, 'No JSON data provided')
                
            refresh_token = data.get('refresh_token')
            
            if not refresh_token:
                api.abort(400, 'Refresh token is required')
            
            secret_key = os.environ.get('SECRET_KEY', '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3')
            try:
                payload = jwt.decode(refresh_token, secret_key, algorithms=['HS256'])
            except jwt.ExpiredSignatureError:
                api.abort(401, 'Refresh token has expired')
            except jwt.InvalidTokenError:
                api.abort(401, 'Invalid refresh token')
            
            if payload.get('type') != 'refresh':
                api.abort(400, 'Invalid token type')
            
            access_token, _, expires_at = generate_tokens(payload['user_id'], payload['user_type'])
            
            return {
                'access_token': access_token,
                'expires_in': ACCESS_TOKEN_EXPIRES_HOURS * 3600,
                'expires_at': expires_at.isoformat()
            }, 200
            
        except Exception as e:
            api.abort(500, f'Token refresh failed: {str(e)}')

@api.route('/logout')
class Logout(Resource):
    @api.doc('logout')
    def post(self):
        """Logout user and invalidate tokens"""
        try:
            auth_header = request.headers.get('Authorization')
            if not auth_header or not auth_header.startswith('Bearer '):
                api.abort(401, 'Authorization token required')
            
            token = auth_header.split(' ')[1]
            
            try:
                auth_token = AuthToken.query.filter_by(access_token=token).first()
                if auth_token:
                    db.session.delete(auth_token)
                    db.session.commit()
            except Exception as db_error:
                db.session.rollback()
                api.abort(500, f'Database error: {str(db_error)}')
            
            return {'message': 'Successfully logged out'}, 200
            
        except Exception as e:
            api.abort(500, f'Logout failed: {str(e)}')

@api.route('/verify')
class VerifyToken(Resource):
    @api.doc('verify_token')
    def post(self):
        """Verify if a token is valid and get user info"""
        try:
            auth_header = request.headers.get('Authorization')
            if not auth_header or not auth_header.startswith('Bearer '):
                api.abort(401, 'Authorization token required')
            
            token = auth_header.split(' ')[1]
            secret_key = os.environ.get('SECRET_KEY', '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3')
            
            try:
                payload = jwt.decode(token, secret_key, algorithms=['HS256'])
                
                exp_timestamp = payload.get('exp')
                current_timestamp = datetime.utcnow().timestamp()
                
                return {
                    'valid': True,
                    'user_id': payload.get('user_id'),
                    'user_type': payload.get('user_type'),
                    'expires_at': datetime.fromtimestamp(exp_timestamp).isoformat() if exp_timestamp else None,
                    'expires_in_seconds': int(exp_timestamp - current_timestamp) if exp_timestamp else None,
                    'token_type': payload.get('type', 'access')
                }, 200
                
            except jwt.ExpiredSignatureError:
                return {
                    'valid': False,
                    'error': 'Token has expired',
                    'expired': True
                }, 401
            except jwt.InvalidTokenError as e:
                return {
                    'valid': False,
                    'error': f'Invalid token: {str(e)}',
                    'expired': False
                }, 401
                
        except Exception as e:
            api.abort(500, f'Token verification failed: {str(e)}')