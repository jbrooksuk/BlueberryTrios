<template>
    <div>
        <!-- Atmosphere -->
        <div class="atmosphere">
            <div v-for="i in 6" :key="i" class="berry-float" />
        </div>

        <!-- Hero -->
        <section class="hero">
            <div class="container hero-content">
                <div class="hero-berries fade-up">
                    <img src="/berry-smile.svg" alt="" class="hero-berry berry-left" />
                    <img src="/berry-happy.svg" alt="" class="hero-berry berry-center" />
                    <img src="/berry-wink.svg" alt="" class="hero-berry berry-right" />
                </div>
                <h1 class="fade-up">Berroku</h1>
                <p class="hero-tagline fade-up">Place 3 berries in every row, column &amp; block.<br>A fresh logic puzzle that's delightfully addictive.</p>
                <a href="https://apps.apple.com/us/app/berroku/id6761375301" class="btn-primary fade-up">
                    <AppleIcon />
                    Download on the App Store
                </a>
            </div>
        </section>

        <!-- Phone showcase -->
        <section class="showcase">
            <div class="container">
                <div class="phone-row">
                    <div class="phone-frame side fade-up" style="transition-delay: 0.1s;">
                        <img :src="'/screenshots/puzzle-light.png'" alt="Berroku puzzle screen" loading="lazy">
                    </div>
                    <div class="phone-frame hero-phone fade-up">
                        <img :src="'/screenshots/home-light.png'" alt="Berroku home screen" loading="lazy">
                    </div>
                    <div class="phone-frame side fade-up" style="transition-delay: 0.2s;">
                        <img :src="'/screenshots/puzzle-gameplay.png'" alt="Berroku puzzle gameplay" loading="lazy">
                    </div>
                </div>
            </div>
        </section>

        <!-- How it works -->
        <section class="how-it-works">
            <div class="container section-center">
                <h2 class="fade-up">Simple rules, deep logic</h2>
                <p class="section-sub fade-up">A berry-themed logic puzzle inspired by Sudoku. Easy to learn, endlessly satisfying.</p>
                <div class="rules-grid">
                    <div v-for="(rule, i) in rules" :key="rule.title" class="rule-card fade-up" :style="{ transitionDelay: `${i * 0.1}s` }">
                        <div class="rule-number">{{ rule.number }}</div>
                        <h3>{{ rule.title }}</h3>
                        <p>{{ rule.desc }}</p>
                    </div>
                </div>
            </div>
        </section>

        <!-- Features -->
        <section class="features">
            <div class="container section-center">
                <h2 class="fade-up">Everything you need</h2>
                <p class="section-sub fade-up">Packed with features to keep you puzzling every day.</p>
                <div class="features-grid">
                    <div v-for="(feature, i) in features" :key="feature.title" class="feature-card fade-up" :style="{ transitionDelay: `${i * 0.08}s` }">
                        <div class="feature-icon">{{ feature.icon }}</div>
                        <h3>{{ feature.title }}</h3>
                        <p>{{ feature.desc }}</p>
                    </div>
                </div>
            </div>
        </section>

        <!-- Pro -->
        <section class="pro-section">
            <div class="container section-center">
                <div class="pro-badge fade-up">PRO</div>
                <h2 class="fade-up">Never run out of puzzles</h2>
                <p class="section-sub fade-up">Go beyond the daily challenge with unlimited access to our full library of hand-crafted puzzles.</p>
                <div class="pro-grid">
                    <div v-for="(perk, i) in proPerks" :key="perk.title" class="pro-card fade-up" :style="{ transitionDelay: `${i * 0.1}s` }">
                        <div class="pro-icon">{{ perk.icon }}</div>
                        <h3>{{ perk.title }}</h3>
                        <p>{{ perk.desc }}</p>
                    </div>
                </div>
                <div class="pro-price fade-up">
                    <span class="price">$1.99</span>
                    <span class="price-note">One-time purchase. No subscriptions.</span>
                </div>
            </div>
        </section>

        <!-- CTA -->
        <section id="download" class="cta-section">
            <div class="container section-center">
                <div class="cta-berries fade-up">
                    <img src="/berry-smile.svg" alt="" class="cta-berry" />
                    <img src="/berry-happy.svg" alt="" class="cta-berry cta-berry-center" />
                    <img src="/berry-wink.svg" alt="" class="cta-berry" />
                </div>
                <h2 class="fade-up">Ready to pick some 🫐?</h2>
                <p class="fade-up">Free to play. New puzzles every day.</p>
                <a href="https://apps.apple.com/us/app/berroku/id6761375301" class="btn-primary fade-up">
                    <AppleIcon />
                    Download on the App Store
                </a>
            </div>
        </section>
    </div>
