# Updated subscription.py model
from datetime import datetime
from uuid import UUID
import uuid
from database import db

class Subscription(db.Model):
    __tablename__ = 'subscriptions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    
    # Plan information
    plan_id = db.Column(db.String(50), nullable=False)  # e.g., 'premium_monthly'
    plan_name = db.Column(db.String(100), nullable=False)
    
    # Payment information
    amount_paid = db.Column(db.DECIMAL(10,2), nullable=False)
    currency = db.Column(db.String(3), nullable=False, default='KES')  # KES, USD, EUR
    payment_method = db.Column(db.String(50), default='IntaSend')
    
    # IntaSend payment details
    checkout_id = db.Column(db.String(100), nullable=True)  # IntaSend checkout ID
    payment_reference = db.Column(db.String(100), nullable=True, unique=True)  # Our reference
    intasend_tracking_id = db.Column(db.String(100), nullable=True)  # IntaSend's tracking ID
    
    # Subscription period
    start_date = db.Column(db.TIMESTAMP, nullable=False, default=db.func.current_timestamp())
    end_date = db.Column(db.TIMESTAMP, nullable=False)
    
    # Status tracking
    status = db.Column(db.String(20), default='pending')  # pending, active, cancelled, expired
    payment_status = db.Column(db.String(20), default='pending')  # pending, completed, failed, refunded
    
    # Timestamps
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())
    
    # Auto-renewal settings (for future implementation)
    auto_renew = db.Column(db.Boolean, default=False)
    next_billing_date = db.Column(db.TIMESTAMP, nullable=True)
    
    # Relationships
    user = db.relationship('User', backref='subscriptions')
    
    def __repr__(self):
        return f'<Subscription {self.id}: {self.plan_name} for User {self.user_id}>'
    
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
            'payment_reference': self.payment_reference,
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'status': self.status,
            'payment_status': self.payment_status,
            'auto_renew': self.auto_renew,
            'days_remaining': self.days_remaining(),
            'is_active': self.is_active(),
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }

# pending_payments.py - Track payments in progress
class PendingPayment(db.Model):
    __tablename__ = 'pending_payments'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False)
    
    # Payment session details
    checkout_id = db.Column(db.String(100), nullable=False, unique=True)
    checkout_url = db.Column(db.Text, nullable=False)
    payment_reference = db.Column(db.String(100), nullable=False, unique=True)
    
    # Plan and amount
    plan_id = db.Column(db.String(50), nullable=False)
    amount = db.Column(db.DECIMAL(10,2), nullable=False)
    currency = db.Column(db.String(3), nullable=False)
    
    # Status and timestamps
    status = db.Column(db.String(20), default='pending')  # pending, completed, failed, expired
    expires_at = db.Column(db.TIMESTAMP, nullable=False)  # Payment session expiry
    created_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp())
    updated_at = db.Column(db.TIMESTAMP, default=db.func.current_timestamp(), onupdate=db.func.current_timestamp())
    
    # Relationships
    user = db.relationship('User', backref='pending_payments')
    
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
        }

# migration_script.py - Database migration
"""
Run this script to update your existing subscription table:

python migration_script.py
"""

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from alembic import command
from alembic.config import Config
from alembic.migration import MigrationContext
from alembic.operations import Operations
import sqlalchemy as sa

def upgrade_subscription_table():
    """Add new columns to existing subscription table"""
    
    # Get current database connection
    connection = db.engine.connect()
    ctx = MigrationContext.configure(connection)
    op = Operations(ctx)
    
    # Check if columns already exist before adding them
    inspector = sa.inspect(db.engine)
    existing_columns = [col['name'] for col in inspector.get_columns('subscriptions')]
    
    # Add new columns if they don't exist
    new_columns = {
        'plan_id': sa.Column('plan_id', sa.String(50)),
        'plan_name': sa.Column('plan_name', sa.String(100)),
        'currency': sa.Column('currency', sa.String(3), default='KES'),
        'checkout_id': sa.Column('checkout_id', sa.String(100)),
        'payment_reference': sa.Column('payment_reference', sa.String(100)),
        'intasend_tracking_id': sa.Column('intasend_tracking_id', sa.String(100)),
        'payment_status': sa.Column('payment_status', sa.String(20), default='pending'),
        'auto_renew': sa.Column('auto_renew', sa.Boolean, default=False),
        'next_billing_date': sa.Column('next_billing_date', sa.TIMESTAMP),
    }
    
    for col_name, column in new_columns.items():
        if col_name not in existing_columns:
            try:
                op.add_column('subscriptions', column)
                print(f"Added column: {col_name}")
            except Exception as e:
                print(f"Error adding column {col_name}: {e}")
    
    # Create pending_payments table if it doesn't exist
    if not inspector.has_table('pending_payments'):
        try:
            PendingPayment.__table__.create(db.engine)
            print("Created pending_payments table")
        except Exception as e:
            print(f"Error creating pending_payments table: {e}")
    
    connection.close()
    print("Database migration completed!")

if __name__ == '__main__':
    # Initialize your Flask app and database
    app = Flask(__name__)
    app.config['SQLALCHEMY_DATABASE_URI'] = 'your_database_uri'  # Update this
    db.init_app(app)
    
    with app.app_context():
        upgrade_subscription_table()

# requirements.txt additions
"""
Add these to your requirements.txt:

requests>=2.28.0
webview-flutter>=4.0.0  # For Flutter WebView
intasend-python>=1.0.0  # If IntaSend has an official Python SDK
celery>=5.2.0  # For background payment processing (optional)
redis>=4.3.0  # For Celery broker (optional)
"""