#!/bin/bash

###############################################################################
# Tooryst Single VM Deployment Script
# Deploys both staging and production to one VM on different ports
# Usage: ./deploy-single-vm.sh
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}
ZONE=${ZONE:-us-central1-a}
VM_NAME="tooryst-server"
REPO_URL="https://github.com/YOUR_ACTUAL_USERNAME/tooryst.git"  # Update this with your actual GitHub username

# Port configuration
STAGING_FRONTEND_PORT=3000
STAGING_BACKEND_PORT=8000
PRODUCTION_FRONTEND_PORT=3001
PRODUCTION_BACKEND_PORT=8001

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

run_on_vm() {
    local command="$1"
    gcloud compute ssh $VM_NAME --zone=$ZONE --command="$command"
}

deploy_environment() {
    local env_name=$1
    local frontend_port=$2
    local backend_port=$3
    local db_password=$4
    
    log_info "Deploying $env_name environment..."
    
    # Clone repository for this environment
    run_on_vm "sudo rm -rf /var/www/tooryst-$env_name"
    run_on_vm "sudo mkdir -p /var/www/tooryst-$env_name"
    run_on_vm "sudo chown -R \$USER:\$USER /var/www/tooryst-$env_name"
    run_on_vm "cd /var/www && git clone $REPO_URL tooryst-$env_name"
    
    # Setup database for this environment
    run_on_vm "sudo mysql -e \"CREATE DATABASE IF NOT EXISTS tooryst_$env_name;\""
    run_on_vm "sudo mysql -e \"CREATE USER IF NOT EXISTS 'tooryst_${env_name}_user'@'localhost' IDENTIFIED BY '$db_password';\""
    run_on_vm "sudo mysql -e \"GRANT ALL PRIVILEGES ON tooryst_$env_name.* TO 'tooryst_${env_name}_user'@'localhost';\""
    run_on_vm "sudo mysql -e \"FLUSH PRIVILEGES;\""
    
    # Setup backend
    run_on_vm "cd /var/www/tooryst-$env_name/backend && python3.11 -m venv venv"
    run_on_vm "cd /var/www/tooryst-$env_name/backend && source venv/bin/activate && pip install --upgrade pip"
    run_on_vm "cd /var/www/tooryst-$env_name/backend && source venv/bin/activate && pip install -r requirements.txt"
    
    # Create backend .env file
    run_on_vm "cat > /var/www/tooryst-$env_name/backend/.env << 'EOF'
APP_NAME=Tooryst
APP_VERSION=0.1.0
ENVIRONMENT=$env_name

DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=tooryst_${env_name}_user
DATABASE_PASSWORD=$db_password
DATABASE_NAME=tooryst_$env_name

ADMIN_API_KEY=${env_name}_admin_key_123

# Add your API keys here
GOOGLE_PLACES_API_KEY=
GOOGLE_MAPS_API_KEY=
GOOGLE_DIRECTIONS_API_KEY=
YOUTUBE_API_KEY=
REDDIT_CLIENT_ID=
REDDIT_CLIENT_SECRET=
REDDIT_USER_AGENT=ToorystBot
OPENWEATHERMAP_API_KEY=
GEMINI_API_KEY=
BESTTIME_API_PRIVATE_KEY=

REDIS_HOST=localhost
REDIS_PORT=6379
CELERY_BROKER_URL=redis://localhost:6379/$([[ \"$env_name\" == \"staging\" ]] && echo \"0\" || echo \"2\")
CELERY_RESULT_BACKEND=redis://localhost:6379/$([[ \"$env_name\" == \"staging\" ]] && echo \"1\" || echo \"3\")

LOG_LEVEL=INFO
CORS_ALLOWED_ORIGINS=http://localhost:$frontend_port,https://$([[ \"$env_name\" == \"staging\" ]] && echo \"staging.\" || echo \"\")tooryst.co
EOF"
    
    # Run database migrations
    run_on_vm "cd /var/www/tooryst-$env_name/backend && source venv/bin/activate && alembic upgrade head" || log_warning "Migrations may not exist yet"
    
    # Setup frontend
    run_on_vm "cd /var/www/tooryst-$env_name/client && pnpm install"
    
    # Create frontend .env.local file
    run_on_vm "cat > /var/www/tooryst-$env_name/client/.env.local << 'EOF'
NODE_ENV=production
NEXT_PUBLIC_API_URL=http://localhost:$backend_port
NEXT_PUBLIC_ENVIRONMENT=$env_name
PORT=$frontend_port
EOF"
    
    # Build frontend
    run_on_vm "cd /var/www/tooryst-$env_name/client && TURBOPACK=false NODE_OPTIONS='--max-old-space-size=4096' pnpm build"
    
    log_success "$env_name environment deployed"
}

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🚀 Tooryst Single VM Deployment                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Step 1: Verify VM is running
    log_info "Step 1: Verifying VM status..."
    
    VM_STATUS=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="get(status)")
    if [ "$VM_STATUS" != "RUNNING" ]; then
        log_info "Starting VM..."
        gcloud compute instances start $VM_NAME --zone=$ZONE
        sleep 30
    fi
    
    VM_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
    log_success "VM is running at IP: $VM_IP"
    echo ""

    # Step 2: Deploy staging environment
    deploy_environment "staging" $STAGING_FRONTEND_PORT $STAGING_BACKEND_PORT "staging_pass_123"
    echo ""

    # Step 3: Deploy production environment
    deploy_environment "production" $PRODUCTION_FRONTEND_PORT $PRODUCTION_BACKEND_PORT "production_pass_456"
    echo ""

    # Step 4: Setup PM2 ecosystem
    log_info "Step 4: Setting up PM2 processes..."
    
    run_on_vm "cat > /var/www/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    // Staging Apps
    {
      name: 'tooryst-backend-staging',
      cwd: '/var/www/tooryst-staging/backend',
      script: 'venv/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port $STAGING_BACKEND_PORT',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: { NODE_ENV: 'production' },
      error_file: '/var/log/tooryst/staging-backend-error.log',
      out_file: '/var/log/tooryst/staging-backend-out.log',
      log_file: '/var/log/tooryst/staging-backend.log'
    },
    {
      name: 'tooryst-frontend-staging',
      cwd: '/var/www/tooryst-staging/client',
      script: 'npm',
      args: 'start',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: { NODE_ENV: 'production', PORT: $STAGING_FRONTEND_PORT },
      error_file: '/var/log/tooryst/staging-frontend-error.log',
      out_file: '/var/log/tooryst/staging-frontend-out.log',
      log_file: '/var/log/tooryst/staging-frontend.log'
    },
    {
      name: 'tooryst-celery-staging',
      cwd: '/var/www/tooryst-staging/backend',
      script: 'venv/bin/celery',
      args: '-A app.celery_app worker -Q pipeline,celery -c 2 -n staging@%h --loglevel=INFO',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      error_file: '/var/log/tooryst/staging-celery-error.log',
      out_file: '/var/log/tooryst/staging-celery-out.log',
      log_file: '/var/log/tooryst/staging-celery.log'
    },
    
    // Production Apps
    {
      name: 'tooryst-backend-production',
      cwd: '/var/www/tooryst-production/backend',
      script: 'venv/bin/uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port $PRODUCTION_BACKEND_PORT --workers 2',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      env: { NODE_ENV: 'production' },
      error_file: '/var/log/tooryst/production-backend-error.log',
      out_file: '/var/log/tooryst/production-backend-out.log',
      log_file: '/var/log/tooryst/production-backend.log'
    },
    {
      name: 'tooryst-frontend-production',
      cwd: '/var/www/tooryst-production/client',
      script: 'npm',
      args: 'start',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: { NODE_ENV: 'production', PORT: $PRODUCTION_FRONTEND_PORT },
      error_file: '/var/log/tooryst/production-frontend-error.log',
      out_file: '/var/log/tooryst/production-frontend-out.log',
      log_file: '/var/log/tooryst/production-frontend.log'
    },
    {
      name: 'tooryst-celery-production',
      cwd: '/var/www/tooryst-production/backend',
      script: 'venv/bin/celery',
      args: '-A app.celery_app worker -Q pipeline,celery -c 4 -n production@%h --loglevel=INFO',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: '/var/log/tooryst/production-celery-error.log',
      out_file: '/var/log/tooryst/production-celery-out.log',
      log_file: '/var/log/tooryst/production-celery.log'
    }
  ]
};
EOF"
    
    log_success "PM2 ecosystem configured"
    echo ""

    # Step 5: Setup Nginx
    log_info "Step 5: Setting up Nginx..."
    
    run_on_vm "sudo tee /etc/nginx/sites-available/tooryst << 'EOF'
