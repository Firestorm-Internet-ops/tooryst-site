# Complete Deployment Guide: Check → Deploy → Run

**For Google Cloud Compute Engine VM (No Docker)**

---

## 📋 PART 1: PRE-DEPLOYMENT CHECKS (Local Machine)

### 1.1 Code Quality Checks

```bash
cd /path/to/project

# Run linting
npm run lint
# ✅ Expected: No errors

# Run tests
npm run test
# ✅ Expected: All tests pass

# Build frontend
npm run build
# ✅ Expected: Build succeeds, no errors

# Build backend (optional)
cd backend && python -m py_compile app/main.py
# ✅ Expected: No syntax errors
```

### 1.2 Environment Variables Check

```bash
# Backend environment
cat backend/.env | grep -E "^[A-Z_]+" | head -20
# ✅ Expected: All required vars present (DATABASE_URL, API_KEYS, etc.)

# Frontend environment
cat client/.env.local | grep -E "^NEXT_PUBLIC_"
# ✅ Expected: NEXT_PUBLIC_API_BASE_URL set correctly
```

### 1.3 Git Status Check

```bash
# Check for uncommitted changes
git status
# ✅ Expected: "nothing to commit, working tree clean"

# View recent commits
git log --oneline -5
# ✅ Expected: Meaningful commit messages

# Verify branch
git branch
# ✅ Expected: On main branch
```

### 1.4 Database Check (Local)

```bash
# Backend
cd backend
source venv/bin/activate

# Check database connection
python -c "
from app.infrastructure.persistence.db import SessionLocal
from app.infrastructure.persistence import models
session = SessionLocal()
print(f'✅ Database connected')
print(f'Attractions: {session.query(models.Attraction).count()}')
print(f'Cities: {session.query(models.City).count()}')
session.close()
"
# ✅ Expected: Connection successful, data present
```

### 1.5 API Endpoints Check (Local)

```bash
# Start backend (if not running)
cd backend && source venv/bin/activate
python -m uvicorn app.main:app --reload --port 8000 &

# Test endpoints
curl http://localhost:8000/health
# ✅ Expected: {"status":"ok"}

curl http://localhost:8000/api/v1/cities
# ✅ Expected: JSON array of cities

curl http://localhost:8000/api/v1/attractions
# ✅ Expected: JSON array of attractions
```

### 1.6 Frontend Check (Local)

```bash
# Start frontend (if not running)
cd client
npm run dev &

# Test homepage
curl http://localhost:3000/
# ✅ Expected: HTML response

# Check console for errors
# Open http://localhost:3000 in browser
# ✅ Expected: No red errors in console
```

### 1.7 Final Pre-Deployment Checklist

```bash
# Run all checks in sequence
echo "🔍 Running pre-deployment checks..."

# 1. Code quality
npm run lint && echo "✅ Lint passed" || echo "❌ Lint failed"
npm run test && echo "✅ Tests passed" || echo "❌ Tests failed"
npm run build && echo "✅ Build passed" || echo "❌ Build failed"

# 2. Git status
git status | grep "nothing to commit" && echo "✅ Git clean" || echo "❌ Uncommitted changes"

# 3. Environment
[ -f backend/.env ] && echo "✅ Backend .env exists" || echo "❌ Backend .env missing"
[ -f client/.env.local ] && echo "✅ Frontend .env.local exists" || echo "❌ Frontend .env.local missing"

# 4. Ready to push
echo "✅ All checks passed - Ready to deploy!"
```

---

## 🚀 PART 2: DEPLOYMENT STEPS (Push to GitHub & VM)

### 2.1 Push Code to GitHub

```bash
cd /path/to/project

# Add all changes
git add .

# Commit with meaningful message
git commit -m "feat: deployment ready - performance optimizations and pipeline fixes

- Implement code splitting for heavy components
- Add Web Vitals tracking
- Create placeholder cards for missing data
- Optimize images with AVIF/WebP support
- Add lazy loading with Intersection Observer
- Fix pipeline stage tracking and error handling
- Enable YouTube quota handling
- Update next.config.ts with performance settings"

# Push to GitHub
git push origin main

# Verify on GitHub
echo "✅ Code pushed to GitHub"
echo "Visit: https://github.com/your-username/your-repo"
```

### 2.2 SSH to Google Cloud VM

```bash
# Connect to VM
ssh -i /path/to/key.pem user@your-vm-ip

# Or if using gcloud CLI
gcloud compute ssh your-instance-name --zone=your-zone

# Verify connection
pwd
# ✅ Expected: You're on the VM
```

### 2.3 Clone Repository on VM

