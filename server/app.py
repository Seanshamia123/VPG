from flask import Flask, jsonify
from flask_restful import Api
from flasgger import Swagger
import os
from flask_restx import Api as RestxApi
from database import db, migrate
from dotenv import load_dotenv
from flask_cors import CORS
from flask_socketio import SocketIO, join_room, leave_room, emit

def create_app(config_name=None):
    app = Flask(__name__)

    # Development CORS: allow local and emulator/web origins
    CORS(app, resources={r"/*": {"origins": "*"}})

    
    # Configuration
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
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
    
    # Cloudinary configuration
    app.config['CLOUDINARY_CLOUD_NAME'] = os.environ.get('CLOUDINARY_CLOUD_NAME')
    app.config['CLOUDINARY_API_KEY'] = os.environ.get('CLOUDINARY_API_KEY')
    app.config['CLOUDINARY_API_SECRET'] = os.environ.get('CLOUDINARY_API_SECRET')
    app.config['CLOUDINARY_UPLOAD_PRESET'] = os.environ.get('CLOUDINARY_UPLOAD_PRESET')
        
    # Swagger configuration
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
    
    # Initialize extensions
    db.init_app(app)
    migrate.init_app(app, db)
    swagger = Swagger(app, config=swagger_config, template=swagger_template)
    
    api = RestxApi(app)
    # Initialize Socket.IO and store on app extensions
    socketio = SocketIO(cors_allowed_origins='*')
    socketio.init_app(app, cors_allowed_origins='*')
    app.extensions['socketio'] = socketio

    # Import models inside app context
    with app.app_context():
        from models.advertiser import Advertiser
        from models.commentlike import CommentLike
        from models.message import Message
        from models.subsricption import Subscription
        from models.userblock import UserBlock
        from models.user_settings import UserSetting
        from models.user import User
        
        # Initialize Cloudinary service
        from server.cloudinary_service import cloudinary_service
        cloudinary_service.init_app(app)

    # Import and register APIs AFTER app is created
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
    # from apis.user_block_api import api as user

    # Register routes
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

    

    # Simple health endpoint for frontend connectivity checks
    @app.route('/health')
    def health():
        return jsonify({"status": "ok"}), 200

    # Basic Socket.IO events
    @socketio.on('join_conversation')
    def on_join(data):
        try:
            conv_id = data.get('conversation_id')
            if conv_id:
                join_room(f"conv_{conv_id}")
                emit('joined', {'room': f"conv_{conv_id}"})
        except Exception:
            pass

    @socketio.on('leave_conversation')
    def on_leave(data):
        try:
            conv_id = data.get('conversation_id')
            if conv_id:
                leave_room(f"conv_{conv_id}")
        except Exception:
            pass

    return app

if __name__ == '__main__':
    app = create_app()
    with app.app_context():
        # Initialize Cloudinary service within app context
        from server.cloudinary_service import cloudinary_service
        cloudinary_service.init_app(app)
        db.create_all()
    # Run through SocketIO to enable websockets
    app.extensions['socketio'].run(app, debug=True, port=5002)
