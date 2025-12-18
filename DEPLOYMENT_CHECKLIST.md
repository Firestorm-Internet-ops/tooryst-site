# ✅ Deployment Checklist

Complete checklist for deploying Storyboard to staging and production environments.

---

## 📋 PRE-DEPLOYMENT (Local Machine)

### Code Quality
- [ ] Run `npm run lint` in client - no errors
- [ ] Run `npm run build` in client - succeeds
- [ ] Run Python syntax check in backend - no errors
- [ ] All tests pass (if applicable)
- [ ] No console warnings or errors

### Git & GitHub
- [ ] Update `.gitignore` with sensitive files
- [ ] All changes committed: `git status` shows clean
- [ ] Code pushed to GitHub: `git push origin main`
- [ ] Verify on GitHub: code is visible and complete
- [ ] No `.env` files in repository
- [ ] No `node_modules` in repository
- [ ] No `__pycache__` in repository

### Environment Files
- [ ] Backend `.env.example` exists
- [ ] Frontend `.env.example` exists
- [ ] All required variables documented
- [ ] No sensitive data in example files

---

## 🖥️ VM SETUP

### Google Cloud Setup
- [ ] VM instance created (e2-medium, Ubuntu 22.04)
- [ ] Static IP reserved
- [ ] Firewall rules configured (HTTP, HTTPS, SSH)
- [ ] SSH access verified
- [ ] VM has sufficient disk space (50GB+)

### System Dependencies
- [ ] Node.js 20 installed: `node --version`
- [ ] npm installed: `npm --version`
- [ ] Python 3.11 installed: `python3 --version`
- [ ] MySQL installed: `mysql --version`
- [ ] Redis installed: `redis-cli --version`
- [ ] Nginx installed: `nginx -v`
- [ ] PM2 installed: `pm2 --version`
- [ ] Certbot installed: `certbot --version`

### Directory Structure
- [ ] `/var/www/storyboard` created
- [ ] `/backups` directory created
- [ ] `/var/www/storyboard/logs` created
- [ ] Proper permissions set

### Repository
- [ ] Code cloned from GitHub
- [ ] All files present: `ls -la`
- [ ] Git history available: `git log`
- [ ] Can pull updates: `git pull origin main`

---

## ⚙️ CONFIGURATION

### Backend Environment
- [ ] `.env` file created from `.env.example`
- [ ] `DATABASE_HOST` set to `localhost`
- [ ] `DATABASE_USER` set to `storyboard_user`
- [ ] `DATABASE_PASSWORD` set to strong password
- [ ] `DATABASE_NAME` set to `storyboard`
- [ ] `CELERY_BROKER_URL` set to `redis://localhost:6379/0`
- [ ] `CELERY_RESULT_BACKEND` set to `redis://localhost:6379/1`
- [ ] `DEBUG` set to `False`
- [ ] `ENVIRONMENT` set to `staging` or `production`
- [ ] All API keys configured
- [ ] `SECRET_KEY` generated and set

### Frontend Environment
- [ ] `.env.local` file created from `.env.example`
- [ ] `NEXT_PUBLIC_API_BASE_URL` set correctly
- [ ] `NEXT_PUBLIC_ENVIRONMENT` set to `staging` or `production`

### Database
- [ ] MySQL service running: `sudo systemctl status mysql`
- [ ] Database created: `storyboard`
- [ ] User created: `storyboard_user`
- [ ] Permissions granted: `GRANT ALL PRIVILEGES`
- [ ] Connection verified: `mysql -u storyboard_user -p storyboard -e "SELECT 1;"`

### Redis
- [ ] Redis service running: `sudo systemctl status redis-server`
- [ ] Redis responding: `redis-cli ping` returns `PONG`

---

## 🔧 BACKEND SETUP

### Virtual Environment
- [ ] Virtual environment created: `python3 -m venv venv`
- [ ] Virtual environment activated: `source venv/bin/activate`
- [ ] pip upgraded: `pip install --upgrade pip`

### Dependencies
- [ ] Requirements installed: `pip install -r requirements.txt`
- [ ] All packages listed: `pip list`
- [ ] No errors during installation

### Database
- [ ] Database tables created
- [ ] Migrations applied (if applicable)
- [ ] Initial data loaded (if applicable)
- [ ] Database connection verified

### Testing
- [ ] Backend starts: `python -m uvicorn app.main:app --host 0.0.0.0 --port 8000`
- [ ] Health endpoint responds: `curl http://localhost:8000/health`
- [ ] API endpoints respond: `curl http://localhost:8000/api/v1/cities`
- [ ] No errors in console

---

## 🎨 FRONTEND SETUP

### Dependencies
- [ ] npm dependencies installed: `npm install`
- [ ] All packages listed: `npm list`
- [ ] No errors during installation

