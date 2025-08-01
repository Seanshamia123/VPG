from models.posts import Post
from models.advertiser import Advertiser  # Changed here
from database import db
from datetime import datetime, timedelta
import random

def seed_posts():
    """Seeds the Posts table with sample data linked to existing advertisers."""
    print("Seeding Posts...")
    
    # Get all existing advertisers to create posts for them
    advertisers = Advertiser.query.all()  # Changed here
    
    if not advertisers:
        print("No advertisers found! Please seed advertisers first.")
        return
    
    # Sample Kenyan-themed captions for posts
    captions = [
        "Beautiful sunrise over Mount Kenya! 🌅 #MountKenya #Kenya #Nature",
        "Enjoying nyama choma with friends at the weekend! 🍖 #NyamaChoma #Friends #Weekend",
        "Traffic jam on Thika Road again... but the matatu music keeps me entertained 🚌 #ThikaRoad #Nairobi #MataturCulture",
        "Fresh mandazi from mama mboga this morning! 😋 #Mandazi #Breakfast #Kenyan",
        "Watching lions at Maasai Mara - Kenya is truly beautiful! 🦁 #MaasaiMara #Safari #Wildlife",
        "Ugali and sukuma wiki for lunch - simple but delicious! 🍽️ #Ugali #SukumaWiki #KenyanFood",
        "Beach vibes at Diani - the Indian Ocean is so blue! 🏖️ #DianiBeach #Beach #Mombasa",
        "Stuck in Nairobi traffic but grateful for another day! 🚗 #NairobiTraffic #Grateful #Life",
        "Traditional Kikuyu dance at the cultural festival today! 💃 #Culture #Traditional #Dance",
        "Early morning jog around Karura Forest - fresh air! 🏃‍♀️ #KaruraForest #Jogging #Fitness",
        "Chapati and tea for breakfast - perfect start to the day! ☕ #Chapati #Tea #Breakfast",
        "Visiting Lake Nakuru - the flamingos are amazing! 🦩 #LakeNakuru #Flamingos #Nature",
        "Matatu ride to town - love the colorful designs! 🎨 #Matatu #Nairobi #Transport",
        "Fresh vegetables from the local market 🥬 #FreshVegetables #Market #Healthy",
        "Sunset at Hell's Gate National Park - breathtaking! 🌄 #HellsGate #Sunset #Kenya",
        "Traditional Kenyan coffee - the best in the world! ☕ #KenyanCoffee #Coffee #Local",
        "Weekend at Lake Naivasha with family 🚤 #LakeNaivasha #Family #Weekend",
        "Street food adventures in downtown Nairobi! 🌮 #StreetFood #Downtown #Nairobi",
        "Hiking at Ngong Hills - amazing views of the city! ⛰️ #NgongHills #Hiking #Views",
        "Traditional beadwork from Maasai artisans - so beautiful! 💎 #Maasai #Beadwork #Art",
        "Fish and chips at the coast - nothing beats it! 🐟 #FishAndChips #Coast #Mombasa",
        "Rugby match at RFUEA - supporting our local team! 🏉 #Rugby #RFUEA #Sports",
        "Fresh fruit salad with tropical fruits 🥭 #FruitSalad #Tropical #Healthy",
        "Traditional Luo music performance - so energetic! 🎵 #LuoMusic #Traditional #Performance",
        "Morning prayers at the local mosque 🕌 #Prayers #Faith #Community",
        "Volunteering at the children's home today ❤️ #Volunteering #Community #Children",
        "Traditional Luhya wedding ceremony - beautiful! 💒 #Wedding #Luhya #Traditional",
        "Fresh samosas from the local vendor 🥟 #Samosas #StreetFood #Delicious",
        "Early morning at Nairobi National Park 🦏 #NairobiNationalPark #Wildlife #Morning",
        "Traditional Kalenjin running training session! 🏃‍♂️ #Kalenjin #Running #Training",
        "Weekend market shopping in Gikomba 🛍️ #Gikomba #Market #Shopping",
        "Fresh coconut water at the beach 🥥 #CoconutWater #Beach #Refreshing",
        "Traditional Embu dance performance at school 🎭 #EmbuDance #School #Culture",
        "Motorcycle taxi (boda boda) ride to work 🏍️ #BodaBoda #Transport #Work",
        "Fresh fish from Lake Victoria - dinner sorted! 🐟 #LakeVictoria #Fish #Dinner",
        "Traditional Turkana jewelry - such craftsmanship! 💍 #Turkana #Jewelry #Craft",
        "Sunday service at the local church ⛪ #Church #Sunday #Faith",
        "Fresh githeri for lunch - comfort food! 🍛 #Githeri #Lunch #ComfortFood",
        "Traditional Kamba music session 🎶 #KambaMusic #Traditional #Music",
        "Weekend trip to Amboseli - elephants everywhere! 🐘 #Amboseli #Elephants #Safari"
    ]
    
    # Sample image URLs (using placeholder service for demo)
    image_urls = [
        "https://picsum.photos/600/400?random=1",
        "https://picsum.photos/600/400?random=2", 
        "https://picsum.photos/600/400?random=3",
        "https://picsum.photos/600/400?random=4",
        "https://picsum.photos/600/400?random=5",
        "https://picsum.photos/600/400?random=6",
        "https://picsum.photos/600/400?random=7",
        "https://picsum.photos/600/400?random=8",
        "https://picsum.photos/600/400?random=9",
        "https://picsum.photos/600/400?random=10",
        "https://picsum.photos/600/400?random=11",
        "https://picsum.photos/600/400?random=12",
        "https://picsum.photos/600/400?random=13",
        "https://picsum.photos/600/400?random=14",
        "https://picsum.photos/600/400?random=15",
        "https://picsum.photos/600/400?random=16",
        "https://picsum.photos/600/400?random=17",
        "https://picsum.photos/600/400?random=18",
        "https://picsum.photos/600/400?random=19",
        "https://picsum.photos/600/400?random=20"
    ]
    
    posts_data = []
    
    # Generate posts for each user (1-5 posts per user randomly)
     
    for advertiser in advertisers:
        if advertiser.username in ['admin', 'testuser']:
            num_posts = random.randint(1, 2)
        else:
            num_posts = random.randint(1, 5)
        
        for _ in range(num_posts):
            advertiser_age_in_days = (datetime.utcnow() - advertiser.created_at).days
            if advertiser_age_in_days > 0:
                days_after_creation = random.randint(0, advertiser_age_in_days)
                created_at = advertiser.created_at + timedelta(days=days_after_creation)
            else:
                created_at = advertiser.created_at
            
            updated_at = created_at + timedelta(minutes=random.randint(0, 60))
            
            post_data = {
                "advertiser_id": advertiser.id,  # Assuming Post.user_id still refers to advertiser
                "image_id": random.choice(image_urls),
                "caption": random.choice(captions),
                "created_at": created_at,
                "updated_at": updated_at
            }
            
            posts_data.append(post_data)
    
    print(f"Generated {len(posts_data)} posts for {len(advertisers)} advertisers")
    
    for post_data in posts_data:
        new_post = Post(**post_data)
        db.session.add(new_post)
    
    try:
        db.session.commit()
        print(f"Successfully seeded {len(posts_data)} posts!")
        
        print("\n--- Seeding Statistics ---")
        for advertiser in advertisers[:10]:
            advertiser_posts_count = len([p for p in posts_data if p['advertiser_id'] == advertiser.id])
            print(f"{advertiser.name}: {advertiser_posts_count} posts")
        
        if len(advertisers) > 10:
            print(f"... and {len(advertisers) - 10} more advertisers")
            
    except Exception as e:
        db.session.rollback()
        print(f"Error seeding posts: {str(e)}")

if __name__ == "__main__":
    seed_posts()



