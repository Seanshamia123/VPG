from datetime import datetime
from uuid import UUID
import uuid
from database import db

class Message(db.Model):
    __tablename__ = 'messages'
    
    id = db.Column(db.Integer, primary_key=True)
    conversation_id = db.Column(
        db.ForeignKey('conversations.id', ondelete='CASCADE'), 
        nullable=False
    )
    sender_id = db.Column(
        db.Integer, 
        nullable=True  # KEEP AS NULLABLE - allows SET NULL when user is deleted
    )
    sender_type = db.Column(
        db.String(20), 
        nullable=False,  # REQUIRED - distinguishes user vs advertiser
        default='user'
    )
    content = db.Column(db.Text)
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(
        db.TIMESTAMP, 
        default=db.func.current_timestamp()
    )
    updated_at = db.Column(
        db.TIMESTAMP, 
        default=db.func.current_timestamp(), 
        onupdate=db.func.current_timestamp()
    )
    
    # Indexes for faster lookups
    __table_args__ = (
        db.Index('idx_message_sender', 'conversation_id', 'sender_id', 'sender_type'),
        db.Index('idx_message_conversation', 'conversation_id', 'created_at'),
    )