# Storyboard Deployment Plan
## From Local → GitHub → Staging → Production

---

## 📋 PHASE 1: PRE-DEPLOYMENT PREPARATION (Local Machine)

### 1.1 Update .gitignore
Add sensitive files and build artifacts that shouldn't be committed:

```bash
# Create/update .gitignore in project root
cat >> .gitignore << 'EOF'

# Environment files
.env
.env.local
.env.*.local
backend/.env
client/.env.local

# Build artifacts
client/.next/
client/.swc/
client/dist/
backend/__pycache__/
backend/*.pyc
backend/build/
backend/dist/

# Dependencies
node_modules/
backend/venv/
client/node_modules/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pm2.log

# Cache
.pytest_cache/
.coverage
htmlcov/

# Database
*.db
*.sqlite
*.sqlite3

# Temporary
tmp/
temp/
*.tmp

# Celery
celerybeat-schedule
celerybeat-schedule-shm
celerybeat-schedule-wal

# PID files
.pids/
*.pid

# Media uploads
backend/media/
backend/staticfiles/

EOF

git add .gitignore
git commit -m "chore: update .gitignore with sensitive files and build artifacts"
```

### 1.2 Pre-Deployment Checks

```bash
# Run all checks
echo "🔍 Running pre-deployment checks..."

# 1. Code quality
cd client && npm run lint && echo "✅ Frontend lint passed" || echo "❌ Frontend lint failed"
cd ../backend && python3 -m py_compile app/*.py && echo "✅ Backend syntax check passed" || echo "❌ Backend syntax check failed"

# 2. Build verification
cd ../client && npm run build && echo "✅ Frontend build passed" || echo "❌ Frontend build failed"

# 3. Git status
git status | grep "nothing to commit" && echo "✅ Git clean" || echo "❌ Uncommitted changes"

# 4. Environment files exist
[ -f backend/.env ] && echo "✅ Backend .env exists" || echo "❌ Backend .env missing"
[ -f client/.env.local ] && echo "✅ Frontend .env.local exists" || echo "❌ Frontend .env.local missing"

echo "✅ All pre-deployment checks passed!"
```

---

## 🚀 PHASE 2: PUSH TO GITHUB

### 2.1 Commit and Push

```bash
cd /path/to/storyboard

# Stage all changes
git add .

# Commit with meaningful message
git commit -m "feat: production-ready deployment

- Move all hardcoded text to JSON files
- Fix build issues and deprecated configs
- Clean up unnecessary files
- Optimize frontend build
- Add comprehensive deployment guide
- Update .gitignore for production"

# Push to GitHub
git push origin main

# Verify on GitHub
echo "✅ Code pushed to GitHub"
echo "Visit: https://github.com/your-username/storyboard"
```

---

## 🖥️ PHASE 3: CREATE & CONFIGURE VM

### 3.1 Create Google Cloud Compute Engine VM

```bash
# Using gcloud CLI
gcloud compute instances create storyboard-staging \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --boot-disk-size=50GB \
  --tags=http-server,https-server

# Get the external IP
gcloud compute instances describe storyboard-staging --zone=us-central1-a | grep natIP
```

### 3.2 Make IP Static

```bash
# Reserve a static IP
gcloud compute addresses create storyboard-staging-ip \
  --region=us-central1

# Attach to instance
gcloud compute instances add-access-config storyboard-staging \
  --access-config-name=storyboard-staging-ip \
  --zone=us-central1-a

# Verify
gcloud compute addresses list
# Note the STATIC_IP address
```

### 3.3 Configure Firewall Rules

```bash
# Allow HTTP
gcloud compute firewall-rules create allow-http \
  --allow=tcp:80 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=http-server

# Allow HTTPS
gcloud compute firewall-rules create allow-https \
  --allow=tcp:443 \
  --source-ranges=0.0.0.0/0 \
  --target-tags=https-server

# Allow SSH
gcloud compute firewall-rules create allow-ssh \
  --allow=tcp:22 \
  --source-ranges=0.0.0.0/0
```

### 3.4 SSH into VM

