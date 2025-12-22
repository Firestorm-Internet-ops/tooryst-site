#!/bin/bash

###############################################################################
# Tooryst Single VM Setup Script
# Creates one VM that hosts both staging and production environments
# Usage: ./setup-single-vm.sh
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
REGION=${REGION:-us-central1}
ZONE=${ZONE:-us-central1-a}
VM_NAME="tooryst-server"

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

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     🏗️  Tooryst Single VM Setup                          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log_info "Project: $PROJECT_ID"
    log_info "Region: $REGION"
    log_info "Zone: $ZONE"
    echo ""

    # Enable required APIs
    log_info "Enabling required APIs..."
    gcloud services enable compute.googleapis.com
    log_success "APIs enabled"
    echo ""

    # Setup firewall rules
    log_info "Setting up firewall rules..."
    
    # Allow HTTP/HTTPS
    gcloud compute firewall-rules create allow-tooryst-web \
        --allow tcp:80,tcp:443,tcp:3000,tcp:3001,tcp:8000,tcp:8001 \
        --source-ranges 0.0.0.0/0 \
        --target-tags http-server \
        --description "Allow Tooryst web traffic" || log_warning "Firewall rule may already exist"
    
    log_success "Firewall rules configured"
    echo ""

    # Create VM
    log_info "Creating VM: $VM_NAME"
    
    if gcloud compute instances describe $VM_NAME --zone=$ZONE --quiet 2>/dev/null; then
        log_success "VM $VM_NAME already exists"
        VM_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
        log_info "VM IP: $VM_IP"
        return 0
    fi
    
    gcloud compute instances create $VM_NAME \
        --zone=$ZONE \
        --machine-type=e2-standard-4 \
        --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
        --maintenance-policy=MIGRATE \
        --provisioning-model=STANDARD \
        --service-account=$(gcloud iam service-accounts list --filter="displayName:Compute Engine default service account" --format="value(email)") \
        --scopes=https://www.googleapis.com/auth/cloud-platform \
        --tags=http-server,https-server \
        --create-disk=auto-delete=yes,boot=yes,device-name=$VM_NAME,image=projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts,mode=rw,size=50,type=projects/$PROJECT_ID/zones/$ZONE/diskTypes/pd-standard \
        --labels=environment=multi,project=tooryst \
        --metadata=startup-script='#!/bin/bash
# Update system
apt-get update
apt-get upgrade -y

# Install essential packages
apt-get install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release

# Install Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# Install pnpm
npm install -g pnpm

# Install Python 3.11
add-apt-repository ppa:deadsnakes/ppa -y
apt-get update
apt-get install -y python3.11 python3.11-venv python3.11-dev python3-pip

# Install MySQL
apt-get install -y mysql-server mysql-client

# Install Redis
apt-get install -y redis-server

# Install Nginx
apt-get install -y nginx

# Install PM2
npm install -g pm2

# Install certbot for SSL
apt-get install -y certbot python3-certbot-nginx

# Create application directories
mkdir -p /var/www/tooryst-staging
mkdir -p /var/www/tooryst-production
chown -R www-data:www-data /var/www/tooryst-*

# Create logs directory
mkdir -p /var/log/tooryst
chown -R www-data:www-data /var/log/tooryst

# Configure MySQL
systemctl start mysql
systemctl enable mysql

# Configure Redis
systemctl start redis-server
systemctl enable redis-server

# Configure Nginx
systemctl start nginx
systemctl enable nginx

# Create tooryst user
useradd -m -s /bin/bash tooryst
usermod -aG sudo tooryst
usermod -aG www-data tooryst

echo "VM setup completed" > /var/log/startup-script.log
'
    
    log_success "VM $VM_NAME created successfully"
    
    # Wait for VM to be ready
    log_info "Waiting for VM to be ready..."
    sleep 60
    
    # Get external IP
    VM_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
    log_success "VM $VM_NAME is ready at IP: $VM_IP"
    echo ""

    # Summary
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ✅ Single VM Setup Complete!                          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}📊 VM Configuration:${NC}"
    echo "  • VM Name: $VM_NAME"
    echo "  • Machine Type: e2-standard-4 (4 vCPUs, 16GB RAM)"
    echo "  • Disk: 50GB SSD"
    echo "  • IP Address: $VM_IP"
    echo "  • SSH: gcloud compute ssh $VM_NAME --zone=$ZONE"
    echo ""
    echo -e "${YELLOW}🌐 Port Configuration:${NC}"
    echo "  • Staging Frontend: http://$VM_IP:3000"
    echo "  • Staging Backend: http://$VM_IP:8000"
    echo "  • Production Frontend: http://$VM_IP:3001"
    echo "  • Production Backend: http://$VM_IP:8001"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo "  1. Configure DNS records:"
    echo "     staging.tooryst.co → $VM_IP (port 3000)"
    echo "     tooryst.co → $VM_IP (port 3001)"
    echo ""
    echo "  2. Wait 5 minutes for VM setup to complete"
    echo ""
    echo "  3. Deploy applications:"
    echo "     ./deploy-single-vm.sh"
    echo ""
    echo -e "${YELLOW}💰 Estimated Monthly Cost: ~$120-150${NC}"
    echo ""
}

# Run main function
main "$@"