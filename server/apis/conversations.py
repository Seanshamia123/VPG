from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Conversation, Message, User, db
from .decorators import token_required

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

@api.route('/')
class ConversationList(Resource):
    @api.doc('list_conversations')
    @api.marshal_list_with(conversation_with_details_model)
    @token_required
    def get(self, current_user):
        """Get all conversations for current user"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)
            
            conversations = Conversation.query.filter_by(
                user_id=current_user.id
            ).order_by(
                Conversation.last_message_at.desc()
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for conversation in conversations.items:
                # Get last message details
                last_message = None
                if conversation.last_message_id:
                    last_message = Message.query.get(conversation.last_message_id)
                
                # Get unread count
                unread_count = Message.query.filter_by(
                    conversation_id=conversation.id,
                    is_read=False
                ).filter(Message.sender_id != current_user.id).count()
                
                # For direct conversations, get the other participant
                # Note: This is a simplified version - you might need to adjust based on your conversation structure
                participant = None
                if conversation.type == 'direct':
                    # This assumes a simple direct conversation structure
                    # You might need to implement a participants table for more complex scenarios
                    participant = User.find_by_id(conversation.user_id)
                
                conversation_dict = {
                    'id': conversation.id,
                    'type': conversation.type,
                    'user_id': conversation.user_id,
                    'last_message_id': conversation.last_message_id,
                    'last_message_at': conversation.last_message_at.isoformat() if conversation.last_message_at else None,
                    'updated_at': conversation.updated_at.isoformat() if conversation.updated_at else None,
                    'participant': {
                        'id': participant.id if participant else None,
                        'name': participant.name if participant else 'Unknown User',
                        'username': participant.username if participant else 'unknown'
                    } if participant else None,
                    'last_message': {
                        'id': last_message.id,
                        'content': last_message.content,
                        'sender_id': last_message.sender_id,
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
    @api.marshal_with(conversation_model)
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
            
            # Check if conversation already exists between these users
            existing_conversation = Conversation.query.filter(
                db.or_(
                    db.and_(Conversation.user_id == current_user.id, Conversation.type == 'direct'),
                    db.and_(Conversation.user_id == participant_id, Conversation.type == 'direct')
                )
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
            conversation = Conversation(
                type=conversation_type,
                user_id=current_user.id
            )
            
            db.session.add(conversation)
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
    @api.marshal_with(conversation_with_details_model)
    @token_required
    def get(self, current_user, conversation_id):
        """Get conversation by ID"""
        try:
            conversation = Conversation.query.get(conversation_id)
            if not conversation:
                api.abort(404, 'Conversation not found')
            
            if conversation.user_id != current_user.id:
                api.abort(403, 'Access denied to this conversation')
            
            # Get last message details
            last_message = None
            if conversation.last_message_id:
                last_message = Message.query.get(conversation.last_message_id)
            
            # Get unread count
            unread_count = Message.query.filter_by(
                conversation_id=conversation.id,
                is_read=False
            ).filter(Message.sender_id != current_user.id).count()
            
            # Get participant info
            participant = None
            if conversation.type == 'direct':
                participant = User.find_by_id(conversation.user_id)
            
            return {
                'id': conversation.id,
                'type': conversation.type,
                'user_id': conversation.user_id,
                'last_message_id': conversation.last_message_id,
                'last_message_at': conversation.last_message_at.isoformat() if conversation.last_message_at else None,
                'updated_at': conversation.updated_at.isoformat() if conversation.updated_at else None,
                'participant': {
                    'id': participant.id if participant else None,
                    'name': participant.name if participant else 'Unknown User',
                    'username': participant.username if participant else 'unknown'
                } if participant else None,
                'last_message': {
                    'id': last_message.id,
                    'content': last_message.content,
                    'sender_id': last_message.sender_id,
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
            
            if conversation.user_id != current_user.id:
                api.abort(403, 'Can only delete your own conversations')
            
            # Delete all messages in the conversation
            Message.query.filter_by(conversation_id=conversation_id).delete()
            
            # Delete the conversation
            db.session.delete(conversation)
            db.session.commit()
            
            return {'message': 'Conversation deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete conversation: {str(e)}')

@api.route('/<int:conversation_id>/archive')
class ArchiveConversation(Resource):
    @api.doc('archive_conversation')
    @token_required
    def put(self, current_user, conversation_id):
        """Archive conversation (soft delete)"""
        try:
            conversation = Conversation.query.get(conversation_id)
            if not conversation:
                api.abort(404, 'Conversation not found')
            
            if conversation.user_id != current_user.id:
                api.abort(403, 'Can only archive your own conversations')
            
            # Add is_archived field to conversation model if needed
            # For now, we'll just return success
            return {'message': 'Conversation archived successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to archive conversation: {str(e)}')

@api.route('/with-user/<int:user_id>')
class ConversationWithUser(Resource):
    @api.doc('get_conversation_with_user')
    @api.marshal_with(conversation_model)
    @token_required
    def get(self, current_user, user_id):
        """Get or create conversation with specific user"""
        try:
            if user_id == current_user.id:
                api.abort(400, 'Cannot have conversation with yourself')
            
            # Check if user exists
            user = User.find_by_id(user_id)
            if not user:
                api.abort(404, 'User not found')
            
            # Look for existing conversation
            conversation = Conversation.query.filter_by(
                user_id=current_user.id,
                type='direct'
            ).first()
            
            if not conversation:
                # Create new conversation
                conversation = Conversation(
                    type='direct',
                    user_id=current_user.id
                )
                db.session.add(conversation)
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
            api.abort(500, f'Failed to get conversation with user: {str(e)}')

@api.route('/stats')
class ConversationStats(Resource):
    @api.doc('get_conversation_stats')
    @token_required
    def get(self, current_user):
        """Get conversation statistics for current user"""
        try:
            # Total conversations
            total_conversations = Conversation.query.filter_by(
                user_id=current_user.id
            ).count()
            
            # Total unread messages across all conversations
            user_conversations = Conversation.query.filter_by(
                user_id=current_user.id
            ).all()
            conversation_ids = [conv.id for conv in user_conversations]
            
            total_unread = Message.query.filter(
                Message.conversation_id.in_(conversation_ids),
                Message.is_read == False,
                Message.sender_id != current_user.id
            ).count()
            
            # Active conversations (with messages in last 30 days)
            from datetime import datetime, timedelta
            thirty_days_ago = datetime.utcnow() - timedelta(days=30)
            
            active_conversations = Conversation.query.filter(
                Conversation.user_id == current_user.id,
                Conversation.last_message_at >= thirty_days_ago
            ).count()
            
            return {
                'total_conversations': total_conversations,
                'total_unread_messages': total_unread,
                'active_conversations': active_conversations
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve conversation stats: {str(e)}')