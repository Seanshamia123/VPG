from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import User, Post, UserBlock, db
from .decorators import token_required
from server.cloudinary_service import get_service as get_cloudinary_service
from flask_restx import fields

api = Namespace('users', description='User management operations')

# Models for Swagger documentation
user_model = api.model('User', {
    'id': fields.Integer(description='User ID'),
    'username': fields.String(description='Username'),
    'name': fields.String(description='Full name'),
    'email': fields.String(description='Email address'),
    'phone_number': fields.String(description='Phone number'),
    'location': fields.String(description='Location'),
    'gender': fields.String(description='Gender'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp'),
    'last_active': fields.String(description='Last active timestamp')
})

user_update_model = api.model('UserUpdate', {
    'name': fields.String(description='Full name'),
    'phone_number': fields.String(description='Phone number'),
    'location': fields.String(description='Location')
})

user_avatar_model = api.model('UserAvatar', {
    'image': fields.String(required=True, description='Base64 encoded image data')
})

user_block_model = api.model('UserBlock', {
    'blocked_id': fields.Integer(required=True, description='ID of user to block')
})

@api.route('/')
class UserList(Resource):
    @api.doc('list_users')
    @api.marshal_list_with(user_model)
    @token_required
    def get(self):
        """Get all active users"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            location = request.args.get('location')
            
            query = User.query
            
            if location:
                query = query.filter_by(location=location)
            
            users = query.paginate(
                page=page, 
                per_page=per_page, 
                error_out=False
            )
            
            return [user.to_dict_safe() for user in users.items]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve users: {str(e)}')

@api.route('/<int:user_id>')
class UserDetail(Resource):
    @api.doc('get_user')
    @api.marshal_with(user_model)
    @token_required
    def get(self, current_user, user_id):
        """Get user by ID"""
        try:
            user = User.find_by_id(user_id)
            if not user:
                api.abort(404, 'User not found')
            
            return user.to_dict_safe()
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve user: {str(e)}')
    
    @api.doc('update_user')
    @api.expect(user_update_model)
    @api.marshal_with(user_model)
    @token_required
    def put(self, current_user, user_id):
        """Update user profile (only own profile)"""
        try:
            if current_user.id != user_id:
                api.abort(403, 'Can only update your own profile')
            
            data = request.get_json()
            current_user.update(**data)
            
            return current_user.to_dict_safe()
            
        except Exception as e:
            api.abort(500, f'Failed to update user: {str(e)}')
    
    @api.doc('delete_user')
    @token_required
    def delete(self, current_user, user_id):
        """Delete user account (only own account)"""
        try:
            if current_user.id != user_id:
                api.abort(403, 'Can only delete your own account')
            
            current_user.delete()
            return {'message': 'User account deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete user: {str(e)}')

@api.route('/<int:user_id>/posts')
class UserPosts(Resource):
    @api.doc('get_user_posts')
    @token_required
    def get(self, current_user, user_id):
        """Get posts by user"""
        try:
            user = User.find_by_id(user_id)
            if not user:
                api.abort(404, 'User not found')
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            posts = Post.query.filter_by(user_id=user_id).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            return {
                'posts': [post.to_dict() for post in posts.items],
                'total': posts.total,
                'pages': posts.pages,
                'current_page': posts.page
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve user posts: {str(e)}')

@api.route('/profile')
class UserProfile(Resource):
    @api.doc('get_current_user_profile')
    @api.marshal_with(user_model)
    @token_required
    def get(self, current_user):
        """Get current user profile"""
        try:
            return current_user.to_dict()
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve profile: {str(e)}')

@api.route('/block')
class BlockUser(Resource):
    @api.doc('block_user')
    @api.expect(user_block_model)
    @token_required
    def post(self, current_user):
        """Block a user"""
        try:
            data = request.get_json()
            blocked_id = data.get('blocked_id')
            
            if not blocked_id:
                api.abort(400, 'blocked_id is required')
            
            if blocked_id == current_user.id:
                api.abort(400, 'Cannot block yourself')
            
            # Check if user exists
            blocked_user = User.find_by_id(blocked_id)
            if not blocked_user:
                api.abort(404, 'User to block not found')
            
            # Check if already blocked
            existing_block = UserBlock.query.filter_by(
                blocker_id=current_user.id,
                blocked_id=blocked_id
            ).first()
            
            if existing_block:
                api.abort(400, 'User is already blocked')
            
            # Create block
            user_block = UserBlock(
                blocker_id=current_user.id,
                blocked_id=blocked_id
            )
            db.session.add(user_block)
            db.session.commit()
            
            return {'message': 'User blocked successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to block user: {str(e)}')

@api.route('/unblock/<int:blocked_id>')
class UnblockUser(Resource):
    @api.doc('unblock_user')
    @token_required
    def delete(self, current_user, blocked_id):
        """Unblock a user"""
        user_block = UserBlock.query.filter_by(
            blocker_id=current_user.id,
            blocked_id=blocked_id
        ).first()

        if not user_block:
            api.abort(404, 'Block relationship not found')

        db.session.delete(user_block)
        db.session.commit()

        return {'message': 'User unblocked successfully'}

@api.route('/blocked')
class BlockedUsers(Resource):
    @api.doc('get_blocked_users')
    @token_required
    def get(self, current_user):
        """Get list of blocked users"""
        try:
            blocked_users = db.session.query(User).join(
                UserBlock, User.id == UserBlock.blocked_id
            ).filter(UserBlock.blocker_id == current_user.id).all()
            
            return {
                'blocked_users': [user.to_dict_safe() for user in blocked_users]
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve blocked users: {str(e)}')

@api.route('/search')
class SearchUsers(Resource):
    @api.doc('search_users')
    @token_required
    def get(self, current_user):
        """Search users by name or username"""
        try:
            query = request.args.get('q', '').strip()
            if not query:
                api.abort(400, 'Search query is required')
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            users = User.query.filter(
                db.or_(
                    User.name.ilike(f'%{query}%'),
                    User.username.ilike(f'%{query}%')
                )
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            return {
                'users': [user.to_dict_safe() for user in users.items],
                'total': users.total,
                'pages': users.pages,
                'current_page': users.page
            }
            
        except Exception as e:
            api.abort(500, f'Failed to search users: {str(e)}')
@api.route('/<int:user_id>/avatar')
class UserAvatar(Resource):
    @api.doc('upload_user_avatar')
    @api.expect(user_avatar_model)
    @token_required
    def post(self, current_user, user_id):
        """Upload user profile avatar to Cloudinary and update profile_image_url."""
        try:
            if current_user.id != user_id:
                api.abort(403, 'Can only update your own profile')
            data = request.get_json()
            if not data or not data.get('image'):
                api.abort(400, 'image is required')
            cloudinary_service = get_cloudinary_service()
            result = cloudinary_service.upload_base64_image(
                data['image'],
                folder='vpg/users',
                public_id=f'user_{user_id}'
            )
            if not result['success']:
                api.abort(400, f"Image upload failed: {result['error']}")
            current_user.profile_image_url = result['secure_url']
            db.session.commit()
            return {
                'message': 'Avatar updated',
                'profile_image_url': current_user.profile_image_url
            }, 201
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to upload avatar: {str(e)}')
