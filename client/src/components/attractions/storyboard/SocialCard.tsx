'use client';

import { SocialVideoCard } from '@/types/attraction-page';
import React from 'react';

interface SocialCardProps {
  social: SocialVideoCard;
}

export function SocialCard({ social }: SocialCardProps) {
  if (!social || !social.embed_url) return null;

  const handleScrollToSocial = () => {
    if (typeof window === 'undefined') return;

    // SectionShell prefixes ids with "section-"
    const section =
      document.getElementById('section-social-videos') ||
      document.getElementById('social-videos');

    if (section) {
      // Account for sticky headers (main header + sections navbar) and a small padding
      const mainHeaderHeight = 64;
      const sectionsNavbarHeight = 72;
      const totalOffset = mainHeaderHeight + sectionsNavbarHeight + 16;

      const elementPosition = section.getBoundingClientRect().top + window.pageYOffset;
      const offsetPosition = elementPosition - totalOffset;

      window.scrollTo({
        top: offsetPosition,
        behavior: 'smooth',
      });
      return;
    }

    // Fallback: set hash so navigation jumps if section exists later
    window.location.hash = '#social-videos';
  };

  return (
    <article className="rounded-3xl bg-gray-50 border border-gray-200 overflow-hidden w-full h-full flex flex-col">
      {/* YouTube video with constrained height - only show on desktop */}
      <div className="relative w-full flex-1 hidden lg:block">
        <iframe
          src={social.embed_url}
          title={social.title || 'Social video'}
          className="absolute inset-0 w-full h-full border-0"
          allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
          allowFullScreen
          loading="lazy"
        />
      </div>
      
      {/* Video title */}
      {social.title && (
        <div className="p-4 bg-white lg:bg-transparent lg:absolute lg:bottom-0 lg:left-0 lg:right-0 lg:bg-gradient-to-t lg:from-black/70 lg:to-transparent lg:text-white">
          <h3 className="text-sm font-semibold text-gray-900 lg:text-white line-clamp-2">
            {social.title}
          </h3>
          <a
            href="#section-social-videos"
            onClick={(e) => {
              e.preventDefault();
              handleScrollToSocial();
            }}
            className="text-xs text-primary-600 lg:text-white hover:text-primary-700 lg:hover:text-gray-200 mt-2 inline-flex items-center gap-1 font-medium transition-colors cursor-pointer"
          >
            View more →
          </a>
        </div>
      )}
      
      {/* Placeholder content for mobile/tablet when no video is shown */}
      <div className="lg:hidden flex-1 flex items-center justify-center p-6">
        <div className="text-center">
          <div className="w-12 h-12 mx-auto mb-3 bg-primary-100 rounded-full flex items-center justify-center">
            <svg className="w-6 h-6 text-primary-600" fill="currentColor" viewBox="0 0 24 24">
              <path d="M8 5v14l11-7z"/>
            </svg>
          </div>
          <p className="text-sm text-gray-600 mb-2">Video content</p>
          <p className="text-xs text-gray-500">Tap to view videos</p>
        </div>
      </div>
    </article>
  );
}

