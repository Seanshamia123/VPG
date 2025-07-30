from datetime import datetime
from uuid import UUID
import uuid
from database import db
class Conversation(db.Model):
    __tablename__ = 'conversations'

    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String(20), default='direct')
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    
    last_message_id = db.Column(
        db.Integer,
        db.ForeignKey('messages.id', use_alter=True, name='fk_last_message_id', ondelete='SET NULL'),
        nullable=True
    )

    last_message_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())
