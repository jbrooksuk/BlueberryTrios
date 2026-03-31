<template>
    <main class="legal">
        <div class="container" style="max-width: 720px; padding-top: 100px; padding-bottom: 80px;">
            <h1>Privacy Policy</h1>
            <p class="date">Effective date: 30 March 2026</p>

            <h2>Overview</h2>
            <p>Berroku ("the App") is a puzzle game developed by James Brooks. Your privacy is important to us. This policy explains what information the App collects and how it is used.</p>

            <h2>Data We Collect</h2>
            <p>Berroku does not collect, store, or transmit any personal data. All gameplay data — including puzzle progress, statistics, streaks, and settings — is stored locally on your device and is never sent to any server.</p>

            <h2>Game Center</h2>
            <p>The App integrates with Apple's Game Center for achievements and leaderboards. Game Center is operated by Apple and governed by <a href="https://www.apple.com/legal/privacy/" target="_blank" rel="noopener">Apple's Privacy Policy</a>. We do not have access to your Game Center data beyond what Apple provides through their standard APIs.</p>

            <h2>In-App Purchases</h2>
            <p>The App offers an optional in-app purchase ("Pro Puzzles") processed entirely by Apple through the App Store. We do not collect or have access to any payment information.</p>

            <h2>Analytics</h2>
            <p>Berroku does not include any third-party analytics, tracking, or advertising SDKs.</p>

            <h2>Children's Privacy</h2>
            <p>The App does not knowingly collect personal information from children. Since we do not collect any personal data from any user, there is no data to collect from children.</p>

            <h2>Data Storage</h2>
            <p>All data is stored on-device using Apple's standard frameworks (SwiftData and UserDefaults). If you delete the App, all associated data is removed from your device.</p>

            <h2>Changes to This Policy</h2>
            <p>We may update this privacy policy from time to time. Any changes will be reflected on this page with an updated effective date.</p>

            <h2>Contact</h2>
            <p>If you have any questions about this privacy policy, please contact us at <a href="mailto:hello@jbrooks.uk">hello@jbrooks.uk</a>.</p>
        </div>
    </main>
</template>

<script setup>
useHead({
    title: 'Privacy Policy — Berroku',
    meta: [
        { name: 'description', content: 'Berroku privacy policy. We do not collect, store, or transmit any personal data. All gameplay data is stored locally on your device.' },
        { property: 'og:title', content: 'Privacy Policy — Berroku' },
        { property: 'og:description', content: 'Berroku privacy policy. We do not collect, store, or transmit any personal data.' },
        { name: 'robots', content: 'index, follow' },
    ],
    link: [
        { rel: 'canonical', href: 'https://berroku.com/privacy' },
    ],
})
</script>
