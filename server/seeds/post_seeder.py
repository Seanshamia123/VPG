"""
Post seeder for populating the posts table
"""
import random
from faker import Faker
from models.user import User
from models.posts import Post
from app import db

fake = Faker()

def seed_posts():
    """Seed posts table with sample data"""
    
    # Get all users
    users = User.query.all()
    if not users:
        print("No users found. Please seed users first.")
        return
    
    # Sample captions for social media posts
    sample_captions = [
        "Beautiful sunset today! 🌅 #sunset #nature #photography",
        "Just finished an amazing workout! 💪 #fitness #motivation #health",
        "Delicious homemade pasta for dinner 🍝 #foodie #cooking #italian",
        "Coffee and good vibes ☕ #coffee #monday #mood",
        "Exploring new places 🗺️ #travel #adventure #wanderlust",
        "Family time is the best time ❤️ #family #love #blessed",
        "New book, new adventures 📚 #reading #books #literature",
        "Weekend market finds 🛍️ #shopping #market #local",
        "Morning run complete! 🏃‍♀️ #running #fitness #morning",
        "Art exhibition was incredible 🎨 #art #culture #inspiration",
        "Beach day with friends 🏖️ #beach #friends #summer",
        "Cooking experiment success! 👨‍🍳 #cooking #experiment #delicious",
        "New haircut, new me ✂️ #haircut #style #fresh",
        "Concert was absolutely amazing! 🎵 #music #concert #live",
        "Gardening therapy 🌱 #gardening #plants #green",
        "Movie night essentials 🍿 #movies #popcorn #relaxation",
        "Sunrise hike was worth it 🥾 #hiking #sunrise #nature",
        "Homemade pizza night 🍕 #pizza #homemade #delicious",
        "New city, new experiences 🏙️ #city #travel #exploring",
        "Yoga session complete 🧘‍♀️ #yoga #mindfulness #peace",
        "Weekend farmers market haul 🥕 #farmers #organic #healthy",
        "Just learned something new today 🤓 #learning #growth #knowledge",
        "Dance class was so much fun! 💃 #dance #fun #movement",
        "Finished my latest project 🎯 #project #completed #proud",
        "Time with my pets 🐕 #pets #love #companionship"
    ]
    
    # Sample image IDs (you can replace these with actual image URLs or IDs)
    sample_image_ids = [
        "image_sunset_001.jpg",
        "image_workout_002.jpg",
        "image_food_003.jpg",
        "image_coffee_004.jpg",
        "image_travel_005.jpg",
        "image_family_006.jpg",
        "image_books_007.jpg",
        "image_shopping_008.jpg",
        "image_running_009.jpg",
        "image_art_010.jpg",
        "image_beach_011.jpg",
        "image_cooking_012.jpg",
        "image_style_013.jpg",
        "image_music_014.jpg",
        "image_plants_015.jpg",
        "image_movies_016.jpg",
        "image_hiking_017.jpg",
        "image_pizza_018.jpg",
        "image_city_019.jpg",
        "image_yoga_020.jpg"
    ]
    
    # Create posts
    posts_created = 0
    
    for user in users:
        # Each user gets a random number of posts (0-10)
        num_posts = random.randint(0, 10)
        
        for _ in range(num_posts):
            # Select random caption and image
            caption = random.choice(sample_captions)
            image_id = random.choice(sample_image_ids)
            
            # Sometimes add location-specific content
            if random.random() < 0.3:  # 30% chance
                caption += f" #{user.location.lower().replace(' ', '')}"
            
            # Create post
            post = Post(
                user_id=user.id,
                image_id=image_id,
                caption=caption
            )
            
            # Set random creation time (within last 60 days)
            post.created_at = fake.date_time_between(start_date='-60d', end_date='now')
            post.updated_at = post.created_at
            
            # 10% chance the post was updated after creation
            if random.random() < 0.1:
                post.updated_at = fake.date_time_between(start_date=post.created_at, end_date='now')
            
            db.session.add(post)
            posts_created += 1
    
    # Add some posts with custom captions mentioning Kenyan locations
    kenyan_posts = [
        {
            'caption': "Exploring the beautiful streets of Nairobi! 🏙️ #Nairobi #Kenya #city",
            'image_id': "nairobi_street_001.jpg"
        },
        {
            'caption': "Mombasa beaches are paradise! 🏖️ #Mombasa #beach #paradise #Kenya",
            'image_id': "mombasa_beach_001.jpg"
        },
        {
            'caption': "Lake Victoria sunset from Kisumu 🌅 #Kisumu #LakeVictoria #sunset",
            'image_id': "kisumu_sunset_001.jpg"
        },
        {
            'caption': "Nakuru National Park wildlife 🦒 #Nakuru #wildlife #safari #Kenya",
            'image_id': "nakuru_wildlife_001.jpg"
        },
        {
            'caption': "Eldoret morning jog 🏃‍♀️ #Eldoret #running #morning #Kenya",
            'image_id': "eldoret_jog_001.jpg"
        }
    ]
    
    # Add Kenyan-specific posts
    for post_data in kenyan_posts:
        random_user = random.choice(users)
        post = Post(
            user_id=random_user.id,
            image_id=post_data['image_id'],
            caption=post_data['caption']
        )
        post.created_at = fake.date_time_between(start_date='-30d', end_date='now')
        post.updated_at = post.created_at
        
        db.session.add(post)
        posts_created += 1
    
    # Commit all posts
    try:
        db.session.commit()
        print(f"Successfully seeded {posts_created} posts")
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding posts: {e}")
        raise