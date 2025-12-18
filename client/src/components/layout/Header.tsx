'use client';

import * as React from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Menu } from 'lucide-react';
import config from '@/lib/config';

const links = [
  { label: 'Home', href: '/' },
  { label: 'Explore', href: '/search' },
  { label: 'Cities', href: '/cities' },
  { label: 'About', href: '/about' },
  { label: 'Contact', href: '/contact' },
];

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = React.useState(false);
  const [mounted, setMounted] = React.useState(false);

  React.useEffect(() => {
    setMounted(true);
  }, []);

  return (
    <header className="sticky top-0 z-50 border-b border-gray-100 bg-white/95 shadow-sm backdrop-blur">
      <div className="mx-auto flex max-w-7xl items-center justify-center px-4 py-8 md:py-6 relative">
        <Link
          href="/"
          className="absolute left-4 flex items-center gap-2 hover:opacity-80 transition-opacity"
        >
          <Image
            src="/logo.svg"
            alt={config.appName}
            width={40}
            height={40}
            className="w-8 h-8 md:w-10 md:h-10 lg:w-12 lg:h-12"
            priority
          />
          <span className="hidden sm:inline text-lg md:text-xl font-display font-semibold text-primary-700">
            {config.appName}
          </span>
        </Link>

        <nav id="main-navigation" className="hidden items-center gap-6 text-base font-medium text-gray-600 md:flex" aria-label="Main navigation">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="transition hover:text-primary-600"
            >
              {link.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-2 absolute right-4">
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="inline-flex items-center justify-center rounded-md border border-gray-200 p-2 text-gray-600 hover:text-primary-600 md:hidden"
            aria-label="Open navigation"
            aria-expanded={mobileMenuOpen}
          >
            <Menu size={20} />
          </button>
        </div>
      </div>

      {mounted && mobileMenuOpen && (
      <nav className="border-t border-gray-100 bg-white md:hidden" aria-label="Mobile navigation">
        <div className="mx-auto max-w-7xl px-4 py-2">
          {links.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className="block px-4 py-2 text-sm text-gray-600 hover:bg-gray-50 hover:text-primary-600 transition-colors"
              onClick={() => setMobileMenuOpen(false)}
            >
              {link.label}
            </Link>
          ))}
        </div>
      </nav>
    )}
    </header>
  );
}
