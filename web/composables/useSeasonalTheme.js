import { getActiveSeason, resolveSeasonalTheme, themeStorageKey } from '~/utils/seasonal-theme.mjs'

export function useSeasonalTheme(initialize = false) {
    const requestURL = useRequestURL()
    const preference = useCookie(themeStorageKey, {
        maxAge: 60 * 60 * 24 * 365,
        sameSite: 'lax',
    })
    const initialTheme = resolveSeasonalTheme(preference.value ?? null, currentDate())
    if (initialTheme.storedPreference !== (preference.value ?? null)) {
        preference.value = initialTheme.storedPreference
    }
    const activeSeason = useState('active-season', () => initialTheme.season)
    const activeTheme = useState('active-theme', () => initialTheme.activeTheme)
    let midnightTimer

    function savePreference(selection) {
        preference.value = selection
    }

    function refreshTheme() {
        const resolved = resolveSeasonalTheme(preference.value ?? null, currentDate())
        activeSeason.value = resolved.season
        activeTheme.value = resolved.activeTheme

        if (resolved.storedPreference !== (preference.value ?? null)) {
            savePreference(resolved.storedPreference)
        }
    }

    function selectTheme(theme) {
        const season = getActiveSeason(currentDate())
        const selection = theme === 'default' ? 'default' : season?.id
        if (!selection) return

        activeSeason.value = season
        activeTheme.value = selection
        savePreference(`${season.id}:${selection === 'default' ? 'off' : 'on'}`)
    }

    function currentDate() {
        if (import.meta.dev) {
            const preview = requestURL.searchParams.get('season')
            if (preview === 'halloween') return new Date(2026, 9, 28, 12)
            if (preview === 'christmas') return new Date(2026, 11, 24, 12)
        }
        return new Date()
    }

    const scheduleMidnightRefresh = () => {
        window.clearTimeout(midnightTimer)
        const now = new Date()
        const midnight = new Date(now)
        midnight.setHours(24, 0, 0, 0)
        midnightTimer = window.setTimeout(() => {
            refreshTheme()
            scheduleMidnightRefresh()
        }, midnight.getTime() - now.getTime() + 100)
    }

    const refreshWhenVisible = () => {
        if (document.visibilityState === 'visible') refreshTheme()
    }

    if (initialize) {
        onMounted(() => {
            refreshTheme()
            scheduleMidnightRefresh()
            window.addEventListener('focus', refreshTheme)
            document.addEventListener('visibilitychange', refreshWhenVisible)
        })

        onBeforeUnmount(() => {
            window.clearTimeout(midnightTimer)
            window.removeEventListener('focus', refreshTheme)
            document.removeEventListener('visibilitychange', refreshWhenVisible)
        })
    }

    return { activeSeason, activeTheme, selectTheme }
}
