from flask import Flask
from flask_restful import Api
from flasgger import Swagger
import os
import sys
from flask_restx import Api
from database import db, migrate
from dotenv import load_dotenv

load_dotenv()

def create_app(config_name=None):
    app = Flask(__name__)
    
    # Configuration
    app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL') or \
        f"mysql+pymysql://{os.environ.get('MYSQL_USER')}:{os.environ.get('MYSQL_PASSWORD', 'your_password')}@{os.environ.get('MYSQL_HOST', 'localhost')}:{os.environ.get('MYSQL_PORT', '3306')}/{os.environ.get('MYSQL_DB', 'flutter_app_db')}"
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
        'pool_timeout': 20,
        'max_overflow': 0
    }
        
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
            "title": "Social Media API",
            "description": "API for social media application",
            "version": "1.0.0"
        },
        "consumes": [
            "application/json",
        ],
        "produces": [
            "application/json",
        ],
    }
    
    # Initialize extensions with app
    db.init_app(app)
    migrate.init_app(app, db)
    swagger = Swagger(app, config=swagger_config, template=swagger_template)
    
    # Initialize API
    api = Api(app)
    
    # Import models within app context
    with app.app_context():
        from models.advertiser import Advertiser
        from models.commentlike import CommentLike
        from models.message import Message
        from models.subsricption import Subscription  # Fixed typo from 'subsricption'
        from models.userblock import UserBlock
        from models.user_settings import UserSetting
        from models.user import User

        # Debug: Print detected models (remove this after confirming it works)
        print("Detected models:")
        for table_name in db.metadata.tables:
            print(f"  - {table_name}")

    # Import and register API resources
    from apis.users import api as users_ns
    
    # Uncomment these as you implement the corresponding APIs
    from apis.advertiser_api import api as advertiser_ns
    # from apis.message_api import api as message_ns
    # from apis.subscription_api import api as subscription_ns
    # from apis.user_block_api import api as user_block_ns
    # from apis.user_settings_api import api as user_settings_ns
    # from apis.comment_like_api import api as comment_like_ns
    
    # Register API routes
    api.add_namespace(users_ns, path='/api/users')
    
    # Uncomment these as you implement the corresponding APIs
    api.add_namespace(advertiser_ns, path='/api/advertisers')
    # api.add_namespace(message_ns, path='/api/messages')
    # api.add_namespace(subscription_ns, path='/api/subscriptions')
    # api.add_namespace(user_block_ns, path='/api/user-blocks')
    # api.add_namespace(user_settings_ns, path='/api/user-settings')
    # api.add_namespace(comment_like_ns, path='/api/comment-likes')
    
    return app

if __name__ == '__main__':
    app = create_app()
    with app.app_context():
        db.create_all()
    app.run(debug=True, port=5002)