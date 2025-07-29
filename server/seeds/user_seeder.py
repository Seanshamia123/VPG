"""
User seeder for populating the users table
"""
from datetime import datetime, timedelta
import random
from faker import Faker
from werkzeug.security import generate_password_hash
from models.user import User
from app import db

fake = Faker()

def seed_users():
    """Seed users table with sample data"""
    
    # Create some predefined users for testing
    predefined_users = [
        {
            'username': 'john_doe',
            'name': 'John Doe',
            'email': 'john@example.com',
            'phone_number': '+254700123456',
            'location': 'Nairobi',
            'gender': 'Male',
            'password_hash': generate_password_hash('password123')
        },
        {
            'username': 'jane_smith',
            'name': 'Jane Smith',
            'email': 'jane@example.com',
            'phone_number': '+254700123457',
            'location': 'Mombasa',
            'gender': 'Female',
            'password_hash': generate_password_hash('password123')
        },
        {
            'username': 'mike_wilson',
            'name': 'Mike Wilson',
            'email': 'mike@example.com',
            'phone_number': '+254700123458',
            'location': 'Kisumu',
            'gender': 'Male',
            'password_hash': generate_password_hash('password123')
        },
        {
            'username': 'sarah_johnson',
            'name': 'Sarah Johnson',
            'email': 'sarah@example.com',
            'phone_number': '+254700123459',
            'location': 'Nakuru',
            'gender': 'Female',
            'password_hash': generate_password_hash('password123')
        },
        {
            'username': 'alex_brown',
            'name': 'Alex Brown',
            'email': 'alex@example.com',
            'phone_number': '+254700123460',
            'location': 'Eldoret',
            'gender': 'other',
            'password_hash': generate_password_hash('password123')
        }
    ]
    
    # Kenyan cities for location diversity
    kenyan_cities = [
        'Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret', 
        'Thika', 'Malindi', 'Kitale', 'Garissa', 'Kakamega',
        'Machakos', 'Meru', 'Nyeri', 'Kericho', 'Embu'
    ]
    
    # Add predefined users
    for user_data in predefined_users:
        user = User(**user_data)
        # Set created_at to random time in the past 30 days
        user.created_at = fake.date_time_between(start_date='-30d', end_date='now')
        user.updated_at = user.created_at
        # Set last_active to random time between created_at and now
        user.last_active = fake.date_time_between(start_date=user.created_at, end_date='now')
        
        db.session.add(user)
    
    # Generate additional random users
    for i in range(95):  # Total 100 users (5 predefined + 95 random)
        # Generate unique username and email
        username = fake.user_name()
        while User.query.filter_by(username=username).first():
            username = fake.user_name()
        
        email = fake.email()
        while User.query.filter_by(email=email).first():
            email = fake.email()
        
        # Generate phone number in Kenyan format
        phone_number = f"+254{random.randint(700000000, 799999999)}"
        
        user = User(
            username=username,
            name=fake.name(),
            email=email,
            phone_number=phone_number,
            location=random.choice(kenyan_cities),
            gender=random.choice(['Male', 'Female', 'other']),
            password_hash=generate_password_hash('password123')
        )
        
        # Set random creation time in the past 90 days
        user.created_at = fake.date_time_between(start_date='-90d', end_date='now')
        user.updated_at = fake.date_time_between(start_date=user.created_at, end_date='now')
        
        # 80% chance user has been active recently
        if random.random() < 0.8:
            user.last_active = fake.date_time_between(start_date='-7d', end_date='now')
        else:
            user.last_active = fake.date_time_between(start_date=user.created_at, end_date='-7d')
        
        db.session.add(user)
    
    # Commit all users
    try:
        db.session.commit()
        print(f"Successfully seeded {User.query.count()} users")
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding users: {e}")
        raise