from flask import request, jsonify
from flask_restx import Namespace, Resource, fields
from models import Comment, CommentLike, User, Post, db
from .decorators import token_required

api = Namespace('comments', description='Comment management operations')

# Models for Swagger documentation
comment_model = api.model('Comment', {
    'id': fields.Integer(description='Comment ID'),
    'user_id': fields.Integer(description='User ID who created the comment'),
    'target_type': fields.String(description='Type of target (post/profile)'),
    'target_id': fields.Integer(description='ID of the target'),
    'parent_comment_id': fields.Integer(description='Parent comment ID for replies'),
    'content': fields.String(description='Comment content'),
    'likes_count': fields.Integer(description='Number of likes'),
    'is_deleted': fields.Boolean(description='Whether comment is deleted'),
    'created_at': fields.String(description='Creation timestamp'),
    'updated_at': fields.String(description='Last update timestamp')
})

comment_create_model = api.model('CommentCreate', {
    'target_type': fields.String(required=True, description='Type of target', enum=['post', 'profile']),
    'target_id': fields.Integer(required=True, description='ID of the target'),
    'parent_comment_id': fields.Integer(description='Parent comment ID for replies'),
    'content': fields.String(required=True, description='Comment content')
})

comment_update_model = api.model('CommentUpdate', {
    'content': fields.String(required=True, description='Updated comment content')
})

comment_with_user_model = api.model('CommentWithUser', {
    'id': fields.Integer(description='Comment ID'),
    'user_id': fields.Integer(description='User ID'),
    'target_type': fields.String(description='Target type'),
    'target_id': fields.Integer(description='Target ID'),
    'parent_comment_id': fields.Integer(description='Parent comment ID'),
    'content': fields.String(description='Comment content'),
    'likes_count': fields.Integer(description='Number of likes'),
    'created_at': fields.String(description='Creation timestamp'),
    'user': fields.Nested(api.model('CommentUser', {
        'id': fields.Integer(description='User ID'),
        'name': fields.String(description='User name'),
        'username': fields.String(description='Username')
    })),
    'replies': fields.List(fields.Nested(api.model('CommentReply', {
        'id': fields.Integer(description='Reply ID'),
        'content': fields.String(description='Reply content'),
        'user': fields.Nested(api.model('ReplyUser', {
            'id': fields.Integer(description='User ID'),
            'name': fields.String(description='User name'),
            'username': fields.String(description='Username')
        })),
        'created_at': fields.String(description='Creation timestamp')
    })))
})

@api.route('/')
class CommentList(Resource):
    @api.doc('create_comment')
    @api.expect(comment_create_model)
    @token_required
    def post(self, current_user):
        """Create a new comment"""
        try:
            data = request.get_json()
            
            target_type = data.get('target_type')
            target_id = data.get('target_id')
            content = data.get('content')
            parent_comment_id = data.get('parent_comment_id')
            
            if not all([target_type, target_id, content]):
                return {'error': 'target_type, target_id, and content are required'}, 400
            
            # Validate target exists
            if target_type == 'post':
                target = Post.query.get(target_id)
                if not target:
                    return {'error': 'Post not found'}, 404
            elif target_type == 'profile':
                target = User.find_by_id(target_id)
                if not target:
                    return {'error': 'User profile not found'}, 404
            else:
                return {'error': 'Invalid target_type'}, 400
            
            # Handle parent_comment_id properly
            if parent_comment_id in [0, None, '', '0']:
                parent_comment_id = None
            else:
                parent_comment = Comment.query.get(parent_comment_id)
                if not parent_comment:
                    return {'error': 'Parent comment not found'}, 404
                if parent_comment.target_type != target_type or parent_comment.target_id != target_id:
                    return {'error': 'Parent comment must be on the same target'}, 400
            
            comment = Comment(
                user_id=current_user.id,
                target_type=target_type,
                target_id=target_id,
                parent_comment_id=parent_comment_id,
                content=content
            )
            
            db.session.add(comment)
            db.session.commit()
            
            # Return complete comment data with user information
            return {
                'success': True,
                'comment': {
                    'id': comment.id,
                    'user_id': comment.user_id,
                    'target_type': comment.target_type,
                    'target_id': comment.target_id,
                    'parent_comment_id': comment.parent_comment_id,
                    'content': comment.content,
                    'likes_count': comment.likes_count,
                    'is_deleted': comment.is_deleted,
                    'created_at': comment.created_at.isoformat() if comment.created_at else None,
                    'updated_at': comment.updated_at.isoformat() if comment.updated_at else None,
                    'advertiser': {  # Match frontend expectation
                        'id': current_user.id,
                        'name': current_user.name,
                        'username': current_user.username
                    }
                }
            }, 201
            
        except Exception as e:
            print(f"Comment creation error: {str(e)}")
            return {'error': f'Failed to create comment: {str(e)}'}, 500

