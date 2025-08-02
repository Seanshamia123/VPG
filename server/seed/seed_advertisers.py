from models.advertiser import Advertiser
from database import db
from datetime import datetime, timedelta
from werkzeug.security import generate_password_hash
import random

def seed_advertisers():
    """Seeds the Advertisers table with sample data."""
    print("Seeding Advertisers...")
    
    # Kenyan locations for realistic data
    kenyan_locations = [
        "Nairobi", "Mombasa", "Kisumu", "Nakuru", "Eldoret",
        "Thika", "Malindi", "Kitale", "Garissa", "Kakamega",
        "Machakos", "Meru", "Nyeri", "Kericho", "Embu",
        "Migori", "Homa Bay", "Bungoma", "Kapsabet", "Voi"
    ]
    
    # Unique female names for advertisers
    female_names = [
        "Aisha Wanjiku", "Beatrice Akinyi", "Caroline Chebet", "Diana Nyambura",
        "Esther Wambui", "Florence Atieno", "Gloria Muthoni", "Helen Jepkemboi",
        "Irene Njeri", "Janet Wairimu", "Karen Moraa", "Linda Cherono",
        "Monica Wanjiru", "Nancy Makena", "Olivia Adhiambo", "Patricia Kipketer",
        "Queen Nyokabi", "Rita Achieng", "Stella Chepkemoi", "Teresa Wawira",
        "Ursula Nyawira", "Violet Kemunto", "Winnie Jepchumba", "Ximena Wanjala",
        "Yvonne Kawira", "Zipporah Cheptoo", "Agnes Mumbi", "Brenda Naserian",
        "Cynthia Wangui", "Doreen Akoth", "Eunice Jeptanui", "Fridah Waruguru",
        "Gladys Nekesa", "Hope Njambi", "Ivy Wangeci", "Joy Awino",
        "Keren Chepchumba", "Lydia Wanjeri", "Millicent Aoko", "Naomi Chepngetich",
        "Purity Mumbua", "Rachael Jebiwott", "Salome Wangechi", "Tabitha Chemtai",
        "Veronicah Nyaguthii", "Winifred Chepkoech", "Yvette Wangari", "Zenaida Chepkirui"
    ]
    
    # Business-related bio samples for advertisers
    bio_samples = [
        "Digital marketing specialist focusing on local businesses and startups.",
        "Fashion entrepreneur showcasing Kenyan designers and trends.",
        "Food blogger and restaurant reviewer covering Nairobi's dining scene.",
        "Travel enthusiast promoting Kenya's beautiful destinations.",
        "Beauty and wellness coach helping women feel confident.",
        "Tech entrepreneur connecting businesses with modern solutions.",
        "Event planner creating memorable experiences across Kenya.",
        "Fitness trainer and nutritionist promoting healthy lifestyles.",
        "Real estate consultant helping families find perfect homes.",
        "Educational content creator supporting student success.",
        "Small business advocate and financial literacy educator.",
        "Sustainable living promoter and eco-friendly product reviewer.",
        "Arts and crafts entrepreneur showcasing handmade creations.",
        "Photography services for weddings and corporate events.",
        "Social media strategist helping brands grow their online presence."
    ]
    
    advertisers_data = []
    
    # Generate 48 sample advertisers (using unique female names)
    for i, name in enumerate(female_names[:48]):
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
        
        # Random last active (some advertisers more recent than others)
        last_active_days = random.randint(0, 30)
        last_active = datetime.utcnow() - timedelta(days=last_active_days)
        
        # Random verification status (70% verified)
        is_verified = random.choice([True] * 7 + [False] * 3)
        
        # Random online status (80% online)
        is_online = random.choice([True] * 8 + [False] * 2)
        
        advertiser_data = {
            "username": username,
            "name": name,
            "email": email,
            "phone_number": phone_number,
            "location": random.choice(kenyan_locations),
            "gender": "Female",
            "profile_image_url": f"https://via.placeholder.com/150?text={name.split()[0]}",
            "is_verified": is_verified,
            "is_online": is_online,
            "bio": random.choice(bio_samples),
            "password_hash": generate_password_hash("advertiser123"),
            "created_at": created_at,
            "updated_at": created_at,
            "last_active": last_active
        }
        
        advertisers_data.append(advertiser_data)
    
    # Add some specific admin/test advertisers
    admin_advertisers = [
        {
            "username": "admin_advertiser",
            "name": "Admin Advertiser",
            "email": "admin.advertiser@system.ke",
            "phone_number": "0700000011",
            "location": "Nairobi",
            "gender": "Female",
            "profile_image_url": "https://via.placeholder.com/150?text=Admin",
            "is_verified": True,
            "is_online": True,
            "bio": "System administrator for advertiser management.",
            "password_hash": generate_password_hash("adminadv123"),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "last_active": datetime.utcnow()
        },
        {
            "username": "test_advertiser",
            "name": "Test Advertiser",
            "email": "test.advertiser@example.ke",
            "phone_number": "0700000012",
            "location": "Nairobi",
            "gender": "Female",
            "profile_image_url": "https://via.placeholder.com/150?text=Test",
            "is_verified": True,
            "is_online": True,
            "bio": "Test account for advertiser functionality testing.",
            "password_hash": generate_password_hash("testadv123"),
            "created_at": datetime.utcnow(),
            "updated_at": datetime.utcnow(),
            "last_active": datetime.utcnow()
        }
    ]
    
    # Combine all advertisers
    all_advertisers = advertisers_data + admin_advertisers
    
    # Insert advertisers into database
    for advertiser_data in all_advertisers:
        # Check if advertiser already exists by email
        exists = Advertiser.query.filter_by(email=advertiser_data["email"]).first()
        if not exists:
            new_advertiser = Advertiser(**advertiser_data)
            db.session.add(new_advertiser)
    
    try:
        db.session.commit()
        print(f"Successfully seeded {len(all_advertisers)} advertisers!")
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding advertisers: {str(e)}")

if __name__ == "__main__":
    seed_advertisers()