<template>
    <main class="legal">
        <div class="container" style="max-width: 720px; padding-top: 100px; padding-bottom: 80px;">
            <h1>Terms of Use</h1>
            <p class="date">Effective date: 30 March 2026</p>

            <h2>Acceptance of Terms</h2>
            <p>By downloading, installing, or using Berroku ("the App"), you agree to these Terms of Use. If you do not agree, please do not use the App.</p>

            <h2>Description of Service</h2>
            <p>Berroku is a logic puzzle game available for iOS. The App provides daily puzzles and optional additional puzzle sets through an in-app purchase.</p>

            <h2>Use of the App</h2>
            <p>You may use the App for personal, non-commercial purposes. You agree not to:</p>
            <ul>
                <li>Reverse engineer, decompile, or disassemble the App</li>
                <li>Reproduce, redistribute, or create derivative works from the App</li>
                <li>Use the App for any unlawful purpose</li>
            </ul>

            <h2>In-App Purchases</h2>
            <p>The App offers an optional "Pro Puzzles" in-app purchase. All purchases are processed by Apple and subject to the <a href="https://www.apple.com/legal/internet-services/itunes/" target="_blank" rel="noopener">Apple Media Services Terms and Conditions</a>. All sales are final, except as required by applicable law or Apple's refund policies.</p>

            <h2>Intellectual Property</h2>
            <p>The App, including its design, code, puzzles, and artwork, is the property of James Brooks and is protected by copyright and other intellectual property laws. The puzzle format is inspired by publicly available logic puzzle designs.</p>

            <h2>Game Center</h2>
            <p>The App uses Apple's Game Center for achievements and leaderboards. Your use of Game Center is subject to Apple's terms and conditions.</p>

            <h2>Disclaimer of Warranties</h2>
            <p>The App is provided "as is" without warranty of any kind, express or implied. We do not guarantee that the App will be error-free, uninterrupted, or free of defects.</p>

            <h2>Limitation of Liability</h2>
            <p>To the fullest extent permitted by applicable law, James Brooks shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App.</p>

            <h2>Changes to These Terms</h2>
            <p>We may update these terms from time to time. Continued use of the App after changes constitutes acceptance of the revised terms.</p>

            <h2>Contact</h2>
            <p>If you have any questions about these terms, please contact us at <a href="mailto:hello@jbrooks.uk">hello@jbrooks.uk</a>.</p>
        </div>
    </main>
</template>

<script setup>
useHead({
    title: 'Terms of Use — Berroku',
    meta: [
        { name: 'description', content: 'Berroku terms of use. By downloading, installing, or using Berroku, you agree to these terms.' },
        { property: 'og:title', content: 'Terms of Use — Berroku' },
        { property: 'og:description', content: 'Berroku terms of use. By downloading, installing, or using Berroku, you agree to these terms.' },
        { name: 'robots', content: 'index, follow' },
    ],
    link: [
        { rel: 'canonical', href: 'https://berroku.com/terms' },
    ],
})
</script>
