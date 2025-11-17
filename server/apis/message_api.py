from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Message, Conversation, ConversationParticipant, User, Advertiser, db
from flask import current_app
from .decorators import token_required
from datetime import datetime
from sqlalchemy import case
from werkzeug.utils import secure_filename
import os

api = Namespace('messages', description='Message management operations')

# Import media utilities (create this file from the artifact)
try:
    from .utils.media_utils import upload_media_file

    MEDIA_UPLOAD_ENABLED = True
except ImportError:
    print("[MessageAPI] WARNING: media_utils not found. Media upload disabled.")
    MEDIA_UPLOAD_ENABLED = False

# Models for Swagger documentation
message_model = api.model('Message', {
    'id': fields.Integer(description='Message ID'),
    'conversation_id': fields.Integer(description='Conversation ID'),
    'sender_id': fields.Integer(description='Sender user ID'),
    'sender_type': fields.String(description='Type of sender (user or advertiser)'),
    'sender': fields.Nested(api.model('MessageSender', {
        'id': fields.Integer(description='Sender ID'),
        'name': fields.String(description='Sender name'),
        'username': fields.String(description='Sender username'),
        'profile_image_url': fields.String(description='Sender profile image URL')
    })),
    'content': fields.String(description='Message content'),
    'message_type': fields.String(description='Message type (text, image, video, audio)'),
    'media_url': fields.String(description='Media file URL'),
    'thumbnail_url': fields.String(description='Thumbnail URL (for videos)'),
    'media_metadata': fields.Raw(description='Media metadata (dimensions, duration, etc.)'),
    'is_read': fields.Boolean(description='Read status'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp')
})

message_create_model = api.model('MessageCreate', {
    'conversation_id': fields.Integer(required=True, description='Conversation ID'),
    'sender_id': fields.Integer(required=True, description='Sender user ID'),
    'sender_type': fields.String(description='Sender type (user or advertiser)'),
    'content': fields.String(description='Message content'),
    'message_type': fields.String(description='Message type (text, image, video, audio)', default='text')
})

message_update_model = api.model('MessageUpdate', {
    'content': fields.String(description='Message content'),
    'is_read': fields.Boolean(description='Read status')
})

def _build_message_dict(msg, include_sender=True):
    """
    Helper function to build a message dictionary with sender info.
    UPDATED: Now includes multimedia fields
    """
    msg_dict = {
        'id': msg.id,
        'conversation_id': msg.conversation_id,
        'sender_id': msg.sender_id,
        'sender_type': msg.sender_type or 'user',
        'content': msg.content,
        'message_type': getattr(msg, 'message_type', 'text') or 'text',  # NEW
        'media_url': getattr(msg, 'media_url', None),  # NEW
        'thumbnail_url': getattr(msg, 'thumbnail_url', None),  # NEW
        'media_metadata': getattr(msg, 'media_metadata', None),  # NEW
        'is_read': msg.is_read,
        'created_at': msg.created_at.isoformat() if msg.created_at else None,
        'updated_at': msg.updated_at.isoformat() if msg.updated_at else None
    }
    
    if include_sender:
        sender = None
        sender_type = msg.sender_type or 'user'
        
        # Normalize sender type
        if sender_type.lower() in ['advertiser', 'escort', 'provider']:
            sender_type = 'advertiser'
            sender = Advertiser.find_by_id(msg.sender_id)
        else:
            sender_type = 'user'
            sender = User.find_by_id(msg.sender_id)
        
        msg_dict['sender_type'] = sender_type
        msg_dict['sender'] = {
            'id': sender.id if sender else None,
            'name': sender.name if sender else 'Unknown',
            'username': sender.username if sender else 'unknown',
            'profile_image_url': getattr(sender, 'profile_image_url', None) if sender else None,
        } if sender else None
    
    return msg_dict

# Import notification utils if available
try:
    from .notification_utils import send_message_notification
    NOTIFICATIONS_ENABLED = True
except ImportError:
    print("[MessageAPI] WARNING: notification_utils not found. Notifications disabled.")
    NOTIFICATIONS_ENABLED = False

@api.route('/')
class MessageList(Resource):
    @api.doc('create_message')
    @api.expect(message_create_model)
    @token_required
    def post(self, current_user):
        """Create a new message (text or media) and broadcast via WebSocket + Send Push Notification"""
        try:
            # Check if this is a multipart/form-data request (file upload)
            is_file_upload = request.content_type and 'multipart/form-data' in request.content_type
            
            if is_file_upload:
                if not MEDIA_UPLOAD_ENABLED:
                    api.abort(501, 'Media upload is not configured. Please set up media_utils.py')
                
                # Handle file upload
                data = request.form.to_dict()
                file = request.files.get('file')
                
                if not file:
                    api.abort(400, 'No file provided')
                
                message_type = data.get('message_type', 'text')
                
                # Validate message type
                if message_type not in ['image', 'video', 'audio']:
                    api.abort(400, 'Invalid message_type for file upload. Must be: image, video, or audio')
                
                # Upload file and get URL
                try:
                    print(f'[MessageAPI] Uploading {message_type} file...')
                    upload_result = upload_media_file(file, message_type)
                    media_url = upload_result['url']
                    thumbnail_url = upload_result.get('thumbnail_url')
                    media_metadata = upload_result.get('metadata', {})
                    print(f'[MessageAPI] File uploaded successfully: {media_url}')
                except ValueError as ve:
                    api.abort(400, str(ve))
                except Exception as e:
                    print(f"[MessageAPI] File upload error: {e}")
                    import traceback
                    traceback.print_exc()
                    api.abort(500, f'Failed to upload file: {str(e)}')
            else:
                # Handle regular JSON request (text message)
                data = request.get_json()
                message_type = data.get('message_type', 'text')
                media_url = None
                thumbnail_url = None
                media_metadata = None
            
            sender_id = int(data.get('sender_id'))
            sender_type = data.get('sender_type', 'user').lower()
            
            # Normalize sender type
            if sender_type in ['advertiser', 'escort', 'provider']:
                sender_type = 'advertiser'
            else:
                sender_type = 'user'
            
            # Verify sender is current user and type matches
            current_user_type = 'advertiser' if isinstance(current_user, Advertiser) else 'user'
            
            if sender_id != current_user.id or sender_type != current_user_type:
                api.abort(403, 'Sender does not match current user')
            
            # Verify conversation exists
            conversation = Conversation.query.get(data['conversation_id'])
            if not conversation:
                api.abort(404, 'Conversation not found')
            
            # Verify user is participant
            is_participant = ConversationParticipant.query.filter_by(
                conversation_id=conversation.id,
                participant_id=sender_id,
                participant_type=sender_type
            ).first()
            
            if not is_participant:
                api.abort(403, 'Not a participant in this conversation')
            
            # Get content (optional for media messages)
            content = data.get('content', '')
            
            # For media messages, ensure we have either content or media
            if message_type != 'text' and not media_url:
                api.abort(400, 'Media URL is required for non-text messages')
            
            # Create message with multimedia support
            message_data = {
                'conversation_id': data['conversation_id'],
                'sender_id': sender_id,
                'sender_type': sender_type,
                'content': content,
            }
            
            # Add multimedia fields if they exist in the model
            if hasattr(Message, 'message_type'):
                message_data['message_type'] = message_type
            if hasattr(Message, 'media_url'):
                message_data['media_url'] = media_url
            if hasattr(Message, 'thumbnail_url'):
                message_data['thumbnail_url'] = thumbnail_url
            if hasattr(Message, 'media_metadata'):
                message_data['media_metadata'] = media_metadata
            
            message = Message(**message_data)
            
            db.session.add(message)
            db.session.flush()
            
            # Update conversation's last_message_id and last_message_at
            conversation.last_message_id = message.id
            conversation.last_message_at = datetime.utcnow()
            conversation.updated_at = datetime.utcnow()
            
            db.session.commit()
            
            print(f'[MessageAPI] Message {message.id} created (type: {message_type})')

            # Build response payload
            payload = _build_message_dict(message, include_sender=True)
            
            # ========== SEND PUSH NOTIFICATIONS ==========
            if NOTIFICATIONS_ENABLED:
                try:
                    # Get OTHER participants in the conversation
                    other_participants = ConversationParticipant.query.filter(
                        ConversationParticipant.conversation_id == conversation.id,
                        db.or_(
                            ConversationParticipant.participant_id != sender_id,
                            ConversationParticipant.participant_type != sender_type
                        )
                    ).all()
                    
                    # Get sender info for notification
                    sender_name = current_user.name if hasattr(current_user, 'name') else 'Someone'
                    sender_avatar = getattr(current_user, 'profile_image_url', None)
                    
                    # Determine notification content based on message type
                    if message_type == 'text':
                        notification_content = content
                    elif message_type == 'image':
                        notification_content = '📷 Sent a photo'
                    elif message_type == 'video':
                        notification_content = '🎥 Sent a video'
                    elif message_type == 'audio':
                        notification_content = '🎤 Sent a voice message'
                    else:
                        notification_content = 'Sent a message'
                    
                    # Send notification to each recipient
                    for participant in other_participants:
                        try:
                            if participant.participant_type == 'user':
                                recipient = User.find_by_id(participant.participant_id)
                            else:
                                recipient = Advertiser.find_by_id(participant.participant_id)
                            
                            if not recipient:
                                continue
                            
                            fcm_token = getattr(recipient, 'fcm_token', None)
                            
                            if fcm_token:
                                print(f'[MessageAPI] Sending notification to {participant.participant_type}:{participant.participant_id}')
                                
                                send_message_notification(
                                    fcm_token=fcm_token,
                                    sender_name=sender_name,
                                    message_content=notification_content,
                                    conversation_id=conversation.id,
                                    sender_id=sender_id,
                                    sender_type=sender_type,
                                    sender_avatar=sender_avatar
                                )
                            else:
                                print(f'[MessageAPI] No FCM token for {participant.participant_type}:{participant.participant_id}')
                        
                        except Exception as notif_error:
                            print(f'[MessageAPI] Error sending notification: {notif_error}')
                            continue
                
                except Exception as notif_error:
                    print(f'[MessageAPI] Error in notification process: {notif_error}')
            
            # ========== END PUSH NOTIFICATIONS ==========
            
            # Emit via WebSocket
            try:
                socketio = current_app.extensions.get('socketio')
                if socketio:
                    room = f"conv_{message.conversation_id}"
                    socketio.emit('new_message', payload, room=room)
                    print(f'[MessageAPI] WebSocket emitted for message {message.id}')
            except Exception as ws_error:
                print(f'[MessageAPI] WebSocket emit error: {ws_error}')

            return payload, 201
            
        except Exception as e:
            db.session.rollback()
            print(f'[MessageAPI] Error creating message: {str(e)}')
            import traceback
            traceback.print_exc()
            api.abort(500, f'Failed to create message: {str(e)}')

@api.route('/upload')
class MediaUpload(Resource):
    @api.doc('upload_media')
    @token_required
    def post(self, current_user):
        """Upload media file (image, video, or audio) without creating a message"""
        if not MEDIA_UPLOAD_ENABLED:
            api.abort(501, 'Media upload is not configured. Please set up media_utils.py')
        
        try:
            if 'file' not in request.files:
                api.abort(400, 'No file provided')
            
            file = request.files['file']
            media_type = request.form.get('media_type', 'image')
            
            if media_type not in ['image', 'video', 'audio']:
                api.abort(400, 'Invalid media_type. Must be image, video, or audio')
            
            # Upload file
            try:
                upload_result = upload_media_file(file, media_type)
                return upload_result, 200
            except ValueError as ve:
                api.abort(400, str(ve))
            except Exception as e:
                print(f"[MessageAPI] File upload error: {e}")
                api.abort(500, f'Failed to upload file: {str(e)}')
        
        except Exception as e:
            print(f'[MessageAPI] Error in media upload: {str(e)}')
            api.abort(500, f'Failed to upload media: {str(e)}')

@api.route('/<int:message_id>')
class MessageDetail(Resource):
    @api.doc('get_message')
    @token_required
    def get(self, current_user, message_id):
        """Get message by ID with sender info"""
        try:
            message = Message.query.get(message_id)
            if not message:
                api.abort(404, 'Message not found')
            
            return _build_message_dict(message, include_sender=True)
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve message: {str(e)}')
    
    @api.doc('update_message')
    @api.expect(message_update_model)
    @token_required
    def put(self, current_user, message_id):
        """Update message (only own messages, only text content)"""
        try:
            message = Message.query.get(message_id)
            if not message:
                api.abort(404, 'Message not found')
            if message.sender_id != current_user.id:
                api.abort(403, 'Can only update your own messages')
            
            data = request.get_json()
            
            # Only allow updating text content for text messages
            message_type = getattr(message, 'message_type', 'text')
            if 'content' in data and message_type == 'text':
                message.content = data['content']
            if 'is_read' in data:
                message.is_read = data['is_read']
            
            message.updated_at = datetime.utcnow()
            db.session.commit()
            
            # Broadcast update via WebSocket
            try:
                socketio = current_app.extensions.get('socketio')
                if socketio:
                    socketio.emit('message_updated', _build_message_dict(message, include_sender=True),
                                room=f"conv_{message.conversation_id}")
            except Exception as ws_error:
                print(f'WebSocket emit error: {ws_error}')
            
            return _build_message_dict(message, include_sender=True)
            
        except Exception as e:
            api.abort(500, f'Failed to update message: {str(e)}')
    
    @api.doc('delete_message')
    @token_required
    def delete(self, current_user, message_id):
        """Delete message (only own messages)"""
        try:
            message = Message.query.get(message_id)
            if not message:
                api.abort(404, 'Message not found')
            if message.sender_id != current_user.id:
                api.abort(403, 'Can only delete your own messages')
            
            conversation_id = message.conversation_id
            db.session.delete(message)
            db.session.commit()
            
            # Broadcast deletion via WebSocket
            try:
                socketio = current_app.extensions.get('socketio')
                if socketio:
                    socketio.emit('message_deleted', {
                        'message_id': message.id,
                        'conversation_id': conversation_id
                    }, room=f"conv_{conversation_id}")
            except Exception as ws_error:
                print(f'WebSocket emit error: {ws_error}')
            
            return {'message': 'Message deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete message: {str(e)}')

@api.route('/conversation/<int:conversation_id>')
class ConversationMessages(Resource):
    @api.doc('get_conversation_messages')
    @token_required
    def get(self, current_user, conversation_id):
        """Get all messages in a conversation with full sender info"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 50, type=int)
            
            # Verify conversation exists
            conversation = Conversation.query.get(conversation_id)
            if not conversation:
                api.abort(404, 'Conversation not found')
            
            # Determine current user type
            current_user_type = 'advertiser' if isinstance(current_user, Advertiser) else 'user'
            
            # Verify user is participant (for security)
            is_participant = ConversationParticipant.query.filter_by(
                conversation_id=conversation_id,
                participant_id=current_user.id,
                participant_type=current_user_type
            ).first()
            
            if not is_participant:
                api.abort(403, 'Not a participant in this conversation')
            
            # CRITICAL FIX: Auto-mark messages as read when fetching
            unread_messages = Message.query.filter(
                Message.conversation_id == conversation_id,
                Message.is_read == False,
                db.not_(
                    db.and_(
                        Message.sender_id == current_user.id,
                        Message.sender_type == current_user_type
                    )
                )
            ).all()
            
            for msg in unread_messages:
                msg.is_read = True
            
            if unread_messages:
                db.session.commit()
                print(f'[MessageAPI] Marked {len(unread_messages)} messages as read in conversation {conversation_id}')
            
            # Get messages ordered chronologically
            messages = Message.query.filter_by(
                conversation_id=conversation_id
            ).order_by(Message.created_at.asc()).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = [_build_message_dict(msg, include_sender=True) for msg in messages.items]
            
            return {
                'messages': result,
                'total': messages.total,
                'pages': messages.pages,
                'current_page': messages.page,
            }
            
        except Exception as e:
            db.session.rollback()
            print(f'[MessageAPI] Error fetching messages: {str(e)}')
            api.abort(500, f'Failed to retrieve conversation messages: {str(e)}')

@api.route('/recent')
class RecentConversations(Resource):
    @api.doc('get_recent_conversations')
    @token_required
    def get(self, current_user):
        """Get recent conversations for the current user with last message and sender info"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)

            # Determine participant type and ID
            if isinstance(current_user, User):
                participant_type = 'user'
                participant_id = current_user.id
            elif isinstance(current_user, Advertiser):
                participant_type = 'advertiser'
                participant_id = current_user.id
            else:
                return {'conversations': [], 'total': 0}, 200

            # MySQL-compatible NULL handling
            query = db.session.query(Conversation).join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id
            ).filter(
                ConversationParticipant.participant_type == participant_type,
                ConversationParticipant.participant_id == participant_id
            ).order_by(
                case(
                    (Conversation.last_message_at.is_(None), datetime(9999, 12, 31)),
                    else_=Conversation.last_message_at
                ).desc()
            )
            
            pagination = query.paginate(page=page, per_page=per_page, error_out=False)

            items = []
            for conv in pagination.items:
                # Get last message with sender info
                last_msg = Message.query.filter_by(
                    conversation_id=conv.id
                ).order_by(Message.created_at.desc()).first()
                last_msg_dict = _build_message_dict(last_msg, include_sender=True) if last_msg else None
                
                # Calculate unread count
                unread_count = Message.query.filter(
                    Message.conversation_id == conv.id,
                    Message.is_read == False,
                    db.not_(
                        db.and_(
                            Message.sender_id == participant_id,
                            Message.sender_type == participant_type
                        )
                    )
                ).count()
                
                # Get all participants
                all_participants = ConversationParticipant.query.filter_by(
                    conversation_id=conv.id
                ).all()
                
                # Find the OTHER participant (not current user)
                participant_info = None
                for p in all_participants:
                    if p.participant_type == participant_type and p.participant_id == participant_id:
                        continue
                        
                    if p.participant_type == 'user':
                        u = User.find_by_id(p.participant_id)
                        if u:
                            participant_info = {
                                'type': 'user',
                                'id': u.id,
                                'name': u.name,
                                'username': u.username,
                                'profile_image_url': getattr(u, 'profile_image_url', None),
                            }
                            break
                    elif p.participant_type == 'advertiser':
                        a = Advertiser.find_by_id(p.participant_id)
                        if a:
                            participant_info = {
                                'type': 'advertiser',
                                'id': a.id,
                                'name': a.name,
                                'username': a.username,
                                'profile_image_url': getattr(a, 'profile_image_url', None),
                            }
                            break

                items.append({
                    'conversation_id': conv.id,
                    'participant': participant_info,
                    'last_message': last_msg_dict,
                    'last_message_at': conv.last_message_at.isoformat() if conv.last_message_at else None,
                    'unread_count': unread_count,
                })

            print(f'[MessageAPI] Returning {len(items)} conversations, sorted by last_message_at')
            
            return {
                'conversations': items,
                'total': pagination.total,
                'pages': pagination.pages,
                'current_page': pagination.page,
            }
        except Exception as e:
            print(f'[MessageAPI] Error in /recent: {str(e)}')
            import traceback
            traceback.print_exc()
            api.abort(500, f'Failed to retrieve recent conversations: {str(e)}')

