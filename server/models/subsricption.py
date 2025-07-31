from datetime import datetime
from uuid import UUID
import uuid
from database import db
class Subscription(db.Model):
    __tablename__ = 'subscriptions'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    amount_paid = db.Column(db.DECIMAL(10,2))
    payment_method = db.Column(db.String(20))
    start_date = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    end_date = db.Column(db.TIMESTAMP)
    status = db.Column(db.String(20), default='active')
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())