### Build
- [ ] Frontend builds successfully: `npm run build`
- [ ] `.next` directory created
- [ ] No build errors or warnings
- [ ] Build size reasonable

### Testing
- [ ] Frontend starts: `npm start`
- [ ] Homepage loads: `curl http://localhost:3000/`
- [ ] No console errors
- [ ] All pages accessible

---

## 🌐 NGINX CONFIGURATION

### Configuration Files
- [ ] Nginx config created: `/etc/nginx/sites-available/staging.tourists.co`
- [ ] Upstream servers configured
- [ ] Frontend proxy configured
- [ ] Backend API blocked (403)
- [ ] Backend docs blocked (403)
- [ ] Static files configured
- [ ] Media files configured

### Nginx Setup
- [ ] Configuration syntax valid: `sudo nginx -t`
- [ ] Site enabled: symlink created
- [ ] Default site disabled
- [ ] Nginx reloaded: `sudo systemctl reload nginx`
- [ ] Nginx running: `sudo systemctl status nginx`

### SSL Certificate
- [ ] Certificate obtained: `sudo certbot certonly --nginx`
- [ ] Certificate paths added to Nginx config
- [ ] HTTP to HTTPS redirect configured
- [ ] SSL configuration valid: `sudo nginx -t`
- [ ] Nginx reloaded with SSL
- [ ] Certificate valid: `echo | openssl s_client -servername staging.tourists.co -connect staging.tourists.co:443 2>/dev/null | openssl x509 -noout -dates`

---

## 🚀 PM2 SETUP

### Ecosystem File
- [ ] `ecosystem.config.js` created
- [ ] Backend service configured
- [ ] Frontend service configured
- [ ] Celery worker configured
- [ ] Celery beat configured
- [ ] Log files configured
- [ ] Auto-restart enabled
- [ ] Memory limits set

### Services
- [ ] Services started: `pm2 start ecosystem.config.js`
- [ ] All services online: `pm2 status`
- [ ] Configuration saved: `pm2 save`
- [ ] Startup enabled: `pm2 startup`

### Verification
- [ ] Backend running on port 8000
- [ ] Frontend running on port 3000
- [ ] Celery worker running
- [ ] Celery beat running
- [ ] No errors in logs: `pm2 logs`

---

## 🧪 STAGING VERIFICATION

### Services
- [ ] All services online: `pm2 status`
- [ ] No errors in logs: `pm2 logs`
- [ ] Memory usage reasonable: `pm2 monit`
- [ ] CPU usage reasonable: `pm2 monit`

### Backend (Internal)
- [ ] Health endpoint: `curl http://localhost:8000/health`
- [ ] API endpoints: `curl http://localhost:8000/api/v1/cities`
- [ ] Database connected
- [ ] Redis connected

### Frontend (Internal)
- [ ] Homepage loads: `curl http://localhost:3000/`
- [ ] All pages accessible
- [ ] No console errors

### Domain (External)
- [ ] Frontend accessible: `curl https://staging.tourists.co/`
- [ ] Homepage loads in browser
- [ ] All pages accessible
- [ ] No console errors
- [ ] SSL certificate valid

### Security
- [ ] Backend API blocked: `curl https://staging.tourists.co/api/` returns 403
- [ ] Backend docs blocked: `curl https://staging.tourists.co/docs` returns 403
- [ ] Redoc blocked: `curl https://staging.tourists.co/redoc` returns 403
- [ ] OpenAPI blocked: `curl https://staging.tourists.co/openapi.json` returns 403

### Performance
- [ ] Page load time < 2 seconds
- [ ] API response time < 500ms
- [ ] No memory leaks
- [ ] No CPU spikes

---

## 📊 STAGING TESTING

### Functionality
- [ ] Homepage loads correctly
- [ ] Navigation works
- [ ] Search functionality works
- [ ] City pages load
- [ ] Attraction pages load
- [ ] About page loads
- [ ] Contact page loads
- [ ] FAQ page loads
- [ ] Privacy policy loads
- [ ] Terms of service load

### Data
- [ ] Cities displayed
- [ ] Attractions displayed
- [ ] Reviews displayed
- [ ] Images load
- [ ] No missing data

### Browser Compatibility
- [ ] Chrome/Chromium works
- [ ] Firefox works
- [ ] Safari works
- [ ] Mobile responsive

### Accessibility
- [ ] Keyboard navigation works
- [ ] Screen reader compatible
- [ ] Color contrast sufficient
- [ ] No accessibility errors

---

## 🎯 PRODUCTION SETUP

### Domain Configuration
- [ ] DNS A record points to static IP
- [ ] www subdomain configured
- [ ] DNS propagated (wait 24 hours if needed)
- [ ] Domain resolves: `nslookup tourists.co`

