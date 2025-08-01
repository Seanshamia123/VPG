from .seed_users import seed_users
from .seed_advertisers import seed_advertisers
# Add other seed imports as needed
from .seed_posts import seed_posts
# from .seed_user_blocks import seed_user_blocks

def seed_all():
    """Runs all seed functions in the correct order."""
    print("Starting database seeding...")
    
    # Seed in dependency order
    seed_users()
    seed_advertisers()
    # Add other seed functions as needed
    seed_posts()
    # seed_user_blocks()
    
    print("Database seeding completed!")