from flask import request, jsonify
from flask_cors import cross_origin
from flask_restx import Namespace, Resource, fields
from models import Conversation, ConversationParticipant, Message, User, Advertiser, db
from .decorators import token_required
from sqlalchemy.orm import aliased

api = Namespace('conversations', description='Conversation management operations')

# Models for Swagger documentation
conversation_model = api.model('Conversation', {
    'id': fields.Integer(description='Conversation ID'),
    'type': fields.String(description='Conversation type'),
    'user_id': fields.Integer(description='User ID'),
    'last_message_id': fields.Integer(description='Last message ID'),
    'last_message_at': fields.String(description='Last message timestamp'),
    'updated_at': fields.String(description='Last update timestamp')
})

# ============ WITH ADVERTISER - MUST BE BEFORE OTHER ROUTES ============
@api.route('/with-advertiser/<int:advertiser_id>')
class ConversationWithAdvertiser(Resource):
    @cross_origin()
    @api.doc('get_or_create_conversation_with_advertiser')
    @token_required
    def post(self, current_user, advertiser_id):
        """Create or fetch existing conversation between user and advertiser"""
        try:
            print(f'[ConversationWithAdvertiser] POST /with-advertiser/{advertiser_id}')
            
            # Verify advertiser exists
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                print(f'[ConversationWithAdvertiser] Advertiser {advertiser_id} not found')
                api.abort(404, 'Advertiser not found')

            # Create aliases for the participant table since we need to join it twice
            UserParticipant = aliased(ConversationParticipant)
            AdvertiserParticipant = aliased(ConversationParticipant)

            # Check if conversation already exists
            existing = db.session.query(Conversation).join(
                UserParticipant,
                UserParticipant.conversation_id == Conversation.id
            ).join(
                AdvertiserParticipant,
                AdvertiserParticipant.conversation_id == Conversation.id
            ).filter(
                UserParticipant.participant_type == 'user',
                UserParticipant.participant_id == current_user.id,
                AdvertiserParticipant.participant_type == 'advertiser',
                AdvertiserParticipant.participant_id == advertiser_id,
                Conversation.type == 'direct',
            ).first()

            if existing:
                print(f'[ConversationWithAdvertiser] Found existing conversation {existing.id}')
                response = {
                    'id': existing.id,
                    'conversation_id': existing.id,
                    'type': existing.type,
                    'user_id': existing.user_id,
                    'last_message_id': existing.last_message_id,
                    'last_message_at': existing.last_message_at.isoformat() if existing.last_message_at else None,
                    'updated_at': existing.updated_at.isoformat() if existing.updated_at else None,
                }
                return response, 200

            # Create new conversation
            print(f'[ConversationWithAdvertiser] Creating new conversation')
            conv = Conversation(type='direct', user_id=current_user.id)
            db.session.add(conv)
            db.session.flush()
            
            # Add participants
            user_participant = ConversationParticipant(
                conversation_id=conv.id,
                participant_type='user',
                participant_id=current_user.id
            )
            advertiser_participant = ConversationParticipant(
                conversation_id=conv.id,
                participant_type='advertiser',
                participant_id=advertiser_id
            )
            
            db.session.add(user_participant)
            db.session.add(advertiser_participant)
            db.session.commit()
            
            print(f'[ConversationWithAdvertiser] Created conversation {conv.id}')
            
            response = {
                'id': conv.id,
                'conversation_id': conv.id,
                'type': conv.type,
                'user_id': conv.user_id,
                'last_message_id': conv.last_message_id,
                'last_message_at': conv.last_message_at.isoformat() if conv.last_message_at else None,
                'updated_at': conv.updated_at.isoformat() if conv.updated_at else None,
            }
            return response, 201
            
        except Exception as e:
            print(f'[ConversationWithAdvertiser] Error: {str(e)}')
            db.session.rollback()
            api.abort(500, f'Failed to get conversation with advertiser: {str(e)}')

# ============ STANDARD CONVERSATION ROUTES ============

