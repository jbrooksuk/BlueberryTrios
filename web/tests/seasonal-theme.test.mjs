import assert from 'node:assert/strict'
import test from 'node:test'

import { getActiveSeason, resolveSeasonalTheme } from '../utils/seasonal-theme.mjs'

const localDate = (year, month, day) => new Date(year, month - 1, day, 12)

test('Halloween runs from October 26 through October 31', () => {
    assert.equal(getActiveSeason(localDate(2026, 10, 25)), null)
    assert.equal(getActiveSeason(localDate(2026, 10, 26))?.id, 'halloween')
    assert.equal(getActiveSeason(localDate(2026, 10, 31))?.id, 'halloween')
    assert.equal(getActiveSeason(localDate(2026, 11, 1)), null)
})

test('Christmas runs from December 23 through December 31', () => {
    assert.equal(getActiveSeason(localDate(2026, 12, 22)), null)
    assert.equal(getActiveSeason(localDate(2026, 12, 23))?.id, 'christmas')
    assert.equal(getActiveSeason(localDate(2026, 12, 31))?.id, 'christmas')
    assert.equal(getActiveSeason(localDate(2027, 1, 1)), null)
})

test('the active season is automatic until Berroku is explicitly selected', () => {
    const date = localDate(2026, 10, 28)
    assert.equal(resolveSeasonalTheme(null, date).activeTheme, 'halloween')
    assert.equal(resolveSeasonalTheme('halloween:off', date).activeTheme, 'default')
    assert.equal(resolveSeasonalTheme('halloween:on', date).activeTheme, 'halloween')
})

test('all seasonal preferences are cleared outside their date window', () => {
    const date = localDate(2026, 11, 1)
    assert.equal(resolveSeasonalTheme('halloween:off', date).storedPreference, null)
    assert.equal(resolveSeasonalTheme('halloween:on', date).storedPreference, null)
})

test('a stale seasonal preference yields to the currently active season', () => {
    const resolved = resolveSeasonalTheme('halloween:off', localDate(2026, 12, 24))
    assert.equal(resolved.activeTheme, 'christmas')
    assert.equal(resolved.storedPreference, null)
})
