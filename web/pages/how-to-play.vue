<script setup lang="ts">
const title = 'How to play Berroku — Rules & interactive tutorial'
const description = 'Learn how to play Berroku: place three berries in every row, column and block, read the number clues, and try your first moves in an interactive tutorial.'
useSeoMeta({ title, description, ogTitle: title, ogDescription: description, ogUrl: 'https://berroku.com/how-to-play', twitterTitle: title, twitterDescription: description })
useHead({ link: [{ rel: 'canonical', href: 'https://berroku.com/how-to-play' }] })
</script>

<template>
    <main class="how-to-play container">
        <header class="page-intro">
            <NuxtLink to="/" class="back-link">← Berroku</NuxtLink>
            <h1>How to play</h1>
            <p class="intro">A little counting. A little elimination.<br>One satisfying solution.</p>
            <p class="summary">Place exactly <strong>three berries</strong> in every row, column and block of the 9 × 9 grid. Use the number clues to work out where they belong.</p>
        </header>
        <HowToPlay />
        <section class="ready" aria-labelledby="ready-title">
            <div>
                <h2 id="ready-title">Take it one deduction at a time.</h2>
                <p>Start with zeros, look for nearly complete groups, and keep checking where rows, columns and blocks meet. All the rules must be satisfied together.</p>
            </div>
            <a href="https://apps.apple.com/us/app/berroku/id6761375301" class="btn-primary"><AppleIcon />Play on iOS</a>
        </section>
    </main>
</template>

<style scoped>
.how-to-play { padding-top: 132px; padding-bottom: 80px; }
.page-intro { max-width: 680px; margin-bottom: 64px; }
.back-link { font-size: .85rem; display: inline-block; padding: 8px 0; }
h1, h2 { font-family: 'Fraunces', serif; font-weight: 600; }
h1 { font-size: clamp(3rem, 7vw, 5rem); line-height: 1.08; margin: 20px 0 24px; letter-spacing: -.035em; }
.intro { font-size: clamp(1.2rem, 3vw, 1.65rem); color: #d0dcee; line-height: 1.5; }
.summary { color: #b3c1da; max-width: 55ch; line-height: 1.8; margin-top: 24px; }
.summary strong { color: #f0f4ff; font-weight: 600; }
.ready { display: flex; align-items: center; justify-content: space-between; gap: 40px; border-top: 1px solid #283951; margin-top: 72px; padding-top: 48px; }
.ready h2 { font-size: 1.7rem; line-height: 1.25; margin-bottom: 16px; }
.ready p { color: #b3c1da; max-width: 55ch; line-height: 1.8; }
.ready a { flex-shrink: 0; }
a:focus-visible { outline: 2px solid #94c5ff; outline-offset: 5px; }
@media (max-width: 760px) { .how-to-play { padding-top: 112px; padding-bottom: 48px; } .page-intro { margin-bottom: 48px; } .ready { flex-direction: column; align-items: flex-start; margin-top: 48px; } }
@media (prefers-reduced-motion: reduce) { .btn-primary { transition: none; } .btn-primary:hover { transform: none; } }
</style>
