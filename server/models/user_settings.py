from datetime import datetime
from uuid import UUID
import uuid
from database import db

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
    
def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "notification_enabled": self.notification_enabled,
            "dark_mode_enabled": self.dark_mode_enabled,
            "show_online_status": self.show_online_status,
            "read_receipts": self.read_receipts,
            "selected_language": self.selected_language,
            "selected_theme": self.selected_theme
        }