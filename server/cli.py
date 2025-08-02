#!/usr/bin/env python3
import os
from app import create_app
from database import db
from flask_migrate import upgrade, migrate, init, stamp

# Create the Flask application
app = create_app()

if __name__ == '__main__':
    with app.app_context():
        # You can run migrations here or use Flask CLI
        pass