conversation_create_model = api.model('ConversationCreate', {
    'type': fields.String(description='Conversation type', default='direct'),
    'participant_id': fields.Integer(required=True, description='ID of user to start conversation with')
})

conversation_with_details_model = api.model('ConversationWithDetails', {
    'id': fields.Integer(description='Conversation ID'),
    'type': fields.String(description='Conversation type'),
    'user_id': fields.Integer(description='User ID'),
    'last_message_id': fields.Integer(description='Last message ID'),
    'last_message_at': fields.String(description='Last message timestamp'),
    'updated_at': fields.String(description='Last update timestamp'),
    'participant': fields.Nested(api.model('ConversationParticipant', {
        'id': fields.Integer(description='Participant ID'),
        'name': fields.String(description='Participant name'),
        'username': fields.String(description='Participant username')
    })),
    'last_message': fields.Nested(api.model('LastMessage', {
        'id': fields.Integer(description='Message ID'),
        'content': fields.String(description='Message content'),
        'sender_id': fields.Integer(description='Sender ID'),
        'created_at': fields.String(description='Creation timestamp')
    })),
    'unread_count': fields.Integer(description='Number of unread messages')
})

def _get_unread_count_for_conversation(conversation_id, current_user_id, current_user_type):
    """
    Helper to calculate unread count correctly by checking BOTH sender_id AND sender_type.
    Only counts messages NOT sent by current user (matching both ID and type).
    """
    return Message.query.filter(
        Message.conversation_id == conversation_id,
        Message.is_read == False,
        db.not_(
            db.and_(
                Message.sender_id == current_user_id,
                Message.sender_type == current_user_type
            )
        )
    ).count()

