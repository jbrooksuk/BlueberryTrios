<template>
    <nav>
        <div class="container nav-inner">
            <NuxtLink to="/" class="nav-brand">
                <img v-if="activeTheme === 'default'" src="/berry-happy.svg" alt="" class="nav-mark nav-berry" />
                <span v-else class="nav-mark nav-seasonal" aria-hidden="true">{{ activeSeason?.symbol }}</span>
                Berroku
            </NuxtLink>
            <div class="nav-actions">
                <button
                    v-if="activeSeason"
                    type="button"
                    class="theme-toggle"
                    :aria-label="`${activeSeason.name} theme`"
                    :aria-pressed="activeTheme === activeSeason.id"
                    @click="toggleTheme"
                >
                    <span aria-hidden="true">{{ activeSeason.symbol }}</span>
                    <span class="theme-name">{{ activeSeason.name }}</span>
                </button>
                <a href="https://apps.apple.com/us/app/berroku/id6761375301" class="btn-nav">
                    <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                    Download
                </a>
            </div>
        </div>
    </nav>
</template>

<script setup>
const { activeSeason, activeTheme, selectTheme } = useSeasonalTheme()

function toggleTheme() {
    selectTheme(activeTheme.value === 'default' ? activeSeason.value?.id : 'default')
}
</script>

<style scoped>
nav {
    position: fixed;
    top: 0; left: 0; right: 0;
    z-index: 100;
    padding: 16px 24px;
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    background: var(--nav-background);
    border-bottom: 1px solid rgba(255,255,255,0.06);
}
.nav-inner {
    display: flex;
    justify-content: space-between;
    align-items: center;
}
.nav-brand {
    font-family: 'Fraunces', serif;
    font-size: 1.4rem;
    color: var(--text);
    text-decoration: none;
    display: flex;
    align-items: center;
    gap: 8px;
}
.nav-mark {
    width: 32px;
    height: 32px;
}
.nav-seasonal {
    display: grid;
    place-items: center;
    font-family: sans-serif;
    font-size: 1.65rem;
    line-height: 1;
}
.nav-actions {
    display: flex;
    align-items: center;
}
.nav-actions { gap: 12px; }
.theme-toggle {
    min-height: 42px;
    padding: 0 12px;
    display: inline-flex;
    align-items: center;
    gap: 7px;
    background: var(--surface-raised);
    border: 1px solid var(--border);
    border-radius: 12px;
    color: var(--text-muted);
    cursor: pointer;
    font: inherit;
    font-size: 0.82rem;
    font-weight: 650;
    transition: background 180ms ease, border-color 180ms ease, color 180ms ease;
}
.theme-toggle[aria-pressed="true"] {
    background: var(--berry);
    border-color: var(--berry);
    color: var(--button-text);
}
.theme-toggle:focus-visible {
    outline: 2px solid var(--berry-glow);
    outline-offset: 2px;
}

@media (max-width: 640px) {
    nav { padding-inline: 16px; }
    .nav-actions { gap: 8px; }
    .theme-name { display: none; }
    .theme-toggle {
        min-width: 42px;
        padding: 0 8px;
        justify-content: center;
    }
    .btn-nav {
        padding-inline: 12px;
    }
    .btn-nav svg { display: none; }
}
</style>