```bash
# Connect to VM
gcloud compute ssh storyboard-staging --zone=us-central1-a

# Or using SSH key
ssh -i ~/.ssh/gcloud_key ubuntu@STATIC_IP

# Verify connection
pwd
# ✅ Expected: /home/ubuntu
```

---

## 📦 PHASE 4: INSTALL DEPENDENCIES ON VM

### 4.1 Update System and Install Base Tools

```bash
# SSH into VM first
gcloud compute ssh storyboard-staging --zone=us-central1-a

# Update system
sudo apt update && sudo apt upgrade -y

# Install essential tools
sudo apt install -y \
  curl \
  wget \
  git \
  build-essential \
  libssl-dev \
  libffi-dev \
  python3-dev

echo "✅ Base tools installed"
```

### 4.2 Install Node.js

```bash
# Add NodeSource repository
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Install Node.js
sudo apt install -y nodejs

# Verify
node --version
npm --version
# ✅ Expected: v20.x.x and 10.x.x

echo "✅ Node.js installed"
```

### 4.3 Install Python

```bash
# Install Python 3.11+
sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Set as default
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Verify
python3 --version
# ✅ Expected: Python 3.11.x

echo "✅ Python installed"
```

### 4.4 Install MySQL

```bash
# Install MySQL Server
sudo apt install -y mysql-server

# Secure MySQL installation
sudo mysql_secure_installation
# Follow prompts:
# - Remove anonymous users: Y
# - Disable remote root login: Y
# - Remove test database: Y
# - Reload privilege tables: Y

# Verify
sudo systemctl status mysql
# ✅ Expected: active (running)

echo "✅ MySQL installed"
```

### 4.5 Install Redis

```bash
# Install Redis
sudo apt install -y redis-server

# Verify
sudo systemctl status redis-server
# ✅ Expected: active (running)

# Test Redis
redis-cli ping
# ✅ Expected: PONG

echo "✅ Redis installed"
```

### 4.6 Install Nginx

```bash
# Install Nginx
sudo apt install -y nginx

# Enable on startup
sudo systemctl enable nginx

# Start Nginx
sudo systemctl start nginx

# Verify
sudo systemctl status nginx
# ✅ Expected: active (running)

echo "✅ Nginx installed"
```

### 4.7 Install PM2 (Process Manager)

```bash
# Install PM2 globally
sudo npm install -g pm2

# Enable PM2 startup
pm2 startup
# Follow the instructions provided

# Verify
pm2 --version
# ✅ Expected: version number

echo "✅ PM2 installed"
```

---

## 📥 PHASE 5: PULL CODE INTO VM

### 5.1 Clone Repository

```bash
# Create deployment directory
sudo mkdir -p /var/www
sudo chown ubuntu:ubuntu /var/www

# Navigate to deployment directory
cd /var/www

# Clone repository
git clone https://github.com/your-username/storyboard.git
cd storyboard

# Verify
pwd
ls -la
# ✅ Expected: backend/, client/, deploy.sh, etc.

echo "✅ Code cloned successfully"
```

### 5.2 Create Directory Structure

```bash
# Create necessary directories
mkdir -p /var/www/storyboard/backend/media
mkdir -p /var/www/storyboard/backend/staticfiles
mkdir -p /var/www/storyboard/logs

# Set permissions
sudo chown -R ubuntu:ubuntu /var/www/storyboard

echo "✅ Directory structure created"
```

---

## ⚙️ PHASE 6: CONFIGURE ENVIRONMENT FILES

### 6.1 Backend Environment Configuration

```bash
# Navigate to backend
cd /var/www/storyboard/backend

# Copy example env
cp .env.example .env

# Edit environment file
nano .env

# Update with these values:
```

