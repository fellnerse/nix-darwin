// The flock's sheep, ported from herdr-mobile (web/app.js + style.css).
// Copied, not shared: see docs in herdr-mobile/docs/design.md for the reasoning.
// The web app styles the SVG with CSS classes; a standalone .svg file has no
// stylesheet, so every class became an inline attribute here.

const BREEDS = [
  { id: "white", fleece: "#eef1f6", face: "#ccd4e1" },
  { id: "suffolk", fleece: "#e9edf4", face: "#2c3242" },
  { id: "cream", fleece: "#e8dcb9", face: "#b8a878" },
  { id: "oatmeal", fleece: "#d8c9a8", face: "#6f6650" },
  { id: "tan", fleece: "#cfa26b", face: "#a97c49" },
  { id: "saddle", fleece: "#d9b98a", face: "#7a5636", patch: "#6b4a2f", mark: "saddle" },
  { id: "brown", fleece: "#8d5c3c", face: "#e0d4c4" },
  { id: "grey", fleece: "#9aa2b1", face: "#6d7688" },
  { id: "dalmatian", fleece: "#474f61", face: "#d7dce6", patch: "#eef1f6", mark: "dots" },
  { id: "black", fleece: "#2f3543", face: "#1d222c" },
  { id: "badger", fleece: "#5c6678", face: "#e3e8f1", patch: "#e8edf6", mark: "belt" },
  { id: "spotted", fleece: "#edf0f6", face: "#8d5c3c", patch: "#8d5c3c", mark: "spots" },
  { id: "jacob", fleece: "#c3c9d4", face: "#333a49", patch: "#333a49", mark: "spots" },
];

const MARKS = {
  spots: '<circle cx="13.5" cy="16.5" r="4.6"/><circle cx="27" cy="13.5" r="3.8"/>',
  dots: [
    [10, 14, 1.9], [15.5, 11, 1.7], [20.5, 15.5, 2], [25, 10.5, 1.7],
    [29.5, 14.5, 1.9], [13, 21, 1.7], [19, 21.5, 1.6], [25.5, 20.5, 1.8],
    [32, 19.5, 1.5], [8.5, 19, 1.5],
  ].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}"/>`).join(""),
  belt: '<rect x="14" y="0" width="7.5" height="34" rx="0.5"/>',
  saddle: '<path d="M6 4 h26 v9 q-13 4 -26 0 z"/>',
};

const HORNS = {
  none: "",
  curl: "M0 0 c-1.4 -3.2 -5.2 -4 -7 -1.4 c-1.4 2 -0.2 4.2 1.8 4.4",
  spiral: "M0 0 c-1.6 -3.8 -6.4 -5 -8.6 -1.8 c-1.9 2.8 -0.2 6 3 6 c2.4 0 3.6 -1.9 2.8 -3.6 c-0.6 -1.3 -2.3 -1.5 -3.2 -0.5",
};
const HORN_KINDS = ["none", "curl", "spiral"];
const COATS = ["woolly", "shorn", "fringe"];

const POSE = { working: "graze", idle: "stand", done: "sleep", blocked: "alert" };

const GRASS = "#4c9a5a";
const GRASS_SPENT = "#6b5f43";

function fnv1a(text) {
  let hash = 0x811c9dc5;
  for (let i = 0; i < text.length; i++) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 0x01000193);
  }
  return hash >>> 0;
}

function sheepMarks(seed) {
  const hash = fnv1a(String(seed || ""));
  return {
    breed: BREEDS[hash % BREEDS.length],
    horn: HORN_KINDS[(hash >>> 5) % HORN_KINDS.length],
    coat: COATS[(hash >>> 11) % COATS.length],
    muzzle: ((hash >>> 17) & 1) === 1,
  };
}

function isLight(hex) {
  const n = parseInt(hex.slice(1), 16);
  return ((n >> 16) * 0.299 + ((n >> 8) & 255) * 0.587 + (n & 255) * 0.114) > 110;
}
const eyeOn = (face) => (isLight(face) ? "#12161f" : "#e8edf6");
const hornOn = (fleece) => (isLight(fleece) ? "#4a4235" : "#e4d9bd");

function rimFor(fleece) {
  if (isLight(fleece)) return "";
  const n = parseInt(fleece.slice(1), 16);
  const mix = (c, to) => Math.round(c + (to - c) * 0.55);
  return `rgb(${mix(n >> 16, 0xc6)},${mix((n >> 8) & 255, 0xcf)},${mix(n & 255, 0xdd)})`;
}

