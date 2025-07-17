from datetime import datetime

from . import db

class AuthToken(db.Model):
    __tablename__ = 'auth_tokens'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    access_token = db.Column(db.Text, nullable=False)
    refresh_token = db.Column(db.Text, nullable=False)
    user_agent = db.Column(db.Text)
    ip_address = db.Column(db.Text)
    expires_at = db.Column(db.TIMESTAMP)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())