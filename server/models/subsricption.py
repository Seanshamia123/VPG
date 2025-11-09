# models/subscription.py - Enhanced Subscription Model
from datetime import datetime, timedelta
from database import db
from sqlalchemy import event

class Subscription(db.Model):
    __tablename__ = 'subscriptions'
    
    # Primary Key
    id = db.Column(db.Integer, primary_key=True)
    
    # Foreign Key - Links to advertisers table
    user_id = db.Column(db.Integer, db.ForeignKey('advertisers.id', ondelete='CASCADE'), nullable=False)
    
    # Plan Information
    plan_id = db.Column(db.String(50), nullable=False)
    plan_name = db.Column(db.String(100), nullable=False)
    
    # Payment Information
    amount_paid = db.Column(db.DECIMAL(10, 2), nullable=False)
    currency = db.Column(db.String(3), nullable=False, default='KES')
    payment_method = db.Column(db.String(50), default='IntaSend')
    
    # Payment Details
    checkout_id = db.Column(db.String(100), nullable=True)
    invoice_id = db.Column(db.String(100), nullable=True)
    payment_reference = db.Column(db.String(100), nullable=True, unique=True)
    intasend_tracking_id = db.Column(db.String(100), nullable=True)
    
    # Subscription Period
    start_date = db.Column(db.TIMESTAMP, nullable=False, default=db.func.current_timestamp())
    end_date = db.Column(db.TIMESTAMP, nullable=False)
    
    # Status Tracking
    status = db.Column(db.String(20), default='pending')
    payment_status = db.Column(db.String(20), default='pending')
    
    # Auto-renewal Settings (Set to 3rd of each month)
    auto_renew = db.Column(db.Boolean, default=True)
    renewal_day = db.Column(db.Integer, default=3)  # 3rd of each month
    next_billing_date = db.Column(db.TIMESTAMP, nullable=True)
    
    # Email Notification Tracking
    reminder_7days_sent = db.Column(db.Boolean, default=False)
    reminder_3days_sent = db.Column(db.Boolean, default=False)
    last_reminder_sent = db.Column(db.TIMESTAMP, nullable=True)
    
    # Cancellation Tracking
    cancelled_at = db.Column(db.TIMESTAMP, nullable=True)
    cancellation_reason = db.Column(db.Text, nullable=True)
    
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
    
    def calculate_next_billing_date(self):
        """Calculate next billing date (3rd of next month)"""
        today = datetime.utcnow()
        
        # If we're before the 3rd this month, next billing is 3rd of this month
        if today.day < self.renewal_day:
            next_date = datetime(today.year, today.month, self.renewal_day)
        else:
            # Otherwise, it's 3rd of next month
            if today.month == 12:
                next_date = datetime(today.year + 1, 1, self.renewal_day)
            else:
                next_date = datetime(today.year, today.month + 1, self.renewal_day)
        
        return next_date
    
    def is_active(self):
        """Check if subscription is currently active"""
        if self.status == 'cancelled':
            return False
        
        return (
            self.status == 'active' and 
            self.payment_status == 'completed' and
            datetime.utcnow() <= self.end_date
        )
    
    def days_remaining(self):
        """Calculate days remaining in subscription"""
        if not self.is_active():
            return 0
        
        delta = self.end_date - datetime.utcnow()
        return max(0, delta.days)
    
    def days_until_renewal(self):
        """Calculate days until next renewal"""
        if not self.next_billing_date:
            return None
        
        delta = self.next_billing_date - datetime.utcnow()
        return max(0, delta.days)
    
    def needs_7day_reminder(self):
        """Check if 7-day reminder should be sent"""
        if not self.auto_renew or self.reminder_7days_sent:
            return False
        
        days_until = self.days_until_renewal()
        return days_until is not None and days_until <= 7 and days_until > 3
    
    def needs_3day_reminder(self):
        """Check if 3-day reminder should be sent"""
        if not self.auto_renew or self.reminder_3days_sent:
            return False
        
        days_until = self.days_until_renewal()
        return days_until is not None and days_until <= 3 and days_until > 0
    
    def cancel(self, reason=None):
        """Cancel subscription"""
        self.status = 'cancelled'
        self.auto_renew = False
        self.cancelled_at = datetime.utcnow()
        self.cancellation_reason = reason
    
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
            'renewal_day': self.renewal_day,
            'next_billing_date': self.next_billing_date.isoformat() if self.next_billing_date else None,
            'days_remaining': self.days_remaining(),
            'days_until_renewal': self.days_until_renewal(),
            'is_active': self.is_active(),
            'cancelled_at': self.cancelled_at.isoformat() if self.cancelled_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }


# Event listener to set next_billing_date when subscription is activated
@event.listens_for(Subscription, 'before_insert')
@event.listens_for(Subscription, 'before_update')
def set_next_billing_date(mapper, connection, target):
    """Automatically set next_billing_date when subscription becomes active"""
    if target.status == 'active' and target.payment_status == 'completed':
        if not target.next_billing_date and target.auto_renew:
            target.next_billing_date = target.calculate_next_billing_date()
            target.reminder_7days_sent = False
            target.reminder_3days_sent = False