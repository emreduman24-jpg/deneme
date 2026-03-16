const TILE_SET = [
  { key: "dots-1", suit: "dots", rank: 1 },
  { key: "dots-2", suit: "dots", rank: 2 },
  { key: "dots-3", suit: "dots", rank: 3 },
  { key: "dots-4", suit: "dots", rank: 4 },
  { key: "dots-5", suit: "dots", rank: 5 },
  { key: "dots-6", suit: "dots", rank: 6 },
  { key: "bamboo-2", suit: "bamboo", rank: 2 },
  { key: "bamboo-3", suit: "bamboo", rank: 3 },
  { key: "bamboo-4", suit: "bamboo", rank: 4 },
  { key: "symbol-1", suit: "symbol", rank: 1, char: "一萬" },
  { key: "symbol-5", suit: "symbol", rank: 5, char: "五萬" },
  { key: "symbol-9", suit: "symbol", rank: 9, char: "九萬" },
  { key: "dragon-red", suit: "dragon", rank: 0, char: "中" },
  { key: "dragon-green", suit: "dragon", rank: 0, char: "發" },
  { key: "wind-east", suit: "wind", rank: 0, char: "東" },
  { key: "wind-north", suit: "wind", rank: 0, char: "北" }
];

const TILE_MAP = Object.fromEntries(TILE_SET.map((tile) => [tile.key, tile]));

const layout = [
  { row: 0, col: 3, z: 2 },
  ...Array.from({ length: 8 }, (_, i) => ({ row: 1, col: i, z: 1 })),
  ...Array.from({ length: 7 }, (_, i) => ({ row: 2, col: i + 1, z: 0 })),
  ...Array.from({ length: 6 }, (_, i) => ({ row: 3, col: i + 1, z: 0 })),
  ...Array.from({ length: 5 }, (_, i) => ({ row: 4, col: i + 2, z: 0 })),
  ...Array.from({ length: 4 }, (_, i) => ({ row: 5, col: i + 2, z: 0 })),
  { row: 6, col: 2, z: 0 },
  { row: 6, col: 5, z: 0 },
  { row: 6, col: 4, z: 1 },
  { row: 3, col: 3, z: 1 },
  { row: 3, col: 4, z: 1 },
  { row: 3, col: 5, z: 1 }
];

const tileW = 76;
const tileH = 100;
const dx = 44;
const dy = 72;

const boardEl = document.getElementById("board");
const trayEl = document.getElementById("tray");
const scoreEl = document.getElementById("score");
const modalEl = document.getElementById("modal");
const modalTitleEl = document.getElementById("modalTitle");
const modalTextEl = document.getElementById("modalText");

const state = {
  tiles: [],
  tray: [],
  history: [],
  score: 0
};

