#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of javascript, as a script that
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
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 and Chromium 141,
# TZ=America/Sao_Paulo.
set -uo pipefail
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

put protocol.js <<'JS'
const shelf = ["Iracema", "Dom Casmurro"];
const it = shelf[Symbol.iterator]();

console.log(it.next());
console.log(it.next());
console.log(it.next());
console.log(it.next());
console.log(typeof Symbol.iterator, typeof shelf[Symbol.iterator]);
JS
block protocol
on 'node protocol.js'

put strings.js <<'JS'
const word = "Olá \u{1F44B}";
console.log(word.length, [...word].length);
console.log([...word].map((ch) => ch.codePointAt(0).toString(16)));
console.log(word.split("").map((unit) => unit.charCodeAt(0).toString(16)));
JS
block strings
on 'node strings.js'

put of-in.js <<'JS'
const shelf = ["Iracema", "Dom Casmurro"];
Array.prototype.extra = "added by some library";

for (const i in shelf) {
  console.log("in:", i, typeof i);
}
for (const title of shelf) {
  console.log("of:", title);
}

const loans = new Map([["Iracema", 3]]);
for (const [title, n] of loans) {
  console.log(title, n);
}
JS
block of-in
on 'node of-in.js'

put not-iterable.js <<'JS'
const book = { title: "Iracema", year: 1865 };
for (const [key, value] of Object.entries(book)) {
  console.log(key, value);
}
for (const part of book) {
  console.log(part);
}
JS
block not-iterable
on 'node not-iterable.js 2>&1 | head -n 7'

put consumers.js <<'JS'
const noisy = {
  [Symbol.iterator]() {
    let n = 0;
    return {
      next() {
        n += 1;
        console.log(`  next() call ${n}`);
        return n <= 2 ? { value: n * 10, done: false } : { value: undefined, done: true };
      },
    };
  },
};

console.log("spread:", [...noisy]);
console.log("destructuring:");
const [first] = noisy;
console.log(first);
console.log("Array.from:", Array.from(noisy));
JS
block consumers
on 'node consumers.js'

put range.js <<'JS'
class Range {
  constructor(from, to, step = 1) {
    this.from = from;
    this.to = to;
    this.step = step;
  }

  [Symbol.iterator]() {
    let current = this.from;
    const { to, step } = this;
    return {
      next() {
        if (current > to) return { value: undefined, done: true };
        const value = current;
        current += step;
        return { value, done: false };
      },
    };
  }
}

const r = new Range(1, 10, 3);
console.log([...r]);
console.log([...r]);
console.log(Math.max(...new Range(1900, 1930, 10)));
JS
block range-out
run 'node range.js'

put generator.js <<'JS'
function* steps() {
  console.log("  body: started");
  yield "first";
  console.log("  body: after first");
  yield "second";
  console.log("  body: finishing");
  return "done";
}

const g = steps();
console.log("created, nothing has run yet");
console.log(g.next());
console.log(g.next());
console.log(g.next());
console.log(g.next());
JS
block generator
on 'node generator.js'

put range-gen.js <<'JS'
class Range {
  constructor(from, to, step = 1) {
    Object.assign(this, { from, to, step });
  }

  *[Symbol.iterator]() {
    for (let n = this.from; n <= this.to; n += this.step) {
      yield n;
    }
  }
}

console.log([...new Range(1, 10, 3)]);
JS
block range-gen
on 'node range-gen.js'

put lazy.js <<'JS'
let produced = 0;

function* naturals() {
  let n = 1;
  while (true) {
    produced += 1;
    yield n++;
  }
}

function* filter(items, keep) {
  for (const item of items) {
    if (keep(item)) yield item;
  }
}

function* map(items, change) {
  for (const item of items) yield change(item);
}

function* take(items, count) {
  if (count <= 0) return;
  for (const item of items) {
    yield item;
    if (--count === 0) return;
  }
}

const result = take(map(filter(naturals(), (n) => n % 7 === 0), (n) => n * n), 4);
console.log([...result]);
console.log("numbers produced:", produced);
JS
block lazy
on 'node lazy.js'

put talk.js <<'JS'
function* conversation() {
  const name = yield "What is your name?";
  const book = yield `Hello, ${name}. Which book?`;
  return `${name} is reading ${book}`;
}

const c = conversation();
console.log(c.next().value);
console.log(c.next("ana").value);
console.log(c.next("Iracema"));
JS
block talk
on 'node talk.js'

put cleanup.js <<'JS'
function* pages() {
  try {
    yield "page 1";
    yield "page 2";
    yield "page 3";
  } finally {
    console.log("closing the file");
  }
}

for (const p of pages()) {
  console.log(p);
  if (p === "page 2") break;
}

function* everything() {
  yield* ["cover", "contents"];
  yield* pages();
  yield "back cover";
}
console.log([...everything()]);
JS
block cleanup
on 'node cleanup.js'

put async-pages.mjs <<'JS'
const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function* fetchPages(total) {
  for (let page = 1; page <= total; page += 1) {
    await wait(50);
    yield { page, titles: [`book ${page * 2 - 1}`, `book ${page * 2}`] };
  }
}

for await (const { page, titles } of fetchPages(3)) {
  console.log(page, titles);
}
console.log("all pages read");
JS
block async-pages
on 'node async-pages.mjs'
