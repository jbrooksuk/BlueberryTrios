<template>
    <div>
        <!-- Atmosphere -->
        <div class="atmosphere">
            <div v-for="i in 6" :key="i" class="berry-float" />
        </div>

        <!-- Hero -->
        <section class="hero">
            <div class="container" style="text-align: center;">
                <div class="hero-berries">
                    <img src="/berry-smile.svg" alt="" class="hero-berry berry-left" />
                    <img src="/berry-happy.svg" alt="" class="hero-berry berry-center" />
                    <img src="/berry-wink.svg" alt="" class="hero-berry berry-right" />
                </div>
                <h1>Berroku</h1>
                <p class="hero-tagline">Place 3 berries in every row, column &amp; block. A fresh logic puzzle that's delightfully addictive.</p>
                <a href="https://apps.apple.com/us/app/berroku/id6761375301" class="btn-primary">
                    <AppleIcon />
                    Download on the App Store
                </a>
            </div>
        </section>

        <!-- Phone Showcase -->
        <section class="showcase">
            <div class="container">
                <div class="phone-row">
                    <div class="phone-frame side">
                        <img :src="'/screenshots/home-dark.png'" alt="Berroku dark mode" loading="lazy">
                    </div>
                    <div class="phone-frame hero-phone">
                        <img :src="'/screenshots/home-light.png'" alt="Berroku home screen" loading="lazy">
                    </div>
                    <div class="phone-frame side">
                        <img :src="'/screenshots/puzzle-gameplay.png'" alt="Berroku puzzle gameplay" loading="lazy">
                    </div>
                </div>
            </div>
        </section>

        <!-- How It Works -->
        <section class="how-it-works">
            <div class="container" style="text-align: center;">
                <h2>Simple rules, deep logic</h2>
                <p class="section-sub">Berroku is a berry-themed logic puzzle inspired by Sudoku. Easy to learn, endlessly satisfying.</p>
                <div class="rules">
                    <div v-for="rule in rules" :key="rule.title" class="rule">
                        <div class="rule-number">{{ rule.number }}</div>
                        <h3>{{ rule.title }}</h3>
                        <p>{{ rule.desc }}</p>
                    </div>
                </div>
            </div>
        </section>

        <!-- Features -->
        <section class="features">
            <div class="container" style="text-align: center;">
                <h2>Everything you need</h2>
                <p class="section-sub">Packed with features to keep you puzzling every day.</p>
                <div class="features-grid">
                    <div v-for="feature in features" :key="feature.title" class="feature-card">
                        <div class="feature-icon">{{ feature.icon }}</div>
                        <h3>{{ feature.title }}</h3>
                        <p>{{ feature.desc }}</p>
                    </div>
                </div>
            </div>
        </section>

        <!-- Pro Puzzles -->
        <section class="pro-section">
            <div class="container" style="text-align: center;">
                <div class="pro-badge">PRO</div>
                <h2>Never run out of puzzles</h2>
                <p class="section-sub">Go beyond the daily challenge. Pro Puzzles gives you unlimited access to our full library of hand-crafted puzzles.</p>
                <div class="pro-grid">
                    <div v-for="perk in proPerks" :key="perk.title" class="pro-card">
                        <div class="pro-icon">{{ perk.icon }}</div>
                        <h3>{{ perk.title }}</h3>
                        <p>{{ perk.desc }}</p>
                    </div>
                </div>
                <div class="pro-price">
                    <span class="price">$1.99</span>
                    <span class="price-note">One-time purchase. No subscriptions.</span>
                </div>
            </div>
        </section>

        <!-- CTA -->
        <section id="download" class="cta-section">
            <div class="container" style="text-align: center;">
                <h2>Ready to pick some berries?</h2>
                <p>Free to play. New puzzles every day.</p>
                <a href="https://apps.apple.com/us/app/berroku/id6761375301" class="btn-primary">
                    <AppleIcon />
                    Download on the App Store
                </a>
            </div>
        </section>
    </div>
</template>

<script setup>
const rules = [
    { number: '3', title: 'Three per row', desc: 'Place exactly 3 berries in every row of the 9×9 grid.' },
    { number: '3', title: 'Three per column', desc: 'Every column must also contain exactly 3 berries.' },
    { number: '?', title: 'Follow the clues', desc: 'Numbers tell you how many of the 8 surrounding cells contain berries.' },
]

const proPerks = [
    { icon: '♾️', title: 'Unlimited Puzzles', desc: 'Access our full library of 3,300+ puzzles across all three difficulty levels.' },
    { icon: '⚡', title: 'Play on Your Schedule', desc: 'No waiting for the next daily puzzle. Start a new challenge whenever you want.' },
    { icon: '📈', title: 'All Difficulties', desc: 'Standard, Advanced, and Expert puzzles available from the start.' },
]

