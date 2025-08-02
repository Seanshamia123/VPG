"""
Advertiser seeder for populating the advertisers table
"""
import random
from faker import Faker # type: ignore
from werkzeug.security import generate_password_hash
from models.advertiser import Advertiser
from app import db

fake = Faker()

def seed_advertisers():
    """Seed advertisers table with sample data"""
    
    # Kenyan business categories and names
    kenyan_businesses = [
        {
            'company_name': 'Safaricom Ltd',
            'category': 'Telecommunications',
            'description': 'Leading telecommunications company in Kenya'
        },
        {
            'company_name': 'Kenya Airways',
            'category': 'Aviation',
            'description': 'National airline of Kenya'
        },
        {
            'company_name': 'Equity Bank',
            'category': 'Banking',
            'description': 'Leading financial services provider'
        },
        {
            'company_name': 'Tusker Breweries',
            'category': 'Beverages',
            'description': 'Premium beer and beverage manufacturer'
        },
        {
            'company_name': 'Nakumatt Holdings',
            'category': 'Retail',
            'description': 'Major retail chain in East Africa'
        },
        {
            'company_name': 'Nation Media Group',
            'category': 'Media',
            'description': 'Leading media and publishing company'
        },
        {
            'company_name': 'KenGen',
            'category': 'Energy',
            'description': 'Kenya\'s largest electric power generator'
        },
        {
            'company_name': 'Bamburi Cement',
            'category': 'Construction',
            'description': 'Leading cement manufacturer in Kenya'
        },
        {
            'company_name': 'Brookside Dairy',
            'category': 'Food & Beverages',
            'description': 'Major dairy products manufacturer'
        },
        {
            'company_name': 'Unga Group',
            'category': 'Food Processing',
            'description': 'Leading flour and animal feed manufacturer'
        }
    ]
    
    # Additional business categories for random generation
    business_categories = [
        'Technology', 'Healthcare', 'Education', 'Real Estate', 'Agriculture',
        'Tourism', 'Fashion', 'Automotive', 'Hospitality', 'Manufacturing',
        'Logistics', 'Entertainment', 'Sports', 'Beauty', 'Furniture'
    ]
    
    # Kenyan cities for business locations
    kenyan_cities = [
        'Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret', 
        'Thika', 'Malindi', 'Kitale', 'Garissa', 'Kakamega'
    ]
    
    # Add predefined Kenyan businesses
    for i, business in enumerate(kenyan_businesses):
        email = f"contact@{business['company_name'].lower().replace(' ', '').replace('ltd', '').replace('.', '')}.co.ke"
        
        advertiser = Advertiser(
            name=fake.name(),
            email=email,
            phone_number=f"+254{random.randint(700000000, 799999999)}",
            company_name=business['company_name'],
            business_category=business['category'],
            location=random.choice(kenyan_cities),
            gender=random.choice(['Male', 'Female', 'other']),
            password_hash=generate_password_hash('advertiser123'),
            business_description=business['description']
        )
        
        # Set random creation time
        advertiser.created_at = fake.date_time_between(start_date='-180d', end_date='now')
        advertiser.updated_at = advertiser.created_at
        
        # Set last active time
        if random.random() < 0.9:  # 90% chance they've been active recently
            advertiser.last_active = fake.date_time_between(start_date='-14d', end_date='now')
        else:
            advertiser.last_active = fake.date_time_between(start_date=advertiser.created_at, end_date='-14d')
        
        db.session.add(advertiser)
    
    # Generate additional random advertisers
    for i in range(40):  # Total 50 advertisers (10 predefined + 40 random)
        company_name = f"{fake.company()} {random.choice(['Ltd', 'Limited', 'Co.', 'Group', 'Holdings'])}"
        
        # Generate unique email
        email_base = company_name.lower().replace(' ', '').replace('ltd', '').replace('limited', '').replace('co.', '').replace('.', '')[:20]
        email = f"info@{email_base}.com"
        
        # Ensure email uniqueness
        counter = 1
        while Advertiser.query.filter_by(email=email).first():
            email = f"info{counter}@{email_base}.com"
            counter += 1
        
        # Generate business description
        category = random.choice(business_categories)
        descriptions = [
            f"Leading {category.lower()} company providing innovative solutions",
            f"Professional {category.lower()} services for businesses and individuals",
            f"Quality {category.lower()} products and services since establishment",
            f"Trusted {category.lower()} partner for all your needs",
            f"Premium {category.lower()} solutions with customer satisfaction focus"
        ]
        
        advertiser = Advertiser(
            name=fake.name(),
            email=email,
            phone_number=f"+254{random.randint(700000000, 799999999)}",
            company_name=company_name,
            business_category=category,
            location=random.choice(kenyan_cities),
            gender=random.choice(['Male', 'Female', 'other']),
            password_hash=generate_password_hash('advertiser123'),
            business_description=random.choice(descriptions)
        )
        
        # Set random timestamps
        advertiser.created_at = fake.date_time_between(start_date='-365d', end_date='now')
        advertiser.updated_at = fake.date_time_between(start_date=advertiser.created_at, end_date='now')
        
        # Set activity status
        if random.random() < 0.85:  # 85% active advertisers
            advertiser.last_active = fake.date_time_between(start_date='-30d', end_date='now')
        else:
            advertiser.last_active = fake.date_time_between(start_date=advertiser.created_at, end_date='-30d')
        
        db.session.add(advertiser)
    
    # Commit all advertisers
    try:
        db.session.commit()
        print(f"Successfully seeded {Advertiser.query.count()} advertisers")
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding advertisers: {e}")
        raise