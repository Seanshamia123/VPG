# models.py - Complete Subscription and PendingPayment models
from datetime import datetime
from database import db

class Subscription(db.Model):
    __tablename__ = 'subscriptions'
    
    # Primary Key
    id = db.Column(db.Integer, primary_key=True)
    
    # Foreign Key - Links to advertisers table (not users)
    user_id = db.Column(db.Integer, db.ForeignKey('advertisers.id', ondelete='CASCADE'), nullable=False)
    
    # Plan Information
    plan_id = db.Column(db.String(50), nullable=False)  # e.g., 'basic', 'premium'
    plan_name = db.Column(db.String(100), nullable=False)  # e.g., 'Basic Plan', 'Premium Plan'
    
    # Payment Information
    amount_paid = db.Column(db.DECIMAL(10, 2), nullable=False)
    currency = db.Column(db.String(3), nullable=False, default='KES')  # KES, USD, EUR
    payment_method = db.Column(db.String(50), default='IntaSend')
    
    # IntaSend Payment Details
    checkout_id = db.Column(db.String(100), nullable=True)  # IntaSend checkout session ID
    invoice_id = db.Column(db.String(100), nullable=True)  # IntaSend invoice ID
    payment_reference = db.Column(db.String(100), nullable=True, unique=True)  # Our unique reference (SUB_xxx)
    intasend_tracking_id = db.Column(db.String(100), nullable=True)  # M-Pesa reference or card transaction ID
    
    # Subscription Period
    start_date = db.Column(db.TIMESTAMP, nullable=False, default=db.func.current_timestamp())
    end_date = db.Column(db.TIMESTAMP, nullable=False)
    
    # Status Tracking
    status = db.Column(db.String(20), default='pending')  # pending, active, cancelled, expired
    payment_status = db.Column(db.String(20), default='pending')  # pending, completed, failed, refunded
    
    # Auto-renewal Settings (for future implementation)
    auto_renew = db.Column(db.Boolean, default=False)
    next_billing_date = db.Column(db.TIMESTAMP, nullable=True)
    
    # Timestamps
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), nullable=False)
    updated_at = db.Column(
        db.TIMESTAMP, 
        default=db.func.current_timestamp(), 
        onupdate=db.func.current_timestamp(),
        nullable=False
    )
    
    # Relationships
    advertiser = db.relationship('Advertiser', backref='subscriptions')
    
    def __repr__(self):
        return f'<Subscription {self.id}: {self.plan_name} for Advertiser {self.user_id}>'
    
    def is_active(self):
        """Check if subscription is currently active"""
        return (
            self.status == 'active' and 
            self.payment_status == 'completed' and
            self.end_date > datetime.utcnow()
        )
    
    def days_remaining(self):
        """Calculate days remaining in subscription"""
        if not self.is_active():
            return 0
        
        delta = self.end_date - datetime.utcnow()
        return max(0, delta.days)
    
    def to_dict(self):
        """Convert subscription to dictionary for API responses"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'plan_id': self.plan_id,
            'plan_name': self.plan_name,
            'amount_paid': str(self.amount_paid),
            'currency': self.currency,
            'payment_method': self.payment_method,
            'checkout_id': self.checkout_id,
            'invoice_id': self.invoice_id,
            'payment_reference': self.payment_reference,
            'intasend_tracking_id': self.intasend_tracking_id,
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'status': self.status,
            'payment_status': self.payment_status,
            'auto_renew': self.auto_renew,
            'next_billing_date': self.next_billing_date.isoformat() if self.next_billing_date else None,
            'days_remaining': self.days_remaining(),
            'is_active': self.is_active(),
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }


class PendingPayment(db.Model):
    """Track payment sessions in progress"""
    __tablename__ = 'pending_payments'
    
    # Primary Key
    id = db.Column(db.Integer, primary_key=True)
    
    # Foreign Key - Links to advertisers table
    user_id = db.Column(db.Integer, db.ForeignKey('advertisers.id', ondelete='CASCADE'), nullable=False)
    
    # Payment Session Details
    checkout_id = db.Column(db.String(100), nullable=False, unique=True)
    checkout_url = db.Column(db.Text, nullable=True)  # May be null for M-Pesa STK Push
    payment_reference = db.Column(db.String(100), nullable=False, unique=True)
    
    # Plan and Amount
    plan_id = db.Column(db.String(50), nullable=False)
    amount = db.Column(db.DECIMAL(10, 2), nullable=False)
    currency = db.Column(db.String(3), nullable=False)
    
    # Status and Timestamps
    status = db.Column(db.String(20), default='pending')  # pending, completed, failed, expired
    expires_at = db.Column(db.TIMESTAMP, nullable=False)  # Payment session expiry (24 hours)
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), nullable=False)
    updated_at = db.Column(
        db.TIMESTAMP, 
        default=db.func.current_timestamp(), 
        onupdate=db.func.current_timestamp(),
        nullable=False
    )
    
    # Relationships
    advertiser = db.relationship('Advertiser', backref='pending_payments')
    
    def __repr__(self):
        return f'<PendingPayment {self.id}: {self.checkout_id} for Advertiser {self.user_id}>'
    
    def is_expired(self):
        """Check if payment session has expired"""
        return datetime.utcnow() > self.expires_at
    
    def to_dict(self):
        return {
            'id': self.id,
            'checkout_id': self.checkout_id,
            'checkout_url': self.checkout_url,
            'payment_reference': self.payment_reference,
            'plan_id': self.plan_id,
            'amount': str(self.amount),
            'currency': self.currency,
            'status': self.status,
            'expires_at': self.expires_at.isoformat(),
            'is_expired': self.is_expired(),
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
