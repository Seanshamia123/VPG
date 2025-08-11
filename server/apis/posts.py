from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Post, Advertiser, Comment, db
from .decorators import token_required_simple as token_required

api = Namespace('posts', description='Post management operations')

# Models for Swagger documentation
post_model = api.model('Post', {
    'id': fields.Integer(description='Post ID'),
    'advertiser_id': fields.Integer(description='Advertiser ID who created the post'),
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
    'caption': fields.String(description='Updated post caption'),
    'image_id': fields.String(description='Updated image ID or URL')
})

post_with_advertiser_model = api.model('PostWithAdvertiser', {
    'id': fields.Integer(description='Post ID'),
    'advertiser_id': fields.Integer(description='Advertiser ID'),
    'image_id': fields.String(description='Image ID or URL'),
    'caption': fields.String(description='Post caption'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp'),
    'advertiser': fields.Nested(api.model('PostAdvertiser', {
        'id': fields.Integer(description='Advertiser ID'),
        'name': fields.String(description='Advertiser name'),
        'username': fields.String(description='Username')
    }))
})

@api.route('/')
class PostList(Resource):
    @api.doc('list_posts')
    @api.marshal_list_with(post_with_advertiser_model)
    @token_required
    def get(self, current_advertiser):
        """Get all posts (feed)"""
        print(f"DEBUG: GET posts - current_advertiser: {current_advertiser}, type: {type(current_advertiser)}")
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            posts = db.session.query(Post).join(Advertiser).order_by(
                Post.created_at.desc()
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for post in posts.items:
                advertiser = Advertiser.find_by_id(post.advertiser_id)
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_id': post.image_id,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'advertiser': {
                        'id': advertiser.id if advertiser else None,
                        'name': advertiser.name if advertiser else 'Unknown Advertiser',
                        'username': advertiser.username if advertiser else 'unknown'
                    }
                }
                result.append(post_dict)
            
            return result
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve posts: {str(e)}')
    
    @api.doc('create_post')
    @api.expect(post_create_model)
    @api.marshal_with(post_model)
    @token_required
    def post(self, current_advertiser):
        """Create a new post"""
        print("=== POST CREATION DEBUG START ===")
        print(f"DEBUG: current_advertiser parameter: {current_advertiser}")
        print(f"DEBUG: current_advertiser type: {type(current_advertiser)}")
        print(f"DEBUG: self object: {self}")
        print(f"DEBUG: self type: {type(self)}")
        
        # Check if current_advertiser is actually the PostList object (wrong parameter order)
        if isinstance(current_advertiser, PostList):
            print("ERROR: current_advertiser is actually the PostList object! Decorator parameter order issue.")
            api.abort(500, 'Internal authentication error - decorator parameter mismatch')
        
        try:
            data = request.get_json()
            print(f"DEBUG: Received JSON data: {data}")
            
            if not data:
                print("DEBUG: No JSON data received")
                api.abort(400, 'No JSON data provided')
            
            if not data.get('image_id'):
                print("DEBUG: image_id is missing")
                api.abort(400, 'image_id is required')
            
            # Verify current_advertiser has the required attributes
            if not hasattr(current_advertiser, 'id'):
                print(f"DEBUG: current_advertiser has no 'id' attribute. Available attributes: {dir(current_advertiser)}")
                api.abort(401, 'Invalid advertiser object - missing ID')
            
            advertiser_id = current_advertiser.id
            print(f"DEBUG: Using advertiser_id: {advertiser_id}")
            
            post = Post(
                advertiser_id=advertiser_id,
                image_id=data['image_id'],
                caption=data.get('caption', '')
            )
            
            print(f"DEBUG: Created post object: advertiser_id={post.advertiser_id}, image_id={post.image_id}")
            
            db.session.add(post)
            db.session.commit()
            
            # Refresh to get the generated ID and timestamps
            db.session.refresh(post)
            
            result = {
                'id': post.id,
                'advertiser_id': post.advertiser_id,
                'image_id': post.image_id,
                'caption': post.caption,
                'created_at': post.created_at.isoformat() if post.created_at else None,
                'updated_at': post.updated_at.isoformat() if post.updated_at else None
            }
            
            print(f"DEBUG: Post created successfully: {result}")
            print("=== POST CREATION DEBUG END ===")
            
            return result, 201
            
        except Exception as e:
            print(f"DEBUG: Exception in post creation: {type(e).__name__}: {str(e)}")
            import traceback
            traceback.print_exc()
            db.session.rollback()
            api.abort(500, f'Failed to create post: {str(e)}')

