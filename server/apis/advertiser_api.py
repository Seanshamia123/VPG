from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Advertiser, db
from .decorators import advertiser_required
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
    'profile_image_url': fields.String(description='Profile image URL'),
    'latitude': fields.Float(description='Latitude'),
    'longitude': fields.Float(description='Longitude')
})

advertiser_update_model = api.model('AdvertiserUpdate', {
    'name': fields.String(description='Full name'),
    'phone_number': fields.String(description='Phone number'),
    'location': fields.String(description='Location'),
    'bio': fields.String(description='Bio/Description'),
    'profile_image_url': fields.String(description='Profile image URL'),
    'is_online': fields.Boolean(description='Online status'),
    'latitude': fields.Float(description='Latitude'),
    'longitude': fields.Float(description='Longitude')
})

advertiser_login_model = api.model('AdvertiserLogin', {
    'email': fields.String(required=True, description='Email address'),
    'password': fields.String(required=True, description='Password')
})

@api.route('/')
class AdvertiserList(Resource):
    @api.doc('list_advertisers')
    def get(self):
        """Get all advertisers (paginated)."""
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

            pagination = query.paginate(page=page, per_page=per_page, error_out=False)
            items = [adv.to_dict_safe() for adv in pagination.items]
            return {
                'items': items,
                'total': pagination.total,
                'pages': pagination.pages,
                'current_page': pagination.page,
                'per_page': pagination.per_page,
            }
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
                latitude=data.get('latitude'),
                longitude=data.get('longitude'),
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
    @advertiser_required
    def put(self, current_advertiser, advertiser_id):
        """Update advertiser profile"""
        try:
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, 'Advertiser not found')
            if current_advertiser.id != advertiser_id:
                api.abort(403, 'Can only update your own profile')
            
            data = request.get_json()
            advertiser.update(**data)
            
            return advertiser.to_dict_safe()
            
        except Exception as e:
            api.abort(500, f'Failed to update advertiser: {str(e)}')
    
    @api.doc('delete_advertiser')
    @advertiser_required
    def delete(self, current_advertiser, advertiser_id):
        """Delete advertiser account"""
        try:
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, 'Advertiser not found')
            if current_advertiser.id != advertiser_id:
                api.abort(403, 'Can only delete your own account')
            
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

## Redundant advertiser login removed — use /auth/login instead

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

coords_model = api.model('AdvertiserCoords', {
    'latitude': fields.Float(required=True, description='Latitude'),
    'longitude': fields.Float(required=True, description='Longitude')
})

@api.route('/<int:advertiser_id>/coords')
class AdvertiserCoords(Resource):
    @api.doc('set_advertiser_coords')
    @api.expect(coords_model)
    @advertiser_required
    def post(self, current_advertiser, advertiser_id):
        """Set/Update advertiser coordinates (POST for client convenience)."""
        try:
            if current_advertiser.id != advertiser_id:
                api.abort(403, 'Can only update your own coordinates')
            data = request.get_json() or {}
            lat = data.get('latitude')
            lon = data.get('longitude')
            if lat is None or lon is None:
                api.abort(400, 'latitude and longitude are required')
            adv = Advertiser.find_by_id(advertiser_id)
            if not adv:
                api.abort(404, 'Advertiser not found')
            adv.update(latitude=lat, longitude=lon)
            return {'message': 'Coordinates updated', 'advertiser': adv.to_dict_safe()}
        except Exception as e:
            api.abort(500, f'Failed to update coordinates: {str(e)}')

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

@api.route('/search')
class SearchAdvertisers(Resource):
    @api.doc('search_advertisers')
    def get(self):
        """Search advertisers by name or username."""
        try:
            q = (request.args.get('q') or '').strip()
            if not q:
                api.abort(400, 'q is required')
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            qry = Advertiser.query.filter(db.or_(Advertiser.name.ilike(f'%{q}%'), Advertiser.username.ilike(f'%{q}%')))
            pagination = qry.paginate(page=page, per_page=per_page, error_out=False)
            return {
                'items': [a.to_dict_safe() for a in pagination.items],
                'total': pagination.total,
                'pages': pagination.pages,
                'current_page': pagination.page,
                'per_page': pagination.per_page,
            }
        except Exception as e:
            api.abort(500, f'Failed to search advertisers: {str(e)}')

@api.route('/nearby')
class NearbyAdvertisers(Resource):
    @api.doc('nearby_advertisers')
    def get(self):
        """Return advertisers within radius_km of lat/lon (requires saved coords)."""
        try:
            try:
                lat = float(request.args.get('lat'))
                lon = float(request.args.get('lon'))
            except Exception:
                api.abort(400, 'lat and lon are required')
            radius_km = float(request.args.get('radius_km', 10))

            # Simple in-Python filter (not using geography type)
            from math import radians, sin, cos, sqrt, atan2

            def haversine(lat1, lon1, lat2, lon2):
                R = 6371.0
                dlat = radians(lat2 - lat1)
                dlon = radians(lon2 - lon1)
                a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
                c = 2 * atan2(sqrt(a), sqrt(1-a))
                return R * c

            advs = Advertiser.query.filter(Advertiser.latitude.isnot(None), Advertiser.longitude.isnot(None)).all()
            out = []
            for a in advs:
                d = haversine(lat, lon, float(a.latitude), float(a.longitude))
                if d <= radius_km:
                    obj = a.to_dict_safe()
                    obj['distance_km'] = round(d, 2)
                    out.append(obj)
            out.sort(key=lambda x: x['distance_km'])
            return {'items': out, 'total': len(out)}
        except Exception as e:
            api.abort(500, f'Failed to compute nearby advertisers: {str(e)}')
