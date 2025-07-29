"""
Seed package initialization and runner
"""
import os
import sys
from app import create_app, db

def run_seeds():
    """Run all seed files"""
    app = create_app()
    
    with app.app_context():
        # Drop all tables and recreate them (WARNING: This will delete all data)
        print("Dropping all tables...")
        db.drop_all()
        
        print("Creating all tables...")
        db.create_all()
        
        # Import and run all seeders
        from .user_seeder import seed_users
        from .advertiser_seeder import seed_advertisers
        from .post_seeder import seed_posts
        from .message_seeder import seed_messages
        from .user_block_seeder import seed_user_blocks
        from .comment_seeder import seed_comments
        
        print("Seeding users...")
        seed_users()
        
        print("Seeding advertisers...")
        seed_advertisers()
        
        print("Seeding posts...")
        seed_posts()
        
        print("Seeding messages...")
        seed_messages()
        
        print("Seeding user blocks...")
        seed_user_blocks()
        
        print("Seeding comments...")
        seed_comments()
        
        print("All seeds completed successfully!")

if __name__ == "__main__":
    run_seeds()