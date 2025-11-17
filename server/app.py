# ============================================
# app.py - UPDATED with JWT Support
# ============================================

from flask import Flask, jsonify, send_from_directory
from flask_restful import Api
from flasgger import Swagger
import os
from flask_restx import Api as RestxApi
from database import db, migrate
from dotenv import load_dotenv
from flask_cors import CORS
from flask_socketio import SocketIO, join_room, leave_room, emit
from flask_jwt_extended import JWTManager
from datetime import timedelta
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_app(config_name=None):
    
    app = Flask(__name__)
    
    # Load environment variables
    load_dotenv()
    
    # ========== BASIC CONFIG ==========
    app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER', 'smtp.gmail.com')
    app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT', 587))
    app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS', 'true').lower() == 'true'
    app.config['MAIL_USERNAME'] = os.environ.get('MAIL_USERNAME')
    app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD')
    app.config['MAIL_DEFAULT_SENDER'] = os.environ.get('MAIL_DEFAULT_SENDER', 'noreply@vpg.com')

    # Development CORS: allow local and emulator/web origins
    CORS(app, resources={r"/*": {"origins": "*"}})

    # ========== DATABASE CONFIG ==========
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
    app.config['SQLALCHEMY_DATABASE_URI'] = (
        os.environ.get('DATABASE_URL')
        or f"mysql+pymysql://{os.environ.get('MYSQL_USER')}:{os.environ.get('MYSQL_PASSWORD', 'your_password')}@"
           f"{os.environ.get('MYSQL_HOST', 'localhost')}:{os.environ.get('MYSQL_PORT', '3306')}/"
           f"{os.environ.get('MYSQL_DB', 'flutter_app_db')}"
    )
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
        'pool_timeout': 20,
        'max_overflow': 0
    }
    
    # ========== JWT CONFIG ==========
    app.config['JWT_SECRET_KEY'] = os.environ.get('JWT_SECRET_KEY', app.config['SECRET_KEY'])
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)
    app.config['JWT_REFRESH_TOKEN_EXPIRES'] = timedelta(days=30)
    app.config['JWT_TOKEN_LOCATION'] = ['headers']
    app.config['JWT_HEADER_NAME'] = 'Authorization'
    app.config['JWT_HEADER_TYPE'] = 'Bearer'
    
    logger.info("✓ JWT Configuration loaded")
    logger.info(f"  - JWT Secret Key: {app.config['JWT_SECRET_KEY'][:20]}...")
    logger.info(f"  - Access Token Expires: {app.config['JWT_ACCESS_TOKEN_EXPIRES']}")
    logger.info(f"  - Refresh Token Expires: {app.config['JWT_REFRESH_TOKEN_EXPIRES']}")
    
    # ========== FILE UPLOAD CONFIG ==========
    app.config['UPLOAD_FOLDER'] = os.path.join(os.getcwd(), 'uploads')
    app.config['MAX_CONTENT_LENGTH'] = 100 * 1024 * 1024  # 100MB max file size
    
    # ========== CLOUDINARY CONFIG ==========
    app.config['CLOUDINARY_CLOUD_NAME'] = os.environ.get('CLOUDINARY_CLOUD_NAME')
    app.config['CLOUDINARY_API_KEY'] = os.environ.get('CLOUDINARY_API_KEY')
    app.config['CLOUDINARY_API_SECRET'] = os.environ.get('CLOUDINARY_API_SECRET')
    app.config['CLOUDINARY_UPLOAD_PRESET'] = os.environ.get('CLOUDINARY_UPLOAD_PRESET')
    
    # ========== PAYMENT PROVIDER CONFIG ==========
    app.config['INTASEND_PUBLISHABLE_KEY'] = os.environ.get('INTASEND_PUBLISHABLE_KEY')
    app.config['INTASEND_SECRET_KEY'] = os.environ.get('INTASEND_SECRET_KEY')
    app.config['INTASEND_IS_TEST'] = os.environ.get('INTASEND_IS_TEST', 'False').lower() == 'true'
    app.config['PAYSTACK_SECRET_KEY'] = os.environ.get('PAYSTACK_SECRET_KEY', '')
    app.config['PAYSTACK_PUBLIC_KEY'] = os.environ.get('PAYSTACK_PUBLIC_KEY', '')
    app.config['PAYSTACK_IS_TEST'] = os.environ.get('PAYSTACK_IS_TEST', 'True').lower() == 'true'
    app.config['BASE_URL'] = os.environ.get('BASE_URL', 'https://vpg-9wlv.onrender.com')
        
    # ========== SWAGGER CONFIG ==========
    swagger_config = {
        "headers": [],
        "specs": [
            {
                "endpoint": 'apispec',
                "route": '/apispec.json',
                "rule_filter": lambda rule: True,
                "model_filter": lambda tag: True,
            }
        ],
        "static_url_path": "/flasgger_static",
        "swagger_ui": True,
        "specs_route": "/swagger/"
    }
    
    swagger_template = {
        "swagger": "2.0",
        "info": {
            "title": "VPG API",
            "description": "API for VPG",
            "version": "1.0.0"
        },
        "consumes": ["application/json"],
        "produces": ["application/json"],
    }
    
    # ========== INITIALIZE EXTENSIONS ==========
    db.init_app(app)
    migrate.init_app(app, db)
    swagger = Swagger(app, config=swagger_config, template=swagger_template)
    
    # Initialize Flask-RESTx API
    api = RestxApi(app)
    
    # Initialize JWT Manager - CRITICAL FOR PAYMENT VERIFICATION
    try:
        jwt = JWTManager(app)
        logger.info("✓ JWT Manager initialized successfully")
        
        # JWT Error Handlers
        @jwt.expired_token_loader
        def expired_token_callback(jwt_header, jwt_data):
            logger.warning(f"JWT token expired for user: {jwt_data.get('sub')}")
            return {
                'error': 'Token expired',
                'message': 'Please refresh your token or login again'
            }, 401
        
        @jwt.invalid_token_loader
        def invalid_token_callback(error):
            logger.warning(f"Invalid JWT token: {error}")
            return {
                'error': 'Invalid token',
                'message': 'Token is malformed or invalid'
            }, 401
        
        @jwt.unauthorized_loader
        def missing_token_callback(error):
            logger.warning(f"Missing JWT token: {error}")
            return {
                'error': 'Missing authorization',
                'message': 'Request does not include an access token'
            }, 401
        
        @jwt.user_lookup_loader
        def user_lookup_callback(_jwt_header, jwt_data):
            from models import Advertiser, User
            identity = jwt_data["sub"]
            return Advertiser.query.get(identity) or User.query.get(identity)
        
    except Exception as e:
        logger.error(f"❌ Failed to initialize JWT: {e}")
        raise
    
    # Initialize Socket.IO
    socketio = SocketIO(cors_allowed_origins='*')
    socketio.init_app(app, cors_allowed_origins='*')
    app.extensions['socketio'] = socketio

    # ========== IMPORT MODELS ==========
    with app.app_context():
        try:
            from models.advertiser import Advertiser
            from models.commentlike import CommentLike
            from models.message import Message
            from models.subsricption import Subscription
            from models.userblock import UserBlock
            from models.user_settings import UserSetting
            from models.user import User
            logger.info("✓ All models imported successfully")
        except Exception as e:
            logger.error(f"❌ Error importing models: {e}")
            raise
        
        # Initialize Cloudinary service
        try:
            from cloudinary_service import cloudinary_service
            cloudinary_service.init_app(app)
            logger.info("✓ Cloudinary service initialized")
        except Exception as e:
            logger.warning(f"⚠ Warning initializing Cloudinary: {e}")

    # ========== REGISTER API NAMESPACES ==========
    try:
        from apis.users import api as users_ns
        from apis.advertiser_api import api as advertiser_ns
        from apis.message_api import api as message_ns
        from apis.user_settings import api as user_settings_ns
        from apis.posts import api as posts_ns
        from apis.comments import api as comments_ns
        from apis.auth import api as auth_ns
        from apis.subscriptions import api as subs_ns
        from apis.payments import api as payments_ns
        from apis.conversations import api as conversations_ns

        api.add_namespace(users_ns, path='/api/users')
        api.add_namespace(advertiser_ns, path='/api/advertisers')
        api.add_namespace(message_ns, path='/api/messages')
        api.add_namespace(conversations_ns, path='/api/conversations')
        api.add_namespace(posts_ns, path='/api/posts')
        api.add_namespace(user_settings_ns, path='/api/user-settings')
        api.add_namespace(comments_ns, path='/api/comments')
        api.add_namespace(auth_ns, path='/auth')
        api.add_namespace(subs_ns, path='/api/subscriptions')
        api.add_namespace(payments_ns, path='/api/payment')
        
        logger.info("✓ All API namespaces registered")
    except Exception as e:
        logger.error(f"❌ Error registering API namespaces: {e}")
        raise

    # ========== INITIALIZE SERVICES ==========
    try:
        from services.email_service import email_service
        email_service.init_app(app)
        logger.info("✓ Email service initialized")
    except Exception as e:
        logger.warning(f"⚠ Warning initializing email service: {e}")
    
    try:
        from tasks.subscription_reminders import init_scheduler
        scheduler = init_scheduler(app)
        app.extensions['scheduler'] = scheduler
        logger.info("✓ Subscription scheduler initialized")
    except Exception as e:
        logger.warning(f"⚠ Warning initializing scheduler: {e}")

    # ========== MEDIA FILE SERVING ==========
    @app.route('/media/<category>/<filename>')
    def serve_media(category, filename):
        """Serve media files (images, videos, audio) from uploads directory"""
        try:
            media_path = os.path.join(app.config['UPLOAD_FOLDER'], category)
            return send_from_directory(media_path, filename, as_attachment=False)
        except FileNotFoundError:
            return {'error': 'File not found'}, 404
        except Exception as e:
            logger.error(f'Error serving media: {e}')
            return {'error': 'Error retrieving file'}, 500

    @app.route('/media/thumbnails/<filename>')
    def serve_thumbnail(filename):
        """Serve thumbnail files from uploads directory"""
        try:
            thumbnail_path = os.path.join(app.config['UPLOAD_FOLDER'], 'thumbnails')
            return send_from_directory(thumbnail_path, filename, as_attachment=False)
        except FileNotFoundError:
            return {'error': 'Thumbnail not found'}, 404
        except Exception as e:
            logger.error(f'Error serving thumbnail: {e}')
            return {'error': 'Error retrieving thumbnail'}, 500

    # ========== HEALTH CHECK ==========
    @app.route('/health')
    def health():
        """Health check endpoint"""
        return jsonify({
            "status": "ok",
            "jwt_enabled": True,
            "database": "connected"
        }), 200

    # ========== SOCKET.IO EVENTS ==========
    @socketio.on('join_conversation')
    def on_join(data):
        try:
            conv_id = data.get('conversation_id')
            if conv_id:
                join_room(f"conv_{conv_id}")
                emit('joined', {'room': f"conv_{conv_id}"})
        except Exception as e:
            logger.error(f"Error in join_conversation: {e}")

    @socketio.on('leave_conversation')
    def on_leave(data):
        try:
            conv_id = data.get('conversation_id')
            if conv_id:
                leave_room(f"conv_{conv_id}")
        except Exception as e:
            logger.error(f"Error in leave_conversation: {e}")

    return app


