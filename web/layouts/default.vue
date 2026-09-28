<template>
    <div :data-theme="activeTheme" class="site-shell">
        <SiteNav />
        <slot />
        <SiteFooter />
    </div>
</template>

<script setup>
const { activeTheme } = useSeasonalTheme(true)
</script>
