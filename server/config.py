import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3') or 'dev-secret-key'
    
    # MySQL Configuration
    MYSQL_HOST = os.environ.get('MYSQL_HOST') or 'localhost'
    MYSQL_PORT = int(os.environ.get('MYSQL_PORT', 3306))
    MYSQL_USER = os.environ.get('MYSQL_USER') or 'sean'
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD') or '12345'
    MYSQL_DB = os.environ.get('MYSQL_DB') or 'VPG'

    CLOUDINARY_CLOUD_NAME = os.environ.get('CLOUDINARY_CLOUD_NAME') or 'VPG_UPLOADS'
    CLOUDINARY_API_KEY = os.environ.get('CLOUDINARY_API_KEY') or '398774447228892'
    CLOUDINARY_API_SECRET = os.environ.get('CLOUDINARY_API_SECRET') or 'WBDJI-xZEAUZ6eU4z3_EPWpvlXA'
    CLOUDINARY_UPLOAD_PRESET = os.environ.get('CLOUDINARY_UPLOAD_PRESET', 'VPG_UPLOADS')

    INTASEND_PUBLISHABLE_KEY = os.environ.get('INTASEND_PUBLISHABLE_KEY')
    INTASEND_SECRET_KEY = os.environ.get('INTASEND_SECRET_KEY')
    INTASEND_IS_TEST = os.environ.get('INTASEND_IS_TEST', 'True').lower() == 'true'
    
    # Base URL for your application (for webhooks)
    BASE_URL = os.environ.get('BASE_URL', 'http://127.0.0.1:5000')


    # Construct DATABASE_URL for MySQL
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        f'mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}'
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
        'pool_timeout': 20,
        'max_overflow': 0
    }
    JSON_SORT_KEYS = False

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False
    # Add SSL for production
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
        'pool_timeout': 20,
        'max_overflow': 0,
        'connect_args': {'ssl_disabled': False}
    }

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}