</template>

<script setup>
import { onMounted } from 'vue'

const rules = [
    { number: '3', title: 'Three per row', desc: 'Place exactly 3 berries in every row of the 9×9 grid.' },
    { number: '3', title: 'Three per column', desc: 'Every column must also contain exactly 3 berries.' },
    { number: '?', title: 'Follow the clues', desc: 'Numbers tell you how many of the 8 surrounding cells contain berries.' },
]

const proPerks = [
    { icon: '♾️', title: 'Unlimited puzzles', desc: 'Access our full library of 6,000+ puzzles across all three difficulty levels.' },
    { icon: '⚡', title: 'Play on your schedule', desc: 'No waiting for the next daily puzzle. Start a new challenge whenever you want.' },
    { icon: '📈', title: 'All difficulties', desc: 'Standard, Advanced, and Expert puzzles available from the start.' },
]

const features = [
    { icon: '📅', title: 'Daily puzzles', desc: 'Three new puzzles every day. Come back tomorrow for a fresh challenge.' },
    { icon: '🎯', title: '3 difficulties', desc: 'Standard, Advanced, and Expert. Work your way up as your skills sharpen.' },
    { icon: '✈️', title: 'Play offline', desc: 'No internet required. All puzzles are bundled so you can play anywhere.' },
    { icon: '🏆', title: 'Achievements', desc: 'Game Center integration with 12 achievements and a fastest-time leaderboard.' },
    { icon: '🔥', title: 'Streak tracking', desc: 'Build your daily streak. How many consecutive days can you solve?' },
    { icon: '📱', title: 'Home screen widget', desc: 'Track your daily progress and streak right from your home screen.' },
]

onMounted(() => {
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible')
            }
        })
    }, { threshold: 0.1, rootMargin: '0px 0px -30px 0px' })

    document.querySelectorAll('.fade-up').forEach(el => observer.observe(el))
})
</script>

<style scoped>
/* ---- Atmosphere ---- */
.atmosphere {
    position: fixed;
    inset: 0;
    z-index: 0;
    pointer-events: none;
    overflow: hidden;
}
.atmosphere::before {
    content: '';
    position: absolute;
    width: 800px; height: 800px;
    top: -200px; left: 50%;
    transform: translateX(-50%);
    background: radial-gradient(circle, rgba(53,132,228,0.15) 0%, transparent 70%);
    border-radius: 50%;
}
.atmosphere::after {
    content: '';
    position: absolute;
    width: 600px; height: 600px;
    bottom: 10%; right: -100px;
    background: radial-gradient(circle, rgba(47,206,81,0.06) 0%, transparent 70%);
    border-radius: 50%;
}

section {
    position: relative;
    z-index: 1;
    padding: 80px 0;
}
.section-center { text-align: center; }

/* ---- Hero ---- */
.hero { padding-top: 140px; padding-bottom: 40px; }
.hero-content { text-align: center; }
.hero-berries {
    display: flex;
    justify-content: center;
    align-items: flex-end;
    margin-bottom: 20px;
}
.hero-berry {
    animation: heroFloat 3s ease-in-out infinite;
}
.berry-left {
    width: 56px;
    transform: rotate(-8deg);
    margin-right: -8px;
}
.berry-center {
    width: 72px;
    animation-delay: 0.3s;
    z-index: 1;
    filter: drop-shadow(0 8px 20px rgba(53,132,228,0.3));
}
.berry-right {
    width: 56px;
    transform: rotate(8deg);
    animation-delay: 0.6s;
    margin-left: -8px;
}

h1 {
    font-family: 'Fraunces', serif;
    font-size: clamp(3.5rem, 8vw, 5.5rem);
    font-weight: 900;
    line-height: 1;
    margin-bottom: 20px;
    letter-spacing: -0.03em;
}
.hero-tagline {
    font-size: clamp(1rem, 2.2vw, 1.2rem);
    color: var(--text-muted);
    margin-bottom: 36px;
    max-width: 440px;
    margin-left: auto;
    margin-right: auto;
    line-height: 1.8;
}