```bash
# Navigate to deployment directory
cd /var/www

# Clone repository (first time only)
git clone https://github.com/your-username/your-repo.git
cd your-repo

# Or update if already cloned
cd /var/www/your-repo
git pull origin main

# Verify
pwd
ls -la
# ✅ Expected: You see backend/, client/, deploy.sh, etc.
```

### 2.4 Install System Dependencies

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Python 3.11+
sudo apt install -y python3 python3-pip python3-venv

# Install MySQL
sudo apt install -y mysql-server

# Install Redis
sudo apt install -y redis-server

# Install Nginx
sudo apt install -y nginx

# Install PM2 (process manager)
sudo npm install -g pm2

# Verify installations
node --version
python3 --version
mysql --version
redis-cli --version
nginx -v
pm2 --version
# ✅ Expected: All versions displayed
```

### 2.5 Backend Setup

```bash
# Navigate to backend
cd /var/www/your-repo/backend

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
# ✅ Expected: All packages installed

# Setup environment file
cp .env.example .env

# Edit .env with production values
nano .env
# Update these values:
# - DATABASE_HOST=localhost
# - DATABASE_USER=root
# - DATABASE_PASSWORD=your_strong_password
# - DATABASE_NAME=storyboard
# - DEBUG=False
# - ADMIN_API_KEY=your_generated_key
# - All API keys (GOOGLE_PLACES_API_KEY, YOUTUBE_API_KEY, etc.)
# - CELERY_BROKER_URL=redis://localhost:6379/0
# - CELERY_RESULT_BACKEND=redis://localhost:6379/1

# Press Ctrl+X, then Y, then Enter to save

# Initialize database
mysql -u root -p
# Enter password when prompted
CREATE DATABASE storyboard;
EXIT;

# Run migrations
python manage.py migrate
# ✅ Expected: Migrations applied successfully

# Collect static files
python manage.py collectstatic --noinput
# ✅ Expected: Static files collected

# Test backend
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
# ✅ Expected: Server running on 0.0.0.0:8000
# Press Ctrl+C to stop
```

### 2.6 Frontend Setup

```bash
# Navigate to frontend
cd /var/www/your-repo/client

# Install dependencies
npm install
# ✅ Expected: All packages installed

# Setup environment file
cp .env.example .env.local

# Edit .env.local with production values
nano .env.local
# Update:
# - NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1
# Press Ctrl+X, then Y, then Enter to save

# Build for production
npm run build
# ✅ Expected: Build succeeds, .next directory created

# Verify build
ls -la .next/
# ✅ Expected: .next directory exists with build files
```

### 2.7 Configure Nginx

```bash
# Create Nginx configuration
sudo nano /etc/nginx/sites-available/default

# Replace entire file with this configuration:
```

```nginx
upstream backend {
    server 127.0.0.1:8000;
}

