from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Post, Advertiser, Comment, PostLike, db
from .decorators import token_required, advertiser_required

import time
import base64
from server.cloudinary_service import get_service as get_cloudinary_service 

api = Namespace('posts', description='Post management operations')

# Models for Swagger documentation
image_upload_model = api.model('ImageUpload', {
    'image': fields.String(required=True, description='Base64 encoded image or image data'),
    'caption': fields.String(description='Post caption'),
    'folder': fields.String(description='Cloudinary folder (optional)')
})

post_model = api.model('Post', {
    'id': fields.Integer(description='Post ID'),
    'advertiser_id': fields.Integer(description='Advertiser ID who created the post'),
    'image_url': fields.String(description='Image URL from Cloudinary'),
    'caption': fields.String(description='Post caption'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp')
})

post_create_model = api.model('PostCreate', {
    'image': fields.String(required=True, description='Base64 encoded image data'),
    'caption': fields.String(description='Post caption')
})

post_update_model = api.model('PostUpdate', {
    'caption': fields.String(description='Updated post caption'),
    'image': fields.String(description='Base64 encoded image data for update')
})

post_with_advertiser_model = api.model('PostWithAdvertiser', {
    'id': fields.Integer(description='Post ID'),
    'advertiser_id': fields.Integer(description='Advertiser ID'),
    'image_url': fields.String(description='Image URL from Cloudinary'),
    'caption': fields.String(description='Post caption'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp'),
    'advertiser': fields.Nested(api.model('PostAdvertiser', {
        'id': fields.Integer(description='Advertiser ID'),
        'name': fields.String(description='Advertiser name'),
        'username': fields.String(description='Username')
    }))
})

@api.route('/upload-image')
class ImageUpload(Resource):
    @api.doc('upload_image')
    @api.expect(image_upload_model)
    @token_required
    def post(self, current_advertiser):
        """Upload image to Cloudinary and return URL"""
        try:
            data = request.get_json()
            
            if not data or not data.get('image'):
                api.abort(400, 'Image data is required')
            
            # Generate unique public_id for the image
            public_id = f"post_{current_advertiser.id}_{int(time.time())}"
            folder = data.get('folder', 'vpg/posts')
            
            # Upload to Cloudinary
            cloudinary_service = get_cloudinary_service()
            result = cloudinary_service.upload_base64_image(
                data['image'],
                folder=folder,
                public_id=public_id
            )
            
            if not result['success']:
                api.abort(400, f'Image upload failed: {result["error"]}')
            
            return {
                'success': True,
                'image_url': result['secure_url'],
                'public_id': result['public_id'],
                'width': result.get('width'),
                'height': result.get('height'),
                'format': result.get('format')
            }, 201
            
        except Exception as e:
            api.abort(500, f'Failed to upload image: {str(e)}')

@api.route('/')
class PostList(Resource):
    @api.doc('list_posts')
    @token_required
    def get(self, current_user):
        """Get all posts (feed)"""
        print(f"DEBUG: GET posts - current_user: {current_user}")
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
                # Likes info
                likes_count = PostLike.query.filter_by(post_id=post.id).count()
                liked_by_me = False
                try:
                    liked_by_me = PostLike.query.filter_by(post_id=post.id, user_id=getattr(current_user, 'id', None)).first() is not None
                except Exception:
                    liked_by_me = False
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': likes_count,
                    'liked_by_me': liked_by_me,
                    'advertiser': {
                        'id': advertiser.id if advertiser else None,
                        'name': advertiser.name if advertiser else 'Unknown Advertiser',
                        'username': advertiser.username if advertiser else 'unknown'
                    }
                }
                result.append(post_dict)
            return {
                'items': result,
                'total': posts.total,
                'pages': posts.pages,
                'current_page': posts.page,
                'per_page': posts.per_page,
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve posts: {str(e)}')
    
    @api.doc('create_post')
    @api.expect(post_create_model)
    @api.marshal_with(post_model)
    @advertiser_required
    def post(self, current_advertiser):
        """Create a new post with image upload to Cloudinary"""
        print("=== POST CREATION DEBUG START ===")
        print(f"DEBUG: current_advertiser parameter: {current_advertiser}")
        print(f"DEBUG: current_advertiser type: {type(current_advertiser)}")
        
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
            
            if not data.get('image'):
                print("DEBUG: image data is missing")
                api.abort(400, 'image is required')
            
            # Verify current_advertiser has the required attributes
            if not hasattr(current_advertiser, 'id'):
                print(f"DEBUG: current_advertiser has no 'id' attribute. Available attributes: {dir(current_advertiser)}")
                api.abort(401, 'Invalid advertiser object - missing ID')
            
            advertiser_id = current_advertiser.id
            print(f"DEBUG: Using advertiser_id: {advertiser_id}")
            
            # Upload image to Cloudinary first
            public_id = f"post_{advertiser_id}_{int(time.time())}"
            cloudinary_service = get_cloudinary_service()
            upload_result = cloudinary_service.upload_base64_image(
                data['image'],
                folder='vpg/posts',
                public_id=public_id
            )
            
            if not upload_result['success']:
                print(f"DEBUG: Image upload failed: {upload_result['error']}")
                api.abort(400, f'Image upload failed: {upload_result["error"]}')
            
            image_url = upload_result['secure_url']
            print(f"DEBUG: Image uploaded successfully: {image_url}")
            
            # Create post with the Cloudinary URL
            post = Post(
                advertiser_id=advertiser_id,
                image_url=image_url,
                caption=data.get('caption', '')
            )
            
            print(f"DEBUG: Created post object: advertiser_id={post.advertiser_id}, image_url={post.image_url}")
            
            db.session.add(post)
            db.session.commit()
            
            # Refresh to get the generated ID and timestamps
            db.session.refresh(post)
            
            result = {
                'id': post.id,
                'advertiser_id': post.advertiser_id,
                'image_url': post.image_url,
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


# Updated AdvertiserPosts endpoint with correct table references
@api.route('/advertiser/<int:advertiser_id>')
class AdvertiserPosts(Resource):
    @api.doc('get_advertiser_posts')
    @token_required
    def get(self, current_advertiser, advertiser_id):
        """Get all posts by a specific advertiser ID"""
        try:
            # Verify the advertiser exists
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, f'Advertiser with ID {advertiser_id} not found')
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)
            
            posts = Post.query.filter_by(
                advertiser_id=advertiser_id
            ).order_by(
                Post.created_at.desc()
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for post in posts.items:
                # Fix: Use correct table name 'post_like' instead of 'post_likes'
                likes_count = PostLike.query.filter_by(post_id=post.id).count()
                
                # Check if current user liked this post
                liked_by_me = False
                try:
                    if hasattr(current_advertiser, 'id') and current_advertiser.id:
                        liked_by_me = PostLike.query.filter_by(
                            post_id=post.id, 
                            user_id=current_advertiser.id
                        ).first() is not None
                except Exception as e:
                    print(f"Error checking if post {post.id} is liked: {e}")
                    liked_by_me = False
                
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': likes_count,
                    'liked_by_me': liked_by_me,
                    'advertiser': {
                        'id': advertiser.id,
                        'name': advertiser.name,
                        'username': advertiser.username
                    }
                }
                result.append(post_dict)
            
            return {
                'posts': result,
                'total': posts.total,
                'pages': posts.pages,
                'current_page': posts.page,
                'per_page': posts.per_page,
                'advertiser_info': {
                    'id': advertiser.id,
                    'name': advertiser.name,
                    'username': advertiser.username
                }
            }
            
        except Exception as e:
            print(f"Error fetching posts for advertiser {advertiser_id}: {str(e)}")
            api.abort(500, f'Failed to retrieve posts for advertiser: {str(e)}')

# Also update your existing PostList endpoint's GET method
@api.route('/')
class PostList(Resource):
    @api.doc('list_posts')
    @token_required
    def get(self, current_user):
        """Get all posts (feed)"""
        print(f"DEBUG: GET posts - current_user: {current_user}")
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
                # Fix: Use correct table name 'post_like' instead of 'post_likes'
                likes_count = PostLike.query.filter_by(post_id=post.id).count()
                liked_by_me = False
                try:
                    liked_by_me = PostLike.query.filter_by(
                        post_id=post.id, 
                        user_id=getattr(current_user, 'id', None)
                    ).first() is not None
                except Exception as e:
                    print(f"Error checking if post {post.id} is liked: {e}")
                    liked_by_me = False
                    
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': likes_count,
                    'liked_by_me': liked_by_me,
                    'advertiser': {
                        'id': advertiser.id if advertiser else None,
                        'name': advertiser.name if advertiser else 'Unknown Advertiser',
                        'username': advertiser.username if advertiser else 'unknown'
                    }
                }
                result.append(post_dict)
            return {
                'items': result,
                'total': posts.total,
                'pages': posts.pages,
                'current_page': posts.page,
                'per_page': posts.per_page,
            }
            
        except Exception as e:
            print(f"Error in PostList GET: {e}")
            api.abort(500, f'Failed to retrieve posts: {str(e)}')