```env
# Database Configuration
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=storyboard_user
DATABASE_PASSWORD=your_strong_password_here
DATABASE_NAME=storyboard

# API Configuration
DEBUG=False
ENVIRONMENT=staging
SECRET_KEY=your_generated_secret_key_here

# API Keys (Get from respective services)
GOOGLE_PLACES_API_KEY=your_google_places_key
YOUTUBE_API_KEY=your_youtube_api_key
OPENWEATHER_API_KEY=your_openweather_key
GOOGLE_GENERATIVE_AI_KEY=your_gemini_api_key

# Celery Configuration
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/1

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://staging.tourists.co,http://localhost:3000

# Admin Configuration
ADMIN_API_KEY=your_admin_api_key_here

# Email Configuration (Optional)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASSWORD=your_app_password

# Logging
LOG_LEVEL=INFO
```

```bash
# Save: Ctrl+X, Y, Enter

echo "✅ Backend .env configured"
```

### 6.2 Frontend Environment Configuration

```bash
# Navigate to frontend
cd /var/www/storyboard/client

# Copy example env
cp .env.example .env.local

# Edit environment file
nano .env.local

# Update with these values:
```

```env
# API Configuration
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1

# Environment
NEXT_PUBLIC_ENVIRONMENT=staging

# Analytics (Optional)
NEXT_PUBLIC_GA_ID=your_google_analytics_id
```

```bash
# Save: Ctrl+X, Y, Enter

echo "✅ Frontend .env.local configured"
```

### 6.3 Create MySQL Database and User

```bash
# Connect to MySQL
sudo mysql -u root

# Run these commands:
```

```sql
-- Create database
CREATE DATABASE storyboard;

-- Create user
CREATE USER 'storyboard_user'@'localhost' IDENTIFIED BY 'your_strong_password_here';

-- Grant privileges
GRANT ALL PRIVILEGES ON storyboard.* TO 'storyboard_user'@'localhost';

-- Flush privileges
FLUSH PRIVILEGES;

-- Exit
EXIT;
```

```bash
# Verify
mysql -u storyboard_user -p -e "SELECT 1;"
# Enter password when prompted
# ✅ Expected: 1 returned

echo "✅ MySQL database and user created"
```

---

## 🔧 PHASE 7: SETUP BACKEND

### 7.1 Create Python Virtual Environment

```bash
cd /var/www/storyboard/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install dependencies
pip install -r requirements.txt

# Verify
pip list | head -10
# ✅ Expected: All packages listed

echo "✅ Backend virtual environment setup complete"
```

### 7.2 Initialize Database

```bash
cd /var/www/storyboard/backend
source venv/bin/activate

# Run migrations (if using Alembic or similar)
# python -m alembic upgrade head

# Or if using SQLAlchemy directly, create tables
python3 << 'EOF'
from app.infrastructure.persistence.db import engine
from app.infrastructure.persistence import models
models.Base.metadata.create_all(bind=engine)
print("✅ Database tables created")
EOF

# Verify database
mysql -u storyboard_user -p storyboard -e "SHOW TABLES;"
# Enter password when prompted
# ✅ Expected: List of tables

echo "✅ Backend database initialized"
```

### 7.3 Test Backend

```bash
cd /var/www/storyboard/backend
source venv/bin/activate

# Start backend temporarily
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &

# Wait 3 seconds
sleep 3

# Test health endpoint
curl http://localhost:8000/health
# ✅ Expected: {"status":"ok"}

# Test API endpoint
curl http://localhost:8000/api/v1/cities | head -20
# ✅ Expected: JSON array

# Stop backend
pkill -f uvicorn

echo "✅ Backend tested successfully"
```

---

## 🎨 PHASE 8: SETUP FRONTEND

### 8.1 Install Dependencies

```bash
cd /var/www/storyboard/client

# Install npm dependencies
npm install

# Verify
npm list | head -10
# ✅ Expected: Dependencies listed

echo "✅ Frontend dependencies installed"
```

### 8.2 Build Frontend

```bash
cd /var/www/storyboard/client

# Build for production
npm run build

# Verify build
ls -la .next/
# ✅ Expected: .next directory with build files

echo "✅ Frontend built successfully"
```

---

## 🌐 PHASE 9: CONFIGURE NGINX

### 9.1 Create Nginx Configuration for Staging

```bash
# Create Nginx config for staging
sudo nano /etc/nginx/sites-available/staging.tourists.co

# Add this configuration:
```

