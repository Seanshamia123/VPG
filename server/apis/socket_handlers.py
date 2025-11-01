from flask_socketio import emit, join_room, leave_room, disconnect
from models import User, Advertiser

def register_socket_handlers(socketio):
    """Register all Socket.IO event handlers"""
    
    @socketio.on('connect')
    def handle_connect():
        """Handle client connection"""
        print(f'Client connected: {request.sid}')
        emit('connect_response', {
            'message': 'Connected to server',
            'data': 'Connected'
        })
    
    @socketio.on('disconnect')
    def handle_disconnect():
        """Handle client disconnection"""
        print(f'Client disconnected: {request.sid}')
    
    @socketio.on('join_conversation')
    def handle_join_conversation(data):
        """
        Handle client joining a conversation room.
        Client emits: {'conversation_id': 123}
        """
        try:
            conversation_id = data.get('conversation_id')
            if not conversation_id:
                emit('error', {'message': 'conversation_id is required'})
                return
            
            room = f"conv_{conversation_id}"
            join_room(room)
            
            print(f'Client {request.sid} joined conversation {conversation_id}')
            
            emit('joined_conversation', {
                'conversation_id': conversation_id,
                'status': 'success',
                'message': 'Successfully joined conversation'
            })
            
            # Optionally notify others in the room
            emit('user_joined_conversation', {
                'conversation_id': conversation_id,
                'user_count': len(socketio.server.rooms.get(room, []))
            }, room=room, skip_sid=True)
            
        except Exception as e:
            print(f'Error in join_conversation: {str(e)}')
            emit('error', {'message': f'Failed to join conversation: {str(e)}'})
    
    @socketio.on('leave_conversation')
    def handle_leave_conversation(data):
        """
        Handle client leaving a conversation room.
        Client emits: {'conversation_id': 123}
        """
        try:
            conversation_id = data.get('conversation_id')
            if not conversation_id:
                emit('error', {'message': 'conversation_id is required'})
                return
            
            room = f"conv_{conversation_id}"
            leave_room(room)
            
            print(f'Client {request.sid} left conversation {conversation_id}')
            
            emit('left_conversation', {
                'conversation_id': conversation_id,
                'status': 'success',
                'message': 'Successfully left conversation'
            })
            
            # Notify others in the room
            emit('user_left_conversation', {
                'conversation_id': conversation_id
            }, room=room)
            
        except Exception as e:
            print(f'Error in leave_conversation: {str(e)}')
            emit('error', {'message': f'Failed to leave conversation: {str(e)}'})
    
    @socketio.on('typing')
    def handle_typing(data):
        """
        Handle typing indicator.
        Client emits: {'conversation_id': 123, 'user_id': 456, 'username': 'john'}
        """
        try:
            conversation_id = data.get('conversation_id')
            user_id = data.get('user_id')
            username = data.get('username', 'Unknown')
            
            if not conversation_id or not user_id:
                emit('error', {'message': 'conversation_id and user_id are required'})
                return
            
            room = f"conv_{conversation_id}"
            
            # Broadcast typing indicator to others in the conversation
            emit('user_typing', {
                'conversation_id': conversation_id,
                'user_id': user_id,
                'username': username
            }, room=room, skip_sid=True)  # Don't send back to sender
            
        except Exception as e:
            print(f'Error in typing: {str(e)}')
    
    @socketio.on('stop_typing')
    def handle_stop_typing(data):
        """
        Handle stop typing indicator.
        Client emits: {'conversation_id': 123, 'user_id': 456}
        """
        try:
            conversation_id = data.get('conversation_id')
            user_id = data.get('user_id')
            
            if not conversation_id or not user_id:
                emit('error', {'message': 'conversation_id and user_id are required'})
                return
            
            room = f"conv_{conversation_id}"
            
            # Broadcast stop typing to others
            emit('user_stopped_typing', {
                'conversation_id': conversation_id,
                'user_id': user_id
            }, room=room, skip_sid=True)
            
        except Exception as e:
            print(f'Error in stop_typing: {str(e)}')
    
    @socketio.on('message_read')
    def handle_message_read(data):
        """
        Handle message read receipt.
        Client emits: {'conversation_id': 123, 'message_id': 789, 'user_id': 456}
        """
        try:
            conversation_id = data.get('conversation_id')
            message_id = data.get('message_id')
            user_id = data.get('user_id')
            
            if not all([conversation_id, message_id, user_id]):
                emit('error', {'message': 'conversation_id, message_id, and user_id are required'})
                return
            
            room = f"conv_{conversation_id}"
            
            # Broadcast read receipt to others
            emit('message_read_receipt', {
                'conversation_id': conversation_id,
                'message_id': message_id,
                'user_id': user_id
            }, room=room)
            
        except Exception as e:
            print(f'Error in message_read: {str(e)}')