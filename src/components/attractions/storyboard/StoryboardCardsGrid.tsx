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
import Link from 'next/link';

interface StoryboardCardsGridProps {
  data: AttractionPageResponse;
}

export function StoryboardCardsGrid({ data }: StoryboardCardsGridProps) {
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
              <Link
                href="#best-times"
                className="flex-1"
              >
                <BestTimeTodayCard
                  bestTime={data.cards.best_time}
                  name={data.name}
                  timezone={data.timezone}
                  latitude={data.cards?.map?.latitude ?? null}
                  longitude={data.cards?.map?.longitude ?? null}
                  visitorInfo={data.visitor_info}
                />
              </Link>

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
            <Link
              href="#reviews"
              className="lg:col-start-1 lg:row-start-1"
            >
              <RatingSummaryCard review={data.cards.review} />
            </Link>

            {/* Map (rows 1–2) - Desktop only */}
            {data.cards.map && (
              <Link
                href="#map"
                className="hidden lg:block lg:col-start-2 lg:row-start-1 lg:row-span-2 h-full"
              >
                <MapTeaserCard map={data.cards.map} />
              </Link>
            )}

            {/* Social (rows 1–3) */}
            <Link
              href="#social-videos"
              className="hidden lg:block lg:col-start-3 lg:row-start-1 lg:row-span-3 h-full"
            >
              {data.cards.social_video ? (
                <SocialCard social={data.cards.social_video} />
              ) : (
                <SocialCardPlaceholder />
              )}
            </Link>

            {/* Tips */}
            {data.cards.tips && (
              <Link
                href="#tips"
                className="hidden lg:block lg:col-start-1 lg:row-start-2"
              >
                <SafetyTipCard tips={data.cards.tips} />
              </Link>
            )}

            {/* About */}
            {data.cards.about && (
              <div className="hidden lg:block lg:col-start-1 lg:row-start-3">
                <AboutSnippetCard about={data.cards.about} />
              </div>
            )}

            {/* Nearby */}
            {data.cards.nearby_attraction && (
              <Link
                href="#nearby-attractions"
                className="hidden lg:block lg:col-start-2 lg:row-start-3"
              >
                <NearbyAttractionCard nearby={data.cards.nearby_attraction} />
              </Link>
            )}

            {/* ───────────── Mobile / Tablet ───────────── */}
            <div className="lg:hidden flex flex-col gap-4">
              {/* Tips and Map cards on mobile/tablet */}
              <div className="flex flex-col md:flex-row gap-4">
                {data.cards.tips && (
                  <Link
                    href="#tips"
                    className="md:flex-1"
                  >
                    <SafetyTipCard tips={data.cards.tips} />
                  </Link>
                )}

                {data.cards.map && (
                  <Link
                    href="#map"
                    className="md:flex-1"
                  >
                    <MapTeaserCard map={data.cards.map} />
                  </Link>
                )}
              </div>

              {/* Social Video Card on left, About + Nearby stacked on right */}
              <div className="flex flex-col md:flex-row gap-4">
                {/* Social Video Card - Left side on tablet */}
                <Link
                  href="#social-videos"
                  className="md:flex-1"
                >
                  {data.cards.social_video ? (
                    <SocialCard social={data.cards.social_video} />
                  ) : (
                    <SocialCardPlaceholder />
                  )}
                </Link>

                {/* About + Nearby cards stacked - Right side on tablet */}
                <div className="flex flex-col gap-4 md:flex-1">
                  {data.cards.about && (
                    <div>
                      <AboutSnippetCard about={data.cards.about} />
                    </div>
                  )}

                  {data.cards.nearby_attraction && (
                    <Link href="#nearby-attractions">
                      <NearbyAttractionCard nearby={data.cards.nearby_attraction} />
                    </Link>
                  )}
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>
    </section>
  );
}