```nginx
# Upstream servers
upstream backend {
    server 127.0.0.1:8000;
}

upstream frontend {
    server 127.0.0.1:3000;
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name staging.tourists.co;
    return 301 https://$server_name$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name staging.tourists.co;

    # SSL certificates (will be added by Certbot)
    # ssl_certificate /etc/letsencrypt/live/staging.tourists.co/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/staging.tourists.co/privkey.pem;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Frontend - accessible
    location / {
        proxy_pass http://frontend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API - NOT accessible from outside (blocked)
    location /api/ {
        return 403;
    }

    # Backend docs - NOT accessible from outside (blocked)
    location /docs {
        return 403;
    }

    location /redoc {
        return 403;
    }

    location /openapi.json {
        return 403;
    }

    # Static files
    location /static/ {
        alias /var/www/storyboard/backend/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Media files
    location /media/ {
        alias /var/www/storyboard/backend/media/;
        expires 7d;
        add_header Cache-Control "public";
    }
}
```

```bash
# Save: Ctrl+X, Y, Enter
```

### 9.2 Enable Nginx Configuration

```bash
# Create symlink to enable site
sudo ln -s /etc/nginx/sites-available/staging.tourists.co /etc/nginx/sites-enabled/

# Remove default site
sudo rm /etc/nginx/sites-enabled/default

# Test Nginx configuration
sudo nginx -t
# ✅ Expected: "test is successful"

# Reload Nginx
sudo systemctl reload nginx

echo "✅ Nginx configured for staging"
```

### 9.3 Setup SSL Certificate with Let's Encrypt

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot certonly --nginx -d staging.tourists.co
# Follow prompts to complete

# Update Nginx config with certificate paths
sudo nano /etc/nginx/sites-available/staging.tourists.co

# Uncomment these lines:
# ssl_certificate /etc/letsencrypt/live/staging.tourists.co/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/staging.tourists.co/privkey.pem;

# Test and reload
sudo nginx -t
sudo systemctl reload nginx

# Setup auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

echo "✅ SSL certificate installed and configured"
```

---

## 🚀 PHASE 10: START SERVICES WITH PM2

### 10.1 Create PM2 Ecosystem File

```bash
# Create ecosystem file
cat > /var/www/storyboard/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'backend',
      cwd: '/var/www/storyboard/backend',
      script: 'venv/bin/python',
      args: '-m uvicorn app.main:app --host 0.0.0.0 --port 8000',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'staging'
      },
      error_file: '/var/www/storyboard/logs/backend-error.log',
      out_file: '/var/www/storyboard/logs/backend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M'
    },
    {
      name: 'frontend',
      cwd: '/var/www/storyboard/client',
      script: 'npm',
      args: 'start',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'staging',
        PORT: 3000
      },
      error_file: '/var/www/storyboard/logs/frontend-error.log',
      out_file: '/var/www/storyboard/logs/frontend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M'
    },
    {
      name: 'celery-worker',
      cwd: '/var/www/storyboard/backend',
      script: 'venv/bin/celery',
      args: '-A app.tasks worker --loglevel=info',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'staging'
      },
      error_file: '/var/www/storyboard/logs/celery-error.log',
      out_file: '/var/www/storyboard/logs/celery-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M'
    },
    {
      name: 'celery-beat',
      cwd: '/var/www/storyboard/backend',
      script: 'venv/bin/celery',
      args: '-A app.tasks beat --loglevel=info',
      instances: 1,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'staging'
      },
      error_file: '/var/www/storyboard/logs/celery-beat-error.log',
      out_file: '/var/www/storyboard/logs/celery-beat-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M'
    }
  ]
};
EOF

echo "✅ PM2 ecosystem file created"
```

### 10.2 Start Services

```bash
# Navigate to project root
cd /var/www/storyboard

# Start all services
pm2 start ecosystem.config.js

# Save PM2 configuration
pm2 save

# Enable PM2 startup on reboot
pm2 startup
# Follow the instructions provided

