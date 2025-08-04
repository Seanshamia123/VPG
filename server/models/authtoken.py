from datetime import datetime
from database import db

class AuthToken(db.Model):
    __tablename__ = 'auth_tokens'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)  # Store ID without FK constraint
    user_type = db.Column(db.Enum('user', 'advertiser', name='user_type_enum'), nullable=False)  # Track type
    access_token = db.Column(db.String(512), index=True)
    refresh_token = db.Column(db.String(512))

    expires_at = db.Column(db.TIMESTAMP)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    
    # Add indexes for better performance
    __table_args__ = (
        db.Index('idx_auth_token_user', 'user_id', 'user_type'),
        db.Index('idx_auth_token_access', 'access_token'),
        db.Index('idx_auth_token_refresh', 'refresh_token'),
        db.Index('idx_auth_token_expires', 'expires_at'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'user_type': self.user_type,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }
    
    @classmethod
    def find_by_access_token(cls, access_token):
        return cls.query.filter_by(access_token=access_token).first()
    
    @classmethod
    def find_by_refresh_token(cls, refresh_token):
        return cls.query.filter_by(refresh_token=refresh_token).first()
    
    @classmethod
    def find_by_user(cls, user_id, user_type):
        return cls.query.filter_by(user_id=user_id, user_type=user_type).all()
    
    @classmethod
    def delete_expired_tokens(cls):
        """Delete all expired tokens"""
        expired_tokens = cls.query.filter(cls.expires_at < datetime.utcnow()).all()
        for token in expired_tokens:
            db.session.delete(token)
        db.session.commit()
        return len(expired_tokens)
    
    def save(self):
        db.session.add(self)
        db.session.commit()
        
    def delete(self):
        db.session.delete(self)
        db.session.commit()