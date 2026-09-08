<script setup lang="ts">
// Mirrors the iOS grid: rounded cells, region boundaries, berry highlights and X marks.
const props = withDefaults(defineProps<{
    size?: number
    blocks: number[]
    clues: (number | null)[]
    cells: string[]
    highlighted?: number[]
    interactive?: boolean
    label: string
}>(), { size: 9, highlighted: () => [], interactive: false })
const emit = defineEmits<{ change: [index: number] }>()
const boundaries = computed(() => {
    const lines: string[] = []
    props.blocks.forEach((block, i) => {
        const x = i % props.size, y = Math.floor(i / props.size)
        if (x < props.size - 1 && block !== props.blocks[i + 1]) lines.push(`M${x + 1},${y}v1`)
        if (y < props.size - 1 && block !== props.blocks[i + props.size]) lines.push(`M${x},${y + 1}h1`)
    })
    return lines.join(' ')
})
function cellLabel(i: number) {
    const position = `Row ${Math.floor(i / props.size) + 1}, column ${i % props.size + 1}`
    if (props.clues[i] != null) return `${position}, clue ${props.clues[i]}`
    const state = props.cells[i] === 'o' ? 'berry' : props.cells[i] === 'x' ? 'crossed out' : 'undecided'
    const next = props.cells[i] === 'o' ? 'clear' : props.cells[i] === 'x' ? 'place a berry' : 'cross out'
    return `${position}, ${state}${props.interactive ? `. Activate to ${next}` : ''}`
}
</script>

<template>
    <div class="puzzle-board" :style="{ '--size': size }" :role="interactive ? 'group' : 'img'" :aria-label="label">
        <component :is="interactive && clues[i] == null ? 'button' : 'div'"
            v-for="(_, i) in blocks" :key="i" class="puzzle-cell"
            :class="{ highlighted: highlighted.includes(i), editable: interactive && clues[i] == null }"
            :type="interactive && clues[i] == null ? 'button' : undefined"
            :aria-label="interactive ? cellLabel(i) : undefined"
            :aria-hidden="!interactive ? true : undefined"
            @click="interactive && clues[i] == null && emit('change', i)">
            <span v-if="clues[i] != null" class="clue">{{ clues[i] }}</span>
            <Transition v-else name="piece" mode="out-in">
                <svg v-if="cells[i] === 'o'" key="berry" class="token" viewBox="0 0 100 100" aria-hidden="true">
                    <circle cx="50" cy="50" r="30" fill="#5a9fe8" />
                    <circle cx="42.5" cy="41" r="10.5" fill="#fafdff" opacity=".25" />
                </svg>
                <svg v-else-if="cells[i] === 'x'" key="cross" class="token" viewBox="0 0 100 100" aria-hidden="true">
                    <path d="M38 38 62 62 M62 38 38 62" fill="none" stroke="#999" stroke-width="3" stroke-linecap="round" />
                </svg>
            </Transition>
        </component>
        <svg class="block-lines" :viewBox="`0 0 ${size} ${size}`" aria-hidden="true">
            <path :d="boundaries" fill="none" stroke="currentColor" stroke-width="2" vector-effect="non-scaling-stroke" />
        </svg>
    </div>
</template>

<style scoped>
.puzzle-board { position: relative; display: grid; grid-template-columns: repeat(var(--size), 1fr); aspect-ratio: 1; width: 100%; border: 2.5px solid #f0f4ff; border-radius: 6px; overflow: hidden; background: #1c1c1e; container-type: inline-size; }
.puzzle-cell { position: relative; display: grid; place-items: center; min-width: 0; padding: 0; margin: 1px; border: 0; border-radius: 2px; background: #2c2c2e; color: #f0f4ff; box-shadow: 0 0 0 .5px #55555580; aspect-ratio: 1; }
.puzzle-cell::before { content: ''; position: absolute; inset: 0; background: #ffbf1a; opacity: 0; transition: opacity 280ms cubic-bezier(.22,1,.36,1); }
.puzzle-cell.highlighted::before { opacity: .23; }
.clue { position: relative; font-family: ui-rounded, 'SF Pro Rounded', system-ui, sans-serif; font-size: calc(50cqw / var(--size)); font-weight: 600; }
.token { position: absolute; width: 100%; height: 100%; }
.block-lines { position: absolute; inset: 0; width: 100%; height: 100%; pointer-events: none; color: #f0f4ff; }
.editable { cursor: pointer; -webkit-tap-highlight-color: transparent; }
.editable:hover { background: #38383c; }
.editable:focus-visible { outline: 3px solid #94c5ff; outline-offset: -4px; z-index: 1; }
.piece-enter-active { transition: transform 180ms cubic-bezier(.22,1,.36,1), opacity 180ms; }
.piece-leave-active { transition: transform 100ms, opacity 100ms; }
.piece-enter-from { transform: scale(.7); opacity: 0; }
.piece-leave-to { transform: scale(.85); opacity: 0; }
@media (prefers-reduced-motion: reduce) { .puzzle-cell::before, .piece-enter-active, .piece-leave-active { transition: none; } }
</style>
