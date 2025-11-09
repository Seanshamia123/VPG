# services/email_service.py - Subscription Email Notifications
import os
import logging
from datetime import datetime
from flask import current_app
from flask_mail import Mail, Message

mail = Mail()

class SubscriptionEmailService:
    """Service for sending subscription-related emails"""
    
    @staticmethod
    def init_app(app):
        """Initialize Flask-Mail with app"""
        app.config['MAIL_SERVER'] = os.environ.get('MAIL_SERVER', 'smtp.gmail.com')
        app.config['MAIL_PORT'] = int(os.environ.get('MAIL_PORT', 587))
        app.config['MAIL_USE_TLS'] = os.environ.get('MAIL_USE_TLS', 'true').lower() == 'true'
        app.config['MAIL_USERNAME'] = os.environ.get('MAIL_USERNAME')
        app.config['MAIL_PASSWORD'] = os.environ.get('MAIL_PASSWORD')
        app.config['MAIL_DEFAULT_SENDER'] = os.environ.get('MAIL_DEFAULT_SENDER', 'noreply@vpg.com')
        
        mail.init_app(app)
    
    @staticmethod
    def send_7day_reminder(advertiser, subscription):
        """Send 7-day renewal reminder"""
        try:
            subject = f"⏰ Your {subscription.plan_name} renews in 7 days"
            
            html_body = f"""
            <html>
                <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                        <h2 style="color: #FFD700;">Subscription Renewal Reminder</h2>
                        
                        <p>Hi {advertiser.name},</p>
                        
                        <p>This is a friendly reminder that your <strong>{subscription.plan_name}</strong> subscription will renew in <strong>7 days</strong>.</p>
                        
                        <div style="background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0;">
                            <h3 style="margin-top: 0; color: #FFD700;">Subscription Details</h3>
                            <p><strong>Plan:</strong> {subscription.plan_name}</p>
                            <p><strong>Amount:</strong> {subscription.currency} {subscription.amount_paid}</p>
                            <p><strong>Renewal Date:</strong> {subscription.next_billing_date.strftime('%B %d, %Y')}</p>
                            <p><strong>Payment Method:</strong> {subscription.payment_method}</p>
                        </div>
                        
                        <p>Your subscription will automatically renew on <strong>{subscription.next_billing_date.strftime('%B %d, %Y')}</strong>. The payment will be processed using your saved payment method.</p>
                        
                        <p>If you wish to cancel your subscription or update your payment method, please log in to your account.</p>
                        
                        <div style="margin: 30px 0;">
                            <a href="{os.environ.get('FRONTEND_URL', 'https://vpg.com')}/profile" 
                               style="background: #FFD700; color: #000; padding: 12px 30px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: bold;">
                                Manage Subscription
                            </a>
                        </div>
                        
                        <p style="color: #666; font-size: 14px;">Thank you for being a valued member!</p>
                        
                        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                        
                        <p style="color: #999; font-size: 12px;">
                            If you have any questions, please contact our support team.<br>
                            This is an automated message, please do not reply to this email.
                        </p>
                    </div>
                </body>
            </html>
            """
            
            text_body = f"""
            Subscription Renewal Reminder
            
            Hi {advertiser.name},
            
            This is a friendly reminder that your {subscription.plan_name} subscription will renew in 7 days.
            
            Subscription Details:
            - Plan: {subscription.plan_name}
            - Amount: {subscription.currency} {subscription.amount_paid}
            - Renewal Date: {subscription.next_billing_date.strftime('%B %d, %Y')}
            - Payment Method: {subscription.payment_method}
            
            Your subscription will automatically renew on {subscription.next_billing_date.strftime('%B %d, %Y')}.
            
            If you wish to cancel or update your payment method, please log in to your account.
            
            Thank you for being a valued member!
            """
            
            msg = Message(
                subject=subject,
                recipients=[advertiser.email],
                body=text_body,
                html=html_body
            )
            
            mail.send(msg)
            logging.info(f"✓ 7-day reminder sent to {advertiser.email}")
            return True
            
        except Exception as e:
            logging.error(f"Failed to send 7-day reminder to {advertiser.email}: {e}")
            return False
    
    @staticmethod
    def send_3day_reminder(advertiser, subscription):
        """Send 3-day renewal reminder"""
        try:
            subject = f"🔔 Your {subscription.plan_name} renews in 3 days"
            
            html_body = f"""
            <html>
                <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                        <h2 style="color: #FFD700;">⚠️ Subscription Renewal Soon</h2>
                        
                        <p>Hi {advertiser.name},</p>
                        
                        <p>Your <strong>{subscription.plan_name}</strong> subscription will renew in just <strong>3 days</strong>.</p>
                        
                        <div style="background: #fff3cd; border-left: 4px solid #FFD700; padding: 15px; margin: 20px 0;">
                            <h3 style="margin-top: 0; color: #856404;">⚡ Action Required Soon</h3>
                            <p><strong>Renewal Date:</strong> {subscription.next_billing_date.strftime('%B %d, %Y')}</p>
                            <p><strong>Amount to be charged:</strong> {subscription.currency} {subscription.amount_paid}</p>
                        </div>
                        
                        <div style="background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0;">
                            <h3 style="margin-top: 0; color: #FFD700;">Subscription Details</h3>
                            <p><strong>Plan:</strong> {subscription.plan_name}</p>
                            <p><strong>Payment Method:</strong> {subscription.payment_method}</p>
                            <p><strong>Status:</strong> Active</p>
                        </div>
                        
                        <p><strong>What happens next?</strong></p>
                        <ul>
                            <li>Your payment method will be automatically charged on {subscription.next_billing_date.strftime('%B %d, %Y')}</li>
                            <li>Your subscription will continue without interruption</li>
                            <li>You'll receive a payment confirmation email</li>
                        </ul>
                        
                        <p style="color: #d9534f; font-weight: bold;">⚠️ Want to cancel? You must do so before {subscription.next_billing_date.strftime('%B %d, %Y')} to avoid being charged.</p>
                        
                        <div style="margin: 30px 0;">
                            <a href="{os.environ.get('FRONTEND_URL', 'https://vpg.com')}/profile" 
                               style="background: #FFD700; color: #000; padding: 12px 30px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: bold;">
                                Manage Subscription
                            </a>
                        </div>
                        
                        <p style="color: #666; font-size: 14px;">Thank you for your continued support!</p>
                        
                        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                        
                        <p style="color: #999; font-size: 12px;">
                            Questions? Contact our support team.<br>
                            This is an automated message, please do not reply to this email.
                        </p>
                    </div>
                </body>
            </html>
            """
            
            text_body = f"""
            ⚠️ Subscription Renewal Soon
            
            Hi {advertiser.name},
            
            Your {subscription.plan_name} subscription will renew in just 3 days.
            
            Renewal Date: {subscription.next_billing_date.strftime('%B %d, %Y')}
            Amount to be charged: {subscription.currency} {subscription.amount_paid}
            
            What happens next?
            - Your payment method will be automatically charged
            - Your subscription will continue without interruption
            - You'll receive a payment confirmation email
            
            ⚠️ Want to cancel? You must do so before {subscription.next_billing_date.strftime('%B %d, %Y')} to avoid being charged.
            
            Manage your subscription: {os.environ.get('FRONTEND_URL', 'https://vpg.com')}/profile
            
            Thank you for your continued support!
            """
            
            msg = Message(
                subject=subject,
                recipients=[advertiser.email],
                body=text_body,
                html=html_body
            )
            
            mail.send(msg)
            logging.info(f"✓ 3-day reminder sent to {advertiser.email}")
            return True
            
        except Exception as e:
            logging.error(f"Failed to send 3-day reminder to {advertiser.email}: {e}")
            return False
    
    @staticmethod
    def send_renewal_success(advertiser, subscription):
        """Send renewal success confirmation"""
        try:
            subject = f"✅ {subscription.plan_name} Renewed Successfully"
            
            html_body = f"""
            <html>
                <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                        <h2 style="color: #28a745;">✅ Subscription Renewed!</h2>
                        
                        <p>Hi {advertiser.name},</p>
                        
                        <p>Great news! Your <strong>{subscription.plan_name}</strong> subscription has been successfully renewed.</p>
                        
                        <div style="background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 20px 0;">
                            <h3 style="margin-top: 0; color: #155724;">Payment Successful</h3>
                            <p><strong>Amount Charged:</strong> {subscription.currency} {subscription.amount_paid}</p>
                            <p><strong>Next Renewal:</strong> {subscription.next_billing_date.strftime('%B %d, %Y')}</p>
                        </div>
                        
                        <div style="background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0;">
                            <h3 style="margin-top: 0; color: #FFD700;">Subscription Details</h3>
                            <p><strong>Plan:</strong> {subscription.plan_name}</p>
                            <p><strong>Status:</strong> Active</p>
                            <p><strong>Valid Until:</strong> {subscription.end_date.strftime('%B %d, %Y')}</p>
                            <p><strong>Payment Reference:</strong> {subscription.payment_reference}</p>
                        </div>
                        
                        <p>Your subscription is now active and you can continue enjoying all premium features.</p>
                        
                        <div style="margin: 30px 0;">
                            <a href="{os.environ.get('FRONTEND_URL', 'https://vpg.com')}/profile" 
                               style="background: #FFD700; color: #000; padding: 12px 30px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: bold;">
                                View Subscription
                            </a>
                        </div>
                        
                        <p style="color: #666; font-size: 14px;">Thank you for your continued support!</p>
                        
                        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                        
                        <p style="color: #999; font-size: 12px;">
                            Questions about your subscription? Contact our support team.<br>
                            This is an automated message, please do not reply to this email.
                        </p>
                    </div>
                </body>
            </html>
            """
            
            msg = Message(
                subject=subject,
                recipients=[advertiser.email],
                html=html_body
            )
            
            mail.send(msg)
            logging.info(f"✓ Renewal success email sent to {advertiser.email}")
            return True
            
        except Exception as e:
            logging.error(f"Failed to send renewal success email: {e}")
            return False
    
    @staticmethod
    def send_cancellation_confirmation(advertiser, subscription):
        """Send cancellation confirmation email"""
        try:
            subject = "Subscription Cancelled"
            
            html_body = f"""
            <html>
                <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
                    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
                        <h2 style="color: #d9534f;">Subscription Cancelled</h2>
                        
                        <p>Hi {advertiser.name},</p>
                        
                        <p>Your <strong>{subscription.plan_name}</strong> subscription has been cancelled as requested.</p>
                        
                        <div style="background: #f8d7da; border-left: 4px solid #d9534f; padding: 15px; margin: 20px 0;">
                            <p><strong>Cancellation Date:</strong> {subscription.cancelled_at.strftime('%B %d, %Y') if subscription.cancelled_at else 'Today'}</p>
                            <p><strong>Access Until:</strong> {subscription.end_date.strftime('%B %d, %Y')}</p>
                        </div>
                        
                        <p>You will continue to have access to premium features until <strong>{subscription.end_date.strftime('%B %d, %Y')}</strong>.</p>
                        
                        <p>After this date, your account will revert to free features.</p>
                        
                        <p>We're sorry to see you go! If you change your mind, you can resubscribe anytime from your profile.</p>
                        
                        <div style="margin: 30px 0;">
                            <a href="{os.environ.get('FRONTEND_URL', 'https://vpg.com')}/subscription-plans" 
                               style="background: #FFD700; color: #000; padding: 12px 30px; text-decoration: none; border-radius: 6px; display: inline-block; font-weight: bold;">
                                Resubscribe
                            </a>
                        </div>
                        
                        <hr style="border: none; border-top: 1px solid #ddd; margin: 30px 0;">
                        
                        <p style="color: #999; font-size: 12px;">
                            Questions? Contact our support team.<br>
                            This is an automated message, please do not reply to this email.
                        </p>
                    </div>
                </body>
            </html>
            """
            
            msg = Message(
                subject=subject,
                recipients=[advertiser.email],
                html=html_body
            )
            
            mail.send(msg)
            logging.info(f"✓ Cancellation email sent to {advertiser.email}")
            return True
            
        except Exception as e:
            logging.error(f"Failed to send cancellation email: {e}")
            return False


# Initialize service
email_service = SubscriptionEmailService()