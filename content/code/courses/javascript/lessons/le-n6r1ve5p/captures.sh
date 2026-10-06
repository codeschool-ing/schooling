#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of javascript, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the user, Node.js, the browser
#   sudo bash captures.sh
#
# What is STAGED rather than typed: the files ana wrote (put below), whose
# contents the lesson shows in full.
#
# THE DEVTOOLS WINDOW IS NOT IN THESE TRANSCRIPTS. The lab's page command asks
# Chromium the same questions DevTools asks, through the same protocol (the
# Chrome DevTools Protocol): where it paused, what the call stack and the
# scopes held, which requests went out, where the CPU time went. What the
# lesson says about the panels themselves is description, and it says so.
#
# The profiler's milliseconds are this run's and move by a few from one run to
# the next; the waterfall is rounded to 100 ms and did not move in the runs
# made for this lesson.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 and Chromium 141, every page
# opened with the lab's page command, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# A line that starts with ana@dev:~/js$ is what ana typed, and what came back.
on() { printf 'ana@dev:~/js$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
# What a program printed, without the command, for a lesson that shows the
# program and its output side by side.
run() { lab exec ana "$*" 2>&1 || true; }
# A file ana wrote. The lesson shows it in full.
put() {
  local f=$1 body
  body=$(cat)
  printf '#####F %s\n%s\n#####E\n' "$f" "$body"
  lab exec ana "mkdir -p \"\$(dirname '$f')\" && cat > '$f'" <<<"$body"
}
block() { printf '##### %s\n' "$1"; }
lab reset >/dev/null

# ---- the console -------------------------------------------------------------
put consoles.js <<'X'
const books = [
  { id: 1, title: "Dom Casmurro", year: 1899, author: { name: "Machado de Assis", born: 1839 } },
  { id: 2, title: "Grande Sertão: Veredas", year: 1956, author: { name: "João Guimarães Rosa", born: 1908 } },
  { id: 3, title: "A Hora da Estrela", year: 1977, author: { name: "Clarice Lispector", born: 1920 } },
];

console.table(books, ["title", "year"]);

console.log(books[0]);
console.dir(books[0], { depth: 0 });

for (const book of books) {
  if (book.year > 1950) console.count("after 1950");
}

console.group("checking years");
console.assert(books.every((b) => b.year > 1900), "a book from before 1900");
console.assert(books.length === 3, "three books");
console.groupEnd();

function render(book) {
  console.trace("render", book.id);
}
render(books[1]);
X
block consoles
on 'node consoles.js 2>&1 | head -n 21'

# ---- breakpoints ---------------------------------------------------------------
put shelf.html <<'X'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Shelf</title></head>
<body>
  <ul id="books"></ul>
  <script src="shelf.js"></script>
</body>
</html>
X
put shelf.js <<'X'
async function load() {
  const res = await fetch("/api/books");
  const books = await res.json();
  render(books);
}

function render(books) {
  const list = document.querySelector("#books");
  for (let i = 0; i <= books.length; i++) {
    const book = books[i];
    const item = document.createElement("li");
    item.textContent = `${book.title} (${book.year})`;
    list.append(item);
  }
}

load();
X
block shelf-error
on "page shelf.html --dom '#books'"
block shelf-uncaught
on 'page shelf.html --break uncaught'
block shelf-condition
on "page shelf.html --break shelf.js:11 --if 'book === undefined'"
block shelf-fix
on "sed -i 's/i <= books.length/i < books.length/' shelf.js"
on 'sed -n 9p shelf.js'
on "page shelf.html --dom '#books'"
block shelf-step
on 'page shelf.html --break shelf.js:4 --step into --step over --step out'

# ---- debugger; ------------------------------------------------------------------
put find.html <<'X'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Find</title></head>
<body>
  <script src="find.js"></script>
</body>
</html>
X
put find.js <<'X'
const books = [
  { title: "Dom Casmurro", year: 1899 },
  { title: "Grande Sertão: Veredas", year: 1956 },
  { title: "A Hora da Estrela", year: 1977 },
];

function after(year) {
  const found = books.filter((book) => book.year > year);
  debugger;
  return found;
}

console.log(after(1950).length, "books after 1950");
X
block find
on 'page find.html'
on 'page find.html --break debugger'

# ---- the network ----------------------------------------------------------------
put missing.html <<'X'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Missing</title></head>
<body>
  <script type="module" src="missing.js"></script>
</body>
</html>
X
put missing.js <<'X'
for (const path of ["/api/books/2", "/api/books/9", "/api/broken"]) {
  const res = await fetch(path);
  console.log(path, "answered", res.status);
}
X
block missing
on 'page missing.html --network'
put waits.html <<'X'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Waits</title></head>
<body>
  <script type="module" src="waits.js"></script>
</body>
</html>
X
put waits.js <<'X'
const get = (book) => fetch(`/api/slow?ms=400&book=${book}`).then((res) => res.json());
const tenths = (ms) => Math.round(ms / 100) * 100;

async function oneByOne() {
  const t0 = performance.now();
  await get(1);
  await get(2);
  await get(3);
  console.log(`one by one: about ${tenths(performance.now() - t0)} ms`);
}

async function together() {
  const t0 = performance.now();
  await Promise.all([get(1), get(2), get(3)]);
  console.log(`together: about ${tenths(performance.now() - t0)} ms`);
}

await oneByOne();
await together();
X
block waits
on 'page waits.html --wait 3000 --waterfall'

# ---- the profiler ---------------------------------------------------------------
put sort.html <<'X'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Sort</title></head>
<body>
  <script src="sort.js"></script>
</body>
</html>
X
put sort.js <<'X'
const words = ["Sertão", "Estrela", "Casmurro", "Veredas", "Iracema", "Macunaíma", "Sagarana", "Capitães"];
const titles = Array.from({ length: 20000 }, (_, i) => `${words[i % 8]} ${words[(i * 7) % 8]} ${i}`);

function key(title) {
  return title.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function byTitle(list) {
  return [...list].sort((a, b) => key(a).localeCompare(key(b)));
}

const sorted = byTitle(titles);
console.log(sorted[0], "|", sorted.at(-1));
X
block sort-slow
on 'page sort.html --profile'
put sort-fixed.html <<'X'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Sort</title></head>
<body>
  <script src="sort-fixed.js"></script>
</body>
</html>
X
put sort-fixed.js <<'X'
const words = ["Sertão", "Estrela", "Casmurro", "Veredas", "Iracema", "Macunaíma", "Sagarana", "Capitães"];
const titles = Array.from({ length: 20000 }, (_, i) => `${words[i % 8]} ${words[(i * 7) % 8]} ${i}`);

function key(title) {
  return title.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function byTitle(list) {
  const keyed = list.map((title) => [key(title), title]);
  keyed.sort((a, b) => a[0].localeCompare(b[0]));
  return keyed.map(([, title]) => title);
}

const sorted = byTitle(titles);
console.log(sorted[0], "|", sorted.at(-1));
X
block sort-fixed
on 'page sort-fixed.html --profile'