if __name__ == '__main__':
    app = create_app()
    
    with app.app_context():
        logger.info("=" * 50)
        logger.info("INITIALIZING APPLICATION")
        logger.info("=" * 50)
        
        try:
            # Initialize Cloudinary service within app context
            from cloudinary_service import cloudinary_service
            cloudinary_service.init_app(app)
            logger.info("✓ Cloudinary initialized")
        except Exception as e:
            logger.warning(f"⚠ Cloudinary initialization warning: {e}")
        
        try:
            db.create_all()
            logger.info("✓ Database tables created")
        except Exception as e:
            logger.error(f"❌ Error creating database tables: {e}")
        
        # Create upload directories
        try:
            upload_folder = app.config['UPLOAD_FOLDER']
            os.makedirs(os.path.join(upload_folder, 'image'), exist_ok=True)
            os.makedirs(os.path.join(upload_folder, 'video'), exist_ok=True)
            os.makedirs(os.path.join(upload_folder, 'audio'), exist_ok=True)
            os.makedirs(os.path.join(upload_folder, 'thumbnails'), exist_ok=True)
            logger.info("✓ Upload directories created")
        except Exception as e:
            logger.error(f"❌ Error creating upload directories: {e}")
        
        logger.info("=" * 50)
        logger.info("APPLICATION READY")
        logger.info("=" * 50)
        logger.info(f"Base URL: {app.config['BASE_URL']}")
        logger.info(f"Debug Mode: {app.debug}")
    
    # Run through SocketIO to enable websockets
    app.extensions['socketio'].run(app, debug=True, host='0.0.0.0', port=5002)

