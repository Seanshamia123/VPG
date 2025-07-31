from datetime import datetime
from uuid import UUID
import uuid
from database import db
class Message(db.Model):
    __tablename__ = 'messages'
    id = db.Column(db.Integer,primary_key=True)
    conversation_id = db.Column(db.ForeignKey('conversations.id', ondelete='CASCADE'), nullable=False)
    sender_id = db.Column(db.ForeignKey('users.id', ondelete='SET NULL'))
    content = db.Column(db.Text)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())