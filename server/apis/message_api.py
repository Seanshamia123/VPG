from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Message, Conversation, ConversationParticipant, User, Advertiser, db
from flask import current_app
from .decorators import token_required
from datetime import datetime

api = Namespace('messages', description='Message management operations')

# Models for Swagger documentation
message_model = api.model('Message', {
    'id': fields.Integer(description='Message ID'),
    'conversation_id': fields.Integer(description='Conversation ID'),
    'sender_id': fields.Integer(description='Sender user ID'),
    'content': fields.String(description='Message content'),
    'is_read': fields.Boolean(description='Read status'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp')
})

message_create_model = api.model('MessageCreate', {
    'conversation_id': fields.Integer(required=True, description='Conversation ID'),
    'sender_id': fields.Integer(required=True, description='Sender user ID'),
    'content': fields.String(required=True, description='Message content')
})

message_update_model = api.model('MessageUpdate', {
    'content': fields.String(description='Message content'),
    'is_read': fields.Boolean(description='Read status')
})

@api.route('/')
class MessageList(Resource):
    @api.doc('list_messages')
    @api.marshal_list_with(message_model)
    @token_required
    def get(self, current_user):
        """Get all messages"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            conversation_id = request.args.get('conversation_id', type=int)
            sender_id = request.args.get('sender_id', type=int)
            
            query = Message.query
            
            if conversation_id:
                query = query.filter_by(conversation_id=conversation_id)
            
            if sender_id:
                query = query.filter_by(sender_id=sender_id)
            
            messages = query.order_by(Message.created_at.desc()).paginate(
                page=page, 
                per_page=per_page, 
                error_out=False
            )
            
            return [{
                'id': msg.id,
                'conversation_id': msg.conversation_id,
                'sender_id': msg.sender_id,
                'content': msg.content,
                'is_read': msg.is_read,
                'created_at': msg.created_at.isoformat() if msg.created_at else None,
                'updated_at': msg.updated_at.isoformat() if msg.updated_at else None
            } for msg in messages.items]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve messages: {str(e)}')
    
    @api.doc('create_message')
    @api.expect(message_create_model)
    @api.marshal_with(message_model, code=201)
    @token_required
    def post(self, current_user):
        """Create a new message"""
        try:
            data = request.get_json()
            if data.get('sender_id') != current_user.id:
                api.abort(403, 'Sender does not match current user')
            
            message = Message(
                conversation_id=data['conversation_id'],
                sender_id=data['sender_id'],
                content=data['content']
            )
            
            db.session.add(message)
            db.session.commit()

            payload = {
                'id': message.id,
                'conversation_id': message.conversation_id,
                'sender_id': message.sender_id,
                'content': message.content,
                'is_read': message.is_read,
                'created_at': message.created_at.isoformat() if message.created_at else None,
                'updated_at': message.updated_at.isoformat() if message.updated_at else None
            }
            # Emit websocket event to room for this conversation
            try:
                socketio = current_app.extensions.get('socketio')
                if socketio:
                    socketio.emit('new_message', payload, room=f"conv_{message.conversation_id}")
            except Exception:
                pass

            return payload, 201
            
        except Exception as e:
            api.abort(500, f'Failed to create message: {str(e)}')

@api.route('/<int:message_id>')
class MessageDetail(Resource):
    @api.doc('get_message')
    @api.marshal_with(message_model)
    @token_required
    def get(self, current_user, message_id):
        """Get message by ID"""
        try:
            message = Message.query.get(message_id)
            if not message:
                api.abort(404, 'Message not found')
            
            return {
                'id': message.id,
                'conversation_id': message.conversation_id,
                'sender_id': message.sender_id,
                'content': message.content,
                'is_read': message.is_read,
                'created_at': message.created_at.isoformat() if message.created_at else None,
                'updated_at': message.updated_at.isoformat() if message.updated_at else None
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve message: {str(e)}')
    
    @api.doc('update_message')
    @api.expect(message_update_model)
    @api.marshal_with(message_model)
    @token_required
    def put(self, current_user, message_id):
        """Update message"""
        try:
            message = Message.query.get(message_id)
            if not message:
                api.abort(404, 'Message not found')
            if message.sender_id != current_user.id:
                api.abort(403, 'Can only update your own messages')
            
            data = request.get_json()
            
            if 'content' in data:
                message.content = data['content']
            if 'is_read' in data:
                message.is_read = data['is_read']
            
            message.updated_at = datetime.utcnow()
            db.session.commit()
            
            return {
                'id': message.id,
                'conversation_id': message.conversation_id,
                'sender_id': message.sender_id,
                'content': message.content,
                'is_read': message.is_read,
                'created_at': message.created_at.isoformat() if message.created_at else None,
                'updated_at': message.updated_at.isoformat() if message.updated_at else None
            }
            
        except Exception as e:
            api.abort(500, f'Failed to update message: {str(e)}')
    
    @api.doc('delete_message')
    @token_required
    def delete(self, current_user, message_id):
        """Delete message"""
        try:
            message = Message.query.get(message_id)
            if not message:
                api.abort(404, 'Message not found')
            if message.sender_id != current_user.id:
                api.abort(403, 'Can only delete your own messages')
            
            db.session.delete(message)
            db.session.commit()
            
            return {'message': 'Message deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete message: {str(e)}')

@api.route('/conversation/<int:conversation_id>')
class ConversationMessages(Resource):
    @api.doc('get_conversation_messages')
    @api.marshal_list_with(message_model)
    @token_required
    def get(self, current_user, conversation_id):
        """Get all messages in a conversation"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)
            
            messages = Message.query.filter_by(
                conversation_id=conversation_id
            ).order_by(Message.created_at.asc()).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            return [{
                'id': msg.id,
                'conversation_id': msg.conversation_id,
                'sender_id': msg.sender_id,
                'content': msg.content,
                'is_read': msg.is_read,
                'created_at': msg.created_at.isoformat() if msg.created_at else None,
                'updated_at': msg.updated_at.isoformat() if msg.updated_at else None
            } for msg in messages.items]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve conversation messages: {str(e)}')

@api.route('/recent')
class RecentConversations(Resource):
    @api.doc('get_recent_conversations')
    @token_required
    def get(self, current_user):
        """Get recent conversations for the current user with last message and sender info"""
        try:
            # Only supports regular users for now (conversations.user_id links to users table)
            if not isinstance(current_user, User):
                return {'conversations': [], 'total': 0}, 200

            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)

            query = Conversation.query.filter_by(user_id=current_user.id).order_by(Conversation.last_message_at.desc())
            pagination = query.paginate(page=page, per_page=per_page, error_out=False)

            items = []
            for conv in pagination.items:
                last_msg = Message.query.get(conv.last_message_id) if conv.last_message_id else None
                sender = User.find_by_id(last_msg.sender_id) if last_msg else None

                # Determine the other participant (user or advertiser)
                other_part = ConversationParticipant.query.filter_by(conversation_id=conv.id).filter(
                    ConversationParticipant.participant_type.in_(['user', 'advertiser'])
                ).all()
                participant_info = None
                for p in other_part:
                    if p.participant_type == 'user' and p.participant_id != current_user.id:
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
                    if p.participant_type == 'advertiser':
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
                    'last_message': {
                        'id': last_msg.id if last_msg else None,
                        'content': last_msg.content if last_msg else None,
                        'created_at': last_msg.created_at.isoformat() if last_msg and last_msg.created_at else None,
                        'sender': {
                            'id': sender.id if sender else None,
                            'name': sender.name if sender else None,
                            'username': sender.username if sender else None,
                        } if sender else None,
                    } if last_msg else None,
                    'last_message_at': conv.last_message_at.isoformat() if conv.last_message_at else None,
                })

            return {
                'conversations': items,
                'total': pagination.total,
                'pages': pagination.pages,
                'current_page': pagination.page,
            }
        except Exception as e:
            api.abort(500, f'Failed to retrieve recent conversations: {str(e)}')

@api.route('/conversation/<int:conversation_id>/mark-read')
class MarkConversationRead(Resource):
    @api.doc('mark_conversation_read')
    def post(self, conversation_id):
        """Mark all messages in a conversation as read"""
        try:
            user_id = request.json.get('user_id')
            if not user_id:
                api.abort(400, 'user_id is required')
            
            # Mark all messages in conversation as read (except those sent by the user)
            Message.query.filter(
                Message.conversation_id == conversation_id,
                Message.sender_id != user_id,
                Message.is_read == False
            ).update({'is_read': True})
            
            db.session.commit()
            
            return {'message': 'Messages marked as read successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to mark messages as read: {str(e)}')

@api.route('/unread/<int:user_id>')
class UnreadMessages(Resource):
    @api.doc('get_unread_messages')
    def get(self, user_id):
        """Get count of unread messages for a user"""
        try:
            # Count unread messages where user is not the sender
            unread_count = Message.query.filter(
                Message.sender_id != user_id,
                Message.is_read == False
            ).count()
            
            return {'unread_count': unread_count}
            
        except Exception as e:
            api.abort(500, f'Failed to get unread count: {str(e)}')
