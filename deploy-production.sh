#!/bin/bash

###############################################################################
# Storyboard Production Deployment Script
# Deploys code from GitHub to production environment with backup
# Usage: ./deploy-production.sh
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
DB_USER="storyboard_user"
DB_NAME="storyboard"

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

confirm() {
    local prompt="$1"
    local response
    
    read -p "$(echo -e ${YELLOW}$prompt${NC}) (yes/no): " response
    
    if [ "$response" != "yes" ]; then
        log_warning "Deployment cancelled"
        exit 0
    fi
}

# Main deployment
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🚀 Storyboard Production Deployment Script             ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Confirmation
    log_warning "⚠️  This will deploy to PRODUCTION environment"
    confirm "Are you sure you want to continue?"
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
    
    if ! command -v mysql &> /dev/null; then
        log_error "MySQL is not installed"
        exit 1
    fi
    
    log_success "Pre-deployment checks passed"
    echo ""

    # Step 2: Create database backup
    log_info "Step 2: Creating database backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    BACKUP_FILE="$BACKUP_DIR/db_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if mysqldump -u "$DB_USER" -p "$DB_NAME" > "$BACKUP_FILE" 2>/dev/null; then
        log_success "Database backed up to: $BACKUP_FILE"
    else
        log_error "Failed to backup database"
        exit 1
    fi
    echo ""

    # Step 3: Pull latest code
    log_info "Step 3: Pulling latest code from GitHub..."
    cd "$PROJECT_DIR"
    
    if git pull origin main; then
        log_success "Code pulled successfully"
    else
        log_error "Failed to pull code from GitHub"
        exit 1
    fi
    echo ""

    # Step 4: Update backend
    log_info "Step 4: Updating backend..."
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

    # Step 5: Update frontend
    log_info "Step 5: Updating frontend..."
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

    # Step 6: Restart services
    log_info "Step 6: Restarting services..."
    
    if pm2 restart all; then
        log_success "Services restarted successfully"
    else
        log_error "Failed to restart services"
        exit 1
    fi
    echo ""

    # Step 7: Verify deployment
    log_info "Step 7: Verifying deployment..."
    
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

    # Step 8: Summary
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ Production Deployment Complete!                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📊 Deployment Summary:${NC}"
    echo "  • Database: Backed up to $BACKUP_FILE"
    echo "  • Code: Updated from GitHub"
    echo "  • Backend: Dependencies installed"
    echo "  • Frontend: Built and ready"
    echo "  • Services: Restarted via PM2"
    echo ""
    echo -e "${YELLOW}🔗 Access Points:${NC}"
    echo "  • Frontend: https://tourists.co"
    echo "  • Backend (internal): http://localhost:8000"
    echo "  • Logs: pm2 logs"
    echo ""
    echo -e "${YELLOW}📝 Post-Deployment:${NC}"
    echo "  1. Visit https://tourists.co to verify"
    echo "  2. Check logs: pm2 logs"
    echo "  3. Monitor: pm2 monit"
    echo "  4. Backup location: $BACKUP_FILE"
    echo ""
    echo -e "${YELLOW}🔄 Rollback (if needed):${NC}"
    echo "  1. Stop services: pm2 stop all"
    echo "  2. Restore database: mysql -u $DB_USER -p $DB_NAME < $BACKUP_FILE"
    echo "  3. Revert code: git revert HEAD"
    echo "  4. Restart: pm2 start all"
    echo ""
}

# Run main function
main "$@"
