#!/usr/bin/env python3
import os
from app import create_app
from database import db
from flask_migrate import upgrade, migrate, init, stamp
from models import Advertiser

# Create the Flask application
app = create_app()

if __name__ == '__main__':
    with app.app_context():
        # You can run migrations here or use Flask CLI
        pass

def seed_advertiser_coords():
    """Seed a few advertisers with sample coordinates (NYC area)."""
    samples = [
        # (username/email fragment, lat, lon)
        ('stacy', 40.7589, -73.9851),
        ('smith', 40.7614, -73.9776),
        ('kriston', 40.7505, -73.9934),
    ]
    updated = 0
    for frag, lat, lon in samples:
        adv = Advertiser.query.filter(
            db.or_(Advertiser.username.ilike(f'%{frag}%'), Advertiser.name.ilike(f'%{frag}%'), Advertiser.email.ilike(f'%{frag}%'))
        ).first()
        if adv:
            adv.latitude = lat
            adv.longitude = lon
            updated += 1
    if updated:
        db.session.commit()
    return updated