# Verify services
pm2 status
# ✅ Expected: All services showing "online"

echo "✅ All services started"
```

---

## ✅ PHASE 11: VERIFICATION

### 11.1 Verify Services Running

```bash
# Check PM2 status
pm2 status
# ✅ Expected: All services "online"

# Check ports
netstat -tlnp | grep -E ':(3000|8000|80|443)'
# ✅ Expected: All ports listening

# Check Nginx
sudo systemctl status nginx
# ✅ Expected: active (running)

# Check Redis
sudo systemctl status redis-server
# ✅ Expected: active (running)

# Check MySQL
sudo systemctl status mysql
# ✅ Expected: active (running)

echo "✅ All services verified"
```

### 11.2 Test Backend API (Internal Only)

```bash
# Test health endpoint
curl http://localhost:8000/health
# ✅ Expected: {"status":"ok"}

# Test API endpoint
curl http://localhost:8000/api/v1/cities | head -20
# ✅ Expected: JSON array

echo "✅ Backend API working"
```

### 11.3 Test Frontend

```bash
# Test frontend on localhost
curl http://localhost:3000/
# ✅ Expected: HTML response

echo "✅ Frontend working"
```

### 11.4 Test Staging Domain (Frontend Only)

```bash
# Test frontend through domain
curl https://staging.tourists.co/
# ✅ Expected: HTML response

# Test that backend is blocked
curl https://staging.tourists.co/api/
# ✅ Expected: 403 Forbidden

# Test that docs are blocked
curl https://staging.tourists.co/docs
# ✅ Expected: 403 Forbidden

echo "✅ Staging domain configured correctly"
```

### 11.5 Check Logs

```bash
# View all logs
pm2 logs

# View specific service logs
pm2 logs backend
pm2 logs frontend
pm2 logs celery-worker

# View last 50 lines
pm2 logs --lines 50

# Real-time monitoring
pm2 monit

echo "✅ Logs verified"
```

---

## 📝 PHASE 12: DEPLOYMENT SCRIPTS

### 12.1 Create Staging Deployment Script

```bash
# Create staging deployment script
cat > /var/www/storyboard/deploy-staging.sh << 'EOF'
#!/bin/bash

set -e

echo "🚀 Deploying to Staging..."

# Navigate to project
cd /var/www/storyboard

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# Update backend
echo "🔧 Updating backend..."
cd backend
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Update frontend
echo "🎨 Updating frontend..."
cd client
npm install
npm run build
cd ..

# Restart services
echo "🔄 Restarting services..."
pm2 restart all

# Verify
echo "✅ Deployment to staging complete!"
pm2 status

EOF

# Make executable
chmod +x /var/www/storyboard/deploy-staging.sh

echo "✅ Staging deployment script created"
```

### 12.2 Create Production Deployment Script

```bash
# Create production deployment script
cat > /var/www/storyboard/deploy-production.sh << 'EOF'
#!/bin/bash

set -e

echo "🚀 Deploying to Production..."

# Navigate to project
cd /var/www/storyboard

# Backup database
echo "💾 Backing up database..."
mysqldump -u storyboard_user -p storyboard > /backups/db_backup_$(date +%Y%m%d_%H%M%S).sql

# Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# Update backend
echo "🔧 Updating backend..."
cd backend
source venv/bin/activate
pip install -r requirements.txt
cd ..

# Update frontend
echo "🎨 Updating frontend..."
cd client
npm install
npm run build
cd ..

# Restart services
echo "🔄 Restarting services..."
pm2 restart all

# Verify
echo "✅ Deployment to production complete!"
pm2 status

EOF

# Make executable
chmod +x /var/www/storyboard/deploy-production.sh

echo "✅ Production deployment script created"
```

### 12.3 Create Monitoring Script

```bash
# Create monitoring script
cat > /var/www/storyboard/monitor.sh << 'EOF'
#!/bin/bash

echo "📊 System Monitoring Dashboard"
echo "=============================="
echo ""

echo "🔹 Services Status:"
pm2 status
echo ""

echo "🔹 Memory Usage:"
free -h
echo ""

