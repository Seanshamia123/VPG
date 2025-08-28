from .seed_users import seed_users
from .seed_advertisers import seed_advertisers
from .messages_seeder import seed_messages
from .conversation_seeder import seed_conversations
from .seed_user_settings import seed_user_settings
# Add other seed imports as needed
# from .seed_posts import seed_posts
# from .seed_user_blocks import seed_user_blocks

def seed_all():
    """Runs all seed functions in the correct order."""
    print("Starting database seeding...")
    
    # Seed in dependency order
    seed_user_settings()
    seed_users()
    seed_advertisers()
    seed_conversations()
    seed_messages()

    #seed_posts() Images are saved in  third party service in the cloud saed as actually as images then converted to a URL 
    # seed_user_blocks()

    print("Database seeding completed!")