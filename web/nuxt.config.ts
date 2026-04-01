const siteUrl = 'https://berroku.com'
const siteTitle = 'Berroku — A Berry Puzzle Game'
const siteDescription = 'Place 3 berries in every row, column & block. A delightful logic puzzle game for iOS with daily puzzles, 3 difficulty levels, and Game Center integration.'
const siteImage = `${siteUrl}/og.png`

export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',
  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      title: siteTitle,
      meta: [
        { name: 'description', content: siteDescription },
        { name: 'theme-color', content: '#0b1628' },
        { name: 'author', content: 'James Brooks' },
        { name: 'robots', content: 'index, follow' },

        // Open Graph
        { property: 'og:type', content: 'website' },
        { property: 'og:url', content: siteUrl },
        { property: 'og:title', content: siteTitle },
        { property: 'og:description', content: siteDescription },
        { property: 'og:image', content: siteImage },
        { property: 'og:site_name', content: 'Berroku' },
        { property: 'og:locale', content: 'en_US' },

        // Twitter Card
        { name: 'twitter:card', content: 'summary_large_image' },
        { name: 'twitter:site', content: '@jbrooksuk' },
        { name: 'twitter:creator', content: '@jbrooksuk' },
        { name: 'twitter:title', content: siteTitle },
        { name: 'twitter:description', content: siteDescription },
        { name: 'twitter:image', content: siteImage },

        // App meta
        { name: 'apple-itunes-app', content: 'app-id=6761375301' },
        { name: 'application-name', content: 'Berroku' },
      ],
      link: [
        { rel: 'canonical', href: siteUrl },
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon-32x32.png' },
        { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/favicon-16x16.png' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' },
        { rel: 'manifest', href: '/site.webmanifest' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:opsz,wght@9..40,300..700&display=swap' },
      ],
      script: [
        { src: 'https://cdn.usefathom.com/script.js', 'data-site': 'HFPTJKUX', defer: true },
        {
          type: 'application/ld+json',
          innerHTML: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'MobileApplication',
            name: 'Berroku',
            description: siteDescription,
            operatingSystem: 'iOS',
            applicationCategory: 'GameApplication',
            offers: {
              '@type': 'Offer',
              price: '0',
              priceCurrency: 'USD',
            },
            author: {
              '@type': 'Person',
              name: 'James Brooks',
            },
          }),
        },
      ],
    },
  },
  css: ['~/assets/css/main.css'],
})
