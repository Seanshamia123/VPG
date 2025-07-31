from datetime import datetime
from uuid import UUID
import uuid
from database import db
class CommentLike(db.Model):
    __tablename__ = 'comment_likes'
    id = db.Column(db.Integer,primary_key=True)
    comment_id = db.Column(db.ForeignKey('comments.id', ondelete='CASCADE'), nullable=False)
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    __table_args__ = (db.UniqueConstraint('comment_id', 'user_id', name='uq_comment_user'),)