function sheepBody(dy, legs, marks, clip, edge) {
  const woolly = `
    ${legs ? '<rect x="11" y="21" width="5" height="12" rx="2.5"/><rect x="23" y="21" width="5" height="12" rx="2.5"/>' : ""}
    <circle cx="11.5" cy="16" r="7.5"/><circle cx="18" cy="11" r="8"/>
    <circle cx="25.5" cy="11.5" r="7.5"/><circle cx="31" cy="16" r="7"/>
    <rect x="5" y="13" width="27" height="13" rx="6.5"/>`;
  const shorn = `
    ${legs ? '<rect x="12" y="21" width="4.4" height="13" rx="2.2"/><rect x="23.5" y="21" width="4.4" height="13" rx="2.2"/>' : ""}
    <ellipse cx="17" cy="18.5" rx="13" ry="7.4"/><ellipse cx="27.5" cy="16.5" rx="7" ry="6.2"/>`;
  const shape = marks.coat === "shorn" ? shorn : woolly;
  const mark = MARKS[marks.breed.mark];
  const pattern = mark
    ? `<clipPath id="${clip}">${shape}</clipPath><g clip-path="url(#${clip})" fill="${marks.breed.patch}">${mark}</g>`
    : "";
  const rim = rimFor(marks.breed.fleece) || edge;
  return `
    <g transform="translate(0 ${dy})">
      <g fill="${rim}" stroke="${rim}" stroke-width="2.6" stroke-linejoin="round">${shape}</g>
      <g fill="${marks.breed.fleece}">${shape}</g>
      ${pattern}
    </g>`;
}

function hornAt(m, x, y, rotate, edge) {
  const path = HORNS[m.horn];
  if (!path) return "";
  return `
    <g transform="translate(${x} ${y}) rotate(${rotate})" fill="none" stroke-linecap="round">
      <path d="${path}" stroke="${edge}" stroke-width="3.8"/>
      <path d="${path}" stroke="${hornOn(m.breed.fleece)}" stroke-width="2.1"/>
    </g>`;
}

const FRINGE = "M-5.6 -2.6 h11.2 v1.4 q-1.9 2.9 -3.8 0 q-1.9 2.9 -3.8 0 q-1.9 2.9 -3.8 0 z";
function fringeAt(m, x, y, rotate, edge) {
  return `<g transform="translate(${x} ${y}) rotate(${rotate})"><path d="${FRINGE}" fill="${m.breed.fleece}" stroke="${edge}" stroke-width="1.1" stroke-linejoin="round"/></g>`;
}

const HEAD_AT = {
  graze: { horn: [38, 15, 110], fringe: [36.4, 17.4, 18] },
  stand: { horn: [38, 8.2, 40], fringe: [36.2, 10.4, 0] },
  alert: { horn: [36.4, 6.2, 15], fringe: [36.6, 8, -6] },
  sleep: { horn: [38, 19.8, 110], fringe: [36.2, 22.6, 12] },
};

// pose -> [ear cx, cy, rx, ry, rotate], [face cx, cy], [muzzle cx, cy], [eye cx, cy, r]
const HEADS = {
  graze: { ear: [33.2, 15.2, 3, 1.8, -42], face: [36.6, 19.4], muzzle: [39.5, 20.5], eye: [38.2, 18, 1.2] },
  stand: { ear: [32.4, 9, 3, 1.8, -38], face: [36.4, 12.6], muzzle: [39.3, 13.7], eye: [38.2, 11.4, 1.2] },
  alert: { ear: [33.6, 6.2, 3.2, 1.7, -72], face: [36.8, 10.2], muzzle: [39.7, 11.3], eye: [38.6, 8.8, 1.3] },
  sleep: { ear: [32.6, 20.4, 3, 1.8, -30], face: [36.4, 24.6], muzzle: [39.3, 25.7], eye: null },
};

