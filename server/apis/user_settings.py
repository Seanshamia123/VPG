from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import UserSetting, User, db
from .decorators import token_required
from datetime import datetime

api = Namespace('user-settings', description='User settings management operations')

# Models for Swagger documentation
user_setting_model = api.model('UserSetting', {
    'id': fields.Integer(description='User setting ID'),
    'user_id': fields.Integer(description='User ID'),
    'notification_enabled': fields.Boolean(description='Notification enabled status'),
    'dark_mode_enabled': fields.Boolean(description='Dark mode enabled status'),
    'show_online_status': fields.Boolean(description='Show online status'),
    'read_receipts': fields.Boolean(description='Read receipts enabled'),
    'selected_language': fields.String(description='Selected language code'),
    'selected_theme': fields.String(description='Selected theme'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp')
})

user_setting_create_model = api.model('UserSettingCreate', {
    'user_id': fields.Integer(required=True, description='User ID'),
    'notification_enabled': fields.Boolean(description='Notification enabled status', default=True),
    'dark_mode_enabled': fields.Boolean(description='Dark mode enabled status', default=False),
    'show_online_status': fields.Boolean(description='Show online status', default=True),
    'read_receipts': fields.Boolean(description='Read receipts enabled', default=True),
    'selected_language': fields.String(description='Selected language code', default='en'),
    'selected_theme': fields.String(description='Selected theme', default='light')
})

user_setting_update_model = api.model('UserSettingUpdate', {
    'notification_enabled': fields.Boolean(description='Notification enabled status'),
    'dark_mode_enabled': fields.Boolean(description='Dark mode enabled status'),
    'show_online_status': fields.Boolean(description='Show online status'),
    'read_receipts': fields.Boolean(description='Read receipts enabled'),
    'selected_language': fields.String(description='Selected language code'),
    'selected_theme': fields.String(description='Selected theme')
})

@api.route('/')
class UserSettingList(Resource):
    @api.doc('list_user_settings')
    @api.marshal_list_with(user_setting_model)
    def get(self):
        """Get all user settings"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            user_id = request.args.get('user_id', type=int)
            
            query = UserSetting.query
            
            if user_id:
                query = query.filter_by(user_id=user_id)
            
            settings = query.paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            return [setting.to_dict() for setting in settings.items]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve user settings: {str(e)}')
    
    @api.doc('create_user_setting')
    @api.expect(user_setting_create_model)
    @api.marshal_with(user_setting_model, code=201)
    @token_required
    def post(self, current_user):
        """Create new user settings"""
        try:
            data = request.get_json()
            if not isinstance(current_user, User) or current_user.id != data.get('user_id'):
                api.abort(403, 'Can only create settings for your own user')
            
            # Check if user settings already exist for this user
            existing_settings = UserSetting.query.filter_by(user_id=data['user_id']).first()
            if existing_settings:
                api.abort(400, f'Settings already exist for user {data["user_id"]}')
            
            user_setting = UserSetting(
                user_id=data['user_id'],
                notification_enabled=data.get('notification_enabled', True),
                dark_mode_enabled=data.get('dark_mode_enabled', False),
                show_online_status=data.get('show_online_status', True),
                read_receipts=data.get('read_receipts', True),
                selected_language=data.get('selected_language', 'en'),
                selected_theme=data.get('selected_theme', 'light')
            )
            
            db.session.add(user_setting)
            db.session.commit()
            
            return user_setting.to_dict(), 201
            
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to create user settings: {str(e)}')

@api.route('/<int:setting_id>')
class UserSettingDetail(Resource):
    @api.doc('get_user_setting')
    @api.marshal_with(user_setting_model)
    @token_required
    def get(self, current_user, setting_id):
        """Get user setting by ID"""
        try:
            user_setting = UserSetting.query.get(setting_id)
            if not user_setting:
                api.abort(404, 'User setting not found')
            if not isinstance(current_user, User) or current_user.id != user_setting.user_id:
                api.abort(403, 'Access denied to these settings')
            
            return user_setting.to_dict()
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve user setting: {str(e)}')
    
    @api.doc('update_user_setting')
    @api.expect(user_setting_update_model)
    @api.marshal_with(user_setting_model)
    @token_required
    def put(self, current_user, setting_id):
        """Update user settings"""
        try:
            user_setting = UserSetting.query.get(setting_id)
            if not user_setting:
                api.abort(404, 'User setting not found')
            if not isinstance(current_user, User) or current_user.id != user_setting.user_id:
                api.abort(403, 'Can only update your own settings')
            
            data = request.get_json()
            
            # Update fields if provided
            if 'notification_enabled' in data:
                user_setting.notification_enabled = data['notification_enabled']
            if 'dark_mode_enabled' in data:
                user_setting.dark_mode_enabled = data['dark_mode_enabled']
            if 'show_online_status' in data:
                user_setting.show_online_status = data['show_online_status']
            if 'read_receipts' in data:
                user_setting.read_receipts = data['read_receipts']
            if 'selected_language' in data:
                user_setting.selected_language = data['selected_language']
            if 'selected_theme' in data:
                user_setting.selected_theme = data['selected_theme']
            
            user_setting.updated_at = datetime.utcnow()
            db.session.commit()
            
            return user_setting.to_dict()
            
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to update user setting: {str(e)}')
    
    @api.doc('delete_user_setting')
    @token_required
    def delete(self, current_user, setting_id):
        """Delete user settings"""
        try:
            user_setting = UserSetting.query.get(setting_id)
            if not user_setting:
                api.abort(404, 'User setting not found')
            if not isinstance(current_user, User) or current_user.id != user_setting.user_id:
                api.abort(403, 'Can only delete your own settings')
            
            db.session.delete(user_setting)
            db.session.commit()
            
            return {'message': 'User settings deleted successfully'}
            
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to delete user setting: {str(e)}')

@api.route('/user/<int:user_id>')
class UserSettingByUser(Resource):
    @api.doc('get_user_settings_by_user_id')
    @api.marshal_with(user_setting_model)
    @token_required
    def get(self, current_user, user_id):
        """Get user settings by user ID"""
        try:
            user_setting = UserSetting.query.filter_by(user_id=user_id).first()
            if not user_setting:
                api.abort(404, f'Settings not found for user {user_id}')
            if not isinstance(current_user, User) or current_user.id != user_id:
                api.abort(403, 'Access denied to these settings')
            
            return user_setting.to_dict()
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve user settings: {str(e)}')
    
    @api.doc('update_user_settings_by_user_id')
    @api.expect(user_setting_update_model)
    @api.marshal_with(user_setting_model)
    @token_required
    def put(self, current_user, user_id):
        """Update user settings by user ID"""
        try:
            user_setting = UserSetting.query.filter_by(user_id=user_id).first()
            if not user_setting:
                api.abort(404, f'Settings not found for user {user_id}')
            if not isinstance(current_user, User) or current_user.id != user_id:
                api.abort(403, 'Can only update your own settings')
            
            data = request.get_json()
            
            # Update fields if provided
            if 'notification_enabled' in data:
                user_setting.notification_enabled = data['notification_enabled']
            if 'dark_mode_enabled' in data:
                user_setting.dark_mode_enabled = data['dark_mode_enabled']
            if 'show_online_status' in data:
                user_setting.show_online_status = data['show_online_status']
            if 'read_receipts' in data:
                user_setting.read_receipts = data['read_receipts']
            if 'selected_language' in data:
                user_setting.selected_language = data['selected_language']
            if 'selected_theme' in data:
                user_setting.selected_theme = data['selected_theme']
            
            user_setting.updated_at = datetime.utcnow()
            db.session.commit()
            
            return user_setting.to_dict()
            
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to update user settings: {str(e)}')

@api.route('/user/<int:user_id>/create-or-update')
class UserSettingCreateOrUpdate(Resource):
    @api.doc('create_or_update_user_settings')
    @api.expect(user_setting_update_model)
    @api.marshal_with(user_setting_model)
    @token_required
    def post(self, current_user, user_id):
        """Create or update user settings for a specific user"""
        try:
            data = request.get_json()
            if not isinstance(current_user, User) or current_user.id != user_id:
                api.abort(403, 'Can only modify your own settings')
            
            # Try to find existing settings
            user_setting = UserSetting.query.filter_by(user_id=user_id).first()
            
            if user_setting:
                # Update existing settings
                if 'notification_enabled' in data:
                    user_setting.notification_enabled = data['notification_enabled']
                if 'dark_mode_enabled' in data:
                    user_setting.dark_mode_enabled = data['dark_mode_enabled']
                if 'show_online_status' in data:
                    user_setting.show_online_status = data['show_online_status']
                if 'read_receipts' in data:
                    user_setting.read_receipts = data['read_receipts']
                if 'selected_language' in data:
                    user_setting.selected_language = data['selected_language']
                if 'selected_theme' in data:
                    user_setting.selected_theme = data['selected_theme']
                
                user_setting.updated_at = datetime.utcnow()
            else:
                # Create new settings
                user_setting = UserSetting(
                    user_id=user_id,
                    notification_enabled=data.get('notification_enabled', True),
                    dark_mode_enabled=data.get('dark_mode_enabled', False),
                    show_online_status=data.get('show_online_status', True),
                    read_receipts=data.get('read_receipts', True),
                    selected_language=data.get('selected_language', 'en'),
                    selected_theme=data.get('selected_theme', 'light')
                )
                db.session.add(user_setting)
            
            db.session.commit()
            return user_setting.to_dict()
            
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to create or update user settings: {str(e)}')

@api.route('/reset/<int:user_id>')
class UserSettingReset(Resource):
    @api.doc('reset_user_settings')
    @api.marshal_with(user_setting_model)
    def post(self, user_id):
        """Reset user settings to default values"""
        try:
            user_setting = UserSetting.query.filter_by(user_id=user_id).first()
            if not user_setting:
                api.abort(404, f'Settings not found for user {user_id}')
            
            # Reset to default values
            user_setting.notification_enabled = True
            user_setting.dark_mode_enabled = False
            user_setting.show_online_status = True
            user_setting.read_receipts = True
            user_setting.selected_language = 'en'
            user_setting.selected_theme = 'light'
            user_setting.updated_at = datetime.utcnow()
            
            db.session.commit()
            
            return user_setting.to_dict()
            
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to reset user settings: {str(e)}')

@api.route('/theme/<string:theme>')
class UsersByTheme(Resource):
    @api.doc('get_users_by_theme')
    @api.marshal_list_with(user_setting_model)
    def get(self, theme):
        """Get all users with a specific theme"""
        try:
            settings = UserSetting.query.filter_by(selected_theme=theme).all()
            return [setting.to_dict() for setting in settings]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve users by theme: {str(e)}')

@api.route('/language/<string:language>')
class UsersByLanguage(Resource):
    @api.doc('get_users_by_language')
    @api.marshal_list_with(user_setting_model)
    def get(self, language):
        """Get all users with a specific language"""
        try:
            settings = UserSetting.query.filter_by(selected_language=language).all()
            return [setting.to_dict() for setting in settings]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve users by language: {str(e)}')
