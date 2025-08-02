from datetime import datetime, timedelta
import random
from database import db
from models.conversations import Conversation
from models.message import Message

def seed_conversations():
    """
    Seed conversations for existing users (assuming user IDs 1-52)
    Creates various types of conversations with realistic timestamps
    """
    
    # Clear existing conversations
    db.session.query(Conversation).delete()
    db.session.commit()
    
    conversations_data = []
    user_ids = list(range(1, 53))  # Assuming 52 users with IDs 1-52
    
    # Create conversations for each user
    for user_id in user_ids:
        # Each user gets 1-5 conversations
        num_conversations = random.randint(1, 5)
        
        for _ in range(num_conversations):
            # Random timestamp within last 30 days
            days_ago = random.randint(0, 30)
            hours_ago = random.randint(0, 23)
            minutes_ago = random.randint(0, 59)
            
            created_time = datetime.now() - timedelta(
                days=days_ago, 
                hours=hours_ago, 
                minutes=minutes_ago
            )
            
            conversation = Conversation(
                type='direct',  # You can add more types if needed
                user_id=user_id,
                last_message_at=created_time,
                updated_at=created_time
            )
            
            conversations_data.append(conversation)
    
    # Add all conversations to the session
    db.session.add_all(conversations_data)
    db.session.commit()
    
    print(f"✅ Successfully seeded {len(conversations_data)} conversations")
    
    # Display some statistics
    total_conversations = len(conversations_data)
    conversations_per_user = {}
    
    for conv in conversations_data:
        conversations_per_user[conv.user_id] = conversations_per_user.get(conv.user_id, 0) + 1
    
    avg_conversations = sum(conversations_per_user.values()) / len(conversations_per_user)
    
    print(f"📊 Statistics:")
    print(f"   - Total conversations: {total_conversations}")
    print(f"   - Average conversations per user: {avg_conversations:.1f}")
    print(f"   - Users with conversations: {len(conversations_per_user)}")

if __name__ == "__main__":
    seed_conversations()