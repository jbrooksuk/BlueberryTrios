#!/usr/bin/env python3
"""
Verify that every Standard puzzle in puzzles.json has at least one "obvious"
starting move — a move deducible purely from the Tier 1 fill/full technique
(no intersection reasoning, no lookahead, no guessing).

Mirrors the logic in Blueberries/Services/PuzzleSolver.swift so results match
what the in-app solver would find.

Usage:
    python3 scripts/verify_standard_starting_moves.py
"""

import json
import sys
from pathlib import Path

PUZZLES_PATH = Path(__file__).resolve().parent.parent / "Blueberries" / "Resources" / "puzzles.json"

UNDECIDED = 0
EMPTY = 1
BERRY = 2


def build_groups(puzzle):
    """Return (groups, initial_cells) where:
        groups: list of (label, clue, frozenset_of_cell_indices)
        initial_cells: list[int] of cell states (row-major)
    """
    rows = puzzle["size"]["rows"]
    cols = puzzle["size"]["columns"]
    n = rows * cols
    cell_clues = puzzle["cellClues"]

    # Mark clue cells as .empty, everything else undecided (matches PuzzleModel init)
    cells = [UNDECIDED] * n
    for i, clue in enumerate(cell_clues):
        if clue is not None:
            cells[i] = EMPTY

    groups = []

    # Row groups
    for r in range(rows):
        members = frozenset(r * cols + c for c in range(cols))
        groups.append((f"row {r}", puzzle["rowClues"][r], members))

    # Column groups
    for c in range(cols):
        members = frozenset(r * cols + c for r in range(rows))
        groups.append((f"col {c}", puzzle["columnClues"][c], members))

    # Block groups
    block_members = {}
    for r in range(rows):
        for c in range(cols):
            b = puzzle["blocks"][r * cols + c]
            block_members.setdefault(b, set()).add(r * cols + c)
    for b in sorted(block_members):
        groups.append((f"block {b}", puzzle["blockClues"][b], frozenset(block_members[b])))

    # Number-clue groups (cell + 8 neighbors, clipped to grid)
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
            groups.append((f"num ({r},{c})", clue, frozenset(members)))

    return groups, cells


def count_states(cells, members):
    berry = empty = undecided = 0
    for idx in members:
        s = cells[idx]
        if s == BERRY:
            berry += 1
        elif s == EMPTY:
            empty += 1
        else:
            undecided += 1
    return berry, empty, undecided


def find_fill_full_moves(cells, groups):
    """Return list of (technique, label, deductions) for every fill/full move
    that is currently applicable in `cells`.
    """
    moves = []
    for label, clue, members in groups:
        berry, _empty, undecided = count_states(cells, members)
        if undecided == 0:
            continue
        if berry == clue:
            deductions = [(idx, EMPTY) for idx in members if cells[idx] == UNDECIDED]
            if deductions:
                moves.append(("full", label, deductions))
        if berry + undecided == clue:
            deductions = [(idx, BERRY) for idx in members if cells[idx] == UNDECIDED]
            if deductions:
                moves.append(("fill", label, deductions))
    return moves


def propagate_fill_full(cells, groups):
    """Repeatedly apply fill/full until no change. Returns the number of cells
    that became decided during propagation.
    """
    start_undecided = sum(1 for s in cells if s == UNDECIDED)
    for _ in range(200):
        moves = find_fill_full_moves(cells, groups)
        if not moves:
            break
        changed = False
        for _tech, _label, deductions in moves:
            for idx, state in deductions:
                if cells[idx] == UNDECIDED:
                    cells[idx] = state
                    changed = True
        if not changed:
            break
    end_undecided = sum(1 for s in cells if s == UNDECIDED)
    return start_undecided - end_undecided


def main():
    with PUZZLES_PATH.open() as f:
        data = json.load(f)

    standard = data.get("Standard", [])
    total = len(standard)
    print(f"Checking {total} Standard puzzles for obvious starting moves (fill/full)...\n")

    no_start_move = []          # puzzles with ZERO fill/full moves at t=0
    starting_move_counts = []   # count of applicable moves at t=0
    cells_decided_by_fillfull = []  # how far fill/full alone can take the puzzle

    for i, puzzle in enumerate(standard):
        groups, cells = build_groups(puzzle)
        moves = find_fill_full_moves(cells, groups)
        starting_move_counts.append(len(moves))
        if not moves:
            no_start_move.append(i)

        # Also track how far fill/full alone propagates (for the
        # "shouldn't be boring" check)
        decided = propagate_fill_full(cells[:], groups)
        cells_decided_by_fillfull.append(decided)

    # Total non-clue (interactive) cells in a 9x9 with K clue cells
    # is 81 - K; record the percentage solved by fill/full alone.
    interactive_counts = [
        sum(1 for c in p["cellClues"] if c is None) for p in standard
    ]

    print("=" * 72)
    print("RESULTS")
    print("=" * 72)

    if no_start_move:
        print(f"\nFAIL: {len(no_start_move)} / {total} Standard puzzles have NO obvious starting move.")
        print("These puzzles require min/max intersection reasoning or guessing on move 1:")
        for idx in no_start_move[:30]:
            p = standard[idx]
            cc = [v for v in p["cellClues"] if v is not None]
            print(f"  - Standard[{idx}]: {len(cc)} number clues, values={sorted(cc)}")
        if len(no_start_move) > 30:
            print(f"  ... and {len(no_start_move) - 30} more")
    else:
        print(f"\nPASS: all {total} Standard puzzles have at least one obvious fill/full starting move.")

    # Distribution of starting-move counts
    from collections import Counter
    dist = Counter(starting_move_counts)
    print("\nDistribution of fill/full moves available on move 1:")
    for k in sorted(dist):
        print(f"  {k:>3} starting move(s): {dist[k]:>5} puzzles")

    # Distribution of how far fill/full alone can solve the puzzle
    percentages = []
    for decided, interactive in zip(cells_decided_by_fillfull, interactive_counts):
        pct = 100.0 * decided / interactive if interactive else 0.0
        percentages.append(pct)

    buckets = [0, 10, 25, 50, 75, 95, 100]
    bucket_counts = [0] * (len(buckets) - 1)
    fully_solved_by_fillfull = 0
    for pct in percentages:
        if pct >= 100.0:
            fully_solved_by_fillfull += 1
        for i in range(len(buckets) - 1):
            if buckets[i] <= pct < buckets[i + 1]:
                bucket_counts[i] += 1
                break

    print("\nHow far fill/full alone can take a Standard puzzle (% of interactive cells decided):")
    for i in range(len(buckets) - 1):
        lo, hi = buckets[i], buckets[i + 1]
        print(f"  [{lo:>3}% .. {hi:>3}%): {bucket_counts[i]:>5} puzzles")
    print(f"\n  Puzzles fully solved by fill/full alone (potentially boring): {fully_solved_by_fillfull}")

    avg_pct = sum(percentages) / len(percentages) if percentages else 0
    print(f"  Average progress from fill/full alone: {avg_pct:.1f}%")

    # Exit non-zero if any puzzle lacks an obvious starting move
    sys.exit(1 if no_start_move else 0)


if __name__ == "__main__":
    main()
