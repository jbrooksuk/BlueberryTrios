<template>
    <footer>
        <div class="container">
            <p>&copy; 2026 Berroku. Made with berries by <a href="https://x.com/jbrooksuk">James Brooks</a>.</p>
            <p class="legal-links">
                <NuxtLink to="/privacy">Privacy Policy</NuxtLink>
                <span>&middot;</span>
                <NuxtLink to="/terms">Terms of Use</NuxtLink>
            </p>
        </div>
    </footer>
</template>

<style scoped>
footer {
    border-top: 1px solid rgba(255,255,255,0.06);
    padding: 32px 0;
    text-align: center;
    color: var(--text-muted);
    font-size: 0.85rem;
}
.legal-links { margin-top: 8px; }
.legal-links span { margin: 0 4px; }
</style>