server {
    listen 80;
    server_name staging.tooryst.co;

    location / {
        proxy_pass http://localhost:$STAGING_FRONTEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /api/ {
        proxy_pass http://localhost:$STAGING_BACKEND_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 80;
    server_name tooryst.co www.tooryst.co;

    location / {
        proxy_pass http://localhost:$PRODUCTION_FRONTEND_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    location /api/ {
        proxy_pass http://localhost:$PRODUCTION_BACKEND_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF"
    
    # Enable site
    run_on_vm "sudo ln -sf /etc/nginx/sites-available/tooryst /etc/nginx/sites-enabled/"
    run_on_vm "sudo rm -f /etc/nginx/sites-enabled/default"
    run_on_vm "sudo nginx -t"
    run_on_vm "sudo systemctl reload nginx"
    
    log_success "Nginx configured"
    echo ""

    # Step 6: Start services
    log_info "Step 6: Starting services..."
    
    # Stop any existing PM2 processes
    run_on_vm "pm2 delete all || true"
    
    # Start services with PM2
    run_on_vm "cd /var/www && pm2 start ecosystem.config.js"
    run_on_vm "pm2 save"
    run_on_vm "pm2 startup | grep 'sudo' | bash || true"
    
    log_success "All services started"
    echo ""

    # Step 7: Verify deployment
    log_info "Step 7: Verifying deployment..."
    
    sleep 10
    
    # Check PM2 status
    run_on_vm "pm2 status"
    
    # Test endpoints
    log_info "Testing endpoints..."
    
    # Test staging
    if curl -s "http://$VM_IP:$STAGING_BACKEND_PORT/health" | grep -q "ok"; then
        log_success "Staging backend health check passed"
    else
        log_warning "Staging backend health check failed"
    fi
    
    if curl -s "http://$VM_IP:$STAGING_FRONTEND_PORT/" | grep -q "html"; then
        log_success "Staging frontend health check passed"
    else
        log_warning "Staging frontend health check failed"
    fi
    
    # Test production
    if curl -s "http://$VM_IP:$PRODUCTION_BACKEND_PORT/health" | grep -q "ok"; then
        log_success "Production backend health check passed"
    else
        log_warning "Production backend health check failed"
    fi
    
    if curl -s "http://$VM_IP:$PRODUCTION_FRONTEND_PORT/" | grep -q "html"; then
        log_success "Production frontend health check passed"
    else
        log_warning "Production frontend health check failed"
    fi
    echo ""

    # Step 8: Summary
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ Single VM Deployment Complete!                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📊 Deployment Summary:${NC}"
    echo "  • VM: $VM_NAME"
    echo "  • IP Address: $VM_IP"
    echo "  • Both staging and production running on same VM"
    echo ""
    echo -e "${YELLOW}🌐 Access Points:${NC}"
    echo "  • Staging: http://staging.tooryst.co (or http://$VM_IP:$STAGING_FRONTEND_PORT)"
    echo "  • Production: http://tooryst.co (or http://$VM_IP:$PRODUCTION_FRONTEND_PORT)"
    echo "  • Staging API: http://$VM_IP:$STAGING_BACKEND_PORT"
    echo "  • Production API: http://$VM_IP:$PRODUCTION_BACKEND_PORT"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo "  1. Configure DNS records:"
    echo "     staging.tooryst.co → $VM_IP"
    echo "     tooryst.co → $VM_IP"
    echo ""
    echo "  2. Setup SSL certificates:"
    echo "     gcloud compute ssh $VM_NAME --zone=$ZONE"
    echo "     sudo certbot --nginx -d staging.tooryst.co -d tooryst.co -d www.tooryst.co"
    echo ""
    echo "  3. Add your API keys to .env files on the VM"
    echo ""
    echo -e "${YELLOW}🔧 Management Commands:${NC}"
    echo "  • SSH: gcloud compute ssh $VM_NAME --zone=$ZONE"
    echo "  • View logs: pm2 logs"
    echo "  • Restart services: pm2 restart all"
    echo "  • Check status: pm2 status"
    echo ""
    echo -e "${YELLOW}💰 Monthly Cost: ~$120-150 (Single VM)${NC}"
    echo ""
}

# Run main function
main "$@"