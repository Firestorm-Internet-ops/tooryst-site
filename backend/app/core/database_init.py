"""Database initialization module - creates database and tables on startup."""
import os
import logging
from pathlib import Path
import pymysql
from typing import Optional

logger = logging.getLogger(__name__)


def get_db_config(include_database: bool = True) -> dict:
    """Get database configuration from environment."""
    config = {
        'host': os.getenv('DATABASE_HOST', 'localhost'),
        'port': int(os.getenv('DATABASE_PORT', 3306)),
        'user': os.getenv('DATABASE_USER', 'root'),
        'password': os.getenv('DATABASE_PASSWORD', ''),
        'charset': 'utf8mb4',
        'cursorclass': pymysql.cursors.DictCursor
    }
    
    if include_database:
        config['database'] = os.getenv('DATABASE_NAME', 'storyboard')
    
    return config


def create_database_if_not_exists(db_name: str) -> bool:
    """Create database if it doesn't exist."""
    try:
        config = get_db_config(include_database=False)
        connection = pymysql.connect(**config)
        
        with connection.cursor() as cursor:
            cursor.execute(
                f"CREATE DATABASE IF NOT EXISTS {db_name} "
                f"CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
            logger.info(f"Database '{db_name}' ready")
        
        connection.commit()
        connection.close()
        return True
    except Exception as e:
        logger.error(f"Failed to create database: {e}")
        return False


def execute_schema_file(db_name: str, schema_file_path: Path) -> bool:
    """Execute SQL schema file to create tables."""
    if not schema_file_path.exists():
        logger.error(f"Schema file not found: {schema_file_path}")
        return False
    
    try:
        # Read schema file
        with open(schema_file_path, 'r', encoding='utf-8') as f:
            schema_sql = f.read()
        
        # Remove comments
        lines = []
        for line in schema_sql.split('\n'):
            if '--' in line:
                line = line[:line.index('--')]
            line = line.strip()
            if line:
                lines.append(line)
        
        schema_sql = ' '.join(lines)
        
        # Split into statements
        statements = []
        current_statement = []
        in_create_table = False
        
        for part in schema_sql.split(';'):
            part = part.strip()
            if not part:
                continue
            
            current_statement.append(part)
            full_statement = ';'.join(current_statement)
            
            if 'CREATE TABLE' in full_statement.upper():
                in_create_table = True
            
            if in_create_table:
                if 'ENGINE=' in full_statement.upper() or full_statement.count('(') == full_statement.count(')'):
                    statements.append(full_statement)
                    current_statement = []
                    in_create_table = False
            else:
                statements.append(full_statement)
                current_statement = []
        
        # Execute statements
        config = get_db_config(include_database=True)
        connection = pymysql.connect(**config)
        
        tables_created = 0
        with connection.cursor() as cursor:
            for statement in statements:
                statement = statement.strip()
                if not statement:
                    continue
                
                try:
                    if statement.upper().startswith('SET'):
                        cursor.execute(statement)
                        continue
                    
                    if 'CREATE TABLE' in statement.upper():
                        cursor.execute(statement)
                        tables_created += 1
                        continue
                    
                    cursor.execute(statement)
                    
                except Exception as e:
                    error_msg = str(e).lower()
                    if 'already exists' not in error_msg and 'duplicate' not in error_msg:
                        logger.warning(f"Error executing statement: {e}")
        
        connection.commit()
        connection.close()
        
        if tables_created > 0:
            logger.info(f"Created {tables_created} tables")
        else:
            logger.info("All tables already exist")
        
        return True
    except Exception as e:
        logger.error(f"Failed to execute schema: {e}")
        return False


def verify_tables(db_name: str, required_tables: list) -> bool:
    """Verify that required tables exist."""
    try:
        config = get_db_config(include_database=True)
        connection = pymysql.connect(**config)
        
        with connection.cursor() as cursor:
            cursor.execute("SHOW TABLES")
            existing_tables = [list(row.values())[0] for row in cursor.fetchall()]
        
        connection.close()
        
        missing_tables = [t for t in required_tables if t not in existing_tables]
        
        if missing_tables:
            logger.warning(f"Missing tables: {missing_tables}")
            return False
        
        logger.info(f"All {len(required_tables)} required tables exist")
        return True
    except Exception as e:
        logger.error(f"Failed to verify tables: {e}")
        return False


def initialize_database() -> bool:
    """Initialize database and tables on application startup."""
    db_name = os.getenv('DATABASE_NAME', 'storyboard')
    
    logger.info("Initializing database...")
    
    # Step 1: Create database
    if not create_database_if_not_exists(db_name):
        logger.error("Failed to create database")
        return False
    
    # Step 2: Execute schema
    schema_path = Path(__file__).parent.parent.parent / 'sql' / 'create_schema.sql'
    if not execute_schema_file(db_name, schema_path):
        logger.error("Failed to execute schema")
        return False
    
    # Step 3: Verify tables
    required_tables = [
        'cities', 'attractions', 'hero_images', 'best_time_data',
        'weather_forecast', 'reviews', 'tips', 'map_snapshot',
        'nearby_attractions', 'widget_config', 'attraction_metadata',
        'audience_profiles', 'social_videos', 'system_alerts',
        'pipeline_runs', 'data_fetch_runs', 'youtube_retry_queue'
    ]
    
    if not verify_tables(db_name, required_tables):
        logger.warning("Some tables are missing")
        return False
    
    logger.info("✓ Database initialization complete")
    return True
