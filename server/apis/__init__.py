from flask import Blueprint
from flask_restx import Api
from .users import api as users_ns
from .advertiser_api import api as advertisers_ns
from .posts import api as posts_ns
from .comments import api as comments_ns
from .message_api import api as messages_ns
from .conversations import api as conversations_ns
# from .subscriptions import api as subscriptions_ns
from .auth import api as auth_ns
from .user_settings import api as user_settings_ns

# Create the main API blueprint
api_bp = Blueprint('api', __name__, url_prefix='/api')

# Initialize Flask-RESTX API with Swagger documentation
api = Api(
    api_bp,
    version='1.0',
    title='VPG API',
    description='A comprehensive social media platform API with user management, posts, comments, messaging, and more',
    doc='/docs/',  # Swagger UI will be available at /api/docs/
    contact='developer@example.com',
    license='MIT',
    authorizations={
        'Bearer': {
            'type': 'apiKey',
            'in': 'header',
            'name': 'Authorization',
            'description': 'Add a JWT token to the header with ** Bearer &lt;JWT&gt; ** token to authorize'
        }
    },
    security=['Bearer']
)

# Add namespaces to the API
api.add_namespace(auth_ns, path='/auth')
api.add_namespace(users_ns, path='/users')
api.add_namespace(advertisers_ns, path='/advertisers')
api.add_namespace(posts_ns, path='/posts')
api.add_namespace(comments_ns, path='/comments')
api.add_namespace(messages_ns, path='/messages')
api.add_namespace(conversations_ns, path='/conversations')
api.add_namespace(user_settings_ns, path='/user-settings')
# api.add_namespace(subscriptions_ns, path='/subscriptions')
# api.add_namespace(user_settings_ns, path='/user-settings')

__all__ = ['api_bp']