@api.route('/conversation/<int:conversation_id>/mark-read')
class MarkConversationRead(Resource):
    @api.doc('mark_conversation_read')
    @token_required
    def post(self, current_user, conversation_id):
        """Mark all messages in a conversation as read"""
        try:
            current_user_type = 'advertiser' if isinstance(current_user, Advertiser) else 'user'
            
            is_participant = ConversationParticipant.query.filter_by(
                conversation_id=conversation_id,
                participant_id=current_user.id,
                participant_type=current_user_type
            ).first()
            
            if not is_participant:
                api.abort(403, 'Not a participant in this conversation')
            
            updated_count = Message.query.filter(
                Message.conversation_id == conversation_id,
                Message.is_read == False,
                db.not_(
                    db.and_(
                        Message.sender_id == current_user.id,
                        Message.sender_type == current_user_type
                    )
                )
            ).update({'is_read': True}, synchronize_session=False)
            
            db.session.commit()
            
            print(f'[MessageAPI] Marked {updated_count} messages as read in conversation {conversation_id}')
            
            try:
                socketio = current_app.extensions.get('socketio')
                if socketio:
                    socketio.emit('conversation_marked_read', {
                        'conversation_id': conversation_id,
                        'user_id': current_user.id,
                        'marked_count': updated_count
                    }, room=f"conv_{conversation_id}")
            except Exception as ws_error:
                print(f'WebSocket emit error: {ws_error}')
            
            return {
                'message': 'Messages marked as read successfully',
                'count': updated_count
            }
            
        except Exception as e:
            db.session.rollback()
            print(f'[MessageAPI] Error marking as read: {str(e)}')
            api.abort(500, f'Failed to mark messages as read: {str(e)}')

@api.route('/unread/<int:user_id>')
class UnreadMessages(Resource):
    @api.doc('get_unread_messages')
    def get(self, user_id):
        """Get count of unread messages for a user across all conversations"""
        try:
            user_conversations = db.session.query(Conversation.id).join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id
            ).filter(
                ConversationParticipant.participant_id == user_id
            ).all()
            
            conversation_ids = [c[0] for c in user_conversations]
            
            unread_count = Message.query.filter(
                Message.conversation_id.in_(conversation_ids),
                Message.sender_id != user_id,
                Message.is_read == False
            ).count()
            
            return {'unread_count': unread_count}
            
        except Exception as e:
            api.abort(500, f'Failed to get unread count: {str(e)}')