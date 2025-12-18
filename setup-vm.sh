#!/bin/bash

###############################################################################
# Storyboard VM Setup Script
# Installs all dependencies and configures the VM for deployment
# Run this on a fresh Ubuntu 22.04 VM
# Usage: ./setup-vm.sh
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

# Main setup
main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🖥️  Storyboard VM Setup Script                        ║${NC}"
    echo -e "${BLUE}║     Ubuntu 22.04 LTS                                      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Step 1: Update system
    log_info "Step 1: Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    log_success "System updated"
    echo ""

    # Step 2: Install essential tools
    log_info "Step 2: Installing essential tools..."
    sudo apt install -y \
        curl \
        wget \
        git \
        build-essential \
        libssl-dev \
        libffi-dev \
        python3-dev \
        software-properties-common
    log_success "Essential tools installed"
    echo ""

    # Step 3: Install Node.js
    log_info "Step 3: Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
    log_success "Node.js $(node --version) installed"
    echo ""

    # Step 4: Install Python
    log_info "Step 4: Installing Python 3.11..."
    sudo apt install -y python3.11 python3.11-venv python3.11-dev python3-pip
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
    log_success "Python $(python3 --version) installed"
    echo ""

    # Step 5: Install MySQL
    log_info "Step 5: Installing MySQL Server..."
    sudo apt install -y mysql-server
    sudo systemctl enable mysql
    sudo systemctl start mysql
    log_success "MySQL installed and started"
    echo ""

    # Step 6: Install Redis
    log_info "Step 6: Installing Redis..."
    sudo apt install -y redis-server
    sudo systemctl enable redis-server
    sudo systemctl start redis-server
    
    # Test Redis
    if redis-cli ping | grep -q "PONG"; then
        log_success "Redis installed and responding"
    else
        log_warning "Redis may not be responding correctly"
    fi
    echo ""

    # Step 7: Install Nginx
    log_info "Step 7: Installing Nginx..."
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    log_success "Nginx installed and started"
    echo ""

    # Step 8: Install PM2
    log_info "Step 8: Installing PM2..."
    sudo npm install -g pm2
    pm2 startup
    log_success "PM2 $(pm2 --version) installed"
    echo ""

    # Step 9: Install Certbot
    log_info "Step 9: Installing Certbot for SSL..."
    sudo apt install -y certbot python3-certbot-nginx
    log_success "Certbot installed"
    echo ""

    # Step 10: Create directories
    log_info "Step 10: Creating necessary directories..."
    sudo mkdir -p "$PROJECT_DIR"
    sudo mkdir -p "$BACKUP_DIR"
    sudo mkdir -p "$PROJECT_DIR/logs"
    sudo chown -R $USER:$USER "$PROJECT_DIR"
    sudo chown -R $USER:$USER "$BACKUP_DIR"
    log_success "Directories created"
    echo ""

    # Step 11: Verify installations
    log_info "Step 11: Verifying installations..."
    echo ""
    echo -e "${YELLOW}📦 Installed Versions:${NC}"
    echo "  • Node.js: $(node --version)"
    echo "  • npm: $(npm --version)"
    echo "  • Python: $(python3 --version)"
    echo "  • MySQL: $(mysql --version | cut -d' ' -f6)"
    echo "  • Redis: $(redis-cli --version)"
    echo "  • Nginx: $(nginx -v 2>&1 | cut -d' ' -f3)"
    echo "  • PM2: $(pm2 --version)"
    echo "  • Certbot: $(certbot --version | cut -d' ' -f1-2)"
    echo ""

    # Step 12: Summary
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ VM Setup Complete!                                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo ""
    echo "1. Clone the repository:"
    echo "   cd $PROJECT_DIR"
    echo "   git clone https://github.com/your-username/storyboard.git"
    echo ""
    echo "2. Configure environment files:"
    echo "   cd $PROJECT_DIR/storyboard/backend"
    echo "   cp .env.example .env"
    echo "   nano .env  # Edit with your values"
    echo ""
    echo "   cd ../client"
    echo "   cp .env.example .env.local"
    echo "   nano .env.local  # Edit with your values"
    echo ""
    echo "3. Setup database:"
    echo "   sudo mysql -u root"
    echo "   CREATE DATABASE storyboard;"
    echo "   CREATE USER 'storyboard_user'@'localhost' IDENTIFIED BY 'password';"
    echo "   GRANT ALL PRIVILEGES ON storyboard.* TO 'storyboard_user'@'localhost';"
    echo "   FLUSH PRIVILEGES;"
    echo "   EXIT;"
    echo ""
    echo "4. Setup backend:"
    echo "   cd $PROJECT_DIR/storyboard/backend"
    echo "   python3 -m venv venv"
    echo "   source venv/bin/activate"
    echo "   pip install -r requirements.txt"
    echo ""
    echo "5. Setup frontend:"
    echo "   cd ../client"
    echo "   npm install"
    echo "   npm run build"
    echo ""
    echo "6. Configure Nginx:"
    echo "   sudo nano /etc/nginx/sites-available/staging.tourists.co"
    echo "   # Add your Nginx configuration"
    echo "   sudo ln -s /etc/nginx/sites-available/staging.tourists.co /etc/nginx/sites-enabled/"
    echo "   sudo nginx -t"
    echo "   sudo systemctl reload nginx"
    echo ""
    echo "7. Setup SSL:"
    echo "   sudo certbot certonly --nginx -d staging.tourists.co"
    echo ""
    echo "8. Start services:"
    echo "   cd $PROJECT_DIR/storyboard"
    echo "   pm2 start ecosystem.config.js"
    echo "   pm2 save"
    echo ""
    echo -e "${YELLOW}📊 System Information:${NC}"
    echo "  • Project Directory: $PROJECT_DIR"
    echo "  • Backup Directory: $BACKUP_DIR"
    echo "  • Logs Directory: $PROJECT_DIR/logs"
    echo ""
    echo -e "${YELLOW}🔗 Useful Commands:${NC}"
    echo "  • Check services: pm2 status"
    echo "  • View logs: pm2 logs"
    echo "  • Monitor: pm2 monit"
    echo "  • Restart all: pm2 restart all"
    echo "  • Stop all: pm2 stop all"
    echo ""
}

# Run main function
main "$@"