### Production Nginx
- [ ] Nginx config created: `/etc/nginx/sites-available/tourists.co`
- [ ] Configuration valid: `sudo nginx -t`
- [ ] Site enabled
- [ ] Nginx reloaded

### Production SSL
- [ ] Certificate obtained for production domain
- [ ] Certificate paths updated in Nginx
- [ ] Nginx reloaded
- [ ] Certificate valid

### Production Environment
- [ ] `.env` updated for production
- [ ] `DEBUG` set to `False`
- [ ] `ENVIRONMENT` set to `production`
- [ ] All API keys configured
- [ ] Database backed up

---

## 🚀 PRODUCTION DEPLOYMENT

### Pre-Deployment
- [ ] Database backup created
- [ ] Backup location noted
- [ ] Code reviewed
- [ ] All tests pass
- [ ] Staging verified

### Deployment
- [ ] Run `deploy-production.sh`
- [ ] Confirm deployment prompt
- [ ] Deployment completes successfully
- [ ] No errors in output

### Post-Deployment
- [ ] All services online: `pm2 status`
- [ ] No errors in logs: `pm2 logs`
- [ ] Domain accessible: `curl https://tourists.co/`
- [ ] Backend blocked: `curl https://tourists.co/api/` returns 403
- [ ] SSL valid: `echo | openssl s_client -servername tourists.co -connect tourists.co:443 2>/dev/null | openssl x509 -noout -dates`

---

## 🔍 PRODUCTION VERIFICATION

### Services
- [ ] All services online
- [ ] No errors in logs
- [ ] Memory usage stable
- [ ] CPU usage normal
- [ ] Disk space available

### Functionality
- [ ] Homepage loads
- [ ] All pages accessible
- [ ] Search works
- [ ] Data displays correctly
- [ ] Images load
- [ ] No console errors

### Performance
- [ ] Page load time < 2 seconds
- [ ] API response time < 500ms
- [ ] No memory leaks
- [ ] No CPU spikes

### Security
- [ ] HTTPS enforced
- [ ] SSL certificate valid
- [ ] Backend API blocked
- [ ] Backend docs blocked
- [ ] No sensitive data exposed

### Monitoring
- [ ] Logs being written
- [ ] Errors being logged
- [ ] Performance metrics available
- [ ] Alerts configured

---

## 📊 ONGOING MAINTENANCE

### Daily
- [ ] Check `pm2 status`
- [ ] Review error logs
- [ ] Monitor resource usage
- [ ] Verify domain accessibility

### Weekly
- [ ] Check disk space: `df -h`
- [ ] Verify backups created
- [ ] Review performance metrics
- [ ] Check SSL certificate expiry

### Monthly
- [ ] Update dependencies
- [ ] Security patches applied
- [ ] Performance optimization
- [ ] Database maintenance

### Quarterly
- [ ] Full security audit
- [ ] Performance review
- [ ] Infrastructure assessment
- [ ] Disaster recovery test

---

## 🆘 EMERGENCY PROCEDURES

### If Services Crash
- [ ] Check logs: `pm2 logs`
- [ ] Check resources: `free -h && df -h`
- [ ] Restart services: `pm2 restart all`
- [ ] Verify recovery: `pm2 status`

### If Database Fails
- [ ] Check MySQL: `sudo systemctl status mysql`
- [ ] Restart MySQL: `sudo systemctl restart mysql`
- [ ] Restore from backup if needed
- [ ] Verify data integrity

### If Nginx Fails
- [ ] Test config: `sudo nginx -t`
- [ ] Check logs: `sudo tail -f /var/log/nginx/error.log`
- [ ] Restart Nginx: `sudo systemctl restart nginx`
- [ ] Verify services responding

### If SSL Certificate Expires
- [ ] Renew certificate: `sudo certbot renew`
- [ ] Verify renewal: `sudo certbot certificates`
- [ ] Reload Nginx: `sudo systemctl reload nginx`

### If Need to Rollback
- [ ] Stop services: `pm2 stop all`
- [ ] Restore database: `mysql -u user -p db < backup.sql`
- [ ] Revert code: `git revert HEAD`
- [ ] Restart services: `pm2 start all`

---

## ✅ FINAL SIGN-OFF

- [ ] All checklist items completed
- [ ] Staging environment verified
- [ ] Production environment verified
- [ ] Monitoring configured
- [ ] Backups verified
- [ ] Team notified
- [ ] Documentation updated
- [ ] Ready for production traffic

---

## 📝 Notes

```
Date Deployed: _______________
Deployed By: _______________
Version: _______________
Issues Encountered: _______________
Resolution: _______________
Approval: _______________
```

---

**Checklist Version:** 1.0  
**Last Updated:** December 16, 2024  
**Status:** Ready for Use
