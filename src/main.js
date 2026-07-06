import { generatePuzzle } from './core.js';
import { solveBILP, getGlpk } from './bilp.js';

const gridEl = document.getElementById('grid');
const statusEl = document.getElementById('status');
const generateBtn = document.getElementById('generate');
const restartBtn = document.getElementById('restart');
const showBtn = document.getElementById('show-solution');
const hideBtn = document.getElementById('hide-solution');
const pencilBtn = document.getElementById('pencil-mode');
const eraseBtn = document.getElementById('erase');
const numpad = document.querySelector('.numpad');
const clueEl = document.getElementById('clue-count');
const timeEl = document.getElementById('solve-time');

/** @type {{given:number,value:number,candidates:Set<number>,solution:number}[][] | null} */
let game = null;
let selected = null; // [r, c]
let pencilMode = false;
let solutionVisible = false;
/** @type {{value:number,candidates:number[]}[][] | null} */
let savedState = null;

function createEmptyGame() {
  return Array.from({ length: 9 }, () =>
    Array.from({ length: 9 }, () => ({
      given: 0,
      value: 0,
      candidates: new Set(),
      solution: 0,
    }))
  );
}

function deepCopyState() {
  if (!game) return null;
  return game.map((row) =>
    row.map((cell) => ({
      value: cell.value,
      candidates: Array.from(cell.candidates),
    }))
  );
}

function restoreState(state) {
  if (!game || !state) return;
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      const cell = game[r][c];
      const saved = state[r][c];
      cell.value = saved.value;
      cell.candidates = new Set(saved.candidates);
    }
  }
}

function render() {
  gridEl.innerHTML = '';
  if (!game) return;

  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      const cellData = game[r][c];
      const cell = document.createElement('div');
      cell.className = 'cell';
      cell.dataset.r = String(r);
      cell.dataset.c = String(c);

      const isSelected = selected && selected[0] === r && selected[1] === c;
      if (isSelected) cell.classList.add('selected');

      if (cellData.given !== 0) {
        cell.classList.add('given');
        cell.textContent = cellData.given;
      } else if (solutionVisible) {
        cell.classList.add('solution');
        cell.textContent = cellData.solution;
      } else if (cellData.value !== 0) {
        cell.classList.add('user');
        cell.textContent = cellData.value;
      } else if (cellData.candidates.size > 0) {
        cell.classList.add('candidates');
        for (let k = 1; k <= 9; k++) {
          const mark = document.createElement('span');
          mark.className = 'candidate';
          mark.textContent = cellData.candidates.has(k) ? String(k) : '';
          cell.appendChild(mark);
        }
      }

      cell.addEventListener('click', () => {
        selected = [r, c];
        render();
      });
      gridEl.appendChild(cell);
    }
  }
}

function setSelectedValue(num) {
  if (!game || !selected || solutionVisible) return;
  const [r, c] = selected;
  const cell = game[r][c];
  if (cell.given !== 0) return;

  if (pencilMode) {
    if (cell.candidates.has(num)) cell.candidates.delete(num);
    else {
      cell.candidates.add(num);
      cell.value = 0;
    }
  } else {
    if (cell.value === num) cell.value = 0;
    else {
      cell.value = num;
      cell.candidates.clear();
    }
  }
  render();
}

function eraseSelected() {
  if (!game || !selected || solutionVisible) return;
  const [r, c] = selected;
  const cell = game[r][c];
  if (cell.given !== 0) return;
  cell.value = 0;
  cell.candidates.clear();
  render();
}

function togglePencil() {
  pencilMode = !pencilMode;
  pencilBtn.classList.toggle('active', pencilMode);
}

function clearUserInput() {
  if (!game) return;
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      const cell = game[r][c];
      if (cell.given === 0) {
        cell.value = 0;
        cell.candidates.clear();
      }
    }
  }
  savedState = null;
  solutionVisible = false;
  showBtn.disabled = false;
  hideBtn.disabled = true;
  render();
}

async function newPuzzle() {
  generateBtn.disabled = true;
  restartBtn.disabled = true;
  showBtn.disabled = true;
  hideBtn.disabled = true;
  statusEl.textContent = 'Generating puzzle…';

  const { puzzle, solved } = generatePuzzle(32);
  game = createEmptyGame();
  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      game[r][c].given = puzzle[r][c];
      game[r][c].solution = solved[r][c];
    }
  }

  statusEl.textContent = 'Solving with BILP…';
  const start = performance.now();
  const bilpSolution = await solveBILP(puzzle);
  const ms = (performance.now() - start).toFixed(1);

  for (let r = 0; r < 9; r++)
    for (let c = 0; c < 9; c++)
      game[r][c].solution = bilpSolution[r][c];

  selected = null;
  solutionVisible = false;
  savedState = null;
  render();

  const clues = puzzle.flat().filter((v) => v !== 0).length;
  clueEl.textContent = `${clues} clues`;
  timeEl.textContent = `${ms} ms (BILP)`;
  statusEl.textContent = 'Ready. Select a cell, then use the numpad or keyboard.';

  generateBtn.disabled = false;
  restartBtn.disabled = false;
  showBtn.disabled = false;
  hideBtn.disabled = true;
}

// Controls
generateBtn.addEventListener('click', newPuzzle);
restartBtn.addEventListener('click', clearUserInput);

showBtn.addEventListener('click', () => {
  if (!game || solutionVisible) return;
  savedState = deepCopyState();
  solutionVisible = true;
  render();
  showBtn.disabled = true;
  hideBtn.disabled = false;
});

hideBtn.addEventListener('click', () => {
  if (!game || !solutionVisible) return;
  restoreState(savedState);
  solutionVisible = false;
  savedState = null;
  render();
  showBtn.disabled = false;
  hideBtn.disabled = true;
});

pencilBtn.addEventListener('click', togglePencil);
eraseBtn.addEventListener('click', eraseSelected);

numpad.addEventListener('click', (e) => {
  const btn = e.target.closest('button[data-num]');
  if (!btn) return;
  setSelectedValue(Number(btn.dataset.num));
});

// Keyboard support
document.addEventListener('keydown', (e) => {
  if (!selected) return;
  if (e.key >= '1' && e.key <= '9') {
    setSelectedValue(Number(e.key));
  } else if (e.key === 'Backspace' || e.key === 'Delete' || e.key === '0') {
    eraseSelected();
  } else if (e.key === 'n' || e.key === 'N') {
    togglePencil();
  }
});

(async () => {
  await getGlpk();
  statusEl.textContent = 'Solver ready. Generating first puzzle…';
  await newPuzzle();
})();
