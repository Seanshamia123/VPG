from datetime import datetime
from database import db

class Comment(db.Model):
    __tablename__ = 'comments'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    target_type = db.Column(db.Enum('post', 'profile', name='comment_target_type'), nullable=False)
    target_id = db.Column(db.Integer, nullable=True)
    parent_comment_id = db.Column(db.ForeignKey('comments.id'))
    content = db.Column(db.Text, nullable=False)
    likes_count = db.Column(db.Integer, default=0)
    is_deleted = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())
    replies = db.relationship('Comment', backref=db.backref('parent', remote_side=[id]), lazy=True)