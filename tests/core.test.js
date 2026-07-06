import { describe, it, expect } from 'vitest';
import {
  emptyGrid,
  isValid,
  solve,
  countSolutions,
  generateFullGrid,
  generatePuzzle,
} from '../src/core.js';

describe('core sudoku', () => {
  it('emptyGrid has correct shape', () => {
    const g = emptyGrid();
    expect(g.length).toBe(9);
    expect(g.every((r) => r.length === 9)).toBe(true);
  });

  it('isValid detects row/col/box conflicts', () => {
    const g = emptyGrid();
    expect(isValid(g, 0, 0, 5)).toBe(true);
    g[0][0] = 5;
    expect(isValid(g, 0, 1, 5)).toBe(false);
    expect(isValid(g, 0, 1, 3)).toBe(true);
  });

  it('solve produces a valid full grid', () => {
    const g = emptyGrid();
    expect(solve(g)).toBe(true);
    expect(g.every((row) => row.every((c) => c !== 0))).toBe(true);
    for (const row of g) expect([...row].sort((a, b) => a - b)).toEqual([1, 2, 3, 4, 5, 6, 7, 8, 9]);
  });

  it('countSolutions returns 1 for solved grid', () => {
    const g = emptyGrid();
    solve(g);
    expect(countSolutions(g.map((r) => [...r]))).toBe(1);
  });

  it('generateFullGrid yields valid solved grid', () => {
    const g = generateFullGrid();
    expect(solve(g.map((r) => [...r]))).toBe(true); // already solved
    for (const row of g) expect(new Set(row).size).toBe(9);
  });

  it('generatePuzzle returns correct clue count and unique solution', () => {
    const { puzzle, solved } = generatePuzzle(35);
    const clues = puzzle.flat().filter((c) => c !== 0).length;
    expect(clues).toBe(35);
    expect(countSolutions(puzzle.map((r) => [...r]))).toBe(1);
    for (let r = 0; r < 9; r++)
      for (let c = 0; c < 9; c++)
        if (puzzle[r][c] !== 0) expect(puzzle[r][c]).toBe(solved[r][c]);
  });
});
