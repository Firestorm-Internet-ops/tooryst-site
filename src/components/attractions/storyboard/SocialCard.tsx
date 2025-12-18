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
      {/* YouTube video with constrained height */}
      <div className="relative w-full flex-1">
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
        <div className="p-4 bg-white">
          <h3 className="text-sm font-semibold text-gray-900 line-clamp-2">
            {social.title}
          </h3>
          <a
            href="#section-social-videos"
            onClick={(e) => {
              e.preventDefault();
              handleScrollToSocial();
            }}
            className="text-xs text-primary-600 hover:text-primary-700 mt-2 inline-flex items-center gap-1 font-medium transition-colors cursor-pointer"
          >
            View more →
          </a>
        </div>
      )}
    </article>
  );
}

