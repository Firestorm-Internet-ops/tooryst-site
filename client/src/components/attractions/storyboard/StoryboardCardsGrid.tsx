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

          {/* ───────────────── Hero Row (UNCHANGED) ───────────────── */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <div className="lg:col-span-2 h-full">
              <HeroImageSlider
                name={data.name}
                city={data.city}
                country={data.country}
                images={data.cards.hero_images?.images ?? []}
              />
            </div>

            <div className="lg:col-span-1 flex flex-col md:flex-row lg:flex-col gap-4">
              <div
                className="cursor-pointer flex-1"
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

              {data.cards.weather && (
                <div className="flex-1">
                  <WeatherSnapshotCard
                    weather={data.cards.weather}
                    timezone={data.timezone}
                  />
                </div>
              )}
            </div>
          </div>

          {/* ───────────────── Rows 2–4 (DESKTOP GRID) ───────────────── */}
          <div className="grid grid-cols-1 lg:grid-cols-3 lg:grid-rows-3 lg:auto-rows-fr gap-4 lg:min-h-[600px]">

            {/* Reviews */}
            <div
              className="lg:col-start-1 lg:row-start-1 cursor-pointer"
              onClick={() => onCardClick?.('reviews')}
            >
              <RatingSummaryCard review={data.cards.review} />
            </div>

            {/* Map (rows 1–2) */}
            {data.cards.map && (
              <div
                className="lg:col-start-2 lg:row-start-1 lg:row-span-2 cursor-pointer h-full"
                onClick={() => onCardClick?.('map')}
              >
                <MapTeaserCard map={data.cards.map} />
              </div>
            )}

            {/* Social (rows 1–3) */}
            <div
              className="hidden lg:block lg:col-start-3 lg:row-start-1 lg:row-span-3 h-full cursor-pointer"
              onClick={() => onCardClick?.('social_videos')}
            >
              {data.cards.social_video ? (
                <SocialCard social={data.cards.social_video} />
              ) : (
                <SocialCardPlaceholder />
              )}
            </div>

            {/* Tips */}
            {data.cards.tips && (
              <div
                className="hidden lg:block lg:col-start-1 lg:row-start-2 cursor-pointer"
                onClick={() => onCardClick?.('tips')}
              >
                <SafetyTipCard tips={data.cards.tips} />
              </div>
            )}

            {/* About */}
            {data.cards.about && (
              <div className="hidden lg:block lg:col-start-1 lg:row-start-3">
                <AboutSnippetCard about={data.cards.about} />
              </div>
            )}

            {/* Nearby */}
            {data.cards.nearby_attraction && (
              <div
                className="hidden lg:block lg:col-start-2 lg:row-start-3 cursor-pointer"
                onClick={() => onCardClick?.('nearby_attractions')}
              >
                <NearbyAttractionCard nearby={data.cards.nearby_attraction} />
              </div>
            )}

            {/* ───────────── Mobile / Tablet ───────────── */}
            <div className="lg:hidden flex flex-col gap-4">
              {/* Tips and Map cards on mobile/tablet */}
              <div className="flex flex-col md:flex-row gap-4">
                {data.cards.tips && (
                  <div
                    className="cursor-pointer md:flex-1"
                    onClick={() => onCardClick?.('tips')}
                  >
                    <SafetyTipCard tips={data.cards.tips} />
                  </div>
                )}

                {data.cards.map && (
                  <div
                    className="cursor-pointer md:flex-1"
                    onClick={() => onCardClick?.('map')}
                  >
                    <MapTeaserCard map={data.cards.map} />
                  </div>
                )}
              </div>

              {/* Social Video Card */}
              <div
                className="cursor-pointer"
                onClick={() => onCardClick?.('social_videos')}
              >
                {data.cards.social_video ? (
                  <SocialCard social={data.cards.social_video} />
                ) : (
                  <SocialCardPlaceholder />
                )}
              </div>

              {/* About + Nearby cards */}
              <div className="flex flex-col md:flex-row gap-4">
                {data.cards.about && (
                  <div className="md:flex-1">
                    <AboutSnippetCard about={data.cards.about} />
                  </div>
                )}

                {data.cards.nearby_attraction && (
                  <div
                    className="cursor-pointer md:flex-1"
                    onClick={() => onCardClick?.('nearby_attractions')}
                  >
                    <NearbyAttractionCard nearby={data.cards.nearby_attraction} />
                  </div>
                )}
              </div>
            </div>

          </div>
        </div>
      </div>
    </section>
  );
}
