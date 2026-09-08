<script setup lang="ts">
import example from '~/data/tutorial-example.json'

const step = ref(0)
const lessons = [
    { title: 'Three in every row', text: 'Every horizontal row needs exactly three berries. Once you have all three, the remaining cells in that row cannot contain a berry.', short: 'Row' },
    { title: 'Three in every column', text: 'The same rule runs from top to bottom: exactly three berries in each column. Every berry you place counts towards both its row and its column.', short: 'Column' },
    { title: 'Three in every block', text: 'The thicker lines divide the board into blocks. Each block also needs exactly three berries. Follow its outline carefully: blocks can be irregular shapes, not just squares.', short: 'Block' },
    { title: 'Numbers look all around', text: 'A number tells you how many berries are in the surrounding cells, including diagonals. The numbered cell itself never holds a berry. At the edge or a corner, only neighbours inside the grid count.', short: 'Clues' },
    { title: 'Start with a zero', text: 'A zero means none of its neighbours can hold a berry. Cross those cells out. Each cell you eliminate brings you closer to finding where the three berries must go.', short: 'Zero' },
]
const clueIndex = example.cellClues.findIndex((v, i) => v === 3 && i % 9 > 0 && i % 9 < 8 && i > 8 && i < 72)
const zeroIndex = example.cellClues.indexOf(0)
function neighbours(index: number) {
    return example.blocks.map((_, i) => i).filter(i => i !== index && Math.abs(i % 9 - index % 9) <= 1 && Math.abs(Math.floor(i / 9) - Math.floor(index / 9)) <= 1)
}
const highlighted = computed(() => {
    if (step.value === 0) return Array.from({ length: 9 }, (_, i) => i + 36)
    if (step.value === 1) return Array.from({ length: 9 }, (_, i) => i * 9 + 4)
    if (step.value === 2) return example.blocks.map((_, i) => i).filter(i => example.blocks[i] === example.blocks[40])
    return neighbours(step.value === 3 ? clueIndex : zeroIndex)
})
const cells = computed(() => example.blocks.map((_, i) => highlighted.value.includes(i) ? example.solution[i]! : '_'))
const boardLabel = computed(() => `${lessons[step.value]!.title}. ${step.value < 3 ? 'The highlighted area contains exactly three berries.' : step.value === 3 ? 'The clue 3 has exactly three berries among its eight highlighted neighbours.' : 'All highlighted neighbours of the zero are empty.'}`)

// A small teaching block: the zero rules out every open cell except the top row.
const practiceClues = [null, null, null, null, null, null, null, 0, null]
const emptyCells = [3, 4, 5, 6, 8]
const practice = ref(Array<string>(9).fill('_'))
const touched = ref(false)
const solved = computed(() => [0, 1, 2].every(i => practice.value[i] === 'o') && emptyCells.every(i => practice.value[i] === 'x'))
const feedback = computed(() => {
    if (solved.value) return 'Sweet! Three berries in the block, and every clue satisfied. That is your first deduction.'
    if (emptyCells.some(i => practice.value[i] === 'o')) return 'A berry is touching the zero. None of its neighbours can hold a berry, including the diagonals. Tap that berry to clear it, then tap again for a ×.'
    if ([0, 1, 2].every(i => practice.value[i] === 'o')) return 'The berries are right. Mark all five neighbours of the zero with a × to finish the block.'
    if (emptyCells.every(i => practice.value[i] === 'x')) return 'The zero is satisfied. Only three cells remain: tap each twice to place the three berries.'
    return touched.value ? 'Cross out all five neighbours of the zero. Then look for the only three cells left for berries.' : 'Start with the zero. Tap each of its five neighbours once to mark it with a ×.'
})
function cycle(index: number) {
    touched.value = true
    practice.value[index] = practice.value[index] === '_' ? 'x' : practice.value[index] === 'x' ? 'o' : '_'
}
function reset() { practice.value = Array<string>(9).fill('_'); touched.value = false }
</script>

