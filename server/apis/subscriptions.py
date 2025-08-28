from flask import request
from flask_restx import Namespace, Resource, fields
from datetime import datetime, timedelta
from models import Subscription, User, db
from .decorators import token_required

api = Namespace('subscriptions', description='Subscription management')

subscription_model = api.model('Subscription', {
    'id': fields.Integer(),
    'user_id': fields.Integer(),
    'amount_paid': fields.String(),
    'payment_method': fields.String(),
    'start_date': fields.String(),
    'end_date': fields.String(),
    'status': fields.String(),
    'created_at': fields.String(),
    'updated_at': fields.String(),
})

subscribe_model = api.model('SubscribeRequest', {
    'amount_paid': fields.Float(required=True, description='Amount paid'),
    'payment_method': fields.String(required=True, description='Payment method'),
    'duration_days': fields.Integer(required=False, description='Subscription duration in days', default=30),
})

@api.route('/my')
class MySubscriptions(Resource):
    @api.marshal_list_with(subscription_model)
    @token_required
    def get(self, current_user):
        subs = Subscription.query.filter_by(user_id=current_user.id).order_by(Subscription.created_at.desc()).all()
        def to_dict(s: Subscription):
            return {
                'id': s.id,
                'user_id': s.user_id,
                'amount_paid': str(s.amount_paid) if s.amount_paid is not None else None,
                'payment_method': s.payment_method,
                'start_date': s.start_date.isoformat() if s.start_date else None,
                'end_date': s.end_date.isoformat() if s.end_date else None,
                'status': s.status,
                'created_at': s.created_at.isoformat() if s.created_at else None,
                'updated_at': s.updated_at.isoformat() if s.updated_at else None,
            }
        return [to_dict(s) for s in subs]

@api.route('/subscribe')
class Subscribe(Resource):
    @api.expect(subscribe_model)
    @api.marshal_with(subscription_model, code=201)
    @token_required
    def post(self, current_user):
        data = request.get_json() or {}
        amount = data.get('amount_paid')
        method = data.get('payment_method')
        duration = int(data.get('duration_days', 30))
        if amount is None or method is None:
            api.abort(400, 'amount_paid and payment_method are required')
        start = datetime.utcnow()
        end = start + timedelta(days=duration)
        sub = Subscription(
            user_id=current_user.id,
            amount_paid=amount,
            payment_method=method,
            start_date=start,
            end_date=end,
            status='active'
        )
        db.session.add(sub)
        db.session.commit()
        return {
            'id': sub.id,
            'user_id': sub.user_id,
            'amount_paid': str(sub.amount_paid),
            'payment_method': sub.payment_method,
            'start_date': sub.start_date.isoformat() if sub.start_date else None,
            'end_date': sub.end_date.isoformat() if sub.end_date else None,
            'status': sub.status,
            'created_at': sub.created_at.isoformat() if sub.created_at else None,
            'updated_at': sub.updated_at.isoformat() if sub.updated_at else None,
        }, 201

@api.route('/cancel/<int:subscription_id>')
class CancelSubscription(Resource):
    @token_required
    def post(self, current_user, subscription_id):
        sub = Subscription.query.get(subscription_id)
        if not sub:
            api.abort(404, 'Subscription not found')
        if sub.user_id != current_user.id:
            api.abort(403, 'Not your subscription')
        sub.status = 'cancelled'
        db.session.commit()
        return {'message': 'Subscription cancelled'}