/* ---- Showcase ---- */
.showcase { padding: 20px 0 80px; }
.phone-row {
    display: flex;
    justify-content: center;
    align-items: flex-end;
    gap: clamp(6px, 2vw, 28px);
    flex-wrap: nowrap;
}

/* ---- Section typography ---- */
h2 {
    font-family: 'Fraunces', serif;
    font-size: clamp(1.8rem, 4.5vw, 2.8rem);
    font-weight: 800;
    margin-bottom: 16px;
    letter-spacing: -0.02em;
}
.section-sub {
    color: var(--text-muted);
    font-size: 1.05rem;
    margin-bottom: 48px;
    max-width: 540px;
    margin-left: auto;
    margin-right: auto;
    line-height: 1.7;
}

/* ---- Rules ---- */
.rules-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
}
.rule-card {
    background: var(--bg-card);
    border: 1px solid rgba(255,255,255,0.06);
    border-radius: var(--radius);
    padding: 32px 24px;
    text-align: center;
    transition: all 0.3s ease;
}
.rule-card:hover {
    background: rgba(255,255,255,0.09);
    transform: translateY(-3px);
    border-color: rgba(53,132,228,0.2);
}
.rule-card h3 {
    font-family: 'Fraunces', serif;
    font-size: 1.1rem;
    font-weight: 700;
    margin-bottom: 8px;
}
.rule-card p {
    color: var(--text-muted);
    font-size: 0.9rem;
    line-height: 1.7;
}

/* ---- Features ---- */
.features-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
    text-align: left;
}
.feature-card h3 {
    font-family: 'Fraunces', serif;
    font-size: 1.15rem;
    font-weight: 700;
    margin-bottom: 6px;
}
.feature-card p {
    color: var(--text-muted);
    font-size: 0.92rem;
    line-height: 1.7;
}

/* ---- Pro ---- */
.pro-section {
    padding: 100px 0;
    border-top: 1px solid rgba(255,255,255,0.04);
}
.pro-badge {
    display: inline-block;
    padding: 5px 18px;
    background: linear-gradient(135deg, var(--berry), var(--berry-glow));
    border-radius: 50px;
    font-size: 0.8rem;
    font-weight: 700;
    letter-spacing: 0.12em;
    margin-bottom: 20px;
}
.pro-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 20px;
    text-align: left;
    margin-bottom: 48px;
}
.pro-card {
    background: rgba(53, 132, 228, 0.06);
    border: 1px solid rgba(53, 132, 228, 0.12);
    border-radius: var(--radius);
    padding: 28px 24px;
    transition: all 0.3s ease;
}
.pro-card:hover {
    background: rgba(53, 132, 228, 0.12);
    transform: translateY(-3px);
    border-color: rgba(53, 132, 228, 0.25);
}
.pro-icon {
    width: 44px; height: 44px;
    background: rgba(53, 132, 228, 0.15);
    border-radius: 12px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 16px;
    font-size: 1.3rem;
}
.pro-card h3 {
    font-family: 'Fraunces', serif;
    font-size: 1.15rem;
    font-weight: 700;
    margin-bottom: 6px;
}
.pro-card p {
    color: var(--text-muted);
    font-size: 0.92rem;
    line-height: 1.7;
}
.pro-price {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
}
.price {
    font-family: 'Fraunces', serif;
    font-size: 2.5rem;
    font-weight: 900;
    background: linear-gradient(135deg, var(--text), var(--berry-glow));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
}
.price-note {
    color: var(--text-muted);
    font-size: 0.95rem;
}

/* ---- CTA ---- */
.cta-section {
    padding: 100px 0;
    border-top: 1px solid rgba(255,255,255,0.04);
}
.cta-section h2 { font-size: clamp(2rem, 5vw, 3rem); }
.cta-section p {
    color: var(--text-muted);
    font-size: 1.05rem;
    margin-bottom: 36px;
}
.cta-berries {
    display: flex;
    justify-content: center;
    align-items: flex-end;
    gap: 2px;
    margin-bottom: 24px;
}
.cta-berry { width: 32px; opacity: 0.6; }
.cta-berry-center { width: 40px; opacity: 0.9; }

/* ---- Responsive ---- */
@media (max-width: 900px) {
    .features-grid,
    .pro-grid { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 640px) {
    .rules-grid,
    .features-grid,
    .pro-grid { grid-template-columns: 1fr; }
    .rules-grid { max-width: 340px; margin: 0 auto; }
}
</style>
