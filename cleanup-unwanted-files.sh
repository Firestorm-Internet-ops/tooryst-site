#!/bin/bash

###############################################################################
# Cleanup Unwanted Deployment Files
# Removes all the complex Docker/GCP files we don't need
# Usage: ./cleanup-unwanted-files.sh
###############################################################################

echo "🗑️  Cleaning up unwanted deployment files..."

# Docker/GCP Cloud Run Files (Not Needed)
echo "Removing Docker/GCP files..."
rm -f cloudbuild.yaml
rm -f deploy-production-gcp.sh
rm -f deploy-staging-gcp.sh
rm -f setup-gcp-infrastructure.sh
rm -f trigger-pipeline.sh

# Separate VM Files (Not Needed)
echo "Removing separate VM files..."
rm -f deploy-vm-production.sh
rm -f deploy-vm-staging.sh
rm -f setup-vm-infrastructure.sh

# Complex Documentation (Not Needed)
echo "Removing complex documentation..."
rm -f DEPLOYMENT_PIPELINE.md
rm -f DEPLOYMENT_QUICK_REFERENCE.md
rm -f VM_DEPLOYMENT_GUIDE.md

# Docker Files (Not Needed)
echo "Removing Docker files..."
rm -f backend/Dockerfile
rm -f client/Dockerfile

echo "✅ Cleanup complete!"
echo ""
echo "📁 Remaining deployment files:"
echo "  • setup-single-vm.sh - Creates one VM for both environments"
echo "  • deploy-single-vm.sh - Deploys both staging and production"
echo "  • deploy-staging.sh - Your existing staging script (keep as backup)"
echo "  • deploy-production.sh - Your existing production script (keep as backup)"
echo "  • ecosystem.config.js - PM2 configuration"
echo ""
echo "🚀 Next steps:"
echo "  1. ./setup-single-vm.sh"
echo "  2. ./deploy-single-vm.sh"