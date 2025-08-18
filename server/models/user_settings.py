from datetime import datetime
from uuid import UUID
import uuid
from database import db


class UserSetting(db.Model):
    __tablename__ = 'user_settings'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False, unique=True)
    notification_enabled = db.Column(db.Boolean, default=True, nullable=False)
    dark_mode_enabled = db.Column(db.Boolean, default=False, nullable=False)
    show_online_status = db.Column(db.Boolean, default=True, nullable=False)
    read_receipts = db.Column(db.Boolean, default=True, nullable=False)
    selected_language = db.Column(db.String(10), default='en', nullable=False)
    selected_theme = db.Column(db.String(20), default='light', nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    def to_dict(self):
        """Convert UserSetting object to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'notification_enabled': self.notification_enabled,
            'dark_mode_enabled': self.dark_mode_enabled,
            'show_online_status': self.show_online_status,
            'read_receipts': self.read_receipts,
            'selected_language': self.selected_language,
            'selected_theme': self.selected_theme,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

    def __repr__(self):
        return f'<UserSetting {self.id}: User {self.user_id}>'