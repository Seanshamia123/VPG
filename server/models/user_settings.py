from datetime import datetime
from uuid import UUID
import uuid
from . import db

class UserSetting(db.Model):
    __tablename__ = 'user_settings'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    notification_enabled = db.Column(db.Boolean, default=True)
    dark_mode_enabled = db.Column(db.Boolean, default=False)
    show_online_status = db.Column(db.Boolean, default=True)
    read_receipts = db.Column(db.Boolean, default=True)
    selected_language = db.Column(db.String(20), default='en')
    selected_theme = db.Column(db.String(20), default='light')
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())
