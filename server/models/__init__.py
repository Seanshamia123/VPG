from flask_sqlalchemy import SQLAlchemy

# Initialize SQLAlchemy
db = SQLAlchemy()

# Import all models here
from .user import User
from .advertiser import Advertiser

# Make them available when importing from models
__all__ = ['db', 'User', 'Advertiser']