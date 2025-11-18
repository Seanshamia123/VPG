# ============================================
# render_init_db.py
# ============================================
# Run database initialization before app starts
# This handles table creation automatically on Render

import os
import sys
import logging
from dotenv import load_dotenv

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def init_database():
    """Initialize database - create tables if they don't exist"""
    try:
        load_dotenv()
        
        # Import Flask app
        from app import create_app
        from database import db
        
        logger.info("=" * 60)
        logger.info("INITIALIZING DATABASE ON RENDER")
        logger.info("=" * 60)
        
        # Create app context
        app = create_app()
        
        with app.app_context():
            try:
                # Import ALL models to register them with SQLAlchemy
                logger.info("Importing all models...")
                from models.user import User
                from models.advertiser import Advertiser
                from models.message import Message
                from models.commentlike import CommentLike
                from models.subsricption import Subscription
                from models.userblock import UserBlock
                from models.user_settings import UserSetting
                logger.info("✓ All models imported")
                
                # Check database connection
                logger.info("Testing database connection...")
                db.session.execute('SELECT 1')
                logger.info("✓ Database connection successful")
                
                # Create all tables
                logger.info("Creating database tables...")
                db.create_all()
                logger.info("✓ Database tables created successfully")
                
                logger.info("=" * 60)
                logger.info("DATABASE INITIALIZATION COMPLETE")
                logger.info("=" * 60)
                
                return True
                
            except Exception as e:
                logger.error(f"✗ Error during database initialization: {e}")
                logger.error(f"Error type: {type(e).__name__}")
                import traceback
                logger.error(traceback.format_exc())
                return False
                
    except Exception as e:
        logger.error(f"✗ Failed to initialize database: {e}")
        import traceback
        logger.error(traceback.format_exc())
        return False


if __name__ == '__main__':
    success = init_database()
    sys.exit(0 if success else 1)