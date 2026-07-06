/**
 * BILP (Binary Integer Linear Programming) Sudoku solver using GLPK.js
 * @typedef {number[][]} Grid
 */

import GLPK from 'glpk.js';

let glpkInstance = null;

export async function getGlpk() {
  if (!glpkInstance) glpkInstance = await GLPK();
  return glpkInstance;
}

function varName(r, c, k) {
  return `x_${r}_${c}_${k}`;
}

/**
 * Build the GLPK LP model for a 9x9 Sudoku puzzle.
 * @param {Grid} puzzle 0 = empty
 * @param {boolean} randomizeObjective if true, random coefs help generate different solutions
 */
export async function buildModel(puzzle, randomizeObjective = false) {
  const glpk = await getGlpk();
  const vars = [];
  const binaries = [];
  const subjectTo = [];

  // All 729 binary variables
  for (let r = 0; r < 9; r++)
    for (let c = 0; c < 9; c++)
      for (let k = 1; k <= 9; k++) {
        const name = varName(r, c, k);
        vars.push({ name, coef: randomizeObjective ? Math.random() : 0 });
        binaries.push(name);
      }

  // Cell constraints: exactly one value per cell
  for (let r = 0; r < 9; r++)
    for (let c = 0; c < 9; c++) {
      subjectTo.push({
        name: `cell_${r}_${c}`,
        vars: Array.from({ length: 9 }, (_, k) => ({ name: varName(r, c, k + 1), coef: 1 })),
        bnds: { type: glpk.GLP_FX, lb: 1, ub: 1 },
      });
    }

  // Row constraints: each value appears once per row
  for (let r = 0; r < 9; r++)
    for (let k = 1; k <= 9; k++) {
      subjectTo.push({
        name: `row_${r}_${k}`,
        vars: Array.from({ length: 9 }, (_, c) => ({ name: varName(r, c, k), coef: 1 })),
        bnds: { type: glpk.GLP_FX, lb: 1, ub: 1 },
      });
    }

  // Column constraints
  for (let c = 0; c < 9; c++)
    for (let k = 1; k <= 9; k++) {
      subjectTo.push({
        name: `col_${c}_${k}`,
        vars: Array.from({ length: 9 }, (_, r) => ({ name: varName(r, c, k), coef: 1 })),
        bnds: { type: glpk.GLP_FX, lb: 1, ub: 1 },
      });
    }

  // Box constraints
  for (let br = 0; br < 3; br++)
    for (let bc = 0; bc < 3; bc++)
      for (let k = 1; k <= 9; k++) {
        const boxVars = [];
        for (let r = br * 3; r < br * 3 + 3; r++)
          for (let c = bc * 3; c < bc * 3 + 3; c++)
            boxVars.push({ name: varName(r, c, k), coef: 1 });
        subjectTo.push({
          name: `box_${br}_${bc}_${k}`,
          vars: boxVars,
          bnds: { type: glpk.GLP_FX, lb: 1, ub: 1 },
        });
      }

  // Given clues
  for (let r = 0; r < 9; r++)
    for (let c = 0; c < 9; c++)
      if (puzzle[r][c] !== 0) {
        subjectTo.push({
          name: `clue_${r}_${c}_${puzzle[r][c]}`,
          vars: [{ name: varName(r, c, puzzle[r][c]), coef: 1 }],
          bnds: { type: glpk.GLP_FX, lb: 1, ub: 1 },
        });
      }

  return {
    name: 'Sudoku',
    objective: {
      direction: glpk.GLP_MAX,
      name: 'obj',
      vars,
    },
    subjectTo,
    binaries,
  };
}

/**
 * Parse GLPK result into a 9x9 grid.
 * @param {any} result
 */
function resultToGrid(result) {
  const res = result.result || result;
  const vars = res.vars;
  const grid = Array.from({ length: 9 }, () => Array(9).fill(0));
  const entries = Array.isArray(vars)
    ? vars.map((v) => [v.name, v.value])
    : Object.entries(vars);
  for (const [name, value] of entries) {
    if (value > 0.5) {
      const [, r, c, k] = name.split('_').map(Number);
      grid[r][c] = k;
    }
  }
  return grid;
}

function checkOptimal(result, glpk) {
  const status = result.result?.status ?? result.status;
  return status === glpk.GLP_OPT;
}

/**
 * Solve a Sudoku puzzle using BILP.
 * @param {Grid} puzzle
 */
export async function solveBILP(puzzle) {
  const glpk = await getGlpk();
  const lp = await buildModel(puzzle);
  const result = await glpk.solve(lp, { msglev: glpk.GLP_MSG_OFF });
  if (!checkOptimal(result, glpk)) throw new Error('No solution found');
  return resultToGrid(result);
}

/**
 * Generate a random fully-solved grid using BILP with a randomized objective.
 */
export async function generateFullGridBILP() {
  const empty = Array.from({ length: 9 }, () => Array(9).fill(0));
  const glpk = await getGlpk();
  const lp = await buildModel(empty, true);
  const result = await glpk.solve(lp, { msglev: glpk.GLP_MSG_OFF });
  if (!checkOptimal(result, glpk)) throw new Error('Generation failed');
  return resultToGrid(result);
}
