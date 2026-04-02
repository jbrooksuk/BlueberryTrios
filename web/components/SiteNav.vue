<template>
    <nav>
        <div class="container nav-inner">
            <NuxtLink to="/" class="nav-brand">
                <img src="/berry-happy.svg" alt="" class="nav-berry" />
                Berroku
            </NuxtLink>
            <a href="https://apps.apple.com/us/app/berroku/id6761375301" class="btn-nav">
                <svg viewBox="0 0 24 24" fill="currentColor" width="18" height="18"><path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/></svg>
                Download
            </a>
        </div>
    </nav>
</template>

<style scoped>
nav {
    position: fixed;
    top: 0; left: 0; right: 0;
    z-index: 100;
    padding: 16px 24px;
    backdrop-filter: blur(20px);
    -webkit-backdrop-filter: blur(20px);
    background: rgba(11,22,40,0.7);
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
.nav-berry {
    width: 32px;
    height: 32px;
}
</style>
