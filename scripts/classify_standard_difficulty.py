#!/usr/bin/env python3
"""
Classify every Standard puzzle by the hardest solving technique it requires.

Mirrors the tier hierarchy in Blueberries/Services/PuzzleSolver.swift:
  Tier 1: fill / full         (single-group counting)
  Tier 2: min/max             (intersection reasoning across two groups)
  Tier 3: deep lookahead      (hypothetical assignment + propagation)

For each puzzle, applies the lowest available tier repeatedly until the
puzzle is solved or stuck, and records the highest tier that was ever
needed. Also reports how far pure "intuitive" fill/full on *number-clue
groups only* can take each puzzle — that is what a player who only reads
the visible number clues (and ignores row/column/block berry counts) sees.

Usage:
    python3 scripts/classify_standard_difficulty.py
"""

import json
import sys
from collections import Counter
from pathlib import Path

PUZZLES_PATH = Path(__file__).resolve().parent.parent / "Blueberries" / "Resources" / "puzzles.json"

UNDECIDED = 0
EMPTY = 1
BERRY = 2


def build_groups(puzzle):
    rows = puzzle["size"]["rows"]
    cols = puzzle["size"]["columns"]
    cell_clues = puzzle["cellClues"]

    cells = [UNDECIDED] * (rows * cols)
    for i, clue in enumerate(cell_clues):
        if clue is not None:
            cells[i] = EMPTY

    line_groups = []   # row / col / block — "counting" groups
    number_groups = [] # cell-clue groups — "intuitive" groups

    for r in range(rows):
        members = frozenset(r * cols + c for c in range(cols))
        line_groups.append(("row", r, puzzle["rowClues"][r], members))

    for c in range(cols):
        members = frozenset(r * cols + c for r in range(rows))
        line_groups.append(("col", c, puzzle["columnClues"][c], members))

    block_members = {}
    for r in range(rows):
        for c in range(cols):
            b = puzzle["blocks"][r * cols + c]
            block_members.setdefault(b, set()).add(r * cols + c)
    for b in sorted(block_members):
        line_groups.append(("block", b, puzzle["blockClues"][b], frozenset(block_members[b])))

    for r in range(rows):
        for c in range(cols):
            clue = cell_clues[r * cols + c]
            if clue is None:
                continue
            members = {r * cols + c}
            for dr in (-1, 0, 1):
                for dc in (-1, 0, 1):
                    if dr == 0 and dc == 0:
                        continue
                    nr, nc = r + dr, c + dc
                    if 0 <= nr < rows and 0 <= nc < cols:
                        members.add(nr * cols + nc)
            number_groups.append(("num", (r, c), clue, frozenset(members)))

    all_groups = line_groups + number_groups
    return all_groups, number_groups, line_groups, cells


def counts(cells, members):
    b = e = u = 0
    for idx in members:
        s = cells[idx]
        if s == BERRY:
            b += 1
        elif s == EMPTY:
            e += 1
        else:
            u += 1
    return b, e, u


def apply_fill_full(cells, groups):
    """One pass of fill/full on the given groups. Returns True if anything changed."""
    changed = False
    for _kind, _gid, clue, members in groups:
        b, _e, u = counts(cells, members)
        if u == 0:
            continue
        if b == clue:
            for idx in members:
                if cells[idx] == UNDECIDED:
                    cells[idx] = EMPTY
                    changed = True
        elif b + u == clue:
            for idx in members:
                if cells[idx] == UNDECIDED:
                    cells[idx] = BERRY
                    changed = True
    return changed


def propagate_fill_full(cells, groups):
    for _ in range(400):
        if not apply_fill_full(cells, groups):
            break


