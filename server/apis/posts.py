from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Post, User, Comment, db
# from .decorators import token_required

api = Namespace('posts', description='Post management operations')

# Models for Swagger documentation
post_model = api.model('Post', {
    'id': fields.Integer(description='Post ID'),
    'user_id': fields.Integer(description='User ID who created the post'),
    'image_id': fields.String(description='Image ID or URL'),
    'caption': fields.String(description='Post caption'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp')
})

post_create_model = api.model('PostCreate', {
    'image_id': fields.String(required=True, description='Image ID or URL'),
    'caption': fields.String(description='Post caption')
})

post_update_model = api.model('PostUpdate', {
    'caption': fields.String(description='Updated post caption')
})

post_with_user_model = api.model('PostWithUser', {
    'id': fields.Integer(description='Post ID'),
    'user_id': fields.Integer(description='User ID'),
    'image_id': fields.String(description='Image ID or URL'),
    'caption': fields.String(description='Post caption'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp'),
    'user': fields.Nested(api.model('PostUser', {
        'id': fields.Integer(description='User ID'),
        'name': fields.String(description='User name'),
        'username': fields.String(description='Username')
    }))
})

@api.route('/')
class PostList(Resource):
    @api.doc('list_posts')
    @api.marshal_list_with(post_with_user_model)
    # @token_required
    def get(self, current_user):
        """Get all posts (feed)"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            posts = db.session.query(Post).join(User).order_by(
                Post.created_at.desc()
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for post in posts.items:
                user = User.find_by_id(post.user_id)
                post_dict = {
                    'id': post.id,
                    'user_id': post.user_id,
                    'image_id': post.image_id,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'user': {
                        'id': user.id if user else None,
                        'name': user.name if user else 'Unknown User',
                        'username': user.username if user else 'unknown'
                    }
                }
                result.append(post_dict)
            
            return result
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve posts: {str(e)}')
    
    @api.doc('create_post')
    @api.expect(post_create_model)
    @api.marshal_with(post_model)
    # @token_required
    def post(self, current_user):
        """Create a new post"""
        try:
            data = request.get_json()
            
            if not data.get('image_id'):
                api.abort(400, 'image_id is required')
            
            post = Post(
                user_id=current_user.id,
                image_id=data['image_id'],
                caption=data.get('caption', '')
            )
            
            db.session.add(post)
            db.session.commit()
            
            return {
                'id': post.id,
                'user_id': post.user_id,
                'image_id': post.image_id,
                'caption': post.caption,
                'created_at': post.created_at.isoformat() if post.created_at else None,
                'updated_at': post.updated_at.isoformat() if post.updated_at else None
            }
            
        except Exception as e:
            api.abort(500, f'Failed to create post: {str(e)}')

@api.route('/<int:post_id>')
class PostDetail(Resource):
    @api.doc('get_post')
    @api.marshal_with(post_with_user_model)
    # @token_required
    def get(self, current_user, post_id):
        """Get post by ID"""
        try:
            post = Post.query.get(post_id)
            if not post:
                api.abort(404, 'Post not found')
            
            user = User.find_by_id(post.user_id)
            
            return {
                'id': post.id,
                'user_id': post.user_id,
                'image_id': post.image_id,
                'caption': post.caption,
                'created_at': post.created_at.isoformat() if post.created_at else None,
                'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                'user': {
                    'id': user.id if user else None,
                    'name': user.name if user else 'Unknown User',
                    'username': user.username if user else 'unknown'
                }
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve post: {str(e)}')
    
    @api.doc('update_post')
    @api.expect(post_update_model)
    @api.marshal_with(post_model)
    # @token_required
    def put(self, current_user, post_id):
        """Update post (only by owner)"""
        try:
            post = Post.query.get(post_id)
            if not post:
                api.abort(404, 'Post not found')
            
            if post.user_id != current_user.id:
                api.abort(403, 'Can only update your own posts')
            
            data = request.get_json()
            
            if 'caption' in data:
                post.caption = data['caption']
            
            db.session.commit()
            
            return {
                'id': post.id,
                'user_id': post.user_id,
                'image_id': post.image_id,
                'caption': post.caption,
                'created_at': post.created_at.isoformat() if post.created_at else None,
                'updated_at': post.updated_at.isoformat() if post.updated_at else None
            }
            
        except Exception as e:
            api.abort(500, f'Failed to update post: {str(e)}')
    
    @api.doc('delete_post')
    # @token_required
    def delete(self, current_user, post_id):
        """Delete post (only by owner)"""
        try:
            post = Post.query.get(post_id)
            if not post:
                api.abort(404, 'Post not found')
            
            if post.user_id != current_user.id:
                api.abort(403, 'Can only delete your own posts')
            
            db.session.delete(post)
            db.session.commit()
            
            return {'message': 'Post deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete post: {str(e)}')

@api.route('/<int:post_id>/comments')
class PostComments(Resource):
    @api.doc('get_post_comments')
    # @token_required
    def get(self, current_user, post_id):
        """Get comments for a post"""
        try:
            post = Post.query.get(post_id)
            if not post:
                api.abort(404, 'Post not found')
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            comments = Comment.query.filter_by(
                target_type='post',
                target_id=post_id,
                is_deleted=False
            ).order_by(Comment.created_at.desc()).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for comment in comments.items:
                user = User.find_by_id(comment.user_id)
                comment_dict = {
                    'id': comment.id,
                    'user_id': comment.user_id,
                    'content': comment.content,
                    'likes_count': comment.likes_count,
                    'created_at': comment.created_at.isoformat() if comment.created_at else None,
                    'user': {
                        'id': user.id if user else None,
                        'name': user.name if user else 'Unknown User',
                        'username': user.username if user else 'unknown'
                    }
                }
                result.append(comment_dict)
            
            return {
                'comments': result,
                'total': comments.total,
                'pages': comments.pages,
                'current_page': comments.page
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve comments: {str(e)}')

@api.route('/my-posts')
class MyPosts(Resource):
    @api.doc('get_my_posts')
    @api.marshal_list_with(post_model)
    # @token_required
    def get(self, current_user):
        """Get current user's posts"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            posts = Post.query.filter_by(
                user_id=current_user.id
            ).order_by(
                Post.created_at.desc()
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for post in posts.items:
                post_dict = {
                    'id': post.id,
                    'user_id': post.user_id,
                    'image_id': post.image_id,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None
                }
                result.append(post_dict)
            
            return result
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve your posts: {str(e)}')

@api.route('/search')
class SearchPosts(Resource):
    @api.doc('search_posts')
    # @token_required
    def get(self, current_user):
        """Search posts by caption"""
        try:
            query = request.args.get('q', '').strip()
            if not query:
                api.abort(400, 'Search query is required')
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            posts = Post.query.filter(
                Post.caption.ilike(f'%{query}%')
            ).order_by(
                Post.created_at.desc()
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for post in posts.items:
                user = User.find_by_id(post.user_id)
                post_dict = {
                    'id': post.id,
                    'user_id': post.user_id,
                    'image_id': post.image_id,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'user': {
                        'id': user.id if user else None,
                        'name': user.name if user else 'Unknown User',
                        'username': user.username if user else 'unknown'
                    }
                }
                result.append(post_dict)
            
            return {
                'posts': result,
                'total': posts.total,
                'pages': posts.pages,
                'current_page': posts.page
            }
            
        except Exception as e:
            api.abort(500, f'Failed to search posts: {str(e)}')