module.exports = {
  apps: [
    {
      name: 'storyboard-backend',
      cwd: './backend',
      script: 'uvicorn',
      args: 'app.main:app --host 0.0.0.0 --port 8000',
      interpreter: './venv/bin/python',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production'
      },
      error_file: './logs/backend-error.log',
      out_file: './logs/backend-out.log',
      log_file: './logs/backend.log'
    },
    {
      name: 'storyboard-frontend',
      cwd: './client',
      script: 'npm',
      args: 'start',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: './logs/frontend-error.log',
      out_file: './logs/frontend-out.log',
      log_file: './logs/frontend.log'
    },
    {
      name: 'celery-main',
      cwd: './backend',
      script: './venv/bin/celery',
      args: '-A app.celery_app worker -Q pipeline,celery -c 4 -n main@%h --loglevel=INFO',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      error_file: './logs/celery-main-error.log',
      out_file: './logs/celery-main-out.log',
      log_file: './logs/celery-main.log'
    },
    {
      name: 'celery-beat',
      cwd: './backend',
      script: './venv/bin/celery',
      args: '-A app.celery_app beat --loglevel=INFO',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '256M',
      error_file: './logs/celery-beat-error.log',
      out_file: './logs/celery-beat-out.log',
      log_file: './logs/celery-beat.log'
    }
  ]
};