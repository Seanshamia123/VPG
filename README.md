# VPG

A new Flutter project.

## Getting Started

## Frontend–Backend Integration (Dev)

- Backend runs on port 5002 (Flask). Health endpoint: `GET /health` returns `{status: "ok"}`.
- CORS is enabled for development for all origins in `server/app.py`.
- Flutter uses centralized config in `lib/config/api_config.dart`:
  - `ApiConfig.base` → `http://127.0.0.1:5002` or `http://10.0.2.2:5002` (Android emulator)
  - `ApiConfig.api` → Base + `/api`
  - `ApiConfig.auth` → Base + `/auth`
- Shared HTTP client in `lib/services/api_client.dart` attaches bearer token and refreshes on 401.

Key flows wired:
- Auth: `lib/services/auth_service.dart` → `/auth/login`, `/auth/register/*`, `/auth/refresh`.
- Posts: `lib/services/post_service.dart` fetches `/api/posts/` for feed; advertiser can create posts from the profile screen.
- Advertiser Profile: The grid tab fetches `/api/posts/my-posts` and shows real images.
- Messages: `lib/services/messages_service.dart` hits `/api/messages/recent` (requires user auth) and shows recent conversations.
- Comments: `lib/services/comments_service.dart` fetches and posts comments under `/api/comments` and `/api/comments/target/post/:id`.

Notes:
- When running on Android emulator, set `ApiConfig.useAndroidEmulator = true`.
- Some UI elements still show placeholder imagery when no data is available (stories, empty feeds).

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.




# Flask MySQL Server Setup Guide

