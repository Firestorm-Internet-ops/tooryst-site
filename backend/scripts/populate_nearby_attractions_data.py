#!/usr/bin/env python3
"""
Script to populate missing data in nearby_attractions table.
Fills in rating, review_count, and image_url from attractions and hero_images tables.
"""
import sys
import logging
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Add backend to path
sys.path.insert(0, '/Users/deepak/Desktop/storyboard/backend')

from app.config import settings
from app.infrastructure.persistence import models
from app.infrastructure.persistence.db import SessionLocal


def populate_nearby_attractions_data():
    """
    Populate missing data in nearby_attractions table.
    """
    session = SessionLocal()
    
    try:
        # Find nearby attractions with nearby_attraction_id but missing data
        nearby_rows = (
            session.query(models.NearbyAttraction)
            .filter(models.NearbyAttraction.nearby_attraction_id.isnot(None))
            .all()
        )
        
        logger.info(f"Found {len(nearby_rows)} nearby attractions with nearby_attraction_id")
        
        updated_count = 0
        
        for nearby in nearby_rows:
            needs_update = False
            
            # Check if any data is missing
            if (nearby.rating is None or 
                nearby.user_ratings_total is None or 
                nearby.review_count is None or 
                nearby.image_url is None):
                
                logger.info(f"\nProcessing: {nearby.name} (id: {nearby.id}, nearby_id: {nearby.nearby_attraction_id})")
                logger.info(f"  Current - rating: {nearby.rating}, reviews: {nearby.review_count}, image: {nearby.image_url}")
                
                # Get the attraction data
                attraction = (
                    session.query(models.Attraction)
                    .filter(models.Attraction.id == nearby.nearby_attraction_id)
                    .first()
                )
                
                if attraction:
                    # Fill in missing rating
                    if nearby.rating is None and attraction.rating is not None:
                        nearby.rating = attraction.rating
                        needs_update = True
                        logger.info(f"  Updated rating: {attraction.rating}")
                    
                    # Fill in missing user_ratings_total
                    if nearby.user_ratings_total is None and attraction.review_count is not None:
                        nearby.user_ratings_total = attraction.review_count
                        needs_update = True
                        logger.info(f"  Updated user_ratings_total: {attraction.review_count}")
                    
                    # Fill in missing review_count
                    if nearby.review_count is None and attraction.review_count is not None:
                        nearby.review_count = attraction.review_count
                        needs_update = True
                        logger.info(f"  Updated review_count: {attraction.review_count}")
                    
                    # Fill in missing image_url
                    if nearby.image_url is None:
                        hero_image = (
                            session.query(models.HeroImage)
                            .filter(models.HeroImage.attraction_id == nearby.nearby_attraction_id)
                            .order_by(models.HeroImage.position.asc())
                            .first()
                        )
                        
                        if hero_image:
                            nearby.image_url = hero_image.url
                            needs_update = True
                            logger.info(f"  Updated image_url: {hero_image.url}")
                        else:
                            logger.warning(f"  No hero image found for attraction {nearby.nearby_attraction_id}")
                else:
                    logger.warning(f"  Attraction not found for nearby_attraction_id: {nearby.nearby_attraction_id}")
                
                if needs_update:
                    updated_count += 1
        
        # Commit all changes
        if updated_count > 0:
            session.commit()
            logger.info(f"\n✓ Successfully updated {updated_count} nearby attractions")
        else:
            logger.info("\nNo updates needed")
        
    except Exception as e:
        logger.error(f"Error: {e}", exc_info=True)
        session.rollback()
    finally:
        session.close()


if __name__ == "__main__":
    logger.info("Starting nearby attractions data population...")
    populate_nearby_attractions_data()
    logger.info("Done!")
