import { AttractionPageResponse } from '@/types/attraction-page';
import { HeroImageSlider } from '@/components/attractions/HeroImagesSlider';
import { BestTimeTodayCard } from '@/components/attractions/storyboard/BestTimeTodayCard';
import { WeatherSnapshotCard } from '@/components/attractions/storyboard/WeatherSnapshotCard';
import { RatingSummaryCard } from '@/components/attractions/storyboard/RatingSummaryCard';
import { SafetyTipCard } from '@/components/attractions/storyboard/SafetyTipCard';
import { MapTeaserCard } from '@/components/attractions/storyboard/MapTeaserCard';
import { AboutSnippetCard } from '@/components/attractions/storyboard/AboutSnippetCard';
import { NearbyAttractionCard } from '@/components/attractions/storyboard/NearbyAttractionCard';
import { SocialCard } from '@/components/attractions/storyboard/SocialCard';
import { SocialCardPlaceholder } from '@/components/attractions/storyboard/SocialCardPlaceholder';

interface StoryboardCardsGridProps {
  data: AttractionPageResponse;
  onCardClick?: (sectionType: string) => void;
}

export function StoryboardCardsGrid({ data, onCardClick }: StoryboardCardsGridProps) {
  return (
    <section className="pb-10">
      <div className="w-full px-4 lg:px-6">
        <div className="flex flex-col gap-4">
          {/* First row: Hero slider + Best time + Weather */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            {/* Hero slider on the left, spanning 2 columns - matches height of right column */}
            <div className="lg:col-span-2 h-full">
              <HeroImageSlider
                name={data.name}
                city={data.city}
                country={data.country}
                images={data.cards.hero_images?.images ?? []}
              />
            </div>

            {/* Right column: responsive layout for best time + weather */}
            <div className="lg:col-span-1 flex flex-col gap-4">
              {/* Best time card */}
              <div 
                className="cursor-pointer"
                onClick={() => onCardClick?.('best_time')}
              >
                <BestTimeTodayCard
                  bestTime={data.cards.best_time}
                  name={data.name}
                  timezone={data.timezone}
                  latitude={data.cards?.map?.latitude ?? null}
                  longitude={data.cards?.map?.longitude ?? null}
                  visitorInfo={data.visitor_info}
                />
              </div>

              {/* Weather card (only render if present) */}
              {data.cards.weather && (
                <div className="flex-1">
                  <WeatherSnapshotCard weather={data.cards.weather} timezone={data.timezone} />
                </div>
              )}
            </div>
          </div>

          {/* Rows 2 & 3: Using CSS Grid with explicit positioning for social card to span both rows */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 lg:auto-rows-auto">
            {/* Row 2, Column 1: Review and Tips cards stacked vertically */}
            <div className="lg:col-start-1 lg:row-start-1 flex flex-col gap-4">
              {/* Review card */}
              <div 
                className="cursor-pointer"
                onClick={() => onCardClick?.('reviews')}
              >
                <RatingSummaryCard review={data.cards.review} />
              </div>

              {/* Tips card below review card */}
              {data.cards.tips && (
                <div 
                  className="cursor-pointer"
                  onClick={() => onCardClick?.('tips')}
                >
                  <SafetyTipCard tips={data.cards.tips} />
                </div>
              )}
            </div>

            {/* Row 2, Column 2: Map card */}
            {data.cards.map && (
              <div 
                className="lg:col-start-2 lg:row-start-1 cursor-pointer"
                onClick={() => onCardClick?.('map')}
              >
                <MapTeaserCard map={data.cards.map} />
              </div>
            )}

            {/* Row 2-3, Column 3: Social card spanning 2 rows */}
            <div 
              className="lg:col-start-3 lg:row-start-1 lg:row-span-2 cursor-pointer"
              onClick={() => onCardClick?.('social_videos')}
            >
              {data.cards.social_video ? (
                <SocialCard social={data.cards.social_video} />
              ) : (
                <SocialCardPlaceholder />
              )}
            </div>

            {/* Row 3, Column 1: About snippet card */}
            {data.cards.about && (
              <div className="lg:col-start-1 lg:row-start-2 h-full">
                <AboutSnippetCard about={data.cards.about} />
              </div>
            )}

            {/* Row 3, Column 2: Nearby attraction card */}
            {data.cards.nearby_attraction && (
              <div
                className="lg:col-start-2 lg:row-start-2 cursor-pointer h-full"
                onClick={() => onCardClick?.('nearby_attractions')}
              >
                <NearbyAttractionCard nearby={data.cards.nearby_attraction} />
              </div>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}
