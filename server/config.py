
# ============================================
# config.py - UPDATED with JWT Support
# ============================================

import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Base configuration"""
    
    # ========== SECRET KEYS ==========
    SECRET_KEY = os.environ.get('SECRET_KEY') or '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3'
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or os.environ.get('SECRET_KEY') or 'jwt-secret-key-change-in-production'
    
    # ========== JWT CONFIGURATION ==========
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    JWT_TOKEN_LOCATION = ['headers']
    JWT_HEADER_NAME = 'Authorization'
    JWT_HEADER_TYPE = 'Bearer'
    
    # ========== MYSQL CONFIGURATION ==========
    MYSQL_HOST = os.environ.get('MYSQL_HOST') or 'localhost'
    MYSQL_PORT = int(os.environ.get('MYSQL_PORT', 3306))
    MYSQL_USER = os.environ.get('MYSQL_USER') or 'sophie'
    MYSQL_PASSWORD = os.environ.get('MYSQL_PASSWORD') or 'Smm_smm_m8'
    MYSQL_DB = os.environ.get('MYSQL_DB') or 'VPG'

    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
        f'mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}'
    
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
        'pool_timeout': 20,
        'max_overflow': 0
    }
    
    # ========== CLOUDINARY CONFIGURATION ==========
    CLOUDINARY_CLOUD_NAME = os.environ.get('CLOUDINARY_CLOUD_NAME') or 'dtbmivwxd'
    CLOUDINARY_API_KEY = os.environ.get('CLOUDINARY_API_KEY') or '398774447228892'
    CLOUDINARY_API_SECRET = os.environ.get('CLOUDINARY_API_SECRET') or 'WBDJI-xZEAUZ6eU4z3_EPWpvlXA'
    CLOUDINARY_UPLOAD_PRESET = os.environ.get('CLOUDINARY_UPLOAD_PRESET', 'VPG_UPLOADS')

    # ========== INTASEND CONFIGURATION ==========
    INTASEND_PUBLISHABLE_KEY = os.environ.get('INTASEND_PUBLISHABLE_KEY') or 'ISPubKey_live_04dfded5-c7c9-4260-a39b-da627003665f'
    INTASEND_SECRET_KEY = os.environ.get('INTASEND_SECRET_KEY') or 'ISSecretKey_live_ef0d34b2-b6e9-4801-80e7-dbce8cc93a79'
    INTASEND_IS_TEST = os.environ.get('INTASEND_IS_TEST', 'False').lower() == 'true'
    
    # ========== PAYSTACK CONFIGURATION ==========
    PAYSTACK_SECRET_KEY = os.environ.get('PAYSTACK_SECRET_KEY', '')
    PAYSTACK_PUBLIC_KEY = os.environ.get('PAYSTACK_PUBLIC_KEY', '')
    PAYSTACK_IS_TEST = os.environ.get('PAYSTACK_IS_TEST', 'True').lower() == 'true'
    
    # ========== BASE URL FOR WEBHOOKS ==========
    BASE_URL = os.environ.get('BASE_URL', 'http://127.0.0.1:5000')
    
    # ========== JSON CONFIGURATION ==========
    JSON_SORT_KEYS = False

class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False

class TestingConfig(Config):
    """Testing configuration"""
    DEBUG = True
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'

class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    # Add SSL for production
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_pre_ping': True,
        'pool_recycle': 300,
        'pool_timeout': 20,
        'max_overflow': 0,
        'connect_args': {'ssl': True}
    }

config = {
    'development': DevelopmentConfig,
    'testing': TestingConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}

# Debug helper - Print configuration on import
if __name__ == '__main__':
    print("=" * 60)
    print("CONFIGURATION DEBUG")
    print("=" * 60)
    print(f"✓ SECRET_KEY: {Config.SECRET_KEY[:20]}...")
    print(f"✓ JWT_SECRET_KEY: {Config.JWT_SECRET_KEY[:20]}...")
    print(f"✓ JWT_ACCESS_TOKEN_EXPIRES: {Config.JWT_ACCESS_TOKEN_EXPIRES}")
    print(f"✓ JWT_REFRESH_TOKEN_EXPIRES: {Config.JWT_REFRESH_TOKEN_EXPIRES}")
    print(f"✓ Database URI: {Config.SQLALCHEMY_DATABASE_URI[:40]}...")
    print(f"✓ INTASEND_PUBLISHABLE_KEY: {Config.INTASEND_PUBLISHABLE_KEY[:20]}..." if Config.INTASEND_PUBLISHABLE_KEY else "✗ INTASEND_PUBLISHABLE_KEY: Not set")
    print(f"✓ INTASEND_SECRET_KEY: {Config.INTASEND_SECRET_KEY[:20]}..." if Config.INTASEND_SECRET_KEY else "✗ INTASEND_SECRET_KEY: Not set")
    print(f"✓ INTASEND_IS_TEST: {Config.INTASEND_IS_TEST}")
    print(f"✓ BASE_URL: {Config.BASE_URL}")
    print("=" * 60)