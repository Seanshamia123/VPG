from datetime import datetime, timedelta
import random
from database import db
from models.conversations import Conversation
from models.message import Message

def seed_messages():
    """
    Seed messages for existing conversations
    Creates realistic message threads with varying read status
    """
    
    # Clear existing messages
    db.session.query(Message).delete()
    db.session.commit()
    
    # Get all conversations
    conversations = db.session.query(Conversation).all()
    
    if not conversations:
        print("❌ No conversations found. Please run conversations_seeder.py first!")
        return
    
    # Sample message content for realistic seeding
    sample_messages = [
        # Greeting messages
    "Hey there! How's your day going?",
    "Hi! I saw your profile and thought I'd say hello 😊",
    "Good evening! Are you available to chat?",
    "Hello beautiful! Hope you're having a great day",
    "Hi! Your photos are amazing. Would love to get to know you better",
    
    # Booking/Service related
    "Are you available this weekend?",
    "What are your rates for tonight?",
    "I'm interested in booking some time with you",
    "What services do you offer?",
    "Can we meet for dinner first?",
    "I'm looking for companionship for an event",
    "Are you available for outcalls?",
    
    # Casual conversation
    "What's your favorite restaurant in the city?",
    "Do you enjoy traveling?",
    "That sounds like fun!",
    "I'd love to hear more about that",
    "You seem really interesting",
    "What do you like to do in your free time?",
    "Have you been to that new place downtown?",
    
    # Response messages
    "Thanks for reaching out!",
    "I appreciate your message",
    "That sounds perfect",
    "I'm definitely interested",
    "Let me check my schedule",
    "I'll get back to you soon",
    "Looking forward to meeting you",
    "That works for me",
    
    # Time/scheduling
    "What time works best for you?",
    "I'm free after 7 PM",
    "How about this Friday?",
    "I can do lunch or dinner",
    "My schedule is pretty flexible",
    "Let me know what works",
    "I'm available most evenings",
    
    # Compliments/flirty
    "You have such a beautiful smile",
    "You look stunning in your photos",
    "I can't wait to meet you in person",
    "You seem like such a fun person",
    "Your profile really caught my attention",
    
    # Short responses
    "Absolutely!",
    "Sounds good!",
    "Perfect 👍",
    "Thank you!",
    "Of course",
    "I agree",
    "That's great!",
    "Definitely",
    "Sure thing",
    "No problem",
    
    # Questions
    "What's your favorite type of cuisine?",
    "Do you prefer quiet evenings or going out?",
    "What's the best way to reach you?",
    "Are you new to the city?",
    "What made you get into this?",
    "Do you have any hobbies?",
    ]
    
    messages_data = []
    user_ids = list(range(1, 53))  # Assuming users 1-52
    
    for conversation in conversations:
        # Each conversation gets 1-15 messages
        num_messages = random.randint(1, 15)
        
        # Start from conversation's last_message_at time
        current_time = conversation.last_message_at
        last_message_id = None
        
        for i in range(num_messages):
            # Messages are sent over time, with some gaps
            if i > 0:
                # Add random time between messages (minutes to hours)
                time_gap = timedelta(
                    minutes=random.randint(1, 30),
                    hours=random.randint(0, 2)
                )
                current_time += time_gap
            
            # Determine sender - conversation owner or random other user
            if i == 0 or random.random() < 0.6:  # 60% chance conversation owner sends message
                sender_id = conversation.user_id
            else:
                # Random other user sends message
                other_users = [uid for uid in user_ids if uid != conversation.user_id]
                sender_id = random.choice(other_users)
            
            # Random message content
            content = random.choice(sample_messages)
            
            # Random read status - newer messages more likely to be unread
            is_read = random.random() < 0.7  # 70% chance of being read
            
            message = Message(
                conversation_id=conversation.id,
                sender_id=sender_id,
                content=content,
                is_read=is_read,
                created_at=current_time,
                updated_at=current_time
            )
            
            messages_data.append(message)
            last_message_id = len(messages_data)  # Temporary ID tracking
    
    # Add all messages to the session
    db.session.add_all(messages_data)
    db.session.commit()
    
    # Update conversations with their last message info
    for conversation in conversations:
        # Get the last message for this conversation
        last_message = db.session.query(Message)\
            .filter_by(conversation_id=conversation.id)\
            .order_by(Message.created_at.desc())\
            .first()
        
        if last_message:
            conversation.last_message_id = last_message.id
            conversation.last_message_at = last_message.created_at
            conversation.updated_at = last_message.created_at
    
    db.session.commit()
    
    print(f"✅ Successfully seeded {len(messages_data)} messages")
    
    # Display statistics
    total_messages = len(messages_data)
    read_messages = sum(1 for msg in messages_data if msg.is_read)
    unread_messages = total_messages - read_messages
    
    messages_per_conversation = {}
    for msg in messages_data:
        messages_per_conversation[msg.conversation_id] = messages_per_conversation.get(msg.conversation_id, 0) + 1
    
    avg_messages_per_conv = sum(messages_per_conversation.values()) / len(messages_per_conversation)
    
    print(f"📊 Statistics:")
    print(f"   - Total messages: {total_messages}")
    print(f"   - Read messages: {read_messages} ({read_messages/total_messages*100:.1f}%)")
    print(f"   - Unread messages: {unread_messages} ({unread_messages/total_messages*100:.1f}%)")
    print(f"   - Average messages per conversation: {avg_messages_per_conv:.1f}")
    print(f"   - Conversations with messages: {len(messages_per_conversation)}")

if __name__ == "__main__":
    seed_messages()