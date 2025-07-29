from datetime import datetime
from . import db

class Advertiser(db.Model):
    __tablename__ = 'advertisers'
    
    id = db.Column(db.Integer,primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False) #prefered username by the user himself
    name = db.Column(db.String(255), nullable=False, index=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    phone_number = db.Column(db.String(20), nullable=False)
    location = db.Column(db.String(255), nullable=False)
    gender = db.Column(db.Enum('Male', 'Female', 'other', name='advertiser_gender_enum'), nullable=False)
    profile_image_url = db.Column(db.String(500), nullable=True)  # URL or file path
    is_verified = db.Column(db.Boolean, default=False)
    is_online = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    last_active = db.Column(db.TIMESTAMP)
    bio = db.Column(db.Text)
    password_hash = db.Column(db.String(100))

    # Add indexes for better performance
    __table_args__ = (
        db.Index('idx_advertiser_name', 'name'),
        db.Index('idx_advertiser_email', 'email'),
        db.Index('idx_advertiser_location', 'location'),
        db.Index('idx_advertiser_gender', 'gender'),
        db.Index('idx_advertiser_verified', 'is_verified'),
    
        db.Index('idx_advertiser_password', 'password_hash'),
        db.Index('idx_advertiser_online', 'is_online'),
        db.Index('idx_advertiser_active', 'last_active'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'number': self.number,
            'location': self.location,
            'gender': self.gender,
            'profile_image_url': self.profile_image_url,
            'is_verified': self.is_verified,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'updated_at': self.updated_at.isoformat()
        }
    
    def to_dict_safe(self):
        """Return dict without sensitive information"""
        return {
            'id': self.id,
            'name': self.name,
            'location': self.location,
            'gender': self.gender,
            'profile_image_url': self.profile_image_url,
            'is_verified': self.is_verified,
            'created_at': self.created_at.isoformat()
        }
    
    def __repr__(self):
        return f'<Advertiser {self.name}>'
    
    @classmethod
    def find_by_email(cls, email):
        return cls.query.filter_by(email=email).first()
    
    @classmethod
    def find_by_id(cls, advertiser_id):
        return cls.query.get(advertiser_id)
    
    @classmethod
    def get_all_active(cls):
        return cls.query.filter_by(is_active=True).all()
    
    @classmethod
    def get_all_verified(cls):
        return cls.query.filter_by(is_verified=True, is_active=True).all()
    
    @classmethod
    def get_by_location(cls, location):
        return cls.query.filter_by(location=location, is_active=True).all()
    
    def save(self):
        db.session.add(self)
        db.session.commit()
        
    def delete(self):
        db.session.delete(self)
        db.session.commit()
        
    def update(self, **kwargs):
        for key, value in kwargs.items():
            if hasattr(self, key):
                setattr(self, key, value)
        self.updated_at = datetime.utcnow()
        db.session.commit()
    
    def verify(self):
        """Mark advertiser as verified"""
        self.is_verified = True
        self.updated_at = datetime.utcnow()
        db.session.commit()
    
    def unverify(self):
        """Mark advertiser as unverified"""
        self.is_verified = False
        self.updated_at = datetime.utcnow()
        db.session.commit()