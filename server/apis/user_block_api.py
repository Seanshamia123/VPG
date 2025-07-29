from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Message, db
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
    def get(self):
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
    def post(self):
        """Create a new message"""
        try:
            data = request.get_json()
            
            message = Message(
                conversation_id=data['conversation_id'],
                sender_id=data['sender_id'],
                content=data['content']
            )
            
            db.session.add(message)
            db.session.commit()
            
            return {
                'id': message.id,
                'conversation_id': message.conversation_id,
                'sender_id': message.sender_id,
                'content': message.content,
                'is_read': message.is_read,
                'created_at': message.created_at.isoformat() if message.created_at else None,
                'updated_at': message.updated_at.isoformat() if message.updated_at else None
            }, 201
            
        except Exception as e:
            api.abort(500, f'Failed to create message: {str(e)}')

@api.route('/<int:message_id>')
class MessageDetail(Resource):
    @api.doc('get_message')
    @api.marshal_with(message_model)
    def get(self, message_id):
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
    def put(self, message_id):
        """Update message"""
        try:
            message = Message.query.get(message_id)
            if not message:
                api.abort(404, 'Message not found')
            
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
    def delete(self, message_id):
        """Delete message"""
        try:
            message = Message.query.get(message_id)
            if not message:
                api.abort(404, 'Message not found')
            
            db.session.delete(message)
            db.session.commit()
            
            return {'message': 'Message deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete message: {str(e)}')

@api.route('/conversation/<int:conversation_id>')
class ConversationMessages(Resource):
    @api.doc('get_conversation_messages')
    @api.marshal_list_with(message_model)
    def get(self, conversation_id):
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