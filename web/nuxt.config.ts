export default defineNuxtConfig({
  compatibilityDate: '2025-05-15',
  app: {
    head: {
      title: 'Berroku — A Berry Puzzle Game',
      meta: [
        { name: 'description', content: 'Place 3 berries in every row, column & block. A delightful logic puzzle game for iOS.' },
        { name: 'theme-color', content: '#0b1628' },
      ],
      link: [
        { rel: 'icon', type: 'image/x-icon', href: '/favicon.ico' },
        { rel: 'icon', type: 'image/png', sizes: '32x32', href: '/favicon-32x32.png' },
        { rel: 'icon', type: 'image/png', sizes: '16x16', href: '/favicon-16x16.png' },
        { rel: 'apple-touch-icon', sizes: '180x180', href: '/apple-touch-icon.png' },
        { rel: 'preconnect', href: 'https://fonts.googleapis.com' },
        { rel: 'preconnect', href: 'https://fonts.gstatic.com', crossorigin: '' },
        { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css2?family=DM+Serif+Display&family=DM+Sans:opsz,wght@9..40,300..700&display=swap' },
      ],
      script: [
        { src: 'https://cdn.usefathom.com/script.js', 'data-site': 'HFPTJKUX', defer: true },
      ],
    },
  },
  css: ['~/assets/css/main.css'],
})
