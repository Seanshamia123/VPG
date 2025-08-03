import sys
import importlib
from flask import Flask
from database import db
from config import Config
from seed import seed_all

def create_app():
    """Application factory function to create the Flask app."""
    app = Flask(__name__)
    app.config.from_object(Config)
    db.init_app(app)
    return app

app = create_app()

def main():
    """Run the seed script with optional arguments."""
    with app.app_context():
        if len(sys.argv) > 1:
            seed_name = sys.argv[1]
            try:
                # Import the specific seed module
                module = importlib.import_module(f"seed.seed_{seed_name}")
                seed_function = getattr(module, f"seed_{seed_name}")
                seed_function()
                print(f"Successfully ran {seed_name} seeder.")
            except (ImportError, AttributeError) as e:
                print(f"Error: Seeder '{seed_name}' not found. ({e})")
                print("Available seeders: users")
        else:
            print("Clearing tables...")
            #db.drop_all()
            print("Creating tables...")
            db.create_all()
            seed_all()

if __name__ == "__main__":
    main()