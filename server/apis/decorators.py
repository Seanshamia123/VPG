from functools import wraps
from flask import request, jsonify
import jwt
import os
from models import User, Advertiser


def _decode_token():
    token = None
    if 'Authorization' in request.headers:
        auth_header = request.headers['Authorization']
        try:
            token = auth_header.split(" ")[1]
        except IndexError:
            return None, ('Invalid token format', 401)
    if not token:
        return None, ('Token is missing', 401)
    try:
        secret_key = os.environ.get('SECRET_KEY', '732ffbadb13fee4198fbd1e32394e7366c595da6cc66d2a3')
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        return payload, None
    except jwt.ExpiredSignatureError:
        return None, ('Token has expired', 401)
    except jwt.InvalidTokenError:
        return None, ('Invalid token', 401)
    except Exception as e:
        return None, (f'Token validation failed: {str(e)}', 401)


def token_required(f):
    """Attach current_user (User or Advertiser) as first arg after self."""
    @wraps(f)
    def wrapper(self, *args, **kwargs):
        payload, err = _decode_token()
        if err:
            msg, code = err
            return jsonify({'message': msg}), code
        user_type = payload.get('user_type', 'user')
        user_id = payload.get('user_id')
        current = Advertiser.find_by_id(user_id) if user_type == 'advertiser' else User.find_by_id(user_id)
        if not current:
            return jsonify({'message': 'User not found'}), 401
        return f(self, current, *args, **kwargs)
    return wrapper


def advertiser_required(f):
    """Require advertiser and attach current_advertiser as first arg after self."""
    @wraps(f)
    def wrapper(self, *args, **kwargs):
        payload, err = _decode_token()
        if err:
            msg, code = err
            return jsonify({'message': msg}), code
        if payload.get('user_type') != 'advertiser':
            return jsonify({'message': 'Advertiser access required'}), 403
        adv = Advertiser.find_by_id(payload.get('user_id'))
        if not adv:
            return jsonify({'message': 'Advertiser not found'}), 401
        return f(self, adv, *args, **kwargs)
    return wrapper
