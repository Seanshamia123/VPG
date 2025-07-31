from models.user import User
from database import db
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash
import random

def seed_users():
    """Seeds the Users table with sample data."""
    print("Seeding Users...")
    
    # Kenyan locations for realistic data
    kenyan_locations = [
        "Nairobi", "Mombasa", "Kisumu", "Nakuru", "Eldoret",
        "Thika", "Malindi", "Kitale", "Garissa", "Kakamega",
        "Machakos", "Meru", "Nyeri", "Kericho", "Embu",
        "Migori", "Homa Bay", "Bungoma", "Kapsabet", "Voi"
    ]
    
    # Sample Kenyan names
    male_names = [
        "John Kamau", "Peter Mwangi", "David Otieno", "Samuel Kiprop",
        "James Njoroge", "Michael Ochieng", "Daniel Kiprotich", "Joseph Mutua",
        "Francis Wanjiku", "Simon Karanja", "Paul Kimani", "Robert Maina",
        "George Omondi", "Stephen Chebet", "Anthony Ngigi", "Evans Wekesa"
    ]
    
    female_names = [
        "Mary Wanjiku", "Grace Akinyi", "Susan Chebet", "Joyce Nyambura",
        "Faith Wambui", "Mercy Atieno", "Lucy Muthoni", "Catherine Jepkemboi",
        "Anne Njeri", "Rose Wairimu", "Elizabeth Moraa", "Hannah Cherono",
        "Margaret Wanjiru", "Sarah Makena", "Jane Adhiambo", "Rachel Kipketer"
    ]
    
    users_data = []
    
    # Generate 50 sample users
    for i in range(50):
        # Randomly choose gender and corresponding name
        gender = random.choice(['Male', 'Female'])
        if gender == 'Male':
            name = random.choice(male_names)
        else:
            name = random.choice(female_names)
        
        # Generate username from name
        username = name.lower().replace(' ', '_') + str(random.randint(1, 999))
        
        # Generate email from name
        email_name = name.lower().replace(' ', '.')
        email_domain = random.choice(['gmail.com', 'yahoo.com', 'hotmail.com', 'outlook.com'])
        email = f"{email_name}{random.randint(1, 999)}@{email_domain}"
        
        # Generate Kenyan phone number
        phone_prefixes = ['0701', '0702', '0703', '0704', '0705', '0706', '0707', '0708', '0709',
                         '0710', '0711', '0712', '0713', '0714', '0715', '0716', '0717', '0718', '0719',
                         '0720', '0721', '0722', '0723', '0724', '0725', '0726', '0727', '0728', '0729']
        phone_number = random.choice(phone_prefixes) + ''.join([str(random.randint(0, 9)) for _ in range(6)])
        
        # Random creation date within the last year
        days_ago = random.randint(1, 365)
        created_at = datetime.utcnow() - timedelta(days=days_ago)
        
        # Random last active (some users more recent than others)
        last_active_days = random.randint(0, 30)
        last_active = datetime.utcnow() - timedelta(days=last_active_days)
        
        user_data = {
            "username": username,
            "name": name,
            "email": email,
            "phone_number": phone_number,
            "location": random.choice(kenyan_locations),
            "gender": gender,
            "password_hash": generate_password_hash("password123"),
            "created_at": created_at,
            "updated_at": created_at,
            "last_active": last_active
        }
        
        users_data.append(user_data)
    
    # Add some specific admin/test users
    admin_users = [
        {
            "username": "admin",
            "name": "System Administrator",
            "email": "admin@system.ke",
            "phone_number": "0700000001",
            "location": "Nairobi",
            "gender": "other",
            "password_hash": generate_password_hash("admin123"),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "last_active": datetime.utcnow()
        },
        {
            "username": "testuser",
            "name": "Test User",
            "email": "test@example.ke",
            "phone_number": "0700000002",
            "location": "Nairobi",
            "gender": "Male",
            "password_hash": generate_password_hash("test123"),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "last_active": datetime.utcnow()
        }
    ]
    
    # Combine all users
    all_users = users_data + admin_users
    
    # Insert users into database
    for user_data in all_users:
        # Check if user already exists by email
        exists = User.query.filter_by(email=user_data["email"]).first()
        if not exists:
            new_user = User(**user_data)
            db.session.add(new_user)
    
    try:
        db.session.commit()
        print(f"Successfully seeded {len(all_users)} users!")
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding users: {str(e)}")