@api.route('/')
class ConversationList(Resource):
    @api.doc('list_conversations')
    @token_required
    def get(self, current_user):
        """Get all conversations for current user"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)
            
            # Determine current user type
            current_user_type = 'advertiser' if isinstance(current_user, Advertiser) else 'user'
            
            conversations = db.session.query(Conversation).join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id,
            ).filter(
                ConversationParticipant.participant_type == current_user_type,
                ConversationParticipant.participant_id == current_user.id,
            ).order_by(Conversation.last_message_at.desc()).paginate(
                page=page,
                per_page=per_page,
                error_out=False,
            )
            
            result = []
            for conversation in conversations.items:
                # Get last message details
                last_message = None
                if conversation.last_message_id:
                    last_message = Message.query.get(conversation.last_message_id)
                
                # FIXED: Get unread count with proper sender type filtering
                unread_count = _get_unread_count_for_conversation(
                    conversation.id,
                    current_user.id,
                    current_user_type
                )
                
                # For direct conversations, get the other participant
                participant = None
                participant_type = None
                if conversation.type == 'direct':
                    # Get all participants
                    all_participants = ConversationParticipant.query.filter_by(
                        conversation_id=conversation.id
                    ).all()
                    
                    # Find the OTHER participant (not current user)
                    for p in all_participants:
                        if p.participant_type == current_user_type and p.participant_id == current_user.id:
                            continue
                        
                        participant_type = p.participant_type
                        if p.participant_type == 'user':
                            participant = User.find_by_id(p.participant_id)
                        elif p.participant_type == 'advertiser':
                            participant = Advertiser.find_by_id(p.participant_id)
                        
                        if participant:
                            break
                
                conversation_dict = {
                    'id': conversation.id,
                    'type': conversation.type,
                    'user_id': conversation.user_id,
                    'last_message_id': conversation.last_message_id,
                    'last_message_at': conversation.last_message_at.isoformat() if conversation.last_message_at else None,
                    'updated_at': conversation.updated_at.isoformat() if conversation.updated_at else None,
                    'participant': {
                        'type': participant_type,
                        'id': participant.id if participant else None,
                        'name': participant.name if participant else 'Unknown User',
                        'username': participant.username if participant else 'unknown',
                        'profile_image_url': getattr(participant, 'profile_image_url', None) if participant else None,
                    } if participant else None,
                    'last_message': {
                        'id': last_message.id,
                        'content': last_message.content,
                        'sender_id': last_message.sender_id,
                        'sender_type': last_message.sender_type or 'user',
                        'created_at': last_message.created_at.isoformat() if last_message.created_at else None
                    } if last_message else None,
                    'unread_count': unread_count
                }
                result.append(conversation_dict)
            
            return result
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve conversations: {str(e)}')
    
    @api.doc('create_conversation')
    @api.expect(conversation_create_model)
    @token_required
    def post(self, current_user):
        """Create a new conversation"""
        try:
            data = request.get_json()
            participant_id = data.get('participant_id')
            conversation_type = data.get('type', 'direct')
            
            if not participant_id:
                api.abort(400, 'participant_id is required')
            
            if participant_id == current_user.id:
                api.abort(400, 'Cannot create conversation with yourself')
            
            # Check if participant exists
            participant = User.find_by_id(participant_id)
            if not participant:
                api.abort(404, 'Participant not found')
            
            # Check if conversation already exists
            existing_conversation = db.session.query(Conversation).join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id,
            ).filter(
                ConversationParticipant.participant_type == 'user',
                ConversationParticipant.participant_id == current_user.id,
                Conversation.type == 'direct',
            ).join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id,
            ).filter(
                ConversationParticipant.participant_type == 'user',
                ConversationParticipant.participant_id == participant_id,
            ).first()
            
            if existing_conversation:
                return {
                    'id': existing_conversation.id,
                    'type': existing_conversation.type,
                    'user_id': existing_conversation.user_id,
                    'last_message_id': existing_conversation.last_message_id,
                    'last_message_at': existing_conversation.last_message_at.isoformat() if existing_conversation.last_message_at else None,
                    'updated_at': existing_conversation.updated_at.isoformat() if existing_conversation.updated_at else None
                }
            
            # Create new conversation
            conversation = Conversation(type=conversation_type, user_id=current_user.id)
            db.session.add(conversation)
            db.session.commit()
            db.session.add(ConversationParticipant(conversation_id=conversation.id, participant_type='user', participant_id=current_user.id))
            db.session.add(ConversationParticipant(conversation_id=conversation.id, participant_type='user', participant_id=participant_id))
            db.session.commit()
            
            return {
                'id': conversation.id,
                'type': conversation.type,
                'user_id': conversation.user_id,
                'last_message_id': conversation.last_message_id,
                'last_message_at': conversation.last_message_at.isoformat() if conversation.last_message_at else None,
                'updated_at': conversation.updated_at.isoformat() if conversation.updated_at else None
            }
            
        except Exception as e:
            api.abort(500, f'Failed to create conversation: {str(e)}')

@api.route('/<int:conversation_id>')
class ConversationDetail(Resource):
    @api.doc('get_conversation')
    @token_required
    def get(self, current_user, conversation_id):
        """Get conversation by ID"""
        try:
            conversation = Conversation.query.get(conversation_id)
            if not conversation:
                api.abort(404, 'Conversation not found')
            
            current_user_type = 'advertiser' if isinstance(current_user, Advertiser) else 'user'
            
            is_participant = ConversationParticipant.query.filter_by(
                conversation_id=conversation.id,
                participant_type=current_user_type,
                participant_id=current_user.id,
            ).first() is not None
            if not is_participant:
                api.abort(403, 'Access denied to this conversation')
            
            # Get last message details
            last_message = None
            if conversation.last_message_id:
                last_message = Message.query.get(conversation.last_message_id)
            
            # FIXED: Get unread count with proper sender type filtering
            unread_count = _get_unread_count_for_conversation(
                conversation.id,
                current_user.id,
                current_user_type
            )
            
            # Get participant info
            participant = None
            participant_type = None
            if conversation.type == 'direct':
                all_participants = ConversationParticipant.query.filter_by(
                    conversation_id=conversation.id
                ).all()
                
                for p in all_participants:
                    if p.participant_type == current_user_type and p.participant_id == current_user.id:
                        continue
                    
                    participant_type = p.participant_type
                    if p.participant_type == 'user':
                        participant = User.find_by_id(p.participant_id)
                    elif p.participant_type == 'advertiser':
                        participant = Advertiser.find_by_id(p.participant_id)
                    
                    if participant:
                        break
            
            return {
                'id': conversation.id,
                'type': conversation.type,
                'user_id': conversation.user_id,
                'last_message_id': conversation.last_message_id,
                'last_message_at': conversation.last_message_at.isoformat() if conversation.last_message_at else None,
                'updated_at': conversation.updated_at.isoformat() if conversation.updated_at else None,
                'participant': {
                    'type': participant_type,
                    'id': participant.id if participant else None,
                    'name': participant.name if participant else 'Unknown User',
                    'username': participant.username if participant else 'unknown',
                    'profile_image_url': getattr(participant, 'profile_image_url', None) if participant else None,
                } if participant else None,
                'last_message': {
                    'id': last_message.id,
                    'content': last_message.content,
                    'sender_id': last_message.sender_id,
                    'sender_type': last_message.sender_type or 'user',
                    'created_at': last_message.created_at.isoformat() if last_message.created_at else None
                } if last_message else None,
                'unread_count': unread_count
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve conversation: {str(e)}')
    
    @api.doc('delete_conversation')
    @token_required
    def delete(self, current_user, conversation_id):
        """Delete conversation"""
        try:
            conversation = Conversation.query.get(conversation_id)
            if not conversation:
                api.abort(404, 'Conversation not found')
            
            current_user_type = 'advertiser' if isinstance(current_user, Advertiser) else 'user'
            
            is_participant = ConversationParticipant.query.filter_by(
                conversation_id=conversation.id,
                participant_type=current_user_type,
                participant_id=current_user.id,
            ).first() is not None
            if not is_participant:
                api.abort(403, 'Can only delete conversations you participate in')
            
            # Delete all messages in the conversation
            Message.query.filter_by(conversation_id=conversation_id).delete()
            
            # Delete conversation participants
            ConversationParticipant.query.filter_by(conversation_id=conversation_id).delete()
            
            # Delete the conversation
            db.session.delete(conversation)
            db.session.commit()
            
            return {'message': 'Conversation deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete conversation: {str(e)}')

@api.route('/stats')
class ConversationStats(Resource):
    @api.doc('get_conversation_stats')
    @token_required
    def get(self, current_user):
        """Get conversation statistics for current user"""
        try:
            current_user_type = 'advertiser' if isinstance(current_user, Advertiser) else 'user'
            
            # Total conversations
            total_conversations = db.session.query(Conversation).join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id
            ).filter(
                ConversationParticipant.participant_type == current_user_type,
                ConversationParticipant.participant_id == current_user.id
            ).count()
            
            # Get all user conversations
            user_conversations = db.session.query(Conversation.id).join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id
            ).filter(
                ConversationParticipant.participant_type == current_user_type,
                ConversationParticipant.participant_id == current_user.id
            ).all()
            conversation_ids = [c[0] for c in user_conversations]
            
            # FIXED: Total unread messages with proper sender type filtering
            total_unread = Message.query.filter(
                Message.conversation_id.in_(conversation_ids),
                Message.is_read == False,
                db.not_(
                    db.and_(
                        Message.sender_id == current_user.id,
                        Message.sender_type == current_user_type
                    )
                )
            ).count()
            
            # Active conversations (with messages in last 30 days)
            from datetime import datetime, timedelta
            thirty_days_ago = datetime.utcnow() - timedelta(days=30)
            
            active_conversations = db.session.query(Conversation).join(
                ConversationParticipant,
                ConversationParticipant.conversation_id == Conversation.id
            ).filter(
                ConversationParticipant.participant_type == current_user_type,
                ConversationParticipant.participant_id == current_user.id,
                Conversation.last_message_at >= thirty_days_ago
            ).count()
            
            return {
                'total_conversations': total_conversations,
                'total_unread_messages': total_unread,
                'active_conversations': active_conversations
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve conversation stats: {str(e)}')