function makeDeck(size) {
  const neededTypes = Math.ceil(size / 3);
  const pool = [];
  for (let i = 0; i < neededTypes; i += 1) {
    const key = TILE_SET[i % TILE_SET.length].key;
    pool.push(key, key, key);
  }
  while (pool.length > size) pool.pop();

  for (let i = pool.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool;
}

function isBlocked(tile, tiles) {
  if (tile.removed) return true;

  const covered = tiles.some((other) => {
    if (other.removed || other.id === tile.id || other.z <= tile.z) return false;
    return Math.abs(other.x - tile.x) < tileW * 0.75 && Math.abs(other.y - tile.y) < tileH * 0.75;
  });

  if (covered) return true;

  const leftBlocked = tiles.some((other) => {
    if (other.removed || other.id === tile.id || other.z !== tile.z) return false;
    return other.row === tile.row && other.col === tile.col - 1;
  });

  const rightBlocked = tiles.some((other) => {
    if (other.removed || other.id === tile.id || other.z !== tile.z) return false;
    return other.row === tile.row && other.col === tile.col + 1;
  });

  return leftBlocked && rightBlocked;
}

function createDot(colorClass = "green") {
  const dot = document.createElement("span");
  dot.className = `dot ${colorClass}`;
  return dot;
}

function createBamboo(colorClass = "green") {
  const bamboo = document.createElement("span");
  bamboo.className = `bamboo ${colorClass}`;
  return bamboo;
}

function createFace(tileDef) {
  const face = document.createElement("div");
  face.className = `tile-face ${tileDef.suit}`;

  if (tileDef.suit === "dots") {
    const counts = [
      ["green"],
      ["red", "blue"],
      ["green", "red", "blue"],
      ["blue", "green", "green", "blue"],
      ["blue", "green", "red", "green", "blue"],
      ["green", "green", "green", "red", "red", "red"]
    ];
    const colors = counts[tileDef.rank - 1] || counts[0];
    colors.forEach((color) => face.appendChild(createDot(color)));
  } else if (tileDef.suit === "bamboo") {
    const colorsByRank = {
      2: ["green", "blue"],
      3: ["green", "blue", "green"],
      4: ["blue", "green", "green", "blue"]
    };
    (colorsByRank[tileDef.rank] || ["green"]).forEach((color) => face.appendChild(createBamboo(color)));
  } else {
    const char = document.createElement("span");
    char.className = "hanzi";
    char.textContent = tileDef.char;
    face.appendChild(char);

    const rank = document.createElement("span");
    rank.className = "mini-rank";
    rank.textContent = tileDef.rank > 0 ? String(tileDef.rank) : "";
    face.appendChild(rank);
  }

  return face;
}

function trayLabel(tileKey) {
  const tileDef = TILE_MAP[tileKey];
  if (!tileDef) return "";
  if (tileDef.suit === "dots") return `${tileDef.rank}●`;
  if (tileDef.suit === "bamboo") return `${tileDef.rank}ⵊ`;
  return tileDef.char;
}

function renderTray() {
  trayEl.innerHTML = "";
  for (let i = 0; i < 4; i += 1) {
    const slot = document.createElement("div");
    slot.className = "tray-slot";
    slot.textContent = state.tray[i] ? trayLabel(state.tray[i]) : "";
    trayEl.appendChild(slot);
  }
}

function checkMatches() {
  const counts = {};
  state.tray.forEach((key) => {
    counts[key] = (counts[key] || 0) + 1;
  });

  let matched = false;
  Object.entries(counts).forEach(([key, count]) => {
    if (count >= 3) {
      let removed = 0;
      state.tray = state.tray.filter((item) => {
        if (item === key && removed < 3) {
          removed += 1;
          return false;
        }
        return true;
      });
      state.score += 30;
      matched = true;
    }
  });

  if (matched) scoreEl.textContent = String(state.score);
}

function renderBoard() {
  boardEl.innerHTML = "";

  const activeTiles = state.tiles.filter((t) => !t.removed);

  activeTiles
    .sort((a, b) => a.z - b.z)
    .forEach((tile) => {
      const btn = document.createElement("button");
      btn.className = "tile";
      btn.style.left = `${tile.x}px`;
      btn.style.top = `${tile.y}px`;
      btn.style.zIndex = String(tile.z * 100 + tile.row * 2 + tile.col);
      btn.appendChild(createFace(TILE_MAP[tile.key]));

      const blocked = isBlocked(tile, activeTiles);
      if (blocked) btn.classList.add("locked");

      btn.addEventListener("click", () => {
        if (isBlocked(tile, state.tiles)) return;

        state.history.push({
          tileId: tile.id,
          trayBefore: [...state.tray],
          scoreBefore: state.score
        });

        tile.removed = true;
        state.tray.push(tile.key);
        checkMatches();
        renderTray();
        renderBoard();
        checkEndState();
      });

      boardEl.appendChild(btn);
    });
}

function checkEndState() {
  const remaining = state.tiles.filter((t) => !t.removed).length;
  if (remaining === 0 && state.tray.length === 0) {
    showModal("Tebrikler!", `Skorun: ${state.score}`);
    return;
  }

  if (state.tray.length >= 4) {
    showModal("Oyun bitti", "Tepsi doldu. Tekrar dene!");
  }
}

function showModal(title, text) {
  modalTitleEl.textContent = title;
  modalTextEl.textContent = text;
  modalEl.classList.remove("hidden");
}

function resetGame() {
  state.score = 0;
  state.tray = [];
  state.history = [];

  const deck = makeDeck(layout.length);
  state.tiles = layout.map((pos, i) => ({
    id: i,
    ...pos,
    x: pos.col * dx + pos.z * 5,
    y: pos.row * dy - pos.z * 7,
    key: deck[i],
    removed: false
  }));

  scoreEl.textContent = "0";
  modalEl.classList.add("hidden");
  renderTray();
  renderBoard();
}

function showHint() {
  const clickable = state.tiles.filter((t) => !t.removed && !isBlocked(t, state.tiles));
  if (!clickable.length) return;
  const pick = clickable[Math.floor(Math.random() * clickable.length)];
  const buttons = [...boardEl.querySelectorAll(".tile")];
  const target = buttons.find((el) => Number.parseFloat(el.style.left) === pick.x && Number.parseFloat(el.style.top) === pick.y);
  if (!target) return;

  target.classList.add("hint");
  setTimeout(() => target.classList.remove("hint"), 900);
}

function shuffleFreeTiles() {
  const free = state.tiles.filter((t) => !t.removed && !isBlocked(t, state.tiles));
  const keys = free.map((t) => t.key);
  for (let i = keys.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [keys[i], keys[j]] = [keys[j], keys[i]];
  }
  free.forEach((tile, idx) => {
    tile.key = keys[idx];
  });
  renderBoard();
}

function undo() {
  const last = state.history.pop();
  if (!last) return;

  const tile = state.tiles.find((t) => t.id === last.tileId);
  tile.removed = false;
  state.tray = last.trayBefore;
  state.score = last.scoreBefore;
  scoreEl.textContent = String(state.score);

  modalEl.classList.add("hidden");
  renderTray();
  renderBoard();
}

document.getElementById("restartBtn").addEventListener("click", resetGame);
document.getElementById("hintBtn").addEventListener("click", showHint);
document.getElementById("shuffleBtn").addEventListener("click", shuffleFreeTiles);
document.getElementById("undoBtn").addEventListener("click", undo);
document.getElementById("backBtn").addEventListener("click", resetGame);
document.getElementById("menuBtn").addEventListener("click", () => showModal("Menü", "Bu demoda ekstra menü yok."));

resetGame();