def apply_min_max(cells, groups):
    """One pass of Tier 2 min/max. Returns True if anything changed.
    Matches PuzzleSolver.findMinMaxMoves / propagateToContradiction."""
    changed = False
    for _pkind, _pid, _pclue, pmembers in groups:
        for _skind, _sid, sclue, smembers in groups:
            if pmembers is smembers:
                continue
            intersection = pmembers & smembers
            if not intersection:
                continue
            ib, _ie, iu = counts(cells, intersection)
            if iu == 0:
                continue
            secondary_only = smembers - pmembers
            sob, _soe, sou = counts(cells, secondary_only)

            max_from_int = min(ib + iu, sclue - sob)
            min_from_int = max(ib, sclue - sob - sou)

            if min_from_int > ib:
                needed = min_from_int - ib
                if needed == iu:
                    for idx in intersection:
                        if cells[idx] == UNDECIDED:
                            cells[idx] = BERRY
                            changed = True
            if max_from_int == ib:
                for idx in intersection:
                    if cells[idx] == UNDECIDED:
                        cells[idx] = EMPTY
                        changed = True
    return changed


def solve_tracking_tiers(cells, groups):
    """Solve by repeatedly trying Tier 1, then Tier 2. Returns (solved, max_tier, tier_uses)."""
    max_tier = 0
    tier_uses = Counter()
    for _ in range(400):
        if apply_fill_full(cells, groups):
            max_tier = max(max_tier, 1)
            tier_uses[1] += 1
            continue
        if apply_min_max(cells, groups):
            max_tier = max(max_tier, 2)
            tier_uses[2] += 1
            continue
        break
    solved = all(s != UNDECIDED for s in cells)
    return solved, max_tier, tier_uses


def main():
    with PUZZLES_PATH.open() as f:
        data = json.load(f)

    standard = data.get("Standard", [])
    total = len(standard)

    print(f"Classifying {total} Standard puzzles by hardest required technique...\n")

    tier1_only = 0
    needs_tier2 = 0
    unsolved = 0

    # "Intuitive" simulation: after one pass of fill/full on JUST number-clue
    # groups, how much of the puzzle can ordinary fill/full continue without
    # needing min/max?
    intuitive_stuck = 0
    intuitive_stuck_indices = []

    for i, puzzle in enumerate(standard):
        groups, number_groups, line_groups, cells = build_groups(puzzle)

        # A) hardest technique needed to solve from scratch
        cells_copy = cells[:]
        solved, max_tier, _ = solve_tracking_tiers(cells_copy, groups)
        if not solved:
            unsolved += 1
        elif max_tier <= 1:
            tier1_only += 1
        else:
            needs_tier2 += 1

        # B) "intuitive player" simulation
        # Step 1: player sees zeros/forced-fills on number clues, plays them
        # (propagate fill/full on NUMBER-CLUE groups only, ignoring rows/cols/blocks)
        cells_b = cells[:]
        propagate_fill_full(cells_b, number_groups)
        # Step 2: is there ANY next fill/full move anywhere (including rows/cols/blocks)?
        next_fillfull_exists = False
        for _kind, _gid, clue, members in groups:
            b, _e, u = counts(cells_b, members)
            if u == 0:
                continue
            if b == clue or b + u == clue:
                next_fillfull_exists = True
                break
        if not next_fillfull_exists:
            # Player is stuck on visual cues — would need to start counting
            # row/col/block berries, or use min/max.
            # Check if it's already solved (unlikely) or truly stuck
            if any(s == UNDECIDED for s in cells_b):
                intuitive_stuck += 1
                intuitive_stuck_indices.append(i)

    print("=" * 72)
    print("A. Hardest technique needed to solve each Standard puzzle")
    print("=" * 72)
    print(f"  Solved with Tier 1 (fill/full) only:     {tier1_only} / {total}")
    print(f"  Required Tier 2 (min/max) at some point: {needs_tier2} / {total}")
    print(f"  Could not be solved with Tier 1+2:       {unsolved} / {total}")

    print()
    print("=" * 72)
    print("B. 'Intuitive player' simulation")
    print("=" * 72)
    print("After propagating fill/full on number-clue groups only (i.e. the")
    print("player has played every visibly-obvious berry and empty), how many")
    print("puzzles have NO further fill/full move available anywhere?")
    print()
    print(f"  Stuck after intuitive moves: {intuitive_stuck} / {total}")
    if intuitive_stuck:
        print(f"  Example indices: {intuitive_stuck_indices[:10]}")

    # If nothing is stuck, that means even after playing only the number-clue
    # moves, a row/col/block fill/full is always available — no need for min/max.


if __name__ == "__main__":
    main()
