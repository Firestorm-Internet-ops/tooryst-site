#!/bin/bash

###############################################################################
# Storyboard Staging Deployment Script
# Deploys code from GitHub to staging environment
# Usage: ./deploy-staging.sh
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/var/www/storyboard"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/client"
LOG_DIR="$PROJECT_DIR/logs"
BACKUP_DIR="/backups"

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

# Main deployment
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🚀 Storyboard Staging Deployment Script               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Step 1: Pre-deployment checks
    log_info "Step 1: Running pre-deployment checks..."
    
    if [ ! -d "$PROJECT_DIR" ]; then
        log_error "Project directory not found: $PROJECT_DIR"
        exit 1
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed"
        exit 1
    fi
    
    if ! command -v pm2 &> /dev/null; then
        log_error "PM2 is not installed"
        exit 1
    fi
    
    log_success "Pre-deployment checks passed"
    echo ""

    # Step 2: Pull latest code
    log_info "Step 2: Pulling latest code from GitHub..."
    cd "$PROJECT_DIR"
    
    if git pull origin main; then
        log_success "Code pulled successfully"
    else
        log_error "Failed to pull code from GitHub"
        exit 1
    fi
    echo ""

    # Step 3: Update backend
    log_info "Step 3: Updating backend..."
    cd "$BACKEND_DIR"
    
    # Activate virtual environment
    if [ ! -d "venv" ]; then
        log_warning "Virtual environment not found, creating..."
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    # Install dependencies
    log_info "Installing Python dependencies..."
    if pip install -r requirements.txt > /dev/null 2>&1; then
        log_success "Backend dependencies installed"
    else
        log_error "Failed to install backend dependencies"
        exit 1
    fi
    
    deactivate
    echo ""

    # Step 4: Update frontend
    log_info "Step 4: Updating frontend..."
    cd "$FRONTEND_DIR"
    
    # Install dependencies
    log_info "Installing npm dependencies..."
    if npm install > /dev/null 2>&1; then
        log_success "Frontend dependencies installed"
    else
        log_error "Failed to install frontend dependencies"
        exit 1
    fi
    
    # Build frontend
    log_info "Building frontend..."
    if npm run build > /dev/null 2>&1; then
        log_success "Frontend built successfully"
    else
        log_error "Failed to build frontend"
        exit 1
    fi
    echo ""

    # Step 5: Restart services
    log_info "Step 5: Restarting services..."
    
    if pm2 restart all; then
        log_success "Services restarted successfully"
    else
        log_error "Failed to restart services"
        exit 1
    fi
    echo ""

    # Step 6: Verify deployment
    log_info "Step 6: Verifying deployment..."
    
    sleep 3
    
    # Check PM2 status
    log_info "Checking service status..."
    pm2 status
    echo ""
    
    # Test backend health
    log_info "Testing backend health..."
    if curl -s http://localhost:8000/health | grep -q "ok"; then
        log_success "Backend is responding"
    else
        log_warning "Backend health check failed"
    fi
    
    # Test frontend
    log_info "Testing frontend..."
    if curl -s http://localhost:3000/ | grep -q "html"; then
        log_success "Frontend is responding"
    else
        log_warning "Frontend health check failed"
    fi
    echo ""

    # Step 7: Summary
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ Staging Deployment Complete!                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📊 Deployment Summary:${NC}"
    echo "  • Code: Updated from GitHub"
    echo "  • Backend: Dependencies installed"
    echo "  • Frontend: Built and ready"
    echo "  • Services: Restarted via PM2"
    echo ""
    echo -e "${YELLOW}🔗 Access Points:${NC}"
    echo "  • Frontend: https://staging.tourists.co"
    echo "  • Backend (internal): http://localhost:8000"
    echo "  • Logs: pm2 logs"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo "  1. Visit https://staging.tourists.co to verify"
    echo "  2. Check logs: pm2 logs"
    echo "  3. Monitor: pm2 monit"
    echo ""
}

# Run main function
main "$@"