@api.route('/<int:post_id>')
class PostDetail(Resource):
    @api.doc('get_post')
    @api.marshal_with(post_with_advertiser_model)
    @token_required
    def get(self, current_advertiser, post_id):
        """Get post by ID"""
        try:
            post = Post.query.get(post_id)
            if not post:
                api.abort(404, 'Post not found')
            
            advertiser = Advertiser.find_by_id(post.advertiser_id)
            
            return {
                'id': post.id,
                'advertiser_id': post.advertiser_id,
                'image_id': post.image_id,
                'caption': post.caption,
                'created_at': post.created_at.isoformat() if post.created_at else None,
                'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                'advertiser': {
                    'id': advertiser.id if advertiser else None,
                    'name': advertiser.name if advertiser else 'Unknown Advertiser',
                    'username': advertiser.username if advertiser else 'unknown'
                }
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve post: {str(e)}')
    
    @api.doc('update_post')
    @api.expect(post_update_model)
    @api.marshal_with(post_model)
    @token_required
    def put(self, current_advertiser, post_id):
        """Update post (only by owner) - can update caption and/or image"""
        print("=== POST UPDATE DEBUG START ===")
        print(f"DEBUG: post_id: {post_id}")
        print(f"DEBUG: current_advertiser: {current_advertiser}, id: {getattr(current_advertiser, 'id', 'NO_ID')}")
        
        try:
            post = Post.query.get(post_id)
            if not post:
                print(f"DEBUG: Post {post_id} not found")
                api.abort(404, 'Post not found')
            
            print(f"DEBUG: Found post - id: {post.id}, advertiser_id: {post.advertiser_id}")
            print(f"DEBUG: Current post data - image_id: {post.image_id}, caption: {post.caption}")
            
            if post.advertiser_id != current_advertiser.id:
                print(f"DEBUG: Permission denied - post owner: {post.advertiser_id}, current user: {current_advertiser.id}")
                api.abort(403, 'Can only update your own posts')
            
            data = request.get_json()
            print(f"DEBUG: Received data: {data}")
            
            if not data:
                print("DEBUG: No JSON data provided")
                api.abort(400, 'No JSON data provided')
            
            # Track if any changes were made
            changes_made = False
            
            # Update caption if provided
            if 'caption' in data:
                old_caption = post.caption
                post.caption = data['caption']
                print(f"DEBUG: Caption update - old: '{old_caption}' -> new: '{post.caption}'")
                changes_made = True
            
            # Update image if provided
            if 'image_id' in data:
                if not data['image_id']:
                    print("DEBUG: Empty image_id provided")
                    api.abort(400, 'image_id cannot be empty')
                
                old_image_id = post.image_id
                post.image_id = data['image_id']
                print(f"DEBUG: Image update - old: '{old_image_id}' -> new: '{post.image_id}'")
                changes_made = True
            
            if not changes_made:
                print("DEBUG: No changes made")
                api.abort(400, 'At least one field (caption or image_id) must be provided for update')
            
            print("DEBUG: About to commit changes...")
            db.session.commit()
            print("DEBUG: Changes committed successfully")
            
            # Refresh the post to get updated timestamp
            db.session.refresh(post)
            print(f"DEBUG: Post after refresh - image_id: {post.image_id}, caption: {post.caption}")
            
            result = {
                'id': post.id,
                'advertiser_id': post.advertiser_id,
                'image_id': post.image_id,
                'caption': post.caption,
                'created_at': post.created_at.isoformat() if post.created_at else None,
                'updated_at': post.updated_at.isoformat() if post.updated_at else None
            }
            
            print(f"DEBUG: Final result: {result}")
            print("=== POST UPDATE DEBUG END ===")
            
            return result
            
        except Exception as e:
            print(f"DEBUG: Exception occurred: {type(e).__name__}: {str(e)}")
            import traceback
            traceback.print_exc()
            db.session.rollback()
            api.abort(500, f'Failed to update post: {str(e)}')
        @api.doc('delete_post')
        @token_required
        def delete(self, current_advertiser, post_id):
            """Delete post (only by owner)"""
            try:
                post = Post.query.get(post_id)
                if not post:
                    api.abort(404, 'Post not found')
                
                if post.advertiser_id != current_advertiser.id:
                    api.abort(403, 'Can only delete your own posts')
                
                db.session.delete(post)
                db.session.commit()
                
                return {'message': 'Post deleted successfully'}
                
            except Exception as e:
                db.session.rollback()
                api.abort(500, f'Failed to delete post: {str(e)}')


@api.route('/<int:post_id>/comments')
class PostComments(Resource):
    @api.doc('get_post_comments')
    @token_required
    def get(self, current_advertiser, post_id):
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
                advertiser = Advertiser.find_by_id(comment.user_id)
                comment_dict = {
                    'id': comment.id,
                    'advertiser_id': comment.user_id,
                    'content': comment.content,
                    'likes_count': comment.likes_count,
                    'created_at': comment.created_at.isoformat() if comment.created_at else None,
                    'advertiser': {
                        'id': advertiser.id if advertiser else None,
                        'name': advertiser.name if advertiser else 'Unknown Advertiser',
                        'username': advertiser.username if advertiser else 'unknown'
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
    @token_required
    def get(self, current_advertiser):
        """Get current advertiser's posts"""
        try:
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            posts = Post.query.filter_by(
                advertiser_id=current_advertiser.id
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
                    'advertiser_id': post.advertiser_id,
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
    @token_required
    def get(self, current_advertiser):
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
                advertiser = Advertiser.find_by_id(post.advertiser_id)
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_id': post.image_id,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'advertiser': {
                        'id': advertiser.id if advertiser else None,
                        'name': advertiser.name if advertiser else 'Unknown Advertiser',
                        'username': advertiser.username if advertiser else 'unknown'
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