@api.route('/<int:comment_id>')
class CommentDetail(Resource):
    @api.doc('get_comment')
    @api.marshal_with(comment_with_user_model)
    @token_required
    def get(self, current_user, comment_id):
        """Get comment by ID with replies"""
        try:
            comment = Comment.query.get(comment_id)
            if not comment or comment.is_deleted:
                api.abort(404, 'Comment not found')
            
            user = User.find_by_id(comment.user_id)
            
            # Get replies
            replies = Comment.query.filter_by(
                parent_comment_id=comment_id,
                is_deleted=False
            ).order_by(Comment.created_at.asc()).all()
            
            reply_list = []
            for reply in replies:
                reply_user = User.find_by_id(reply.user_id)
                reply_dict = {
                    'id': reply.id,
                    'content': reply.content,
                    'user': {
                        'id': reply_user.id if reply_user else None,
                        'name': reply_user.name if reply_user else 'Unknown User',
                        'username': reply_user.username if reply_user else 'unknown'
                    },
                    'created_at': reply.created_at.isoformat() if reply.created_at else None
                }
                reply_list.append(reply_dict)
            
            return {
                'id': comment.id,
                'user_id': comment.user_id,
                'target_type': comment.target_type,
                'target_id': comment.target_id,
                'parent_comment_id': comment.parent_comment_id,
                'content': comment.content,
                'likes_count': comment.likes_count,
                'created_at': comment.created_at.isoformat() if comment.created_at else None,
                'user': {
                    'id': user.id if user else None,
                    'name': user.name if user else 'Unknown User',
                    'username': user.username if user else 'unknown'
                },
                'replies': reply_list
            }
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve comment: {str(e)}')
    
    @api.doc('update_comment')
    @api.expect(comment_update_model)
    @api.marshal_with(comment_model)
    @token_required
    def put(self, current_user, comment_id):
        """Update comment (only by owner)"""
        try:
            comment = Comment.query.get(comment_id)
            if not comment or comment.is_deleted:
                api.abort(404, 'Comment not found')
            
            if comment.user_id != current_user.id:
                api.abort(403, 'Can only update your own comments')
            
            data = request.get_json()
            comment.content = data.get('content', comment.content)
            
            db.session.commit()
            
            return {
                'id': comment.id,
                'user_id': comment.user_id,
                'target_type': comment.target_type,
                'target_id': comment.target_id,
                'parent_comment_id': comment.parent_comment_id,
                'content': comment.content,
                'likes_count': comment.likes_count,
                'is_deleted': comment.is_deleted,
                'created_at': comment.created_at.isoformat() if comment.created_at else None,
                'updated_at': comment.updated_at.isoformat() if comment.updated_at else None
            }
            
        except Exception as e:
            api.abort(500, f'Failed to update comment: {str(e)}')
    
    @api.doc('delete_comment')
    @token_required
    def delete(self, current_user, comment_id):
        """Delete comment (only by owner)"""
        try:
            comment = Comment.query.get(comment_id)
            if not comment or comment.is_deleted:
                api.abort(404, 'Comment not found')
            
            if comment.user_id != current_user.id:
                api.abort(403, 'Can only delete your own comments')
            
            # Soft delete
            comment.is_deleted = True
            db.session.commit()
            
            return {'message': 'Comment deleted successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to delete comment: {str(e)}')