# Update MyPosts endpoint as well
@api.route('/my-posts')
class MyPosts(Resource):
    @api.doc('get_my_posts')
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
                # Fix: Use correct table name 'post_like' instead of 'post_likes'
                likes_count = PostLike.query.filter_by(post_id=post.id).count()
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': likes_count
                }
                result.append(post_dict)
            
            return result
            
        except Exception as e:
            print(f"Error in MyPosts GET: {e}")
            api.abort(500, f'Failed to retrieve your posts: {str(e)}')
# Updated AdvertiserPosts endpoint with correct table references
@api.route('/advertiser/<int:advertiser_id>')
class AdvertiserPosts(Resource):
    @api.doc('get_advertiser_posts')
    @token_required
    def get(self, current_advertiser, advertiser_id):
        """Get all posts by a specific advertiser ID"""
        try:
            # Verify the advertiser exists
            advertiser = Advertiser.find_by_id(advertiser_id)
            if not advertiser:
                api.abort(404, f'Advertiser with ID {advertiser_id} not found')
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)
            
            posts = Post.query.filter_by(
                advertiser_id=advertiser_id
            ).order_by(
                Post.created_at.desc()
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for post in posts.items:
                # Fix: Use correct table name 'post_like' instead of 'post_likes'
                likes_count = PostLike.query.filter_by(post_id=post.id).count()
                
                # Check if current user liked this post
                liked_by_me = False
                try:
                    if hasattr(current_advertiser, 'id') and current_advertiser.id:
                        liked_by_me = PostLike.query.filter_by(
                            post_id=post.id, 
                            user_id=current_advertiser.id
                        ).first() is not None
                except Exception as e:
                    print(f"Error checking if post {post.id} is liked: {e}")
                    liked_by_me = False
                
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': likes_count,
                    'liked_by_me': liked_by_me,
                    'advertiser': {
                        'id': advertiser.id,
                        'name': advertiser.name,
                        'username': advertiser.username
                    }
                }
                result.append(post_dict)
            
            return {
                'posts': result,
                'total': posts.total,
                'pages': posts.pages,
                'current_page': posts.page,
                'per_page': posts.per_page,
                'advertiser_info': {
                    'id': advertiser.id,
                    'name': advertiser.name,
                    'username': advertiser.username
                }
            }
            
        except Exception as e:
            print(f"Error fetching posts for advertiser {advertiser_id}: {str(e)}")
            api.abort(500, f'Failed to retrieve posts for advertiser: {str(e)}')

