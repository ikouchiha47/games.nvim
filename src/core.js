/**
 * Core 9x9 Sudoku generator and solver (backtracking)
 * @typedef {number[][]} Grid
 */

/** @returns {Grid} */
export function emptyGrid() {
  return Array.from({ length: 9 }, () => Array(9).fill(0));
}

/**
 * @param {Grid} grid
 * @param {number} row
 * @param {number} col
 * @param {number} val
 */
export function isValid(grid, row, col, val) {
  if (grid[row].includes(val)) return false;
  for (let r = 0; r < 9; r++) if (grid[r][col] === val) return false;
  const br = Math.floor(row / 3) * 3;
  const bc = Math.floor(col / 3) * 3;
  for (let r = br; r < br + 3; r++)
    for (let c = bc; c < bc + 3; c++) if (grid[r][c] === val) return false;
  return true;
}

/** @param {Grid} grid */
export function findEmpty(grid) {
  for (let r = 0; r < 9; r++)
    for (let c = 0; c < 9; c++) if (grid[r][c] === 0) return [r, c];
  return null;
}

/** @param {Grid} grid */
export function solve(grid) {
  const pos = findEmpty(grid);
  if (!pos) return true;
  const [r, c] = pos;
  for (let val = 1; val <= 9; val++) {
    if (isValid(grid, r, c, val)) {
      grid[r][c] = val;
      if (solve(grid)) return true;
      grid[r][c] = 0;
    }
  }
  return false;
}

/**
 * Count solutions up to limit (early exit)
 * @param {Grid} grid
 * @param {number} [limit=2]
 */
export function countSolutions(grid, limit = 2) {
  const pos = findEmpty(grid);
  if (!pos) return 1;
  const [r, c] = pos;
  let total = 0;
  for (let val = 1; val <= 9 && total < limit; val++) {
    if (isValid(grid, r, c, val)) {
      grid[r][c] = val;
      total += countSolutions(grid, limit);
      grid[r][c] = 0;
    }
  }
  return total;
}

/** @returns {Grid} */
export function generateFullGrid() {
  const grid = emptyGrid();
  const cells = [];
  for (let r = 0; r < 9; r++) for (let c = 0; c < 9; c++) cells.push([r, c]);
  fill(grid, cells, 0);
  return grid;
}

/**
 * @param {Grid} grid
 * @param {[number,number][]} cells
 * @param {number} idx
 */
function fill(grid, cells, idx) {
  if (idx === cells.length) return true;
  const [r, c] = cells[idx];
  const vals = [1, 2, 3, 4, 5, 6, 7, 8, 9].sort(() => Math.random() - 0.5);
  for (const val of vals) {
    if (isValid(grid, r, c, val)) {
      grid[r][c] = val;
      if (fill(grid, cells, idx + 1)) return true;
      grid[r][c] = 0;
    }
  }
  return false;
}

/**
 * Generate puzzle with exactly one solution
 * @param {number} [clues=30]
 * @returns {{puzzle: Grid, solved: Grid}}
 */
export function generatePuzzle(clues = 30) {
  const solved = generateFullGrid();
  const puzzle = solved.map((row) => [...row]);
  const positions = [];
  for (let r = 0; r < 9; r++) for (let c = 0; c < 9; c++) positions.push([r, c]);
  positions.sort(() => Math.random() - 0.5);
  let removed = 0;
  for (const [r, c] of positions) {
    if (81 - removed <= clues) break;
    const saved = puzzle[r][c];
    puzzle[r][c] = 0;
    const tmp = puzzle.map((row) => [...row]);
    if (countSolutions(tmp) !== 1) puzzle[r][c] = saved;
    else removed++;
  }
  return { puzzle, solved };
}
