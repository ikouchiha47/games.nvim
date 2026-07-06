# Sudoku Puzzle Generation: Core Logic

## 1. Generate Full Valid Grid

Use **backtracking** to fill a 9×9 grid:

- Iterate cells row-by-row (or in randomized order for variety).
- For each empty cell, try values 1–9 in random order.
- Check constraints: value must not already exist in the current **row**, **column**, or **3×3 box**.
- Recurse to the next cell.
- If a cell has no valid candidates, backtrack to the previous cell and try the next value.
- Terminate when all 81 cells are filled (guaranteed to produce a valid solved grid).

## 2. Create Puzzle by Removing Numbers

Start from the solved grid and selectively remove entries ("givens" or "clues"):

- For each removal candidate:
  - Remove the number.
  - Run a solver on the resulting grid.
  - Verify the puzzle still has **exactly one unique solution**.
- If multiple solutions appear or the puzzle becomes unsolvable, restore the number.
- Repeat until the desired number of clues remains or further removals violate uniqueness.
- **Minimum clues for uniqueness**: 17 (proven mathematical lower bound).

## 3. Difficulty Control

Difficulty is primarily governed by two factors:

| Level   | Clue Count | Required Techniques                  |
|---------|------------|--------------------------------------|
| Easy    | 50–60+     | Naked/hidden singles                 |
| Medium  | 36–49      | Naked/hidden pairs & triples         |
| Hard    | 24–35      | X-Wing, swordfish, simple chains     |
| Expert  | 17–23      | Advanced chains, forcing nets, etc.  |

### Rating Strategies

- **Clue count** alone is insufficient.
- Use solver-based scoring: count the number of logical "steps" or track which solving techniques are required.
- Human-mimicking solvers simulate techniques in order of complexity rather than brute-force search.
- Optional: apply symmetry (rotational 180°, reflection) or aesthetic clue patterns for visual appeal.

## 4. Mathematical Programming Formulation (ILP / MIP)

Alternative to backtracking: model Sudoku as a **binary integer linear program** (BILP/MIP).

Define binary variables \( x_{ijk} \in \{0,1\} \):

- \( x_{ijk} = 1 \) iff cell \((i,j)\) contains value \( k \).

**Core constraints** (feasibility model):

- Cell constraint: \(\sum_{k} x_{ijk} = 1 \quad \forall i,j\)
- Row constraint: \(\sum_{j} x_{ijk} = 1 \quad \forall i,k\)
- Column constraint: \(\sum_{i} x_{ijk} = 1 \quad \forall j,k\)
- Box constraint: \(\sum_{(i,j)\in\text{box}} x_{ijk} = 1 \quad \forall k,\text{boxes}\)

Fixed clues (givens) are enforced by setting the corresponding \( x_{ijk} = 1 \).

**Generation via MIP** (recent approaches, 2022–2025):

- Use a weighted objective or iterative removal: start from a solved grid, relax clue constraints one-by-one, solve the MIP, and accept removals that keep a unique solution.
- Control difficulty via a continuous `target_difficulty` parameter (0.0 = easiest/max clues, 1.0 = hardest/min clues ≈ 17).
- Libraries (e.g., `sudoku-mip-solver`) expose `generate_random_puzzle(target_difficulty=..., unique_solution=True)`.
- Solvers tested: Julia fastest, followed by Python (PuLP/Highs), MiniZinc; interestingly, “easy” instances (more clues) produce more constraints and can take longer MIP solve time than harder ones.

**Advantage**: exact control over clue count and structure; useful for research and reproducible difficulty curves. Backtracking remains faster for bulk generation.

## Implementation Notes

- Backtracking is fastest for most practical generation; ILP suits research/exact control.
- Randomized cell/value ordering produces more varied puzzles.
- Post-generation symmetry or pattern masks improve perceived quality.
- For production systems, pre-generate and rate puzzles offline, then serve from a database filtered by difficulty score.