# Also update your existing PostList endpoint's GET method
@api.route('/')
class PostList(Resource):
    @api.doc('list_posts')
    @token_required
    def get(self, current_user):
        """Get all posts (feed)"""
        print(f"DEBUG: GET posts - current_user: {current_user}")
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
                # Fix: Use correct table name 'post_like' instead of 'post_likes'
                likes_count = PostLike.query.filter_by(post_id=post.id).count()
                liked_by_me = False
                try:
                    liked_by_me = PostLike.query.filter_by(
                        post_id=post.id, 
                        user_id=getattr(current_user, 'id', None)
                    ).first() is not None
                except Exception as e:
                    print(f"Error checking if post {post.id} is liked: {e}")
                    liked_by_me = False
                    
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': likes_count,
                    'liked_by_me': liked_by_me,
                    'advertiser': {
                        'id': advertiser.id if advertiser else None,
                        'name': advertiser.name if advertiser else 'Unknown Advertiser',
                        'username': advertiser.username if advertiser else 'unknown'
                    }
                }
                result.append(post_dict)
            return {
                'items': result,
                'total': posts.total,
                'pages': posts.pages,
                'current_page': posts.page,
                'per_page': posts.per_page,
            }
            
        except Exception as e:
            print(f"Error in PostList GET: {e}")
            api.abort(500, f'Failed to retrieve posts: {str(e)}')

