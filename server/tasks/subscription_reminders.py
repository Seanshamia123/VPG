# tasks/subscription_reminders.py - Scheduled task for renewal reminders
import logging
from datetime import datetime
from apscheduler.schedulers.background import BackgroundScheduler
from models.subsricption import Subscription
from models.advertiser import Advertiser
from database import db
from services.email_service import email_service

logger = logging.getLogger(__name__)

def check_and_send_reminders():
    """Check all active subscriptions and send reminders if needed"""
    try:
        logger.info("=== Running Subscription Reminder Check ===")
        
        # Get all active subscriptions with auto-renew enabled
        active_subscriptions = Subscription.query.filter_by(
            status='active',
            payment_status='completed',
            auto_renew=True
        ).all()
        
        logger.info(f"Found {len(active_subscriptions)} active subscriptions")
        
        reminders_sent = {
            '7day': 0,
            '3day': 0
        }
        
        for subscription in active_subscriptions:
            try:
                # Get advertiser
                advertiser = Advertiser.query.get(subscription.user_id)
                if not advertiser:
                    logger.warning(f"Advertiser not found for subscription {subscription.id}")
                    continue
                
                # Check for 7-day reminder
                if subscription.needs_7day_reminder():
                    logger.info(f"Sending 7-day reminder to {advertiser.email}")
                    if email_service.send_7day_reminder(advertiser, subscription):
                        subscription.reminder_7days_sent = True
                        subscription.last_reminder_sent = datetime.utcnow()
                        reminders_sent['7day'] += 1
                
                # Check for 3-day reminder
                elif subscription.needs_3day_reminder():
                    logger.info(f"Sending 3-day reminder to {advertiser.email}")
                    if email_service.send_3day_reminder(advertiser, subscription):
                        subscription.reminder_3days_sent = True
                        subscription.last_reminder_sent = datetime.utcnow()
                        reminders_sent['3day'] += 1
                
            except Exception as e:
                logger.error(f"Error processing subscription {subscription.id}: {e}")
                continue
        
        # Commit all changes
        db.session.commit()
        
        logger.info(f"✓ Reminder check complete: {reminders_sent['7day']} 7-day, {reminders_sent['3day']} 3-day reminders sent")
        
    except Exception as e:
        logger.error(f"Error in reminder check: {e}")
        db.session.rollback()


def process_renewals():
    """Process subscription renewals on the 3rd of each month"""
    try:
        logger.info("=== Running Subscription Renewal Process ===")
        
        today = datetime.utcnow()
        
        # Only run on the 3rd of the month
        if today.day != 3:
            logger.info(f"Not renewal day (today is {today.day}th)")
            return
        
        # Get subscriptions due for renewal today
        due_subscriptions = Subscription.query.filter(
            Subscription.status == 'active',
            Subscription.auto_renew == True,
            Subscription.next_billing_date <= today
        ).all()
        
        logger.info(f"Found {len(due_subscriptions)} subscriptions due for renewal")
        
        renewals_processed = 0
        
        for subscription in due_subscriptions:
            try:
                advertiser = Advertiser.query.get(subscription.user_id)
                if not advertiser:
                    continue
                
                # Here you would integrate with payment provider to charge
                # For now, we'll log and update the subscription
                
                logger.info(f"Processing renewal for {advertiser.email}, subscription {subscription.id}")
                
                # TODO: Integrate with IntaSend/Paystack to charge saved payment method
                # payment_result = process_renewal_payment(subscription)
                
                # For now, assuming successful renewal:
                # Update subscription dates
                from datetime import timedelta
                subscription.start_date = datetime.utcnow()
                subscription.end_date = datetime.utcnow() + timedelta(days=30)
                subscription.next_billing_date = subscription.calculate_next_billing_date()
                subscription.reminder_7days_sent = False
                subscription.reminder_3days_sent = False
                subscription.updated_at = datetime.utcnow()
                
                # Send success email
                email_service.send_renewal_success(advertiser, subscription)
                
                renewals_processed += 1
                
            except Exception as e:
                logger.error(f"Error processing renewal for subscription {subscription.id}: {e}")
                continue
        
        db.session.commit()
        logger.info(f"✓ Renewal process complete: {renewals_processed} renewals processed")
        
    except Exception as e:
        logger.error(f"Error in renewal process: {e}")
        db.session.rollback()


def init_scheduler(app):
    """Initialize the scheduler with the Flask app"""
    scheduler = BackgroundScheduler()
    
    # Check for reminders daily at 9 AM
    scheduler.add_job(
        func=check_and_send_reminders,
        trigger='cron',
        hour=9,
        minute=0,
        id='reminder_check',
        name='Check subscription reminders',
        replace_existing=True
    )
    
    # Process renewals daily at 2 AM (will only act on 3rd of month)
    scheduler.add_job(
        func=process_renewals,
        trigger='cron',
        hour=2,
        minute=0,
        id='renewal_process',
        name='Process subscription renewals',
        replace_existing=True
    )
    
    scheduler.start()
    logger.info("✓ Subscription scheduler initialized")
    
    return scheduler


# For manual testing
def test_reminders():
    """Test reminder emails (for development)"""
    from app import create_app
    
    app = create_app()
    with app.app_context():
        check_and_send_reminders()


def test_renewals():
    """Test renewal process (for development)"""
    from app import create_app
    
    app = create_app()
    with app.app_context():
        process_renewals()