function head(pose, m, edge) {
  const h = HEADS[pose];
  const at = HEAD_AT[pose];
  const [ex, ey, erx, ery, er] = h.ear;
  const eye = eyeOn(m.breed.face);
  return `
    <ellipse cx="${ex}" cy="${ey}" rx="${erx}" ry="${ery}" transform="rotate(${er} ${ex} ${ey})" fill="#dfe5f0" stroke="${edge}" stroke-width="1"/>
    ${hornAt(m, ...at.horn, edge)}
    <ellipse cx="${h.face[0]}" cy="${h.face[1]}" rx="5.4" ry="4.6" fill="${m.breed.face}" stroke="${edge}" stroke-width="1.1"/>
    ${m.muzzle ? `<ellipse cx="${h.muzzle[0]}" cy="${h.muzzle[1]}" rx="2" ry="1.6" fill="${eye}"/>` : ""}
    ${m.coat === "fringe" ? fringeAt(m, ...at.fringe, edge) : ""}
    ${h.eye
      ? `<circle cx="${h.eye[0]}" cy="${h.eye[1]}" r="${h.eye[2]}" fill="${eye}"/>`
      : `<path d="M36.4 24.2 q1.6 1.4 3.2 0" fill="none" stroke="${edge}" stroke-width="1.3" stroke-linecap="round"/>`}`;
}

// ---- The pasture ----------------------------------------------------------
const GROUND = 33;
const FIELD = [
  [4.5, 5.4, -1.4], [9, 7, 0.9], [13.5, 5, -1], [18, 6.6, 1.2],
  [22.5, 5.2, -0.8], [27, 7.2, 1], [31.5, 6, -1.2],
];
const MOUTHFUL = [38.6, 11.6, 1.3];
const STUBBLE = 1.3;
const r1 = (n) => Math.round(n * 10) / 10;

export const bladesFor = (left) =>
  left > 0 ? Math.max(1, Math.min(FIELD.length, Math.round(left * FIELD.length))) : 0;

function blade(x, h, lean, color) {
  return `<path d="M${x} ${GROUND} q${r1(lean * 0.4)} ${r1(-h * 0.55)} ${r1(lean)} ${r1(-h)}" fill="none" stroke="${color}" stroke-width="1.5" stroke-linecap="round"/>`;
}
function stubble(x, lean, color) {
  return `<path d="M${x} ${GROUND} q${r1(lean * 0.2)} ${r1(-STUBBLE * 0.6)} ${r1(lean * 0.3)} ${r1(-STUBBLE)}" fill="none" stroke="${color}" stroke-width="1.2" stroke-linecap="round" opacity="0.5"/>`;
}

function grassSvg(pasture) {
  if (!pasture) return "";
  const color = pasture.spent ? GRASS_SPENT : GRASS;
  const standing = bladesFor(pasture.left);
  const eaten = FIELD.length - standing;
  const parts = FIELD.map(([x, h, lean], i) => (i < eaten ? stubble(x, lean, color) : blade(x, h, lean, color)));
  const [mx, mh, ml] = MOUTHFUL;
  parts.push(standing ? blade(mx, mh, ml, color) : stubble(mx, ml, color));
  return parts.join("");
}

let serial = 0;

/** A standalone SVG for one agent. `edge` is the colour of whatever the sheep
 *  stands on (it outlines every part against the row). Padded so horns fit. */
export function sheepSvg({ status, seed, pasture, edge }) {
  const pose = POSE[status] ?? "stand";
  const marks = sheepMarks(seed);
  const asleep = pose === "sleep";
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -5 52 42" width="52" height="42">
    ${sheepBody(asleep ? 5 : 0, !asleep, marks, `fleece-${++serial}`, edge)}
    ${head(pose, marks, edge)}
    ${grassSvg(pasture)}
  </svg>`;
}

/** Everything that changes the picture, so a file is written once per look. */
export function sheepKey({ status, seed, pasture, edge }) {
  const g = pasture ? `${bladesFor(pasture.left)}${pasture.spent ? "s" : ""}` : "x";
  return `${fnv1a(String(seed)).toString(36)}-${POSE[status] ?? "stand"}-${g}-${edge.replace("#", "")}`;
}

// The quota JSON from the gateway -> the field under one kind of agent.
// Same rule as the phone: the tightest live window, a rolled-over one is ignored.
export function pastureOf(quota, kind) {
  if (!kind || !quota) return null;
  const reading = (quota.agents || []).find((a) => a.agent === kind);
  if (!reading || reading.ok === false) return null;
  const live = (reading.buckets || []).filter((b) => !b.expired && (b.utilization > 0 || b.resets_at));
  if (!live.length) return null;
  const tightest = live.reduce((w, b) => (b.utilization > w.utilization ? b : w));
  return {
    left: Math.max(0, Math.min(100, 100 - tightest.utilization)) / 100,
    spent: !!reading.blocked || tightest.utilization >= 100,
  };
}
