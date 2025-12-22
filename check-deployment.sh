#!/bin/bash

###############################################################################
# Tooryst Deployment Status Check Script
# Checks if all services are running correctly
# Usage: ./check-deployment.sh
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

check_service() {
    local service_name="$1"
    local url="$2"
    local expected_content="$3"
    
    log_info "Checking $service_name..."
    
    if curl -s --max-time 10 "$url" | grep -q "$expected_content"; then
        log_success "$service_name is responding correctly"
        return 0
    else
        log_error "$service_name is not responding or returning unexpected content"
        return 1
    fi
}

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🔍 Tooryst Deployment Status Check                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local all_good=true
    
    # Check Redis
    log_info "Checking Redis..."
    if redis-cli ping 2>/dev/null | grep -q "PONG"; then
        log_success "Redis is responding"
    else
        log_error "Redis is not responding"
        all_good=false
    fi
    
    # Check MySQL
    log_info "Checking MySQL..."
    if mysqladmin ping 2>/dev/null | grep -q "alive"; then
        log_success "MySQL is responding"
    else
        log_error "MySQL is not responding"
        all_good=false
    fi
    
    # Check Backend API
    if ! check_service "Backend API" "http://localhost:8000/health" "ok"; then
        all_good=false
    fi
    
    # Check Frontend
    if ! check_service "Frontend" "http://localhost:3000/" "html"; then
        all_good=false
    fi
    
    # Check Backend processes
    log_info "Checking backend processes..."
    if pgrep -f "uvicorn.*app.main:app" > /dev/null; then
        log_success "Backend API process is running"
    else
        log_error "Backend API process is not running"
        all_good=false
    fi
    
    # Check Celery workers
    log_info "Checking Celery workers..."
    if pgrep -f "celery.*worker" > /dev/null; then
        log_success "Celery workers are running"
    else
        log_error "Celery workers are not running"
        all_good=false
    fi
    
    # Check Celery beat
    log_info "Checking Celery beat..."
    if pgrep -f "celery.*beat" > /dev/null; then
        log_success "Celery beat is running"
    else
        log_error "Celery beat is not running"
        all_good=false
    fi
    
    # Check Frontend process
    log_info "Checking frontend process..."
    if pgrep -f "next.*start" > /dev/null || pgrep -f "node.*server.js" > /dev/null; then
        log_success "Frontend process is running"
    else
        log_error "Frontend process is not running"
        all_good=false
    fi
    
    echo ""
    
    if [ "$all_good" = true ]; then
        echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║     ✅ All Services Running Correctly!                    ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}🔗 Access Points:${NC}"
        echo "  • Frontend: http://localhost:3000"
        echo "  • Backend API: http://localhost:8000"
        echo "  • API Docs: http://localhost:8000/docs"
        echo ""
    else
        echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║     ❌ Some Services Have Issues!                         ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}🔧 Troubleshooting:${NC}"
        echo "  • Check logs: tail -f backend/logs/*.log"
        echo "  • Restart backend: cd backend && ./stop_all.sh && ./start_all.sh"
        echo "  • Restart frontend: cd client && npm run start"
        echo "  • Check environment files: backend/.env and client/.env.local"
        echo ""
        exit 1
    fi
}

# Run main function
main "$@"