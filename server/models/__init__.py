from database import db 
# Import all models here
from .user import User
from .advertiser import Advertiser
from .comment import Comment
from .commentlike import CommentLike
from .conversations import Conversation
from .message import Message
from .posts import Post
from .user_settings import UserSetting
from .userblock import UserBlock
from .subsricption import Subscription
from .authtoken import AuthToken


# Make them available when importing from models
__all__ = ['db', 'User', 'Advertiser','AuthToken','UserSetting','Comment','CommentLike','Conversation','Message','Post','Subscription','UserBlock']