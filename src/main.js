import { generatePuzzle } from './core.js';
import { solveBILP, getGlpk } from './bilp.js';

const gridEl = document.getElementById('grid');
const statusEl = document.getElementById('status');
const generateBtn = document.getElementById('generate');
const showBtn = document.getElementById('show-solution');
const hideBtn = document.getElementById('hide-solution');
const clueEl = document.getElementById('clue-count');
const timeEl = document.getElementById('solve-time');

let currentPuzzle = null;
let currentSolution = null;
let solutionVisible = false;

function render() {
  gridEl.innerHTML = '';
  if (!currentPuzzle) return;

  for (let r = 0; r < 9; r++) {
    for (let c = 0; c < 9; c++) {
      const cell = document.createElement('div');
      cell.className = 'cell';
      const given = currentPuzzle[r][c];
      const solved = currentSolution[r][c];

      if (given !== 0) {
        cell.textContent = given;
        cell.classList.add('given');
      } else {
        cell.textContent = solved;
        cell.classList.add('empty');
        if (!solutionVisible) cell.classList.add('hidden');
      }
      gridEl.appendChild(cell);
    }
  }
}

async function newPuzzle() {
  generateBtn.disabled = true;
  showBtn.disabled = true;
  hideBtn.disabled = true;
  statusEl.textContent = 'Generating puzzle…';

  const { puzzle, solved } = generatePuzzle(32);
  currentPuzzle = puzzle;

  statusEl.textContent = 'Solving with BILP…';
  const start = performance.now();
  currentSolution = await solveBILP(puzzle);
  const ms = (performance.now() - start).toFixed(1);

  solutionVisible = false;
  render();

  const clues = puzzle.flat().filter((v) => v !== 0).length;
  clueEl.textContent = `${clues} clues`;
  timeEl.textContent = `${ms} ms (BILP)`;
  statusEl.textContent = 'Ready.';

  generateBtn.disabled = false;
  showBtn.disabled = false;
  hideBtn.disabled = true;
}

generateBtn.addEventListener('click', newPuzzle);

showBtn.addEventListener('click', () => {
  solutionVisible = true;
  render();
  showBtn.disabled = true;
  hideBtn.disabled = false;
});

hideBtn.addEventListener('click', () => {
  solutionVisible = false;
  render();
  showBtn.disabled = false;
  hideBtn.disabled = true;
});

(async () => {
  await getGlpk();
  generateBtn.disabled = false;
  statusEl.textContent = 'Solver ready. Click “Generate New Puzzle”.';
})();