<template>
    <section class="walkthrough" aria-labelledby="rules-title">
        <div class="lesson-copy">
            <p class="eyebrow" id="rules-title">The rules</p>
            <div class="lesson-picker" aria-label="Choose a rule">
                <button v-for="(lesson, i) in lessons" :key="lesson.short" type="button" :aria-pressed="step === i" @click="step = i">{{ lesson.short }}</button>
            </div>
            <div class="lesson-text" aria-live="polite" aria-atomic="true">
                <p class="step-count">0{{ step + 1 }} / 05</p>
                <h2>{{ lessons[step]!.title }}</h2>
                <p>{{ lessons[step]!.text }}</p>
            </div>
            <div class="lesson-actions">
                <button type="button" :disabled="step === 0" @click="step--">← Previous</button>
                <button v-if="step < 4" type="button" @click="step++">Next rule →</button>
                <a v-else href="#try-it">Try it yourself ↓</a>
            </div>
        </div>
        <figure class="example-grid">
            <PuzzleBoard :blocks="example.blocks" :clues="example.cellClues" :cells="cells" :highlighted="highlighted" :label="boardLabel" />
            <figcaption>{{ boardLabel }} <span>Example from the game’s puzzle library.</span></figcaption>
        </figure>
    </section>

    <section id="try-it" class="practice-section" aria-labelledby="practice-title">
        <div class="practice-copy">
            <p class="eyebrow">Your first move</p>
            <h2 id="practice-title">One block. Three berries.</h2>
            <p>Try this small practice block. It needs exactly three berries. Assume any neighbours outside this example are empty; everything you need is here.</p>
            <p>Tap an open cell to cycle through the same states as the app. You can also use Tab, then Enter or Space.</p>
            <ol class="tap-cycle" aria-label="Cell tap cycle">
                <li><span class="sample-mark">×</span>First tap: no berry</li>
                <li><span class="sample-berry" />Second tap: berry</li>
                <li><span class="sample-empty" />Third tap: clear</li>
            </ol>
            <p class="app-tip">In the app, you can also drag across cells to repeat a mark, undo a move, or ask for a hint.</p>
        </div>
        <div class="practice-panel">
            <PuzzleBoard :size="3" :blocks="Array(9).fill(0)" :clues="practiceClues" :cells="practice" interactive label="Practice block. Place three berries. Clue cells cannot be changed." @change="cycle" />
            <p class="practice-feedback" :class="{ solved }" role="status">{{ feedback }}</p>
            <button type="button" class="reset-button" @click="reset">Reset practice</button>
        </div>
    </section>
</template>

<style scoped>
.walkthrough, .practice-section { display: grid; grid-template-columns: 1fr 1fr; gap: clamp(32px, 6vw, 88px); align-items: center; }
.eyebrow { color: #9dbce4; font-size: .8rem; letter-spacing: .12em; text-transform: uppercase; font-weight: 600; }
h2 { font-family: 'Fraunces', serif; font-size: clamp(1.8rem, 3vw, 2.65rem); line-height: 1.15; font-weight: 600; margin: 16px 0 20px; }
p { line-height: 1.8; color: #b3c1da; }
.lesson-picker { display: flex; flex-wrap: wrap; gap: 4px; margin: 24px 0 32px; }
button, .lesson-actions a { font: inherit; font-size: .9rem; min-height: 44px; border: 0; background: transparent; color: #b3c1da; cursor: pointer; border-radius: 8px; }
.lesson-picker button { padding: 10px 12px; }
.lesson-picker button[aria-pressed="true"] { background: #243b58; color: #f0f4ff; }
button:hover:not(:disabled), .lesson-actions a:hover { color: #f0f4ff; background: #1c2d46; }
button:focus-visible, a:focus-visible { outline: 2px solid #94c5ff; outline-offset: 4px; }
button:disabled { opacity: .4; cursor: default; }
.lesson-text { min-height: 265px; }
.step-count { font-variant-numeric: tabular-nums; font-size: .8rem; color: #91a5c4; }
.lesson-actions { display: flex; justify-content: space-between; align-items: center; gap: 16px; margin-top: 24px; }
.lesson-actions button, .lesson-actions a { padding: 12px; }
.example-grid { margin: 0; }
figcaption { font-size: .8rem; color: #a2b3ce; line-height: 1.7; margin-top: 16px; min-height: 70px; }
figcaption span { display: block; }
.practice-section { border-top: 1px solid #283951; padding-top: 72px; margin-top: 72px; scroll-margin-top: 110px; align-items: start; }
.practice-copy > p + p { margin-top: 16px; }
.practice-panel { width: 100%; max-width: 330px; justify-self: center; }
.tap-cycle { list-style: none; display: grid; gap: 12px; margin: 24px 0; color: #d0dcee; font-size: .9rem; }
.tap-cycle li { display: flex; align-items: center; gap: 12px; }
.sample-mark, .sample-berry, .sample-empty { display: inline-grid; place-items: center; width: 24px; height: 24px; flex-shrink: 0; }
.sample-mark { font-size: 1.6rem; color: #aaa; }
.sample-berry { border-radius: 50%; background: #5a9fe8; position: relative; }
.sample-berry::after { content: ''; position: absolute; width: 8px; height: 8px; top: 4px; left: 5px; background: #fafdff40; border-radius: 50%; }
.sample-empty { border: 1px solid #64748b; border-radius: 2px; }
.app-tip { font-size: .85rem; }
.practice-feedback { font-size: .9rem; margin-top: 20px; min-height: 108px; }
.practice-feedback.solved { color: #9bd6ac; }
.reset-button { text-decoration: underline; text-underline-offset: 4px; padding: 8px 0; }
@media (max-width: 760px) { .walkthrough, .practice-section { grid-template-columns: 1fr; gap: 28px; } .lesson-text { min-height: 220px; } .lesson-picker { margin: 20px 0; } .example-grid { max-width: 480px; width: 100%; justify-self: center; } .practice-section { margin-top: 48px; padding-top: 48px; } .lesson-actions { margin-top: 0; } }
</style>
