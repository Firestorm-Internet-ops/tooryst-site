# Tooryst Simple Deployment Guide

## 🎯 Single VM Solution

Deploy both staging and production on **one VM** with different ports. Much simpler and cheaper!

### **VM Specs:**
- **Machine**: e2-standard-4 (4 vCPUs, 16GB RAM)
- **Disk**: 50GB SSD
- **Cost**: ~$120-150/month
- **Environments**: Both staging and production

### **Port Configuration:**
- **Staging Frontend**: Port 3000 → staging.tooryst.co
- **Staging Backend**: Port 8000
- **Production Frontend**: Port 3001 → tooryst.co  
- **Production Backend**: Port 8001

## 🚀 Quick Setup (2 Steps)

### Step 1: Create VM
```bash
chmod +x setup-single-vm.sh
./setup-single-vm.sh
```

### Step 2: Deploy Both Environments
```bash
chmod +x deploy-single-vm.sh
./deploy-single-vm.sh
```

## 📝 Before You Start

1. **Update Repository URL** in `deploy-single-vm.sh`:
   ```bash
   REPO_URL="https://github.com/YOUR_USERNAME/tooryst.git"
   ```

2. **Configure DNS** (after VM creation):
   - staging.tooryst.co → VM_IP
   - tooryst.co → VM_IP

## 🔧 Management

### SSH to VM
```bash
gcloud compute ssh tooryst-server --zone=us-central1-a
```

### View Services
```bash
pm2 status
pm2 logs
```

### Restart Services
```bash
pm2 restart all
```

### Update Code
```bash
# SSH to VM first
cd /var/www/tooryst-staging && git pull
cd /var/www/tooryst-production && git pull
pm2 restart all
```

### Setup SSL
```bash
# SSH to VM first
sudo certbot --nginx -d staging.tooryst.co -d tooryst.co -d www.tooryst.co
```

## 🗑️ Cleanup Old Files

If you want to remove all the complex Docker/GCP files:

```bash
chmod +x cleanup-unwanted-files.sh
./cleanup-unwanted-files.sh
```

## 🎯 Why This Approach?

- ✅ **Simple**: No Docker complexity
- ✅ **Cheap**: One VM instead of multiple services
- ✅ **Easy**: Direct access to everything
- ✅ **Fast**: Quick deployments and updates
- ✅ **Flexible**: Easy to modify and debug

Perfect for your full-stack application!