const features = [
    { icon: '📅', title: 'Daily Puzzles', desc: 'Three new puzzles every day. Come back tomorrow for a fresh challenge.' },
    { icon: '🎯', title: '3 Difficulties', desc: 'Standard, Advanced, and Expert. Work your way up as your skills sharpen.' },
    { icon: '♾️', title: 'Pro Mode', desc: 'Unlock unlimited puzzle sets beyond the daily rotation. Never run out.' },
    { icon: '🏆', title: 'Achievements', desc: 'Game Center integration with 12 achievements and a fastest-time leaderboard.' },
    { icon: '🔥', title: 'Streak Tracking', desc: 'Build your daily streak. How many consecutive days can you solve?' },
    { icon: '📱', title: 'Home Screen Widget', desc: 'Track your daily progress and streak right from your home screen.' },
]
</script>

<style scoped>
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
    background: radial-gradient(circle, rgba(47,206,81,0.08) 0%, transparent 70%);
    border-radius: 50%;
}

section { position: relative; z-index: 1; padding: 80px 0; }

.hero {
    padding-top: 140px;
    padding-bottom: 60px;
}
.hero-berries {
    display: flex;
    justify-content: center;
    align-items: flex-end;
    gap: 0;
    margin-bottom: 24px;
}
.hero-berry {
    background: none;
    border-radius: 0;
    box-shadow: none;
    animation: heroFloat 3s ease-in-out infinite;
    width: auto;
    height: auto;
}
.hero-berry::before, .hero-berry::after { display: none; }
.berry-left {
    width: 56px;
    transform: rotate(-8deg);
    animation-delay: 0s;
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
    font-family: 'DM Serif Display', serif;
    font-size: clamp(3.5rem, 8vw, 6rem);
    line-height: 1;
    margin-bottom: 16px;
    letter-spacing: -0.02em;
}
.hero-tagline {
    font-size: clamp(1.1rem, 2.5vw, 1.4rem);
    color: var(--text-muted);
    margin-bottom: 40px;
    max-width: 500px;
    margin-left: auto;
    margin-right: auto;
}

.showcase { padding: 40px 0 80px; }
.phone-row {
    display: flex;
    justify-content: center;
    align-items: flex-end;
    gap: clamp(16px, 4vw, 40px);
}

.how-it-works h2, .features h2, .cta-section h2 {
    font-family: 'DM Serif Display', serif;
    font-size: clamp(2rem, 5vw, 3rem);
    margin-bottom: 16px;
}
.section-sub {
    color: var(--text-muted);
    font-size: 1.1rem;
    margin-bottom: 60px;
    max-width: 600px;
    margin-left: auto;
    margin-right: auto;
}

.rules {
    display: flex;
    justify-content: center;
    gap: 40px;
    flex-wrap: wrap;
}
.rule { max-width: 260px; }
.rule h3 {
    font-family: 'DM Serif Display', serif;
    font-size: 1.15rem;
    margin-bottom: 8px;
}
.rule p { color: var(--text-muted); font-size: 0.9rem; line-height: 1.6; }

.features-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 20px;
    text-align: left;
}
.feature-card h3 {
    font-family: 'DM Serif Display', serif;
    font-size: 1.25rem;
    margin-bottom: 8px;
}
.feature-card p { color: var(--text-muted); font-size: 0.95rem; line-height: 1.6; }

/* ---- Pro Section ---- */
.pro-section { padding: 100px 0; }
.pro-section h2 {
    font-family: 'DM Serif Display', serif;
    font-size: clamp(2rem, 5vw, 3rem);
    margin-bottom: 16px;
}
.pro-badge {
    display: inline-block;
    padding: 6px 20px;
    background: linear-gradient(135deg, var(--berry), var(--berry-glow));
    border-radius: 50px;
    font-size: 0.85rem;
    font-weight: 700;
    letter-spacing: 0.1em;
    margin-bottom: 20px;
}
.pro-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 20px;
    text-align: left;
    margin-bottom: 48px;
}
.pro-card {
    background: rgba(53, 132, 228, 0.08);
    border: 1px solid rgba(53, 132, 228, 0.15);
    border-radius: var(--radius);
    padding: 32px 28px;
    transition: all 0.3s ease;
    backdrop-filter: blur(10px);
}
.pro-card:hover {
    background: rgba(53, 132, 228, 0.14);
    transform: translateY(-4px);
    border-color: rgba(53, 132, 228, 0.3);
}
.pro-icon {
    width: 48px; height: 48px;
    background: rgba(53, 132, 228, 0.2);
    border-radius: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    margin-bottom: 20px;
    font-size: 1.4rem;
}
.pro-card h3 {
    font-family: 'DM Serif Display', serif;
    font-size: 1.25rem;
    margin-bottom: 8px;
}
.pro-card p { color: var(--text-muted); font-size: 0.95rem; line-height: 1.6; }
.pro-price {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
}
.price {
    font-family: 'DM Serif Display', serif;
    font-size: 2.5rem;
}
.price-note {
    color: var(--text-muted);
    font-size: 1rem;
}

.cta-section { padding: 100px 0; }
.cta-section p { color: var(--text-muted); font-size: 1.1rem; margin-bottom: 36px; }

@media (max-width: 768px) {
    .rules { flex-direction: column; align-items: center; }
    .features-grid { grid-template-columns: 1fr; }
    .pro-grid { grid-template-columns: 1fr; }
}
</style>
