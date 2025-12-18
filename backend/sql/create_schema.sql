-- Create schema for Storyboard backend (MySQL-compatible)
-- No migrations; run these CREATE statements in order.
-- All tables use InnoDB and utf8mb4 for consistency.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Cities
CREATE TABLE IF NOT EXISTS cities (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(255),
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    timezone VARCHAR(50),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_cities_slug (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Attractions
CREATE TABLE IF NOT EXISTS attractions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    city_id BIGINT UNSIGNED NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    resolved_name VARCHAR(255),
    place_id VARCHAR(255),
    rating DECIMAL(3,2),
    review_count INT,
    summary_gemini TEXT,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    address VARCHAR(512),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_attractions_city (city_id),
    INDEX idx_attractions_place (place_id),
    CONSTRAINT fk_attractions_city FOREIGN KEY (city_id) REFERENCES cities(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Hero images for attractions
CREATE TABLE IF NOT EXISTS hero_images (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    url VARCHAR(1024) NOT NULL,
    alt_text VARCHAR(512),
    position INT DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_hero_images_attraction (attraction_id, position),
    CONSTRAINT fk_hero_images_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Best time data (regular days by weekday + special days from BestTime API or Gemini fallback)
CREATE TABLE IF NOT EXISTS best_time_data (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    day_type ENUM('regular', 'special') NOT NULL DEFAULT 'regular',
    date_local DATE NULL,  -- NULL for regular days (day-of-week based)
    day_int TINYINT NULL,  -- 0-6 for regular days (Monday=0 to Sunday=6)
    day_name VARCHAR(16) NOT NULL,
    -- Card data
    is_open_today BOOLEAN NOT NULL DEFAULT FALSE,
    today_opening_time TIME,
    today_closing_time TIME,
    crowd_level_today INT,
    best_time_today VARCHAR(64),
    -- Section data
    reason_text VARCHAR(1024),
    hourly_crowd_levels JSON,
    -- Metadata
    data_source VARCHAR(32) DEFAULT 'besttime',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_best_time_attraction_type_day (attraction_id, day_type, day_int, date_local),
    INDEX idx_best_time_attraction (attraction_id),
    INDEX idx_best_time_date (date_local),
    INDEX idx_best_time_day_int (day_int),
    INDEX idx_best_time_type (day_type),
    CONSTRAINT fk_best_time_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Weather forecast (5 days from OpenWeatherMap)
CREATE TABLE IF NOT EXISTS weather_forecast (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    date_local DATE NOT NULL,
    -- Card data (all weather fields)
    temperature_c INT,
    feels_like_c INT,
    min_temperature_c INT,
    max_temperature_c INT,
    summary VARCHAR(255),
    precipitation_mm DECIMAL(6,1),
    wind_speed_kph INT,
    humidity_percent INT,
    icon_url VARCHAR(1024),
    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_weather_attraction_date (attraction_id, date_local),
    INDEX idx_weather_attraction (attraction_id),
    INDEX idx_weather_date (date_local),
    CONSTRAINT fk_weather_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reviews (Google/others)
CREATE TABLE IF NOT EXISTS reviews (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    author_name VARCHAR(255) NOT NULL,
    author_url VARCHAR(512),
    author_photo_url VARCHAR(512),
    rating TINYINT NOT NULL,
    text TEXT,
    time DATETIME,
    source VARCHAR(64) DEFAULT 'Google',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_reviews_attraction (attraction_id),
    CONSTRAINT fk_reviews_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tips (SAFETY / INSIDER)
CREATE TABLE IF NOT EXISTS tips (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    tip_type ENUM('SAFETY', 'INSIDER') NOT NULL,
    text TEXT NOT NULL,
    source VARCHAR(128),
    scope ENUM('attraction', 'city') NOT NULL DEFAULT 'attraction',
    position INT DEFAULT 1,  -- 0 for prominent/critical tips, 1 for detailed tips
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_tips_attraction (attraction_id, tip_type),
    INDEX idx_tips_scope (scope),
    CONSTRAINT fk_tips_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Map snapshot (directions and static map)
CREATE TABLE IF NOT EXISTS map_snapshot (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    latitude DECIMAL(9,6),
    longitude DECIMAL(9,6),
    address VARCHAR(512),
    directions_url VARCHAR(1024),
    static_map_url VARCHAR(1024),
    zoom_level TINYINT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_map_snapshot_attraction (attraction_id),
    CONSTRAINT fk_map_snapshot_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Nearby attractions
CREATE TABLE IF NOT EXISTS nearby_attractions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    nearby_attraction_id BIGINT UNSIGNED NULL,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255),
    place_id VARCHAR(255),
    rating DECIMAL(3,2),
    user_ratings_total INT,
    review_count INT,
    image_url VARCHAR(1024),
    link VARCHAR(1024),
    vicinity VARCHAR(255),
    distance_text VARCHAR(64),
    distance_km DECIMAL(6,3),
    walking_time_minutes INT,
    audience_type VARCHAR(64),
    audience_text VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_nearby_attractions_attraction (attraction_id),
    INDEX idx_nearby_attractions_nearby_attraction (nearby_attraction_id),
    CONSTRAINT fk_nearby_attractions_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE,
    CONSTRAINT fk_nearby_attractions_nearby_attraction FOREIGN KEY (nearby_attraction_id) REFERENCES attractions(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Widget configuration (HTML/JS components from Excel)
CREATE TABLE IF NOT EXISTS widget_config (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    widget_primary TEXT,
    widget_secondary TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_widget_config_attraction (attraction_id),
    CONSTRAINT fk_widget_config_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Attraction metadata (visitor info, seasonality, hours, social embed)
CREATE TABLE IF NOT EXISTS attraction_metadata (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    contact_info JSON,
    accessibility_info TEXT,
    best_season TEXT,
    opening_hours JSON,
    short_description TEXT,
    recommended_duration_minutes INT,
    highlights JSON,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_metadata_attraction (attraction_id),
    CONSTRAINT fk_metadata_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audience profiles (optional explicit table)
CREATE TABLE IF NOT EXISTS audience_profiles (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    audience_type VARCHAR(64) NOT NULL,
    description TEXT,
    emoji VARCHAR(16),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audience_attraction (attraction_id),
    CONSTRAINT fk_audience_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Social videos (YouTube Shorts)
CREATE TABLE IF NOT EXISTS social_videos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    video_id VARCHAR(255) NOT NULL,
    platform VARCHAR(32) NOT NULL DEFAULT 'youtube',
    title VARCHAR(512),
    embed_url VARCHAR(1024),
    thumbnail_url VARCHAR(1024),
    watch_url VARCHAR(1024),
    duration_seconds INT,
    view_count BIGINT,
    channel_title VARCHAR(255),
    position INT DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_social_videos_attraction (attraction_id),
    UNIQUE KEY uq_social_videos_video (attraction_id, video_id),
    CONSTRAINT fk_social_videos_attraction FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;



-- System alerts (for notification tracking, auditing, and acknowledgment)
CREATE TABLE IF NOT EXISTS system_alerts (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    alert_type VARCHAR(64) NOT NULL,
    severity VARCHAR(32) NOT NULL,
    title VARCHAR(512) NOT NULL,
    message TEXT NOT NULL,
    metadata JSON,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_at TIMESTAMP NULL,
    acknowledged_by VARCHAR(255),
    INDEX idx_system_alerts_created (created_at DESC),
    INDEX idx_system_alerts_type (alert_type),
    INDEX idx_system_alerts_severity (severity),
    INDEX idx_system_alerts_acknowledged (acknowledged)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Pipeline runs (for tracking pipeline execution and monitoring)
CREATE TABLE IF NOT EXISTS pipeline_runs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP NULL,
    status ENUM('running', 'completed', 'failed') NOT NULL DEFAULT 'running',
    attractions_processed INT UNSIGNED DEFAULT 0,
    attractions_completed INT UNSIGNED DEFAULT 0,
    attractions_succeeded INT UNSIGNED DEFAULT 0,
    attractions_failed INT UNSIGNED DEFAULT 0,
    error_message TEXT,
    metadata JSON,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_pipeline_runs_started (started_at DESC),
    INDEX idx_pipeline_runs_status (status),
    INDEX idx_pipeline_runs_completed (completed_at DESC)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Data fetch runs (for tracking data fetching operations with resumable pagination)
CREATE TABLE IF NOT EXISTS data_fetch_runs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    
    -- What type of data are we fetching?
    data_type VARCHAR(50) NOT NULL, -- 'tips', 'reviews', 'photos', 'videos', 'nearby', 'weather', 'best_time', etc.
    
    -- Progress tracking
    items_target INT NOT NULL DEFAULT 0, -- How many items we want to fetch
    items_collected INT NOT NULL DEFAULT 0, -- How many we've collected so far
    
    -- Pagination/cursor for resuming
    cursor_data JSON, -- Flexible JSON to store any pagination data (after, page_token, offset, etc.)
    
    -- Status tracking
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING', -- PENDING, RUNNING, DONE, RATE_LIMITED, FAILED, PAUSED
    
    -- Error handling
    last_error TEXT,
    retry_count INT NOT NULL DEFAULT 0,
    max_retries INT NOT NULL DEFAULT 5,
    
    -- Scheduling
    next_run_at TIMESTAMP NULL, -- When to run next (for rate limits or scheduled updates)
    
    -- Metadata
    metadata JSON, -- Flexible JSON for any additional data (API keys used, filters, etc.)
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    started_at TIMESTAMP NULL,
    completed_at TIMESTAMP NULL,
    
    -- Ensure one active run per attraction per data type
    UNIQUE KEY unique_attraction_data_type (attraction_id, data_type),
    
    -- Foreign key constraint
    CONSTRAINT fk_data_fetch_runs_attraction FOREIGN KEY (attraction_id) 
        REFERENCES attractions(id) ON DELETE CASCADE,
    
    -- Indexes for efficient queries
    INDEX idx_data_fetch_runs_status (status),
    INDEX idx_data_fetch_runs_data_type (data_type),
    INDEX idx_data_fetch_runs_next_run (next_run_at),
    INDEX idx_data_fetch_runs_attraction_type (attraction_id, data_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ================================================================
-- YouTube Retry Queue
-- Tracks attractions that failed to get YouTube videos due to quota exceeded
-- Daily task will retry these attractions
-- ================================================================
CREATE TABLE IF NOT EXISTS youtube_retry_queue (
    id INT AUTO_INCREMENT PRIMARY KEY,
    attraction_id BIGINT UNSIGNED NOT NULL,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    retry_count INT DEFAULT 0,
    last_retry_at TIMESTAMP NULL,
    error_message TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    FOREIGN KEY (attraction_id) REFERENCES attractions(id) ON DELETE CASCADE,
    INDEX idx_status (status),
    INDEX idx_attraction_status (attraction_id, status),
    INDEX idx_added_at (added_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Contact form submissions
CREATE TABLE IF NOT EXISTS contact_submissions (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    subject VARCHAR(512),
    message TEXT NOT NULL,
    status ENUM('new', 'read', 'responded') NOT NULL DEFAULT 'new',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_contact_status (status),
    INDEX idx_contact_created (created_at DESC),
    INDEX idx_contact_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
