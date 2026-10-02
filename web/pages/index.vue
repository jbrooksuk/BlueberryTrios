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
                    <img v-if="activeTheme === 'default'" src="/berry-cluster.svg" alt="" class="hero-cluster" />
                    <div v-else class="seasonal-cluster" aria-hidden="true">
                        <span>{{ activeSeason?.symbol }}</span>
                        <span>{{ activeSeason?.symbol }}</span>
                        <span>{{ activeSeason?.symbol }}</span>
                    </div>
                </div>
                <h1 class="fade-up">Berroku</h1>
                <p class="hero-tagline fade-up">Place 3 {{ markerPlural }} in every row, column &amp; block.<br>A fresh logic puzzle that's delightfully addictive.</p>
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
                        <img :src="'/screenshots/puzzle-gameplay.png'" alt="Berroku puzzle gameplay" loading="lazy">
                    </div>
                    <div class="phone-frame hero-phone fade-up">
                        <img :src="'/screenshots/home.png'" alt="Berroku home screen" loading="lazy">
                    </div>
                    <div class="phone-frame side fade-up" style="transition-delay: 0.2s;">
                        <img :src="'/screenshots/puzzle.png'" alt="Berroku puzzle screen" loading="lazy">
                    </div>
                </div>
            </div>
        </section>

        <!-- How it works -->
        <section class="how-it-works">
            <div class="container section-center">
                <h2 class="fade-up">Simple rules, deep logic</h2>
                <p class="section-sub fade-up">A Berroku logic puzzle inspired by Sudoku. Easy to learn, endlessly satisfying.</p>
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
                    <img v-if="activeTheme === 'default'" src="/berry-cluster.svg" alt="" class="cta-cluster" />
                    <span v-else class="cta-seasonal-mark" aria-hidden="true">{{ activeSeason?.symbol }}</span>
                </div>
                <h2 class="fade-up">Ready for today’s Berroku?</h2>
                <p class="fade-up">Free to play. New puzzles every day.</p>
                <a href="https://apps.apple.com/us/app/berroku/id6761375301" class="btn-primary fade-up">
                    <AppleIcon />
                    Download on the App Store
                </a>
            </div>
        </section>

        <!-- Other games -->
        <section class="other-games">
            <div class="container">
                <div class="other-games-heading fade-up">
                    <h2>Other games.</h2>
                </div>

                <a
                    class="shapoku-card fade-up"
                    href="https://shapoku.com"
                    target="_blank"
                    rel="noopener"
                    aria-label="Discover Shapoku (opens in a new tab)"
                >
                    <div class="shapoku-art" aria-hidden="true">
                        <div class="shapoku-piece shapoku-piece-honey">
                            <i /><i /><i /><i />
                        </div>
                        <div class="shapoku-board">
                            <i
                                v-for="cell in 81"
                                :key="cell"
                                class="shapoku-cell"
                                :class="shapokuCellClass(cell - 1)"
                            />
                        </div>
                        <div class="shapoku-piece shapoku-piece-blue">
                            <i /><i /><i /><i />
                        </div>
                    </div>

                    <div class="shapoku-copy">
                        <span class="shapoku-eyebrow">A block puzzle for iPhone</span>
                        <h3>Shapoku</h3>
                        <p>Place sets of three blocks on a 9×9 grid. Complete rows, columns, and 3×3 regions to clear them and beat your best score.</p>
                        <strong>Discover Shapoku <b aria-hidden="true">↗</b></strong>
                    </div>
                </a>
            </div>
        </section>
    </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'

const { activeSeason, activeTheme } = useSeasonalTheme()
const markerPlural = computed(() => activeTheme.value === 'default' ? 'berries' : activeSeason.value?.markers ?? 'berries')

const rules = computed(() => [
    { number: '3', title: 'Three per row', desc: `Place exactly 3 ${markerPlural.value} in every row of the 9×9 grid.` },
    { number: '3', title: 'Three per column', desc: `Every column must also contain exactly 3 ${markerPlural.value}.` },
    { number: '?', title: 'Follow the clues', desc: `Numbers tell you how many of the 8 surrounding cells contain ${markerPlural.value}.` },
])

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

const shapokuCells = {
    green: new Set([0, 1, 9]),
    red: new Set([4, 5, 6, 15]),
    orange: new Set([20, 21, 30, 39]),
    yellow: new Set([34, 43, 52, 53]),
    blue: new Set([54, 55, 64, 73]),
    purple: new Set([67, 68, 77, 78]),
}