# Update MyPosts endpoint as well
@api.route('/my-posts')
class MyPosts(Resource):
    @api.doc('get_my_posts')
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
                # Fix: Use correct table name 'post_like' instead of 'post_likes'
                likes_count = PostLike.query.filter_by(post_id=post.id).count()
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': likes_count
                }
                result.append(post_dict)
            
            return result
            
        except Exception as e:
            print(f"Error in MyPosts GET: {e}")
            api.abort(500, f'Failed to retrieve your posts: {str(e)}')
                    
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
            likes_count = PostLike.query.filter_by(post_id=post.id).count()
            return {
                'id': post.id,
                'advertiser_id': post.advertiser_id,
                'image_url': post.image_url,
                'caption': post.caption,
                'created_at': post.created_at.isoformat() if post.created_at else None,
                'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                'likes_count': likes_count,
                'advertiser': {
                    'id': advertiser.id if advertiser else None,
                    'name': advertiser.name if advertiser else 'Unknown Advertiser',
                    'username': advertiser.username if advertiser else 'unknown'
                }
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve post: {str(e)}')

@api.route('/<int:post_id>/like')
class PostLikeResource(Resource):
    @api.doc('like_post')
    @token_required
    def post(self, current_user, post_id):
        """Like a post (idempotent)."""
        try:
            post = Post.query.get(post_id)
            if not post:
                api.abort(404, 'Post not found')
            # Idempotent like
            existing = PostLike.query.filter_by(post_id=post_id, user_id=current_user.id).first()
            if existing:
                return {'message': 'Already liked'}, 200
            like = PostLike(post_id=post_id, user_id=current_user.id)
            db.session.add(like)
            db.session.commit()
            count = PostLike.query.filter_by(post_id=post_id).count()
            return {'message': 'Liked', 'likes_count': count}
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to like post: {str(e)}')

    @api.doc('unlike_post')
    @token_required
    def delete(self, current_user, post_id):
        """Unlike a post (idempotent)."""
        try:
            like = PostLike.query.filter_by(post_id=post_id, user_id=current_user.id).first()
            if not like:
                return {'message': 'Not liked'}, 200
            db.session.delete(like)
            db.session.commit()
            count = PostLike.query.filter_by(post_id=post_id).count()
            return {'message': 'Unliked', 'likes_count': count}
        except Exception as e:
            db.session.rollback()
            api.abort(500, f'Failed to unlike post: {str(e)}')
    
    @api.doc('update_post')
    @api.expect(post_update_model)
    @api.marshal_with(post_model)
    @advertiser_required
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
            print(f"DEBUG: Current post data - image_url: {post.image_url}, caption: {post.caption}")
            
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
            old_image_url = post.image_url
            
            # Update caption if provided
            if 'caption' in data:
                old_caption = post.caption
                post.caption = data['caption']
                print(f"DEBUG: Caption update - old: '{old_caption}' -> new: '{post.caption}'")
                changes_made = True
            
            # Update image if provided
            if 'image' in data:
                if not data['image']:
                    print("DEBUG: Empty image data provided")
                    api.abort(400, 'image data cannot be empty')
                
                # Upload new image to Cloudinary
                public_id = f"post_{current_advertiser.id}_{post_id}_{int(time.time())}"
                cloudinary_service = get_cloudinary_service()
                upload_result = cloudinary_service.upload_base64_image(
                    data['image'],
                    folder='vpg/posts',
                    public_id=public_id
                )
                
                if not upload_result['success']:
                    print(f"DEBUG: Image upload failed: {upload_result['error']}")
                    api.abort(400, f'Image upload failed: {upload_result["error"]}')
                
                # Update with new image URL
                post.image_url = upload_result['secure_url']
                print(f"DEBUG: Image update - old: '{old_image_url}' -> new: '{post.image_url}'")
                changes_made = True
                
                # Optionally delete old image from Cloudinary if you want to clean up
                # You'd need to extract the public_id from the old URL to do this
            
            if not changes_made:
                print("DEBUG: No changes made")
                api.abort(400, 'At least one field (caption or image) must be provided for update')
            
            print("DEBUG: About to commit changes...")
            db.session.commit()
            print("DEBUG: Changes committed successfully")
            
            # Refresh the post to get updated timestamp
            db.session.refresh(post)
            print(f"DEBUG: Post after refresh - image_url: {post.image_url}, caption: {post.caption}")
            
            result = {
                'id': post.id,
                'advertiser_id': post.advertiser_id,
                'image_url': post.image_url,
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
    @advertiser_required
    def delete(self, current_advertiser, post_id):
        """Delete post (only by owner)"""
        try:
            post = Post.query.get(post_id)
            if not post:
                api.abort(404, 'Post not found')
            
            if post.advertiser_id != current_advertiser.id:
                api.abort(403, 'Can only delete your own posts')
            
            # Optionally delete image from Cloudinary
            # You'd need to extract public_id from image_url to do this
            # Example: cloudinary_service.delete_image(public_id)
            
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
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': PostLike.query.filter_by(post_id=post.id).count()
                }
                result.append(post_dict)
            
            return result
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve your posts: {str(e)}')
# Add this new endpoint to your posts.py file

@api.route('/<int:post_id>/likes')
class PostLikesResource(Resource):
    @api.doc('get_post_likes')
    @token_required
    def get(self, current_advertiser, post_id):
        """Get list of users who liked a post"""
        try:
            post = Post.query.get(post_id)
            if not post:
                api.abort(404, 'Post not found')
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 20, type=int)
            
            # Get likes with advertiser information
            likes = db.session.query(PostLike).join(
                Advertiser, PostLike.user_id == Advertiser.id
            ).filter(
                PostLike.post_id == post_id
            ).order_by(
                PostLike.created_at.desc()
            ).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for like in likes.items:
                advertiser = Advertiser.find_by_id(like.user_id)
                if advertiser:
                    like_dict = {
                        'id': like.id,
                        'user_id': like.user_id,
                        'created_at': like.created_at.isoformat() if hasattr(like, 'created_at') and like.created_at else None,
                        'advertiser': {
                            'id': advertiser.id,
                            'name': advertiser.name,
                            'username': advertiser.username,
                            'profile_image_url': getattr(advertiser, 'profile_image_url', None)
                        }
                    }
                    result.append(like_dict)
            
            return {
                'likes': result,
                'total': likes.total,
                'pages': likes.pages,
                'current_page': likes.page,
                'per_page': likes.per_page,
            }
            
        except Exception as e:
            print(f"Error fetching likes for post {post_id}: {str(e)}")
            
            
        except Exception as e:
            print(f"Error fetching likes for post {post_id}: {str(e)}")
            api.abort(500, f'Failed to retrieve post likes: {str(e)}')

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
                likes_count = PostLike.query.filter_by(post_id=post.id).count()
                post_dict = {
                    'id': post.id,
                    'advertiser_id': post.advertiser_id,
                    'image_url': post.image_url,
                    'caption': post.caption,
                    'created_at': post.created_at.isoformat() if post.created_at else None,
                    'updated_at': post.updated_at.isoformat() if post.updated_at else None,
                    'likes_count': likes_count,
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