A comprehensive guide to set up and run this Flask application with MySQL Workbench integration.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Python 3.8+** ([Download here](https://www.python.org/downloads/))
- **MySQL Server** ([Download here](https://dev.mysql.com/downloads/mysql/))
- **MySQL Workbench** ([Download here](https://dev.mysql.com/downloads/workbench/))
- **Git** ([Download here](https://git-scm.com/downloads))

## 🚀 Quick Start

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd <your-project-directory>
```

### 2. Set Up Virtual Environment

```bash
# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Linux/Mac:
source venv/bin/activate

```

### 3. Install Dependencies


```bash
pip install -r requirements.txt
```

If `requirements.txt` doesn't exist, install manually:
```bash
pip install flask flask-sqlalchemy flask-migrate flask-cors pymysql python-dotenv
```

### 4. Configure MySQL Database

#### Option A: Using MySQL Workbench (Recommended run line by line)

1. Open **MySQL Workbench**
2. Connect to your MySQL server
3. Create a new database:
   ```sql
   CREATE DATABASE VPG;
   ```
4. Create a new user (optional but recommended):
   ```sql
   CREATE USER 'sean'@'localhost' IDENTIFIED BY 'your_password';
   GRANT ALL PRIVILEGES ON VPG.* TO 'sean'@'localhost';
   FLUSH PRIVILEGES;
   ```

#### Option B: Using Command Line

```bash
# Connect to MySQL
mysql -u root -p

# Create database
CREATE DATABASE your_database_name;

# Create user (optional)
CREATE USER 'your_username'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON your_database_name.* TO 'your_username'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 5. Environment Configuration

Create a `.env` file in the project root:

```bash
# Copy the example environment file
cp .env.example .env
```

Or create manually:

```env
# Flask Configuration
FLASK_APP=app.py
FLASK_ENV=development
SECRET_KEY=your-secret-key-here-generate-a-secure-one

# MySQL Configuration
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=your_username
MYSQL_PASSWORD=your_password
MYSQL_DB=your_database_name

# Alternative: Direct DATABASE_URL (choose one method)
DATABASE_URL=mysql+pymysql://your_username:your_password@localhost:3306/your_database_name
```

**🔐 Security Note:** Generate a secure secret key:
```bash
python -c "import secrets; print(secrets.token_hex(32))"
```

### 6. Database Migration

Initialize and run database migrations:

```bash
# Initialize migration repository
flask db init

# Create initial migration
flask db migrate -m "Initial migration"

# Apply migration to database
flask db upgrade
```

### 7. Verify Setup

Test the database connection:

```bash
# Test app import
python -c "from app import app; print('✅ App imported successfully')"

# Test database connection
python -c "from models import db, User, Advertiser; print('✅ Models imported successfully')"
```

### 8. Run the Application

```bash
# Start the development server
flask run

# Or alternatively
python app.py
```

The server will start at `http://localhost:5000`

## 🛠️ Project Structure

```
your-project/
├── app.py                 # Main Flask application
├── models/                # Database models
│   ├── __init__.py
│   ├── user.py
│   └── advertiser.py
├── migrations/            # Database migrations (auto-generated)
├── venv/                  # Virtual environment (not in git)
├── .env                   # Environment variables (not in git)
├── .env.example          # Example environment file
├── requirements.txt       # Python dependencies
└── README.md             # This file
```

## 🔧 Configuration Options

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `FLASK_APP` | Flask application entry point | `app.py` |
| `FLASK_ENV` | Environment (development/production) | `development` |
| `SECRET_KEY` | Flask secret key for sessions | **Required** |
| `MYSQL_HOST` | MySQL server hostname | `localhost` |
| `MYSQL_PORT` | MySQL server port | `3306` |
| `MYSQL_USER` | MySQL username | **Required** |
| `MYSQL_PASSWORD` | MySQL password | **Required** |
| `MYSQL_DB` | MySQL database name | **Required** |

### Database Configuration

The application supports two ways to configure the database:

1. **Individual variables** (recommended):
   ```env
   MYSQL_HOST=localhost
   MYSQL_PORT=3306
   MYSQL_USER=myuser
   MYSQL_PASSWORD=mypassword
   MYSQL_DB=mydatabase
   ```

2. **Single DATABASE_URL**:
   ```env
   DATABASE_URL=mysql+pymysql://user:password@localhost:3306/database
   ```

## 📡 API Endpoints

### Health Check
- `GET /` - API information
- `GET /api/health` - Health check endpoint

### User Management
- `GET /api/users` - Get all users
- `POST /api/users` - Create new user
- `GET /api/users/<id>` - Get specific user
- `PUT /api/users/<id>` - Update user
- `DELETE /api/users/<id>` - Delete user

### Advertiser Management
- `GET /api/advertisers` - Get all advertisers
- `POST /api/advertisers` - Create new advertiser
- `GET /api/advertisers/<id>` - Get specific advertiser
- `PUT /api/advertisers/<id>` - Update advertiser
- `DELETE /api/advertisers/<id>` - Delete advertiser
- `POST /api/advertisers/<id>/verify` - Verify advertiser
- `GET /api/advertisers/verified` - Get verified advertisers

## 🔍 Testing the Setup

### 1. Test Database Connection

```bash
# Start Flask shell
flask shell

# Test database operations
>>> from models import db, User, Advertiser
>>> db.create_all()  # Should run without errors
>>> User.query.all()  # Should return empty list []
>>> exit()
```

### 2. Test API Endpoints

```bash
# Test health endpoint
curl http://localhost:5000/api/health

# Test users endpoint
curl http://localhost:5000/api/users

# Create a test user
curl -X POST http://localhost:5000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","number":"1234567890","location":"Test City","gender":"Other"}'
```

### 3. Using MySQL Workbench

1. Connect to your MySQL server in Workbench
2. Navigate to your database
3. You should see the created tables: `users`, `advertisers`, `alembic_version`
4. You can view, edit, and query data directly through the Workbench interface

## 🚨 Troubleshooting

### Common Issues

#### "Could not import 'app'"
```bash
# Check if app.py exists
ls -la app.py

# Check for syntax errors
python -m py_compile app.py

# Verify FLASK_APP is set
echo $FLASK_APP
```

#### "No such command 'db'"
```bash
# Install Flask-Migrate
pip install Flask-Migrate

# Verify it's in your app.py
grep -n "flask_migrate" app.py
```

#### Database Connection Errors
```bash
# Test MySQL connection
mysql -u your_username -p your_database_name

# Check if database exists
mysql -u your_username -p -e "SHOW DATABASES;"

# Verify .env file syntax
cat .env
```

#### Import Errors with Models
```bash
# Check if models package exists
ls -la models/

# Check if __init__.py exists
ls -la models/__init__.py

# Test model import
python -c "from models import db, User, Advertiser; print('Success')"
```

### Getting Help

If you encounter issues:

1. **Check the error messages** - they usually point to the specific problem
2. **Verify your .env file** - ensure no syntax errors or missing quotes
3. **Check MySQL server status** - ensure it's running
4. **Verify database exists** - create it if missing
5. **Check Python virtual environment** - ensure it's activated

### Log Files

Enable Flask debugging for detailed error messages:
```env
FLASK_ENV=development
FLASK_DEBUG=1
```

## 📝 Development Workflow

### Making Model Changes

1. Modify your models in the `models/` directory
2. Generate new migration:
   ```bash
   flask db migrate -m "Description of changes"
   ```
3. Review the generated migration file
4. Apply the migration:
   ```bash
   flask db upgrade
   ```

### Adding New Dependencies

1. Install the package:
   ```bash
   pip install package-name
   ```
2. Update requirements:
   ```bash
   pip freeze > requirements.txt
   ```

## 🔒 Security Notes

- Never commit your `.env` file to version control
- Use strong, unique passwords for your MySQL user
- Generate a secure secret key for production
- Consider using environment-specific configuration files
- Use HTTPS in production
- Implement proper authentication and authorization

## 🚀 Deployment

For production deployment:

1. Set `FLASK_ENV=production`
2. Use a production WSGI server (like Gunicorn)
3. Configure proper database connection pooling
4. Set up proper logging
5. Use environment variables for sensitive configuration
6. Consider using a reverse proxy (nginx)

---

**Happy coding! 🎉**

For questions or issues, please check the troubleshooting section or create an issue in the repository.
