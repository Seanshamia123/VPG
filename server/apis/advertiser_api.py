from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Advertiser, db
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

api = Namespace('advertisers', description='Advertiser management operations')

# Models for Swagger documentation
advertiser_model = api.model('Advertiser', {
    'id': fields.Integer(description='Advertiser ID'),
    'username': fields.String(description='Username'),
    'name': fields.String(description='Full name'),
    'email': fields.String(description='Email address'),
    'phone_number': fields.String(description='Phone number'),
    'location': fields.String(description='Location'),
    'gender': fields.String(description='Gender', enum=['Male', 'Female', 'other']),
    'profile_image_url': fields.String(description='Profile image URL'),
    'is_verified': fields.Boolean(description='Verification status'),
    'is_online': fields.Boolean(description='Online status'),
    'bio': fields.String(description='Bio/Description'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp'),
    'last_active': fields.String(description='Last active timestamp')
})

advertiser_create_model = api.model('AdvertiserCreate', {
    'username': fields.String(required=True, description='Username'),
    'name': fields.String(required=True, description='Full name'),
    'email': fields.String(required=True, description='Email address'),
    'phone_number': fields.String(required=True, description='Phone number'),
    'location': fields.String(required=True, description='Location'),
    'gender': fields.String(required=True, description='Gender', enum=['Male', 'Female', 'other']),
    'password': fields.String(required=True, description='Password'),
    'bio': fields.String(description='Bio/Description'),
    'profile_image_url': fields.String(description='Profile image URL')
})

advertiser_update_model = api.model('AdvertiserUpdate', {
    'name': fields.String(description='Full name'),
    'phone_number': fields.String(description='Phone number'),
    'location': fields.String(description='Location'),
    'bio': fields.String(description='Bio/Description'),
    'profile_image_url': fields.String(description='Profile image URL'),
    'is_online': fields.Boolean(description='Online status')
})

advertiser_login_model = api.model('AdvertiserLogin', {
    'email': fields.String(required=True, description='Email address'),
    'password': fields.String(required=True, description='Password')
})

@api.route('/')
class AdvertiserList(Resource):
    @api.doc('list_advertisers')
    @api.marshal_list_with(advertiser_model)
    def get(self):
        """Get all advertisers"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            location = request.args.get('location')
            verified_only = request.args.get('verified_only', False, type=bool)
            
            query = Advertiser.query
            
            if location:
                query = query.filter_by(location=location)
            
            if verified_only:
                query = query.filter_by(is_verified=True)
            
            advertisers = query.paginate(
                page=page, 
                per_page=per_page, 
                error_out=False
            )
            
            return [advertiser.to_dict_safe() for advertiser in advertisers.items]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve advertisers: {str(e)}')
    
    @api.doc('create_advertiser')
    @api.expect(advertiser_create_model)
    @api.marshal_with(advertiser_model, code=201)
    def post(self):
        """Create a new advertiser"""
        try:
            data = request.get_json()
            
            # Check if email already exists
            if Advertiser.find_by_email(data['email']):
                api.abort(400, 'Email already exists')
            
            # Hash password
            password_hash = generate_password_hash(data.pop('password'))
            
            advertiser = Advertiser(
                username=data['username'],
                name=data['name'],
                email=data['email'],
                phone_number=data['phone_number'],
                location=data['location'],
                gender=data['gender'],
                bio=data.get('bio'),
                profile_image_url=data.get('profile_image_url'),
                password_hash=password_hash
            )
            
            advertiser.save()
            return advertiser.to_dict_safe(), 201
            
        except Exception as e:
            api.abort(500, f'Failed to create advertiser: {str(e)}')

@api.route('/<int:advertiser_id>')
class AdvertiserDetail(Resource):
    @api.doc('get_advertiser')
    @api.marshal_with(advertiser_model)
    def get(self, advertiser_id):
        """Get advertiser by ID"""
        try:
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, 'Advertiser not found')
            
            return advertiser.to_dict_safe()
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve advertiser: {str(e)}')
    
    @api.doc('update_advertiser')
    @api.expect(advertiser_update_model)
    @api.marshal_with(advertiser_model)
    def put(self, advertiser_id):
        """Update advertiser profile"""
        try:
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, 'Advertiser not found')
            
            data = request.get_json()
            advertiser.update(**data)
            
            return advertiser.to_dict_safe()
            
        except Exception as e:
            api.abort(500, f'Failed to update advertiser: {str(e)}')
    
    @api.doc('delete_advertiser')
    def delete(self, advertiser_id):
        """Delete advertiser account"""
        try:
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, 'Advertiser not found')
            
            advertiser.delete()
            return {'message': 'Advertiser account deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete advertiser: {str(e)}')

@api.route('/<int:advertiser_id>/verify')
class AdvertiserVerification(Resource):
    @api.doc('verify_advertiser')
    def post(self, advertiser_id):
        """Verify an advertiser"""
        try:
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, 'Advertiser not found')
            
            advertiser.verify()
            return {'message': 'Advertiser verified successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to verify advertiser: {str(e)}')
    
    @api.doc('unverify_advertiser')
    def delete(self, advertiser_id):
        """Unverify an advertiser"""
        try:
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, 'Advertiser not found')
            
            advertiser.unverify()
            return {'message': 'Advertiser unverified successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to unverify advertiser: {str(e)}')

@api.route('/login')
class AdvertiserLogin(Resource):
    @api.doc('advertiser_login')
    @api.expect(advertiser_login_model)
    def post(self):
        """Advertiser login"""
        try:
            data = request.get_json()
            email = data.get('email')
            password = data.get('password')
            
            advertiser = Advertiser.find_by_email(email)
            if not advertiser or not check_password_hash(advertiser.password_hash, password):
                api.abort(401, 'Invalid credentials')
            
            # Update last_active
            advertiser.last_active = datetime.utcnow()
            advertiser.is_online = True
            db.session.commit()
            
            # Here you would typically generate and return a JWT token
            return {
                'message': 'Login successful',
                'advertiser': advertiser.to_dict_safe()
            }
            
        except Exception as e:
            api.abort(500, f'Login failed: {str(e)}')

@api.route('/verified')
class VerifiedAdvertisers(Resource):
    @api.doc('get_verified_advertisers')
    @api.marshal_list_with(advertiser_model)
    def get(self):
        """Get all verified advertisers"""
        try:
            advertisers = Advertiser.get_all_verified()
            return [advertiser.to_dict_safe() for advertiser in advertisers]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve verified advertisers: {str(e)}')

@api.route('/location/<string:location>')
class AdvertisersByLocation(Resource):
    @api.doc('get_advertisers_by_location')
    @api.marshal_list_with(advertiser_model)
    def get(self, location):
        """Get advertisers by location"""
        try:
            advertisers = Advertiser.get_by_location(location)
            return [advertiser.to_dict_safe() for advertiser in advertisers]
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve advertisers by location: {str(e)}')