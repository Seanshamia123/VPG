from datetime import datetime
from uuid import UUID
import uuid
from database import db

class Post(db.Model):
    __tablename__ = 'posts'
    id = db.Column(db.Integer,primary_key=True)
    advertiser_id = db.Column(db.ForeignKey('advertisers.id', ondelete='CASCADE'), nullable=False)
    image_id = db.Column(db.Text)
    caption = db.Column(db.Text)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())