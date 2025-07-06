from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_migrate import Migrate
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Import models
from models import db, User, Advertiser

app = Flask(__name__)

# Configuration
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL') or \
    f"mysql+pymysql://{os.environ.get('MYSQL_USER', 'flutter_user')}:{os.environ.get('MYSQL_PASSWORD', 'your_password')}@{os.environ.get('MYSQL_HOST', 'localhost')}:{os.environ.get('MYSQL_PORT', '3306')}/{os.environ.get('MYSQL_DB', 'flutter_app_db')}"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    'pool_pre_ping': True,
    'pool_recycle': 300,
    'pool_timeout': 20,
    'max_overflow': 0
}

# Initialize extensions
db.init_app(app)
migrate = Migrate(app, db)
CORS(app, origins=["*"])  # Configure this for production

# Routes
@app.route('/')
def index():
    return jsonify({
        'message': 'Flutter Flask API',
        'version': '1.0',
        'endpoints': {
            'users': '/api/users',
            'advertisers': '/api/advertisers',
            'health': '/api/health'
        }
    })

@app.route('/api/health')
def health_check():
    return jsonify({'status': 'healthy', 'message': 'API is running'})

# User Routes
@app.route('/api/users', methods=['GET'])
def get_users():
    try:
        users = User.get_all_active()
        return jsonify([user.to_dict_safe() for user in users])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users', methods=['POST'])
def create_user():
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'email', 'number', 'location', 'gender']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
        
        # Check if user already exists
        if User.find_by_email(data['email']):
            return jsonify({'error': 'User with this email already exists'}), 400
        
        # Create new user
        user = User(
            name=data['name'],
            email=data['email'],
            number=data['number'],
            location=data['location'],
            gender=data['gender'],
            profile_picture=data.get('profile_picture')
        )
        
        user.save()
        return jsonify(user.to_dict()), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        return jsonify(user.to_dict())
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/<int:user_id>', methods=['PUT'])
def update_user(user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        data = request.get_json()
        
        # Check if email is being changed and if it's already taken
        if 'email' in data and data['email'] != user.email:
            if User.find_by_email(data['email']):
                return jsonify({'error': 'Email already taken'}), 400
        
        user.update(**data)
        return jsonify(user.to_dict())
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    try:
        user = User.find_by_id(user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        user.delete()
        return jsonify({'message': 'User deleted successfully'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Advertiser Routes
@app.route('/api/advertisers', methods=['GET'])
def get_advertisers():
    try:
        advertisers = Advertiser.get_all_active()
        return jsonify([advertiser.to_dict_safe() for advertiser in advertisers])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/advertisers', methods=['POST'])
def create_advertiser():
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'email', 'number', 'location', 'gender']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'{field} is required'}), 400
        
        # Check if advertiser already exists
        if Advertiser.find_by_email(data['email']):
            return jsonify({'error': 'Advertiser with this email already exists'}), 400
        
        # Create new advertiser
        advertiser = Advertiser(
            name=data['name'],
            email=data['email'],
            number=data['number'],
            location=data['location'],
            gender=data['gender'],
            profile_picture=data.get('profile_picture'),
            company_name=data.get('company_name'),
            business_type=data.get('business_type')
        )
        
        advertiser.save()
        return jsonify(advertiser.to_dict()), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/advertisers/<int:advertiser_id>', methods=['GET'])
def get_advertiser(advertiser_id):
    try:
        advertiser = Advertiser.find_by_id(advertiser_id)
        if not advertiser:
            return jsonify({'error': 'Advertiser not found'}), 404
        return jsonify(advertiser.to_dict())
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/advertisers/<int:advertiser_id>', methods=['PUT'])
def update_advertiser(advertiser_id):
    try:
        advertiser = Advertiser.find_by_id(advertiser_id)
        if not advertiser:
            return jsonify({'error': 'Advertiser not found'}), 404
        
        data = request.get_json()
        
        # Check if email is being changed and if it's already taken
        if 'email' in data and data['email'] != advertiser.email:
            if Advertiser.find_by_email(data['email']):
                return jsonify({'error': 'Email already taken'}), 400
        
        advertiser.update(**data)
        return jsonify(advertiser.to_dict())
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/advertisers/<int:advertiser_id>', methods=['DELETE'])
def delete_advertiser(advertiser_id):
    try:
        advertiser = Advertiser.find_by_id(advertiser_id)
        if not advertiser:
            return jsonify({'error': 'Advertiser not found'}), 404
        
        advertiser.delete()
        return jsonify({'message': 'Advertiser deleted successfully'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/advertisers/<int:advertiser_id>/verify', methods=['POST'])
def verify_advertiser(advertiser_id):
    try:
        advertiser = Advertiser.find_by_id(advertiser_id)
        if not advertiser:
            return jsonify({'error': 'Advertiser not found'}), 404
        
        advertiser.verify()
        return jsonify({'message': 'Advertiser verified successfully'})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/advertisers/verified', methods=['GET'])
def get_verified_advertisers():
    try:
        advertisers = Advertiser.get_all_verified()
        return jsonify([advertiser.to_dict_safe() for advertiser in advertisers])
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Resource not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    db.session.rollback()
    return jsonify({'error': 'Internal server error'}), 500

# Shell context for Flask CLI
@app.shell_context_processor
def make_shell_context():
    return {'db': db, 'User': User, 'Advertiser': Advertiser}

if __name__ == '__main__':
    with app.app_context():
        db.create_all()
    app.run(debug=True, host='0.0.0.0', port=5000)