function shapokuCellClass(index) {
    const color = Object.entries(shapokuCells).find(([, cells]) => cells.has(index))?.[0]
    return color ? `shapoku-cell-${color}` : ''
}

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
    background: radial-gradient(circle, var(--atmosphere-primary) 0%, transparent 70%);
    border-radius: 50%;
}
.atmosphere::after {
    content: '';
    position: absolute;
    width: 600px; height: 600px;
    bottom: 10%; right: -100px;
    background: radial-gradient(circle, var(--atmosphere-secondary) 0%, transparent 70%);
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
    align-items: center;
    height: clamp(120px, 18.67vw, 160px);
    margin-bottom: 20px;
}
.hero-cluster {
    width: clamp(180px, 28vw, 240px);
    aspect-ratio: 3 / 2;
    height: auto;
    animation: heroFloat 3s ease-in-out infinite;
    filter: drop-shadow(0 10px 22px var(--accent-shadow));
}
.seasonal-cluster {
    position: relative;
    width: clamp(180px, 28vw, 240px);
    aspect-ratio: 3 / 2;
    filter: drop-shadow(0 10px 22px var(--accent-shadow));
}
.seasonal-cluster span {
    position: absolute;
    line-height: 1;
    transform: var(--symbol-transform);
    animation: seasonalFloat 3.2s ease-in-out infinite;
}
.seasonal-cluster span:nth-child(1) {
    left: 4%;
    bottom: 4%;
    font-size: clamp(4rem, 9vw, 5.6rem);
    --symbol-transform: rotate(-8deg);
    animation-delay: -0.5s;
}
.seasonal-cluster span:nth-child(2) {
    right: 3%;
    bottom: 6%;
    font-size: clamp(3.8rem, 8.5vw, 5.2rem);
    --symbol-transform: rotate(8deg);
    animation-delay: -1.2s;
}
.seasonal-cluster span:nth-child(3) {
    left: 50%;
    top: 2%;
    z-index: 1;
    font-size: clamp(5rem, 11.5vw, 6.8rem);
    --symbol-transform: translateX(-50%);
}
@keyframes seasonalFloat {
    0%, 100% { transform: var(--symbol-transform) translateY(0); }
    50% { transform: var(--symbol-transform) translateY(-8px); }
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
    max-width: 1000px;
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
    gap: clamp(12px, 3vw, 28px);
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
    border-color: var(--accent-border);
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
    background: var(--accent-surface);
    border: 1px solid var(--accent-border);
    border-radius: var(--radius);
    padding: 28px 24px;
    transition: all 0.3s ease;
}
.pro-card:hover {
    background: var(--accent-surface-hover);
    transform: translateY(-3px);
    border-color: var(--accent-border-strong);
}
.pro-icon {
    width: 44px; height: 44px;
    background: var(--accent-surface-strong);
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
    color: var(--berry-glow);
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
.cta-cluster {
    width: clamp(120px, 22vw, 160px);
    height: auto;
    opacity: 0.9;
}
.cta-seasonal-mark {
    font-size: clamp(5rem, 16vw, 7rem);
    line-height: 1;
    filter: drop-shadow(0 8px 18px var(--accent-shadow));
}

/* ---- Other games ---- */
.other-games {
    padding: 100px 0 120px;
    border-top: 1px solid rgba(255,255,255,0.04);
}
.other-games-heading {
    margin-bottom: 40px;
}
.other-games-heading h2 { margin-bottom: 0; }
.shapoku-card {
    display: grid;
    grid-template-columns: 1fr 1fr;
    min-height: 500px;
    color: #faf4e8;
    background: #241b2d;
    border: 1px solid rgba(255,255,255,0.08);
    border-radius: 32px;
    overflow: hidden;
    box-shadow: 0 30px 70px rgba(0,0,0,0.25);
    transition: transform 220ms ease, box-shadow 220ms ease, border-color 220ms ease;
}
.shapoku-art {
    position: relative;
    display: grid;
    place-items: center;
    min-width: 0;
    overflow: hidden;
    background: #f2e8d6;
    background-image:
        radial-gradient(circle at 50% 48%, rgba(255,255,255,0.58) 0 25%, transparent 58%),
        repeating-linear-gradient(0deg, rgba(105,75,50,0.025) 0 1px, transparent 1px 5px);
}
.shapoku-art::before,
.shapoku-art::after {
    content: '';
    position: absolute;
    border: 1px solid rgba(102,75,50,0.10);
    border-radius: 50%;
}
.shapoku-art::before { width: 430px; height: 430px; }
.shapoku-art::after { width: 350px; height: 350px; }
.shapoku-board {
    position: relative;
    z-index: 1;
    display: grid;
    grid-template-columns: repeat(9, 1fr);
    width: min(68%, 330px);
    aspect-ratio: 1;
    padding: 12px;
    gap: 4px;
    border-radius: 16px;
    background: #9fa797;
    box-shadow: 0 22px 35px rgba(77,82,70,0.26), inset 0 1px 0 rgba(255,255,255,0.3);
    transform: rotate(-4deg);
}
.shapoku-cell {
    border-radius: 4px;
    background: #bec2b3;
    box-shadow: inset 0 1px 1px rgba(255,255,255,0.3), inset 0 -1px 1px rgba(77,82,70,0.12);
}
.shapoku-cell-green,
.shapoku-cell-red,
.shapoku-cell-orange,
.shapoku-cell-yellow,
.shapoku-cell-blue,
.shapoku-cell-purple {
    border: 1px solid rgba(255,255,255,0.16);
    box-shadow: inset 0 2px 2px rgba(255,255,255,0.24), 0 2px 3px rgba(54,34,24,0.22);
}
.shapoku-cell-green { background: #20a950; }
.shapoku-cell-red { background: #ef4935; }
.shapoku-cell-orange { background: #f78b10; }
.shapoku-cell-yellow { background: #f9bd24; }
.shapoku-cell-blue { background: #2d8dc5; }
.shapoku-cell-purple { background: #ad3fa5; }
.shapoku-piece {
    position: absolute;
    z-index: 2;
    display: grid;
    gap: 4px;
    filter: drop-shadow(0 8px 8px rgba(72,47,31,0.2));
}
.shapoku-piece i {
    width: 28px;
    aspect-ratio: 1;
    border-radius: 5px;
    border: 1px solid rgba(255,255,255,0.2);
    box-shadow: inset 0 2px 2px rgba(255,255,255,0.25);
}
.shapoku-piece-honey {
    top: 10%;
    left: 8%;
    grid-template-columns: repeat(2, 1fr);
    transform: rotate(11deg);
}
.shapoku-piece-honey i { background: #f78b10; }
.shapoku-piece-blue {
    right: 8%;
    bottom: 11%;
    grid-template-columns: repeat(4, 1fr);
    transform: rotate(-9deg);
}
.shapoku-piece-blue i { background: #ad3fa5; }
.shapoku-copy {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: flex-start;
    padding: clamp(40px, 6vw, 64px);
}
.shapoku-eyebrow {
    margin-bottom: 20px;
    color: #d9b15c;
    font-size: 0.75rem;
    font-weight: 700;
    letter-spacing: 0.12em;
    text-transform: uppercase;
}
.shapoku-card h3 {
    margin-bottom: 22px;
    color: #faf4e8;
    font-family: ui-rounded, "SF Pro Rounded", "Avenir Next", Avenir, system-ui, sans-serif;
    font-size: clamp(3.3rem, 6vw, 5rem);
    font-weight: 900;
    letter-spacing: -0.055em;
    line-height: 0.95;
}
.shapoku-card p {
    max-width: 460px;
    color: #cfc2ce;
    font-size: 1rem;
    line-height: 1.75;
}
.shapoku-card strong {
    margin-top: 34px;
    padding-bottom: 5px;
    color: #f0ce79;
    border-bottom: 1px solid #9675a2;
    font-size: 0.85rem;
}
.shapoku-card strong b { margin-left: 8px; }
.shapoku-card:focus-visible {
    outline: 3px solid var(--berry-glow);
    outline-offset: 5px;
}
@media (hover: hover) {
    .shapoku-card:hover {
        color: #faf4e8;
        border-color: rgba(240,206,121,0.3);
        transform: translateY(-4px);
        box-shadow: 0 36px 80px rgba(0,0,0,0.32);
    }
}

/* ---- Responsive ---- */
@media (max-width: 900px) {
    .features-grid,
    .pro-grid { grid-template-columns: repeat(2, 1fr); }

    .shapoku-card { grid-template-columns: 1fr; }
    .shapoku-art { min-height: 430px; }
}
@media (max-width: 640px) {
    .rules-grid,
    .features-grid,
    .pro-grid { grid-template-columns: 1fr; }
    .rules-grid { max-width: 340px; margin: 0 auto; }

    .other-games { padding: 72px 0 80px; }
    .other-games-heading {
        margin-bottom: 28px;
    }
    .shapoku-card { border-radius: 24px; }
    .shapoku-art { min-height: 330px; }
    .shapoku-board {
        width: min(70%, 250px);
        padding: 9px;
        gap: 3px;
        border-radius: 13px;
    }
    .shapoku-piece i { width: 19px; border-radius: 4px; }
    .shapoku-copy { padding: 36px 28px 42px; }
    .shapoku-eyebrow { margin-bottom: 16px; }
    .shapoku-card h3 { font-size: 3.4rem; }
    .shapoku-card p { font-size: 0.95rem; }
}

@media (prefers-reduced-motion: reduce) {
    .hero-cluster,
    .seasonal-cluster span { animation: none; }
    .shapoku-card { transition: none; }
}
</style>
