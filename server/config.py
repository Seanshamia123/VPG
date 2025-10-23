import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    # Fix: Corrected SECRET_KEY loading
    SECRET_KEY = os.environ.get('SECRET_KEY') or '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3'
    
    # MySQL Configuration
    MYSQL_HOST = os.environ.get('MYSQL_HOST') or 'localhost'
    MYSQL_PORT = int(os.environ.get('MYSQL_PORT', 3306))
    MYSQL_USER = os.environ.get('MYSQL_USER') or 'sophie'
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD') or 'Smm_smm_m8'
    MYSQL_DB = os.environ.get('MYSQL_DB') or 'VPG'

    CLOUDINARY_CLOUD_NAME = os.environ.get('CLOUDINARY_CLOUD_NAME') or 'dtbmivwxd'
    CLOUDINARY_API_KEY = os.environ.get('CLOUDINARY_API_KEY') or '398774447228892'
    CLOUDINARY_API_SECRET = os.environ.get('CLOUDINARY_API_SECRET') or 'WBDJI-xZEAUZ6eU4z3_EPWpvlXA'
    CLOUDINARY_UPLOAD_PRESET = os.environ.get('CLOUDINARY_UPLOAD_PRESET', 'VPG_UPLOADS')

    # IntaSend Configuration - Now properly loaded
    INTASEND_PUBLISHABLE_KEY='ISPubKey_live_04dfded5-c7c9-4260-a39b-da627003665f'
    INTASEND_SECRET_KEY ='ISSecretKey_live_ef0d34b2-b6e9-4801-80e7-dbce8cc93a79'
    INTASEND_IS_TEST = os.environ.get('INTASEND_IS_TEST', 'False').lower() == 'true'
    
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

# Debug helper - Add this at the bottom to verify keys are loaded
if __name__ == '__main__':
    print("=== Configuration Debug ===")
    print(f"INTASEND_PUBLISHABLE_KEY: {Config.INTASEND_PUBLISHABLE_KEY[:20]}..." if Config.INTASEND_PUBLISHABLE_KEY else "INTASEND_PUBLISHABLE_KEY: None")
    print(f"INTASEND_SECRET_KEY: {Config.INTASEND_SECRET_KEY[:20]}..." if Config.INTASEND_SECRET_KEY else "INTASEND_SECRET_KEY: None")
    print(f"INTASEND_IS_TEST: {Config.INTASEND_IS_TEST}")
    print(f"BASE_URL: {Config.BASE_URL}")