@api.route('/<int:comment_id>/like')
class CommentLikeResource(Resource):
    @api.doc('like_comment')
    @token_required
    def post(self, current_user, comment_id):
        """Like a comment"""
        try:
            comment = Comment.query.get(comment_id)
            if not comment or comment.is_deleted:
                api.abort(404, 'Comment not found')
            
            # Check if already liked
            existing_like = CommentLike.query.filter_by(
                comment_id=comment_id,
                user_id=current_user.id
            ).first()
            
            if existing_like:
                api.abort(400, 'Comment already liked')
            
            # Create like
            like = CommentLike(
                comment_id=comment_id,
                user_id=current_user.id
            )
            db.session.add(like)
            
            # Update likes count
            comment.likes_count += 1
            db.session.commit()
            
            return {'message': 'Comment liked successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to like comment: {str(e)}')
    
    @api.doc('unlike_comment')
    @token_required
    def delete(self, current_user, comment_id):
        """Unlike a comment"""
        try:
            comment = Comment.query.get(comment_id)
            if not comment or comment.is_deleted:
                api.abort(404, 'Comment not found')
            
            like = CommentLike.query.filter_by(
                comment_id=comment_id,
                user_id=current_user.id
            ).first()
            
            if not like:
                api.abort(404, 'Like not found')
            
            db.session.delete(like)
            
            # Update likes count
            if comment.likes_count > 0:
                comment.likes_count -= 1
            
            db.session.commit()
            
            return {'message': 'Comment unliked successfully'}
            
        except Exception as e:
            api.abort(500, f'Failed to unlike comment: {str(e)}')

@api.route('/target/<string:target_type>/<int:target_id>')
class TargetComments(Resource):
    @api.doc('get_target_comments')
    @api.marshal_list_with(comment_with_user_model)
    @token_required
    def get(self, current_user, target_type, target_id):
        """Get comments for a specific target (post/profile)"""
        try:
            if target_type not in ['post', 'profile']:
                api.abort(400, 'Invalid target_type')
            
            page = request.args.get('page', 1, type=int)
            per_page = request.args.get('per_page', 10, type=int)
            
            # Get parent comments only (not replies)
            comments = Comment.query.filter_by(
                target_type=target_type,
                target_id=target_id,
                parent_comment_id=None,
                is_deleted=False
            ).order_by(Comment.created_at.desc()).paginate(
                page=page,
                per_page=per_page,
                error_out=False
            )
            
            result = []
            for comment in comments.items:
                user = User.find_by_id(comment.user_id)
                
                # Get replies for this comment
                replies = Comment.query.filter_by(
                    parent_comment_id=comment.id,
                    is_deleted=False
                ).order_by(Comment.created_at.asc()).all()
                
                reply_list = []
                for reply in replies:
                    reply_user = User.find_by_id(reply.user_id)
                    reply_dict = {
                        'id': reply.id,
                        'content': reply.content,
                        'user': {
                            'id': reply_user.id if reply_user else None,
                            'name': reply_user.name if reply_user else 'Unknown User',
                            'username': reply_user.username if reply_user else 'unknown'
                        },
                        'created_at': reply.created_at.isoformat() if reply.created_at else None
                    }
                    reply_list.append(reply_dict)
                
                comment_dict = {
                    'id': comment.id,
                    'user_id': comment.user_id,
                    'target_type': comment.target_type,
                    'target_id': comment.target_id,
                    'parent_comment_id': comment.parent_comment_id,
                    'content': comment.content,
                    'likes_count': comment.likes_count,
                    'created_at': comment.created_at.isoformat() if comment.created_at else None,
                    'user': {
                        'id': user.id if user else None,
                        'name': user.name if user else 'Unknown User',
                        'username': user.username if user else 'unknown'
                    },
                    'replies': reply_list
                }
                result.append(comment_dict)
            
            return result
            
        except Exception as e:
            api.abort(500, f'Failed to retrieve comments: {str(e)}')