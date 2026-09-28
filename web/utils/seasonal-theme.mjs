export const themeStorageKey = 'seasonalTheme'

const seasons = {
    halloween: {
        id: 'halloween',
        name: 'Halloween',
        symbol: '🎃',
        markers: 'pumpkins',
        attribution: { prefix: 'Made with pumpkin spice by', symbol: '🎃' },
    },
    christmas: {
        id: 'christmas',
        name: 'Christmas',
        symbol: '❄️',
        markers: 'snowflakes',
        attribution: { prefix: 'Made with gingerbread by', symbol: '🎅' },
    },
}

export function getActiveSeason(date = new Date()) {
    const month = date.getMonth() + 1
    const day = date.getDate()

    if (month === 10 && day >= 26) return seasons.halloween
    if (month === 12 && day >= 23) return seasons.christmas
    return null
}

export function resolveSeasonalTheme(preference, date = new Date()) {
    const season = getActiveSeason(date)

    if (!season) {
        return {
            season: null,
            activeTheme: 'default',
            storedPreference: null,
        }
    }

    if (preference === `${season.id}:off`) {
        return { season, activeTheme: 'default', storedPreference: preference }
    }

    if (preference === `${season.id}:on`) {
        return { season, activeTheme: season.id, storedPreference: preference }
    }

    return { season, activeTheme: season.id, storedPreference: null }
}
