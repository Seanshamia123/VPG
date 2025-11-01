"""
Firebase Cloud Messaging notification utilities
Sends push notifications when new messages are received
"""
import firebase_admin
from firebase_admin import credentials, messaging
from typing import Optional, List
import os

# Initialize Firebase Admin SDK (do this once in your app initialization)
def initialize_firebase():
    """
    Initialize Firebase Admin SDK
    Call this in your app.py or main initialization file
    
    You need to:
    1. Download your Firebase service account JSON from Firebase Console
    2. Save it as 'firebase-credentials.json' in your project root
    3. Or set FIREBASE_CREDENTIALS environment variable with the JSON content
    """
    try:
        if not firebase_admin._apps:
            # Option 1: From file
            if os.path.exists('firebase-credentials.json'):
                cred = credentials.Certificate('firebase-credentials.json')
                firebase_admin.initialize_app(cred)
                print('[Firebase] Initialized from credentials file')
            
            # Option 2: From environment variable
            elif os.getenv('FIREBASE_CREDENTIALS'):
                import json
                cred_dict = json.loads(os.getenv('FIREBASE_CREDENTIALS'))
                cred = credentials.Certificate(cred_dict)
                firebase_admin.initialize_app(cred)
                print('[Firebase] Initialized from environment variable')
            
            else:
                print('[Firebase] WARNING: No credentials found. Notifications disabled.')
                return False
        
        return True
    except Exception as e:
        print(f'[Firebase] Initialization error: {e}')
        return False


def send_message_notification(
    fcm_token: str,
    sender_name: str,
    message_content: str,
    conversation_id: int,
    sender_id: int,
    sender_type: str = 'user',
    sender_avatar: Optional[str] = None
) -> bool:
    """
    Send push notification for new message
    
    Args:
        fcm_token: Recipient's FCM token
        sender_name: Name of the person who sent the message
        message_content: Content of the message
        conversation_id: ID of the conversation
        sender_id: ID of the sender
        sender_type: Type of sender ('user' or 'advertiser')
        sender_avatar: URL of sender's avatar (optional)
    
    Returns:
        True if notification sent successfully, False otherwise
    """
    if not fcm_token:
        print('[FCM] No FCM token provided')
        return False
    
    try:
        # Truncate message if too long
        preview = message_content[:100] + '...' if len(message_content) > 100 else message_content
        
        # Build notification
        notification = messaging.Notification(
            title=sender_name,
            body=preview,
        )
        
        # Build data payload (for handling in app)
        data = {
            'type': 'new_message',
            'conversation_id': str(conversation_id),
            'sender_id': str(sender_id),
            'sender_type': sender_type,
            'sender_name': sender_name,
            'message_content': message_content,
        }
        
        if sender_avatar:
            data['sender_avatar'] = sender_avatar
        
        # Android-specific config (for custom sound, icon, etc.)
        android_config = messaging.AndroidConfig(
            priority='high',
            notification=messaging.AndroidNotification(
                sound='default',
                channel_id='messages_channel',
                icon='ic_launcher',
                color='#2196F3',  # Notification color
                click_action='FLUTTER_NOTIFICATION_CLICK',
            )
        )
        
        # iOS-specific config
        apns_config = messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    sound='default',
                    badge=1,  # You should track this per user
                    category='MESSAGE_CATEGORY',
                )
            )
        )
        
        # Build message
        message = messaging.Message(
            notification=notification,
            data=data,
            token=fcm_token,
            android=android_config,
            apns=apns_config,
        )
        
        # Send message
        response = messaging.send(message)
        print(f'[FCM] Successfully sent message: {response}')
        return True
        
    except Exception as e:
        print(f'[FCM] Error sending notification: {e}')
        return False


def send_notification_to_multiple(
    fcm_tokens: List[str],
    sender_name: str,
    message_content: str,
    conversation_id: int,
    sender_id: int,
    sender_type: str = 'user'
) -> dict:
    """
    Send notification to multiple devices (for multi-device users)
    
    Returns:
        Dictionary with success_count and failure_count
    """
    if not fcm_tokens:
        return {'success_count': 0, 'failure_count': 0}
    
    try:
        preview = message_content[:100] + '...' if len(message_content) > 100 else message_content
        
        # Build multicast message
        notification = messaging.Notification(
            title=sender_name,
            body=preview,
        )
        
        data = {
            'type': 'new_message',
            'conversation_id': str(conversation_id),
            'sender_id': str(sender_id),
            'sender_type': sender_type,
            'sender_name': sender_name,
        }
        
        multicast_message = messaging.MulticastMessage(
            notification=notification,
            data=data,
            tokens=fcm_tokens,
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(
                    sound='default',
                    channel_id='messages_channel',
                )
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(sound='default', badge=1)
                )
            )
        )
        
        # Send to multiple devices
        response = messaging.send_multicast(multicast_message)
        print(f'[FCM] Successfully sent {response.success_count} messages')
        print(f'[FCM] Failed to send {response.failure_count} messages')
        
        return {
            'success_count': response.success_count,
            'failure_count': response.failure_count
        }
        
    except Exception as e:
        print(f'[FCM] Error sending multicast notification: {e}')
        return {'success_count': 0, 'failure_count': len(fcm_tokens)}


def send_typing_notification(
    fcm_token: str,
    sender_name: str,
    conversation_id: int
) -> bool:
    """
    Send silent data-only notification for typing indicator
    (Optional - for better real-time experience without WebSocket)
    """
    if not fcm_token:
        return False
    
    try:
        message = messaging.Message(
            data={
                'type': 'typing',
                'conversation_id': str(conversation_id),
                'sender_name': sender_name,
            },
            token=fcm_token,
            android=messaging.AndroidConfig(
                priority='high',
            ),
        )
        
        messaging.send(message)
        return True
        
    except Exception as e:
        print(f'[FCM] Error sending typing notification: {e}')
        return False