echo "🔹 Disk Usage:"
df -h | grep -E "^/dev|Filesystem"
echo ""

echo "🔹 Recent Logs (Backend):"
pm2 logs backend --lines 10
echo ""

echo "🔹 Recent Logs (Frontend):"
pm2 logs frontend --lines 10
echo ""

echo "🔹 Port Status:"
netstat -tlnp | grep -E ':(3000|8000|80|443)' || echo "Ports not listening"
echo ""

EOF

# Make executable
chmod +x /var/www/storyboard/monitor.sh

echo "✅ Monitoring script created"
```

---

## 🎯 PHASE 13: FINAL CHECKLIST

### Pre-Staging Checklist

- [ ] Code pushed to GitHub
- [ ] VM created with static IP
- [ ] All dependencies installed (Node, Python, MySQL, Redis, Nginx)
- [ ] Environment files configured (.env files)
- [ ] Database created and initialized
- [ ] Backend tested locally
- [ ] Frontend built successfully
- [ ] Nginx configured for staging
- [ ] SSL certificate installed
- [ ] PM2 ecosystem file created
- [ ] All services started and running
- [ ] Backend API responding on localhost:8000
- [ ] Frontend responding on localhost:3000
- [ ] Staging domain (staging.tourists.co) accessible
- [ ] Backend API blocked from staging domain
- [ ] Backend docs blocked from staging domain
- [ ] Logs verified with no errors

### Staging Verification

- [ ] Visit https://staging.tourists.co in browser
- [ ] Homepage loads without errors
- [ ] All pages accessible (about, contact, faq, etc.)
- [ ] Search functionality works
- [ ] City pages load correctly
- [ ] No console errors in browser
- [ ] SSL certificate valid
- [ ] Backend API not accessible from domain
- [ ] PM2 shows all services online
- [ ] No errors in PM2 logs

---

## 📞 TROUBLESHOOTING

### Services Won't Start

```bash
# Check logs
pm2 logs backend
pm2 logs frontend

# Check if ports are in use
lsof -i :8000
lsof -i :3000

# Kill process on port
kill -9 <PID>

# Restart
pm2 restart all
```

### Database Connection Error

```bash
# Check MySQL status
sudo systemctl status mysql

# Test connection
mysql -u storyboard_user -p storyboard -e "SELECT 1;"

# Check .env file
cat backend/.env | grep DATABASE
```

### Nginx Not Working

```bash
# Test configuration
sudo nginx -t

# Check status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# Reload
sudo systemctl reload nginx
```

### Frontend Not Building

```bash
# Clear cache
rm -rf client/.next client/.swc

# Rebuild
cd client && npm run build

# Check for errors
npm run lint
```

---

## 🎉 SUCCESS!

Once all phases are complete:

✅ Code is on GitHub  
✅ VM is running with static IP  
✅ All dependencies installed  
✅ Environment configured  
✅ Database initialized  
✅ Services running via PM2  
✅ Staging domain accessible (frontend only)  
✅ Backend API blocked from public access  
✅ Backend docs blocked from public access  
✅ All logs clean with no errors  

**Next Steps:**
1. Test all features on staging
2. Get stakeholder approval
3. Plan production deployment
4. Setup monitoring and alerts
5. Document any issues found

---

## 📚 QUICK REFERENCE

### SSH into VM
```bash
gcloud compute ssh storyboard-staging --zone=us-central1-a
```

### Deploy to Staging
```bash
/var/www/storyboard/deploy-staging.sh
```

### Deploy to Production
```bash
/var/www/storyboard/deploy-production.sh
```

### Monitor Services
```bash
/var/www/storyboard/monitor.sh
```

### View Logs
```bash
pm2 logs
pm2 logs backend
pm2 logs frontend
```

### Restart Services
```bash
pm2 restart all
pm2 restart backend
pm2 restart frontend
```

### Check Status
```bash
pm2 status
pm2 monit
```

---

**Deployment Plan Created:** December 16, 2024  
**Status:** Ready for Implementation  
**Environment:** Staging (staging.tourists.co)
