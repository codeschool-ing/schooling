#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of javascript, as a script that
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
# Memory figures move from run to run by a few hundred kilobytes, so every
# program rounds them to whole megabytes in its own source. --expose-gc gives
# the programs a gc() to call, so a measurement is taken after a collection
# rather than whenever V8 felt like one; ordinary programs never call it.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0, TZ=America/Sao_Paulo.

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

put lifecycle.js <<'JS'
const mb = () => {
  globalThis.gc();
  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
};

console.log("at start:          ", mb(), "MB");

let books = Array.from({ length: 1_000_000 }, (_, i) => ({ id: i, title: `book ${i}` }));
console.log("a million books:   ", mb(), "MB");

books = null;
console.log("after letting go:  ", mb(), "MB");
JS
block lifecycle
on 'node --expose-gc lifecycle.js'

put cycle.js <<'JS'
let author = { name: "Machado de Assis" };
let book = { title: "Dom Casmurro", author };
author.books = [book];

const ref = new WeakRef(author);
author = null;
book = null;

setTimeout(() => {
  globalThis.gc();
  console.log("the pair after collection:", ref.deref());
}, 0);
JS
block cycle
on 'node --expose-gc cycle.js'

put usage.js <<'JS'
const mb = (n) => `${Math.round(n / 1024 / 1024)} MB`;
const u = process.memoryUsage();
console.log("rss      ", mb(u.rss), "  everything the process holds");
console.log("heapTotal", mb(u.heapTotal), "  the heap V8 has reserved");
console.log("heapUsed ", mb(u.heapUsed), "  what live JavaScript objects use");
console.log("external ", mb(u.external), "  memory outside the heap, such as buffers");
JS
block usage
on 'node --expose-gc usage.js'

put cache-leak.js <<'JS'
const mb = () => {
  globalThis.gc();
  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
};

const cache = new Map();
function render(bookId) {
  if (!cache.has(bookId)) cache.set(bookId, `<li>book ${bookId}</li>`.repeat(20));
  return cache.get(bookId);
}

for (let hour = 1; hour <= 4; hour++) {
  for (let i = 0; i < 50_000; i++) render(`${hour}-${i}`);
  console.log(`hour ${hour}: ${cache.size} entries, ${mb()} MB`);
}
JS
block cache-leak
on 'node --expose-gc cache-leak.js'

put cache-bounded.js <<'JS'
const mb = () => {
  globalThis.gc();
  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
};

const LIMIT = 1000;
const cache = new Map();
function render(bookId) {
  if (cache.has(bookId)) {
    const value = cache.get(bookId);
    cache.delete(bookId);
    cache.set(bookId, value);
    return value;
  }
  const value = `<li>book ${bookId}</li>`.repeat(20);
  cache.set(bookId, value);
  if (cache.size > LIMIT) cache.delete(cache.keys().next().value);
  return value;
}

for (let hour = 1; hour <= 4; hour++) {
  for (let i = 0; i < 50_000; i++) render(`${hour}-${i}`);
  console.log(`hour ${hour}: ${cache.size} entries, ${mb()} MB`);
}
JS
block cache-bounded-out
run 'node --expose-gc cache-bounded.js'

put listeners.js <<'JS'
const { EventEmitter } = require("node:events");

const catalogue = new EventEmitter();
process.on("warning", (w) => console.log(`${w.name}: ${w.message}`));

function handleRequest(n) {
  const page = { n, rows: new Array(10_000).fill("row") };
  catalogue.on("updated", () => console.log("refresh page", page.n));
}

for (let n = 1; n <= 12; n++) handleRequest(n);
console.log("listeners now:", catalogue.listenerCount("updated"));
JS
block listeners
on 'node --no-warnings listeners.js'

put timer-leak.js <<'JS'
function startWidget() {
  const big = new Array(1_000_000).fill("data");
  const timer = setInterval(() => big.length, 1000);
  return { timer, ref: new WeakRef(big) };
}

const forgotten = startWidget();
const stopped = startWidget();
clearInterval(stopped.timer);

setTimeout(() => {
  globalThis.gc();
  console.log("widget never stopped, data alive:", forgotten.ref.deref() !== undefined);
  console.log("widget stopped, data alive:      ", stopped.ref.deref() !== undefined);
  process.exit(0);
}, 100);
JS
block timer-leak
on 'node --expose-gc timer-leak.js'

put finalization.js <<'JS'
const registry = new FinalizationRegistry((label) => console.log("collected:", label));

(function () {
  const cover = { image: new Array(100_000).fill(0) };
  registry.register(cover, "the cover of Iracema");
})();

console.log("cover dropped");
setTimeout(() => globalThis.gc(), 0);
setTimeout(() => console.log("done"), 100);
JS
block finalization
on 'node --expose-gc finalization.js'
