#!/usr/bin/env python3
"""
Main seed runner for the Flask application
Run this file to seed all tables with sample data

Usage:
    python seed.py                    # Seed all tables
    python seed.py --drop             # Drop all tables and recreate with seed data
    python seed.py --specific users   # Seed only specific table
    python seed.py --help             # Show help message
"""

import sys
import os
import argparse
from datetime import datetime

# Add the project root to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app, db

def print_banner():
    """Print application banner"""
    print("=" * 60)
    print("🌱 SOCIAL MEDIA APP DATABASE SEEDER")
    print("=" * 60)
    print(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

def print_completion():
    """Print completion message"""
    print("=" * 60)
    print("✅ DATABASE SEEDING COMPLETED SUCCESSFULLY!")
    print(f"Finished at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

def confirm_action(message):
    """Ask for user confirmation"""
    response = input(f"{message} (y/N): ").lower().strip()
    return response in ['y', 'yes']

def drop_and_create_tables():
    """Drop all tables and recreate them"""
    print("⚠️  WARNING: This will delete ALL existing data!")
    
    if not confirm_action("Are you sure you want to drop all tables?"):
        print("Operation cancelled.")
        return False
    
    print("🗑️  Dropping all tables...")
    db.drop_all()
    
    print("🏗️  Creating all tables...")
    db.create_all()
    
    print("✅ Database schema recreated successfully!")
    return True

def seed_users():
    """Seed users table"""
    print("👥 Seeding users...")
    try:
        from seeds.user_seeder import seed_users
        seed_users()
        print("✅ Users seeded successfully!")
        return True
    except Exception as e:
        print(f"❌ Error seeding users: {e}")
        return False

def seed_advertisers():
    """Seed advertisers table"""
    print("📢 Seeding advertisers...")
    try:
        from seeds.advertiser_seeder import seed_advertisers
        seed_advertisers()
        print("✅ Advertisers seeded successfully!")
        return True
    except Exception as e:
        print(f"❌ Error seeding advertisers: {e}")
        return False

def seed_posts():
    """Seed posts table"""
    print("📝 Seeding posts...")
    try:
        from seeds.post_seeder import seed_posts
        seed_posts()
        print("✅ Posts seeded successfully!")
        return True
    except Exception as e:
        print(f"❌ Error seeding posts: {e}")
        return False

def seed_messages():
    """Seed messages table"""
    print("💬 Seeding messages...")
    try:
        from seeds.message_seeder import seed_messages
        seed_messages()
        print("✅ Messages seeded successfully!")
        return True
    except Exception as e:
        print(f"❌ Error seeding messages: {e}")
        return False

def seed_user_blocks():
    """Seed user blocks table"""
    print("🚫 Seeding user blocks...")
    try:
        from seeds.user_block_seeder import seed_user_blocks
        seed_user_blocks()
        print("✅ User blocks seeded successfully!")
        return True
    except Exception as e:
        print(f"❌ Error seeding user blocks: {e}")
        return False

def seed_comments():
    """Seed comments table"""
    print("💭 Seeding comments...")
    try:
        from seeds.comment_seeder import seed_comments
        seed_comments()
        print("✅ Comments seeded successfully!")
        return True
    except Exception as e:
        print(f"❌ Error seeding comments: {e}")
        return False

def get_table_counts():
    """Get count of records in each table"""
    try:
        from models.user import User
        from models.advertiser import Advertiser
        from models.posts import Post
        from models.message import Message
        from models.userblock import UserBlock
        
        counts = {
            'Users': User.query.count(),
            'Advertisers': Advertiser.query.count(),
            'Posts': Post.query.count(),
            'Messages': Message.query.count(),
            'User Blocks': UserBlock.query.count(),
        }
        
        # Try to get comments count if model exists
        try:
            from models.comment import Comment
            counts['Comments'] = Comment.query.count()
        except ImportError:
            counts['Comments'] = 'N/A (Model not found)'
        
        return counts
    except Exception as e:
        print(f"Warning: Could not get table counts: {e}")
        return {}

def print_table_summary():
    """Print summary of seeded data"""
    print("\n📊 DATABASE SUMMARY:")
    print("-" * 30)
    
    counts = get_table_counts()
    for table, count in counts.items():
        print(f"{table:<15}: {count}")
    
    print("-" * 30)

def seed_all_tables(drop_first=False):
    """Seed all tables with sample data"""
    success = True
    
    if drop_first:
        if not drop_and_create_tables():
            return False
        print()
    
    # Seed in order of dependencies
    seeders = [
        ("users", seed_users),
        ("advertisers", seed_advertisers),
        ("posts", seed_posts),
        ("messages", seed_messages),
        ("user_blocks", seed_user_blocks),
        ("comments", seed_comments),
    ]
    
    for name, seeder_func in seeders:
        if not seeder_func():
            success = False
            break
        print()  # Add spacing between seeders
    
    return success

def seed_specific_table(table_name):
    """Seed a specific table"""
    seeders = {
        'users': seed_users,
        'advertisers': seed_advertisers,
        'posts': seed_posts,
        'messages': seed_messages,
        'user_blocks': seed_user_blocks,
        'blocks': seed_user_blocks,  # Alias
        'comments': seed_comments,
    }
    
    if table_name.lower() not in seeders:
        print(f"❌ Unknown table: {table_name}")
        print(f"Available tables: {', '.join(seeders.keys())}")
        return False
    
    print(f"🌱 Seeding {table_name} table only...")
    return seeders[table_name.lower()]()

def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Seed the database with sample data',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python seed.py                    # Seed all tables
  python seed.py --drop             # Drop all tables and recreate with seed data
  python seed.py --specific users   # Seed only users table
  python seed.py --summary          # Show current table counts
        """
    )
    
    parser.add_argument(
        '--drop',
        action='store_true',
        help='Drop all tables before seeding (WARNING: Deletes all data)'
    )
    
    parser.add_argument(
        '--specific',
        type=str,
        help='Seed only a specific table (users, advertisers, posts, messages, user_blocks, comments)'
    )
    
    parser.add_argument(
        '--summary',
        action='store_true',
        help='Show summary of current table counts'
    )
    
    args = parser.parse_args()
    
    # Create Flask app context
    app = create_app()
    
    with app.app_context():
        print_banner()
        
        # Show summary only
        if args.summary:
            print_table_summary()
            return
        
        success = True
        
        # Seed specific table
        if args.specific:
            success = seed_specific_table(args.specific)
        
        # Seed all tables
        else:
            success = seed_all_tables(drop_first=args.drop)
        
        if success:
            print_table_summary()
            print_completion()
        else:
            print("\n❌ SEEDING FAILED!")
            print("Please check the error messages above.")
            sys.exit(1)

if __name__ == "__main__":
    main()