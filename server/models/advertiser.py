from datetime import datetime
from . import db

class Advertiser(db.Model):
    __tablename__ = 'advertisers'
    
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(255), nullable=False, index=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    number = db.Column(db.String(20), nullable=False)
    location = db.Column(db.String(255), nullable=False)
    gender = db.Column(db.Enum('male', 'female', 'other', name='advertiser_gender_enum'), nullable=False)
    profile_picture = db.Column(db.String(500), nullable=True)  # URL or file path
    company_name = db.Column(db.String(255), nullable=True)  # Additional field for advertisers
    business_type = db.Column(db.String(100), nullable=True)  # Type of business
    is_verified = db.Column(db.Boolean, default=False)  # Advertiser verification status
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Add indexes for better performance
    __table_args__ = (
        db.Index('idx_advertiser_name', 'name'),
        db.Index('idx_advertiser_email', 'email'),
        db.Index('idx_advertiser_location', 'location'),
        db.Index('idx_advertiser_gender', 'gender'),
        db.Index('idx_advertiser_verified', 'is_verified'),
        db.Index('idx_advertiser_active', 'is_active'),
        db.Index('idx_advertiser_business_type', 'business_type'),
    )
    
    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'number': self.number,
            'location': self.location,
            'gender': self.gender,
            'profile_picture': self.profile_picture,
            'company_name': self.company_name,
            'business_type': self.business_type,
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
            'profile_picture': self.profile_picture,
            'company_name': self.company_name,
            'business_type': self.business_type,
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