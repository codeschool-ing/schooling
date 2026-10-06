#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of javascript, as a script that
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
# books/ holds three small JSON files the script writes before the first
# command. Programs that measure time round to the nearest 100 ms in their own
# source, because the exact milliseconds move on every run.
#
# Recorded on Ubuntu 24.04 with Node.js 22.22.0 and Chromium 141,
# TZ=America/Sao_Paulo.

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

put books/7.json <<'JSON'
{ "id": 7, "title": "Iracema", "authorId": 3 }
JSON
put books/12.json <<'JSON'
{ "id": 12, "title": "Dom Casmurro", "authorId": 1 }
JSON
put authors/1.json <<'JSON'
{ "id": 1, "name": "Machado de Assis" }
JSON
put authors/3.json <<'JSON'
{ "id": 3, "name": "José de Alencar" }
JSON

put callbacks.js <<'JS'
const fs = require("node:fs");

console.log("asking for book 12");
fs.readFile("books/12.json", "utf8", (err, text) => {
  if (err) {
    console.log("could not read the book:", err.code);
    return;
  }
  const book = JSON.parse(text);
  fs.readFile(`authors/${book.authorId}.json`, "utf8", (err, text) => {
    if (err) {
      console.log("could not read the author:", err.code);
      return;
    }
    console.log(book.title, "by", JSON.parse(text).name);
  });
});
console.log("asked; carrying on");

fs.readFile("books/99.json", "utf8", (err) => {
  console.log("book 99:", err.code);
});
JS
block callbacks
on 'node callbacks.js'

put promise.js <<'JS'
const { readFile } = require("node:fs/promises");

const p = readFile("books/12.json", "utf8");
console.log(p);

p.then((text) => JSON.parse(text))
  .then((book) => readFile(`authors/${book.authorId}.json`, "utf8").then((a) => [book, JSON.parse(a)]))
  .then(([book, author]) => console.log(book.title, "by", author.name))
  .catch((err) => console.log("failed:", err.code))
  .finally(() => console.log("done, either way"));

readFile("books/99.json", "utf8")
  .then(() => console.log("never printed"))
  .catch((err) => console.log("book 99:", err.code));
JS
block promise
on 'node promise.js'

put make-promise.js <<'JS'
function wait(ms, value) {
  return new Promise((resolve) => setTimeout(() => resolve(value), ms));
}

function failAfter(ms, message) {
  return new Promise((resolve, reject) => setTimeout(() => reject(new Error(message)), ms));
}

const p = wait(100, "a value");
console.log(p);
p.then((v) => console.log("fulfilled with", v, p));

const q = failAfter(150, "the shelf is empty");
q.catch((e) => console.log("rejected with", e.message, q));
JS
block make-promise
on 'node make-promise.js 2>&1 | head -n 8'

put chain-values.js <<'JS'
Promise.resolve(2)
  .then((n) => n * 10)
  .then((n) => {
    console.log("got", n);
  })
  .then((n) => console.log("then got", n));
JS
block chain-values
on 'node chain-values.js'

put await.mjs <<'JS'
import { readFile } from "node:fs/promises";

async function describe(id) {
  const book = JSON.parse(await readFile(`books/${id}.json`, "utf8"));
  const author = JSON.parse(await readFile(`authors/${book.authorId}.json`, "utf8"));
  return `${book.title} by ${author.name}`;
}

const result = describe(12);
console.log(result);
console.log(await result);

try {
  console.log(await describe(99));
} catch (err) {
  console.log("failed:", err.code);
}
JS
block await-out
run 'node await.mjs'

put timing.mjs <<'JS'
const round = (ms) => Math.round(ms / 100) * 100;
const fetchBook = (id) => new Promise((resolve) => setTimeout(() => resolve({ id }), 300));
const ids = [7, 12, 19, 21];

let t = performance.now();
const one = [];
for (const id of ids) {
  one.push(await fetchBook(id));
}
console.log("one after another:", one.length, "books in about", round(performance.now() - t), "ms");

t = performance.now();
const all = await Promise.all(ids.map((id) => fetchBook(id)));
console.log("all at once:      ", all.length, "books in about", round(performance.now() - t), "ms");
JS
block timing
on 'node timing.mjs'

put combinators.mjs <<'JS'
const wait = (ms, v) => new Promise((ok) => setTimeout(() => ok(v), ms));
const fail = (ms, m) => new Promise((_, no) => setTimeout(() => no(new Error(m)), ms));

const jobs = () => [wait(300, "mirror A"), fail(100, "mirror B is down"), wait(200, "mirror C")];

try {
  await Promise.all(jobs());
} catch (e) {
  console.log("all:       ", e.message);
}

const settled = await Promise.allSettled(jobs());
console.log("allSettled:", settled.map((r) => r.status === "fulfilled" ? r.value : `(${r.reason.message})`));

try {
  console.log("race:      ", await Promise.race(jobs()));
} catch (e) {
  console.log("race:       rejected,", e.message);
}

console.log("any:       ", await Promise.any(jobs()));
JS
block combinators
on 'node combinators.mjs'

put forgot.mjs <<'JS'
const save = async (book) => {
  await new Promise((ok) => setTimeout(ok, 50));
  throw new Error(`could not save ${book}`);
};

function onClick() {
  save("Iracema");
  console.log("saved!");
}

onClick();
JS
block forgot
on 'node forgot.mjs; echo "exit code: $?"'

put forgot.html <<'HTML'
<!doctype html>
<script>
  window.addEventListener("unhandledrejection", (event) => {
    console.log("nobody handled:", event.reason.message);
  });
  const save = async (book) => {
    throw new Error(`could not save ${book}`);
  };
  save("Iracema");
  console.log("saved!");
</script>
HTML
block forgot-page
on 'page forgot.html'