upstream frontend {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name your-domain.com www.your-domain.com;

    # Frontend
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

    # Backend API
    location /api/ {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Static files
    location /static/ {
        alias /var/www/your-repo/backend/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Media files
    location /media/ {
        alias /var/www/your-repo/backend/media/;
        expires 7d;
        add_header Cache-Control "public";
    }
}
```

```bash
# Test Nginx configuration
sudo nginx -t
# ✅ Expected: "test is successful"

# Reload Nginx
sudo systemctl reload nginx

# Enable Nginx on startup
sudo systemctl enable nginx

# Start Nginx
sudo systemctl start nginx

# Verify Nginx is running
sudo systemctl status nginx
# ✅ Expected: "active (running)"
```

### 2.8 Setup SSL Certificate (Let's Encrypt)

```bash
# Install Certbot
sudo apt install -y certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot certonly --nginx -d your-domain.com -d www.your-domain.com
# Follow prompts to complete

# Update Nginx config to use HTTPS
sudo nano /etc/nginx/sites-available/default

# Add these lines after "listen 80;":
# listen 443 ssl http2;
# ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
# ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

# Add redirect from HTTP to HTTPS:
# if ($scheme != "https") {
#     return 301 https://$server_name$request_uri;
# }

# Test and reload
sudo nginx -t
sudo systemctl reload nginx

# Setup auto-renewal
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer
```

### 2.9 Start Services with PM2

```bash
# Navigate to backend
cd /var/www/your-repo/backend

# Start backend with PM2
pm2 start "source venv/bin/activate && python -m uvicorn app.main:app --host 0.0.0.0 --port 8000" --name "backend" --interpreter bash
# ✅ Expected: Backend started

# Navigate to frontend
cd /var/www/your-repo/client

# Start frontend with PM2
pm2 start "npm start" --name "frontend"
# ✅ Expected: Frontend started

# Save PM2 configuration
pm2 save

# Enable PM2 startup on reboot
pm2 startup
# Follow the instructions provided

# Verify services
pm2 status
# ✅ Expected: Both backend and frontend showing "online"
```

---

## ✅ PART 3: VERIFICATION & RUNNING

### 3.1 Verify Services Are Running

```bash
# Check PM2 status
pm2 status
# ✅ Expected: 
# ┌─────────────┬──────┬──────┬──────────┬────────┬─────────┐
# │ Name        │ PID  │ Mode │ Status   │ Uptime │ Memory  │
# ├─────────────┼──────┼──────┼──────────┼────────┼─────────┤
# │ backend     │ xxxx │ fork │ online   │ 1m     │ 50.0 MB │
# │ frontend    │ xxxx │ fork │ online   │ 1m     │ 80.0 MB │
# └─────────────┴──────┴──────┴──────────┴────────┴─────────┘

# Check if ports are listening
netstat -tlnp | grep -E ':(3000|8000|80|443)'
# ✅ Expected: All ports showing LISTEN

# Check Nginx status
sudo systemctl status nginx
# ✅ Expected: "active (running)"

# Check Redis status
sudo systemctl status redis-server
# ✅ Expected: "active (running)"
```

### 3.2 Test Backend API

```bash
# Test health endpoint
curl http://localhost:8000/health
# ✅ Expected: {"status":"ok"}

# Test API endpoint
curl http://localhost:8000/api/v1/cities
# ✅ Expected: JSON array of cities

# Test with domain
curl http://your-domain.com/api/v1/cities
# ✅ Expected: Same JSON response
```

### 3.3 Test Frontend

```bash
# Test frontend on localhost
curl http://localhost:3000/
# ✅ Expected: HTML response

# Test through domain
curl http://your-domain.com/
# ✅ Expected: HTML response

# Visit in browser
# Open http://your-domain.com in browser
# ✅ Expected: Homepage loads, no errors in console
```

### 3.4 Check Logs

```bash
# View backend logs
pm2 logs backend --lines 50
# ✅ Expected: No error messages (red text)

# View frontend logs
pm2 logs frontend --lines 50
# ✅ Expected: No error messages

# View Nginx logs
sudo tail -f /var/log/nginx/access.log
# ✅ Expected: Requests being logged

# View Nginx errors
sudo tail -f /var/log/nginx/error.log
# ✅ Expected: No errors
```

### 3.5 Check System Resources

```bash
# Check memory usage
free -h
# ✅ Expected: Sufficient free memory (at least 1GB)

# Check disk space
df -h
# ✅ Expected: Sufficient free space (at least 10GB)

# Check CPU usage
top -b -n 1 | head -20
# ✅ Expected: CPU usage reasonable (< 80%)

# Monitor with PM2
pm2 monit
# ✅ Expected: Services running, memory usage stable
```

### 3.6 Database Verification

```bash
# Connect to database
mysql -u root -p
# Enter password

# Check database exists
SHOW DATABASES;
# ✅ Expected: "storyboard" in list

# Check tables
USE storyboard;
SHOW TABLES;
# ✅ Expected: Multiple tables (attractions, cities, etc.)

# Check data
SELECT COUNT(*) FROM attractions;
# ✅ Expected: Number > 0

# Exit
EXIT;
```

### 3.7 HTTPS/SSL Verification

```bash
# Test HTTPS
curl -I https://your-domain.com/
# ✅ Expected: HTTP/2 200 with SSL headers

# Check certificate
sudo certbot certificates
# ✅ Expected: Certificate valid and not expired

# Check certificate expiry
echo | openssl s_client -servername your-domain.com -connect your-domain.com:443 2>/dev/null | openssl x509 -noout -dates
# ✅ Expected: notAfter date in future
```

### 3.8 Final Deployment Checklist

```bash
# Run comprehensive verification
echo "🔍 Running final deployment verification..."

# 1. Services running
pm2 status | grep "online" && echo "✅ Services running" || echo "❌ Services not running"

# 2. Backend responding
curl -s http://localhost:8000/health | grep "ok" && echo "✅ Backend responding" || echo "❌ Backend not responding"

# 3. Frontend responding
curl -s http://localhost:3000/ | grep -q "html" && echo "✅ Frontend responding" || echo "❌ Frontend not responding"

# 4. Domain working
curl -s http://your-domain.com/ | grep -q "html" && echo "✅ Domain working" || echo "❌ Domain not working"

# 5. Database connected
mysql -u root -p -e "SELECT COUNT(*) FROM storyboard.attractions;" && echo "✅ Database connected" || echo "❌ Database not connected"

# 6. No errors in logs
pm2 logs backend --lines 10 | grep -i "error" && echo "⚠️  Errors in backend logs" || echo "✅ No errors in backend logs"

# 7. Resources available
free -h | grep -q "Gi" && echo "✅ Resources available" || echo "⚠️  Low resources"

echo "✅ Deployment verification complete!"
```

---

## 🔄 PART 4: ONGOING OPERATIONS

### 4.1 Daily Monitoring

```bash
# Check services status
pm2 status

# View recent logs
pm2 logs --lines 50

# Monitor resources
pm2 monit

# Check disk space
df -h

# Check memory
free -h
```

### 4.2 Updating Code

```bash
# Pull latest changes
cd /var/www/your-repo
git pull origin main

# Rebuild frontend
cd client && npm run build

# Run migrations (if needed)
cd ../backend && python manage.py migrate

# Restart services
pm2 restart all

# Verify
pm2 status
curl http://your-domain.com/
```

### 4.3 Restarting Services

```bash
# Restart all services
pm2 restart all

# Restart specific service
pm2 restart backend
pm2 restart frontend

# Stop all services
pm2 stop all

# Start all services
pm2 start all

# View status
pm2 status
```

### 4.4 Viewing Logs

```bash
# View all logs
pm2 logs

# View specific service logs
pm2 logs backend
pm2 logs frontend

# View last N lines
pm2 logs --lines 100

# Real-time monitoring
pm2 monit

# Nginx access logs
sudo tail -f /var/log/nginx/access.log

# Nginx error logs
sudo tail -f /var/log/nginx/error.log
```

### 4.5 Backup Strategy

```bash
# Create backup directory
mkdir -p /backups

# Backup database
mysqldump -u root -p storyboard > /backups/db_backup_$(date +%Y%m%d_%H%M%S).sql

# Backup media files
tar -czf /backups/media_backup_$(date +%Y%m%d_%H%M%S).tar.gz /var/www/your-repo/backend/media/

# Setup daily backup cron
crontab -e
# Add: 0 2 * * * mysqldump -u root -p storyboard > /backups/db_backup_$(date +\%Y\%m\%d).sql
```

### 4.6 Troubleshooting

```bash
# Backend won't start
pm2 logs backend
lsof -i :8000
kill -9 <PID>
pm2 restart backend

# Frontend won't start
pm2 logs frontend
lsof -i :3000
rm -rf /var/www/your-repo/client/.next
cd /var/www/your-repo/client && npm run build
pm2 restart frontend

# Database connection error
sudo systemctl status mysql
mysql -u root -p -e "SELECT 1"

# Nginx not working
sudo nginx -t
sudo systemctl status nginx
sudo systemctl reload nginx

# Check all services
pm2 status
sudo systemctl status nginx
sudo systemctl status mysql
sudo systemctl status redis-server
```

---

## 📊 QUICK REFERENCE COMMANDS

### Service Management
```bash
pm2 status              # Check all services
pm2 logs                # View logs
pm2 restart all         # Restart all services
pm2 stop all            # Stop all services
pm2 start all           # Start all services
pm2 monit               # Monitor resources
```

### System Management
```bash
sudo systemctl status nginx          # Check Nginx
sudo systemctl reload nginx          # Reload Nginx
sudo systemctl status mysql          # Check MySQL
sudo systemctl status redis-server   # Check Redis
free -h && df -h                     # Check resources
```

### Code Updates
```bash
cd /var/www/your-repo
git pull origin main                 # Update code
cd client && npm run build           # Build frontend
cd ../backend && python manage.py migrate  # Run migrations
pm2 restart all                      # Restart services
```

### Testing
```bash
curl http://localhost:8000/health    # Test backend
curl http://localhost:3000/          # Test frontend
curl http://your-domain.com/         # Test domain
curl -I https://your-domain.com/     # Test HTTPS
```

---

## ✨ SUCCESS INDICATORS

✅ `pm2 status` shows all services "online"  
✅ `curl http://localhost:8000/api/v1/` returns data  
✅ `curl http://localhost:3000/` returns HTML  
✅ `curl http://your-domain.com/` works  
✅ `pm2 logs` shows no errors  
✅ `free -h` shows available memory  
✅ `df -h` shows available disk space  
✅ HTTPS works with valid certificate  
✅ All features tested and working  

---

## 🎉 DEPLOYMENT COMPLETE!

Your application is now running on Google Cloud Compute Engine!

**Next steps:**
1. Monitor logs: `pm2 logs`
2. Check performance: `pm2 monit`
3. Test all features
4. Setup monitoring and alerts
5. Document any issues

---

## 📞 SUPPORT

If issues occur:
1. Check logs: `pm2 logs`
2. Check status: `pm2 status`
3. Check resources: `free -h && df -h`
4. Review troubleshooting section above
5. Check system logs: `sudo journalctl -n 50`

