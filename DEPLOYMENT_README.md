# 🚀 Storyboard Deployment Guide

Complete guide for deploying Storyboard from local development to staging and production environments.

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Pre-Deployment](#pre-deployment)
3. [GitHub Setup](#github-setup)
4. [VM Setup](#vm-setup)
5. [Staging Deployment](#staging-deployment)
6. [Production Deployment](#production-deployment)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

### For Experienced Developers

```bash
# 1. Prepare local code
git add .
git commit -m "deployment ready"
git push origin main

# 2. SSH into VM
gcloud compute ssh storyboard-staging --zone=us-central1-a

# 3. Deploy to staging
/var/www/storyboard/deploy-staging.sh

# 4. Deploy to production
/var/www/storyboard/deploy-production.sh
```

---

## 📋 Pre-Deployment

### 1. Update .gitignore

Ensure sensitive files are not committed:

```bash
# Add to .gitignore
.env
.env.local
backend/.env
client/.env.local
client/.next/
client/.swc/
backend/__pycache__/
node_modules/
backend/venv/
```

### 2. Run Pre-Deployment Checks

```bash
# Frontend
cd client
npm run lint
npm run build

# Backend
cd ../backend
python3 -m py_compile app/*.py

# Git
git status
# Should show: "nothing to commit, working tree clean"
```

### 3. Commit and Push to GitHub

```bash
cd /path/to/storyboard

git add .
git commit -m "feat: production-ready deployment

- Move all hardcoded text to JSON files
- Fix build issues and deprecated configs
- Clean up unnecessary files
- Optimize frontend build
- Add comprehensive deployment guide"

git push origin main
```

---

## 🐙 GitHub Setup

### 1. Create Repository (if not exists)

```bash
# Initialize git (if needed)
git init
git add .
git commit -m "Initial commit"

# Add remote
git remote add origin https://github.com/your-username/storyboard.git

# Push to GitHub
git branch -M main
git push -u origin main
```

### 2. Verify on GitHub

Visit: `https://github.com/your-username/storyboard`

Ensure:
- ✅ Code is visible
- ✅ All files present
- ✅ No sensitive files (.env, node_modules, etc.)

---

## 🖥️ VM Setup

### 1. Create Google Cloud VM

```bash
# Create instance
gcloud compute instances create storyboard-staging \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --boot-disk-size=50GB \
  --tags=http-server,https-server

# Get IP
gcloud compute instances describe storyboard-staging --zone=us-central1-a | grep natIP
```

### 2. Reserve Static IP

```bash
# Create static IP
gcloud compute addresses create storyboard-staging-ip --region=us-central1

# Attach to instance
gcloud compute instances add-access-config storyboard-staging \
  --access-config-name=storyboard-staging-ip \
  --zone=us-central1-a

# Get static IP
gcloud compute addresses list
```

### 3. Configure Firewall

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

### 4. SSH into VM

```bash
# Connect
gcloud compute ssh storyboard-staging --zone=us-central1-a

# Or with SSH key
ssh -i ~/.ssh/gcloud_key ubuntu@STATIC_IP
```

### 5. Run VM Setup Script

```bash
# Download setup script
wget https://raw.githubusercontent.com/your-username/storyboard/main/setup-vm.sh

# Make executable
chmod +x setup-vm.sh

# Run setup
./setup-vm.sh

# This will install:
# ✅ Node.js 20
# ✅ Python 3.11
# ✅ MySQL
# ✅ Redis
# ✅ Nginx
# ✅ PM2
# ✅ Certbot
```

### 6. Clone Repository

```bash
# Create project directory
sudo mkdir -p /var/www
sudo chown ubuntu:ubuntu /var/www

# Clone repo
cd /var/www
git clone https://github.com/your-username/storyboard.git
cd storyboard

# Verify
ls -la
# Should show: backend/, client/, deploy-staging.sh, etc.
```

---

## ⚙️ Configure Environment

### 1. Backend Configuration

```bash
cd /var/www/storyboard/backend

# Copy example
cp .env.example .env

# Edit
nano .env
```

Update these values:

```env
# Database
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=storyboard_user
DATABASE_PASSWORD=your_strong_password
DATABASE_NAME=storyboard

# API Keys
GOOGLE_PLACES_API_KEY=your_key
YOUTUBE_API_KEY=your_key
OPENWEATHER_API_KEY=your_key
GOOGLE_GENERATIVE_AI_KEY=your_key

# Celery
CELERY_BROKER_URL=redis://localhost:6379/0
CELERY_RESULT_BACKEND=redis://localhost:6379/1

# Environment
DEBUG=False
ENVIRONMENT=staging
SECRET_KEY=your_generated_key
```

### 2. Frontend Configuration

```bash
cd /var/www/storyboard/client

# Copy example
cp .env.example .env.local

# Edit
nano .env.local
```

Update:

```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1
NEXT_PUBLIC_ENVIRONMENT=staging
```

### 3. Setup Database

```bash
# Connect to MySQL
sudo mysql -u root

# Run:
CREATE DATABASE storyboard;
CREATE USER 'storyboard_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON storyboard.* TO 'storyboard_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;

# Verify
mysql -u storyboard_user -p storyboard -e "SELECT 1;"
```

---

## 🎨 Setup Backend & Frontend

### 1. Backend Setup

```bash
cd /var/www/storyboard/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Initialize database
python3 << 'EOF'
from app.infrastructure.persistence.db import engine
from app.infrastructure.persistence import models
models.Base.metadata.create_all(bind=engine)
print("✅ Database initialized")
EOF

# Test
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 &
sleep 2
curl http://localhost:8000/health
pkill -f uvicorn
```

### 2. Frontend Setup

```bash
cd /var/www/storyboard/client

# Install dependencies
npm install

# Build
npm run build

# Verify
ls -la .next/
```

---

## 🌐 Configure Nginx

### 1. Create Nginx Config

```bash
sudo nano /etc/nginx/sites-available/staging.tourists.co
```

Add:

```nginx
upstream backend {
    server 127.0.0.1:8000;
}

upstream frontend {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name staging.tourists.co;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name staging.tourists.co;

    # SSL (will be added by Certbot)
    # ssl_certificate /etc/letsencrypt/live/staging.tourists.co/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/staging.tourists.co/privkey.pem;

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

    # Backend API - BLOCKED
    location /api/ {
        return 403;
    }

    # Backend docs - BLOCKED
    location /docs {
        return 403;
    }

    location /redoc {
        return 403;
    }

    location /openapi.json {
        return 403;
    }
}
```

### 2. Enable and Test

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/staging.tourists.co /etc/nginx/sites-enabled/

# Remove default
sudo rm /etc/nginx/sites-enabled/default

# Test
sudo nginx -t
# Expected: "test is successful"

# Reload
sudo systemctl reload nginx
```

### 3. Setup SSL

```bash
# Get certificate
sudo certbot certonly --nginx -d staging.tourists.co

# Update Nginx config
sudo nano /etc/nginx/sites-available/staging.tourists.co

# Uncomment SSL lines:
# ssl_certificate /etc/letsencrypt/live/staging.tourists.co/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/staging.tourists.co/privkey.pem;

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🚀 Staging Deployment

### 1. Create PM2 Ecosystem File

```bash
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
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'frontend',
      cwd: '/var/www/storyboard/client',
      script: 'npm',
      args: 'start',
      instances: 1,
      exec_mode: 'fork',
      env: { PORT: 3000 },
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'celery-worker',
      cwd: '/var/www/storyboard/backend',
      script: 'venv/bin/celery',
      args: '-A app.tasks worker --loglevel=info',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '500M'
    },
    {
      name: 'celery-beat',
      cwd: '/var/www/storyboard/backend',
      script: 'venv/bin/celery',
      args: '-A app.tasks beat --loglevel=info',
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      max_memory_restart: '500M'
    }
  ]
};
EOF
```

### 2. Start Services

```bash
cd /var/www/storyboard

# Start all services
pm2 start ecosystem.config.js

# Save configuration
pm2 save

# Enable startup on reboot
pm2 startup
# Follow instructions

# Verify
pm2 status
```

### 3. Deploy to Staging

```bash
# Make script executable
chmod +x /var/www/storyboard/deploy-staging.sh

# Run deployment
/var/www/storyboard/deploy-staging.sh
```

### 4. Verify Staging

```bash
# Check services
pm2 status

# Test backend (internal)
curl http://localhost:8000/health

# Test frontend (internal)
curl http://localhost:3000/

# Test domain (frontend only)
curl https://staging.tourists.co/

# Test that backend is blocked
curl https://staging.tourists.co/api/
# Expected: 403 Forbidden

# Test that docs are blocked
curl https://staging.tourists.co/docs
# Expected: 403 Forbidden
```

---

## 🎯 Production Deployment

### 1. Update Domain DNS

Point `tourists.co` to your static IP:

```
A record: tourists.co -> STATIC_IP
A record: www.tourists.co -> STATIC_IP
```

### 2. Create Production Nginx Config

```bash
sudo nano /etc/nginx/sites-available/tourists.co

# Same as staging but with:
# server_name tourists.co www.tourists.co;
# ssl_certificate /etc/letsencrypt/live/tourists.co/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/tourists.co/privkey.pem;
```

### 3. Setup Production SSL

```bash
sudo certbot certonly --nginx -d tourists.co -d www.tourists.co
```

### 4. Deploy to Production

```bash
# Make script executable
chmod +x /var/www/storyboard/deploy-production.sh

# Run deployment (will prompt for confirmation)
/var/www/storyboard/deploy-production.sh
```

### 5. Verify Production

```bash
# Check services
pm2 status

# Test domain
curl https://tourists.co/

# Verify backend is blocked
curl https://tourists.co/api/
# Expected: 403 Forbidden
```

---

## 📊 Monitoring & Maintenance

### Daily Monitoring

```bash
# Check services
pm2 status

# View logs
pm2 logs

# Monitor resources
pm2 monit

# Check disk space
df -h

# Check memory
free -h
```

### Update Code

```bash
cd /var/www/storyboard

# Pull latest
git pull origin main

# Deploy to staging
./deploy-staging.sh

# After testing, deploy to production
./deploy-production.sh
```

### Restart Services

```bash
# Restart all
pm2 restart all

# Restart specific
pm2 restart backend
pm2 restart frontend

# Stop all
pm2 stop all

# Start all
pm2 start all
```

### View Logs

```bash
# All logs
pm2 logs

# Specific service
pm2 logs backend
pm2 logs frontend

# Last N lines
pm2 logs --lines 100

# Real-time
pm2 monit
```

---

## 🔧 Troubleshooting

### Services Won't Start

```bash
# Check logs
pm2 logs backend

# Check if ports are in use
lsof -i :8000
lsof -i :3000

# Kill process
kill -9 <PID>

# Restart
pm2 restart all
```

### Database Connection Error

```bash
# Check MySQL
sudo systemctl status mysql

# Test connection
mysql -u storyboard_user -p storyboard -e "SELECT 1;"

# Check .env
cat backend/.env | grep DATABASE
```

### Nginx Not Working

```bash
# Test config
sudo nginx -t

# Check status
sudo systemctl status nginx

# View errors
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

### SSL Certificate Issues

```bash
# Check certificate
sudo certbot certificates

# Renew certificate
sudo certbot renew

# Check expiry
echo | openssl s_client -servername staging.tourists.co -connect staging.tourists.co:443 2>/dev/null | openssl x509 -noout -dates
```

---

## 📞 Support

For issues:

1. Check logs: `pm2 logs`
2. Check status: `pm2 status`
3. Check resources: `free -h && df -h`
4. Review troubleshooting section above
5. Check system logs: `sudo journalctl -n 50`

---

## ✅ Deployment Checklist

- [ ] Code pushed to GitHub
- [ ] VM created with static IP
- [ ] All dependencies installed
- [ ] Environment files configured
- [ ] Database created and initialized
- [ ] Backend tested locally
- [ ] Frontend built successfully
- [ ] Nginx configured
- [ ] SSL certificate installed
- [ ] PM2 ecosystem file created
- [ ] All services started
- [ ] Staging domain accessible (frontend only)
- [ ] Backend API blocked from staging domain
- [ ] Backend docs blocked from staging domain
- [ ] Production domain configured
- [ ] Production SSL certificate installed
- [ ] Production deployment tested

---

**Last Updated:** December 16, 2024  
**Status:** Ready for Deployment  
**Environment:** Staging & Production
