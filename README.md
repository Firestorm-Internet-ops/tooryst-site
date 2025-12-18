# Toorysts - Travel Intelligence Platform

Discover the best time to visit any attraction with live crowd signals, hyperlocal weather, and visitor sentiment—all in one storyboard.

## 🎯 Overview

Toorysts is a comprehensive travel intelligence platform that helps travelers discover attractions worldwide and plan the perfect trip. We aggregate information from multiple sources including Google Places, community reviews, real-time weather data, and AI-powered recommendations.

**Live at:** https://toorysts.com

## 🏗️ Architecture

```
toorysts/
├── backend/          # FastAPI + Celery pipeline
├── client/           # Next.js 16 frontend
├── latlong/          # Latitude/longitude data
└── README.md         # This file
```

## 🚀 Quick Start

### Prerequisites
- Node.js 20+
- Python 3.11+
- MySQL 8.0+
- Redis 7.0+

### Backend Setup
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# Edit .env with your API keys
./start_all.sh
```

**Backend runs on:** http://localhost:8000

### Frontend Setup
```bash
cd client
npm install
cp .env.example .env.local
# Edit .env.local with API configuration
npm run dev
```

**Frontend runs on:** http://localhost:3000

## 📚 Documentation

### Root Level
- **COMPLETE_DEPLOYMENT_GUIDE.md** - Full deployment instructions for Google Cloud VM
- **CODEBASE_ANALYSIS.md** - Architecture analysis and recommendations

### Backend
- **backend/README.md** - Backend system overview and API documentation
- **backend/QUICKSTART.md** - Quick start guide for backend setup

### Frontend
- **client/README.md** - Frontend setup and component documentation
- **client/FRONTEND_SETUP.md** - Detailed frontend configuration
- **client/TROUBLESHOOTING.md** - Common issues and solutions
- **client/PERFORMANCE_OPTIMIZATION.md** - Performance tuning guide

## 🎨 Features

### Core Features
- 🌍 **Global Attraction Database** - 5000+ attractions across 245+ destinations
- 📊 **Live Crowd Signals** - Real-time visitor demand and comfort scores
- 🌤️ **Weather Intelligence** - Hyperlocal weather forecasts and seasonality
- ⭐ **Community Reviews** - Authentic traveler insights and ratings
- 🗺️ **Interactive Maps** - Explore attractions and nearby points of interest
- 💡 **AI Recommendations** - Personalized travel suggestions

### Technical Features
- **Automatic Data Pipeline** - Watches Excel file for new attractions
- **Scheduled Refreshes** - Keeps data fresh with smart refresh logic
- **REST API** - Complete API for all features
- **Performance Optimized** - 40-50% faster load times
- **Mobile Responsive** - Works seamlessly on all devices

## 🔧 Technology Stack

### Backend
- **Framework:** FastAPI
- **Task Queue:** Celery + Redis
- **Database:** MySQL
- **APIs:** Google Places, YouTube, OpenWeatherMap, Gemini, Reddit, BestTime

### Frontend
- **Framework:** Next.js 16 (App Router)
- **React:** 19.2.0
- **Styling:** Tailwind CSS 4
- **State:** React Query + Zustand
- **Maps:** Leaflet + React Leaflet
- **Animations:** Framer Motion

## 📋 API Endpoints

### Public Endpoints
```
GET  /health                              # Health check
GET  /api/v1/homepage                     # Homepage data
GET  /api/v1/cities                       # All cities
GET  /api/v1/cities/{slug}                # City details
GET  /api/v1/attractions                  # All attractions
GET  /api/v1/attractions/{slug}           # Complete attraction data
```

### Admin Endpoints
```
POST /api/v1/pipeline/start               # Start pipeline (requires X-Admin-Key)
GET  /api/v1/pipeline/status/{task_id}    # Check task status
GET  /api/v1/pipeline/progress/{run_id}   # Pipeline progress tracking
```

## 🚀 Deployment

### Google Cloud Compute Engine
See **COMPLETE_DEPLOYMENT_GUIDE.md** for step-by-step instructions.

**Quick deployment:**
```bash
# 1. Local checks
npm run lint && npm run test && npm run build

# 2. Push to GitHub
git add . && git commit -m "deployment ready" && git push origin main

# 3. SSH to VM and deploy
ssh user@vm-ip
cd /var/www/your-repo
./deploy.sh production
```

## 🧪 Testing

### Backend
```bash
cd backend
source venv/bin/activate
pytest
```

### Frontend
```bash
cd client
npm run test
npm run lint
```

## 📊 Performance

| Metric | Target | Status |
|--------|--------|--------|
| Bundle Size | < 300kb | ✅ 280kb |
| LCP | < 2.5s | ✅ 1.8s |
| FID | < 100ms | ✅ 80ms |
| CLS | < 0.1 | ✅ 0.05 |

## 🔐 Security

- Environment variables for all secrets
- API key validation on protected endpoints
- HTTPS/SSL in production
- CORS configured for frontend domain
- Input validation on all endpoints

## 📞 Support

### Documentation
- Backend: See `backend/README.md`
- Frontend: See `client/README.md`
- Deployment: See `COMPLETE_DEPLOYMENT_GUIDE.md`

### Common Issues
- Frontend: See `client/TROUBLESHOOTING.md`
- Performance: See `client/PERFORMANCE_OPTIMIZATION.md`

## 📝 License

MIT

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Run tests and linting
4. Submit a pull request

## 📈 Roadmap

- [ ] User authentication and profiles
- [ ] Personalized recommendations
- [ ] Trip planning tools
- [ ] Mobile app (iOS/Android)
- [ ] Real-time notifications
- [ ] Social features

---

**Built with ❤️ for travelers worldwide**
