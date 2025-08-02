from datetime import datetime
from database import db

class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer,primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False) #prefered username by the user himself
    name = db.Column(db.String(255), nullable=False, index=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    phone_number = db.Column(db.String(20), nullable=False)
    location = db.Column(db.String(255), nullable=False)
    gender = db.Column(db.Enum('Male', 'Female', 'other', name='advertiser_gender_enum'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    last_active = db.Column(db.TIMESTAMP)
    password_hash = db.Column(db.String(256))  # or 512 if you're paranoid
    profile_picture = db.Column(db.String(255))  # or Text if you're storing large data



    # Add indexes for better performance
    __table_args__ = (
        db.Index('idx_user_name', 'name'),
        db.Index('idx_user_email', 'email'),
        db.Index('idx_user_location', 'location'),
        db.Index('idx_user_gender', 'gender'),
        db.Index('idx_user_active', 'last_active'),
        db.Index('idx_advertiser_password', 'password_hash'),
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
            'created_at': self.created_at.isoformat()
        }
    
    def __repr__(self):
        return f'<User {self.name}>'
    
    @classmethod
    def find_by_email(cls, email):
        return cls.query.filter_by(email=email).first()
    
    @classmethod
    def find_by_id(cls, user_id):
        return cls.query.get(user_id)
    
    @classmethod
    def get_all_active(cls):
        return cls.query.filter_by(is_active=True).all()
    
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