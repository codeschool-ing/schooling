#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of javascript, as a script that
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

put object-dictionary.js <<'JS'
const iracema = { title: "Iracema" };
const casmurro = { title: "Dom Casmurro" };

const loans = {};
loans[iracema] = 3;
loans[casmurro] = 5;
console.log(Object.keys(loans), loans[iracema]);

const counts = {};
for (const word of ["the", "constructor", "the"]) {
  counts[word] = (counts[word] || 0) + 1;
}
console.log(counts.the);
console.log(counts.constructor);
JS
block object-dictionary
on 'node object-dictionary.js'

put map.js <<'JS'
const iracema = { title: "Iracema" };
const casmurro = { title: "Dom Casmurro" };

const loans = new Map();
loans.set(iracema, 3);
loans.set(casmurro, 5);
loans.set(1, "the number one");
loans.set("1", "the string one");

console.log(loans.get(iracema), loans.get(casmurro));
console.log(loans.get(1), "/", loans.get("1"));
console.log(loans.size, loans.has(casmurro));
loans.delete(1);

for (const [key, value] of loans) {
  console.log(typeof key, value);
}
JS
block map
on 'node map.js'

put map-convert.js <<'JS'
const prices = new Map([
  ["Iracema", 2990],
  ["Dom Casmurro", 3450],
]);
console.log(prices);

const asObject = Object.fromEntries(prices);
console.log(asObject);

const back = new Map(Object.entries(asObject));
console.log(back.get("Iracema"));
console.log(JSON.stringify(prices), JSON.stringify(asObject));
JS
block map-convert
on 'node map-convert.js'

put counts.js <<'JS'
const counts = new Map();
for (const word of ["the", "constructor", "the"]) {
  counts.set(word, (counts.get(word) ?? 0) + 1);
}
console.log(counts);
JS
block counts
on 'node counts.js'

put set.js <<'JS'
const tags = ["novel", "classic", "novel", "romance", "classic"];
const unique = new Set(tags);
console.log(unique, unique.size);
console.log([...unique]);

unique.add("novel");
unique.add("poetry");
console.log(unique.has("poetry"), unique.size);

console.log(new Set([NaN, NaN, 0, -0]).size);
console.log(new Set([{ id: 1 }, { id: 1 }]).size);
JS
block set
on 'node set.js'

put set-ops.js <<'JS'
const ana = new Set(["Iracema", "Dom Casmurro", "Macunaíma"]);
const bia = new Set(["Dom Casmurro", "O Cortiço"]);

console.log(ana.union(bia));
console.log(ana.intersection(bia));
console.log(ana.difference(bia));
console.log(ana.isSupersetOf(new Set(["Iracema"])));
JS
block set-ops
on 'node set-ops.js'

put byid.js <<'JS'
const books = [
  { id: 7, title: "Iracema" },
  { id: 12, title: "Dom Casmurro" },
];
const byId = new Map(books.map((b) => [b.id, b]));
console.log(byId.get(12).title, byId.size);
JS
block byid
on 'node byid.js'

put weakmap.js <<'JS'
const visits = new WeakMap();
const reader = { name: "ana" };

visits.set(reader, 1);
visits.set(reader, visits.get(reader) + 1);
console.log(visits.get(reader), visits.has(reader));
console.log(visits.size, typeof visits.keys);

visits.set("ana", 1);
JS
block weakmap
on 'node weakmap.js 2>&1 | head -n 7'

put private.js <<'JS'
const balances = new WeakMap();

function openAccount(owner) {
  const account = { owner };
  balances.set(account, 0);
  return account;
}

function deposit(account, cents) {
  balances.set(account, balances.get(account) + cents);
}

function balance(account) {
  return balances.get(account);
}

const acc = openAccount("ana");
deposit(acc, 1990);
deposit(acc, 500);
console.log(acc, balance(acc));
JS
block private-out
run 'node private.js'

put weakset.js <<'JS'
function countObjects(value, seen = new WeakSet()) {
  if (typeof value !== "object" || value === null) return 0;
  if (seen.has(value)) return 0;
  seen.add(value);
  let n = 1;
  for (const child of Object.values(value)) {
    n += countObjects(child, seen);
  }
  return n;
}

const author = { name: "Machado de Assis", books: [] };
const book = { title: "Dom Casmurro", author };
author.books.push(book);

console.log(countObjects(book));
JS
block weakset
on 'node weakset.js'

put weak-gc.js <<'JS'
const strong = new Map();
const weak = new WeakMap();

let a = { title: "kept by a Map" };
let b = { title: "kept by a WeakMap" };
strong.set(a, "data");
weak.set(b, "data");

const refA = new WeakRef(a);
const refB = new WeakRef(b);
a = null;
b = null;

setTimeout(() => {
  globalThis.gc();
  console.log("Map key:     ", refA.deref()?.title);
  console.log("WeakMap key: ", refB.deref()?.title);
  console.log("entries in the Map:", strong.size);
}, 0);
JS
block weak-gc
on 'node --expose-gc weak-gc.js'
