from .seed_users import seed_users
from .seed_advertisers import seed_advertisers
from .messages_seeder import seed_messages
from .conversation_seeder import seed_conversations
# Add other seed imports as needed
from .seed_posts import seed_posts
# from .seed_user_blocks import seed_user_blocks

def seed_all():
    """Runs all seed functions in the correct order."""
    print("Starting database seeding...")
    
    # Seed in dependency order
    seed_users()
    seed_advertisers()
    seed_conversations()
    seed_posts()
    seed_messages()
    # seed_user_blocks()

    print("Database seeding completed!")