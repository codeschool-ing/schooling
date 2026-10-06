#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of javascript, as a script that
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

put classic/a.js <<'JS'
function format(title) {
  return `A: ${title}`;
}
JS
put classic/b.js <<'JS'
function format(title) {
  return `B: ${title}`;
}
JS
put classic/page.html <<'HTML'
<!doctype html>
<script src="a.js"></script>
<script src="b.js"></script>
<script>
  console.log(format("Iracema"));
</script>
HTML
block classic
on 'cd classic && page page.html'

put esm/books.mjs <<'JS'
console.log("books.mjs is running");

export const books = [
  { title: "Iracema", year: 1865 },
  { title: "Dom Casmurro", year: 1899 },
];

export function byYear(list) {
  return list.toSorted((a, b) => a.year - b.year);
}

export default class Catalogue {
  constructor(items) {
    this.items = items;
  }
  get size() {
    return this.items.length;
  }
}
JS
put esm/main.mjs <<'JS'
import Catalogue, { books, byYear as sortByYear } from "./books.mjs";
import * as everything from "./books.mjs";

console.log(sortByYear(books).map((b) => b.title));
console.log(new Catalogue(books).size);
console.log(Object.keys(everything));
console.log(typeof byYear, this);
JS
block esm
on 'node esm/main.mjs'

put esm/wrong-name.mjs <<'JS'
import { byTitle } from "./books.mjs";
JS
put esm/no-extension.mjs <<'JS'
import { books } from "./books";
JS
block esm-errors
on 'node esm/wrong-name.mjs 2>&1 | grep Error'
on 'node esm/no-extension.mjs 2>&1 | grep Error'

put typed/package.json <<'JSON'
{
  "name": "typed",
  "type": "module"
}
JSON
put typed/hello.js <<'JS'
import { basename } from "node:path";
console.log(basename(import.meta.filename), typeof require);
JS
block type-module
on 'cat typed/package.json'
on 'node typed/hello.js'

put web/format.js <<'JS'
export function label(title, year) {
  return `${title} (${year})`;
}
JS
put web/app.js <<'JS'
import { label } from "./format.js";

const heading = document.querySelector("h1");
console.log(heading.textContent, "/", label("Iracema", 1865));
console.log(typeof this, typeof window.label, document.readyState);
JS
put web/index.html <<'HTML'
<!doctype html>
<head>
  <script type="module" src="app.js"></script>
</head>
<body>
  <h1>Catalogue</h1>
</body>
HTML
block web
on 'cd web && page index.html'
on 'cd web && page index.html --file'

put cjs/books.js <<'JS'
console.log("books.js is running");

const books = [
  { title: "Iracema", year: 1865 },
  { title: "Dom Casmurro", year: 1899 },
];

function byYear(list) {
  return list.toSorted((a, b) => a.year - b.year);
}

module.exports = { books, byYear };
JS
put cjs/main.js <<'JS'
const { books, byYear } = require("./books");
const again = require("./books.js");

console.log(byYear(books).map((b) => b.title));
console.log(again.books === books);
console.log(this === module.exports, arguments.length);
console.log(__filename);
JS
block cjs
on 'node cjs/main.js'

block wrapper
on "node -p 'require(\"node:module\").wrapper'"

put live/counter.mjs <<'JS'
export let count = 0;
export function increment() {
  count += 1;
}
JS
put live/main.mjs <<'JS'
import { count, increment } from "./counter.mjs";

console.log(count);
increment();
increment();
console.log(count);
JS
put live/counter.cjs <<'JS'
let count = 0;
function increment() {
  count += 1;
}
module.exports = { count, increment };
JS
put live/main.cjs <<'JS'
const { count, increment } = require("./counter.cjs");

console.log(count);
increment();
increment();
console.log(count);
JS
put live/assign.mjs <<'JS'
import { count } from "./counter.mjs";
count = 10;
JS
block live
on 'node live/main.mjs'
on 'node live/main.cjs'
on 'node live/assign.mjs 2>&1 | grep Error'

put mixed/legacy.cjs <<'JS'
exports.greet = (name) => `hello, ${name}`;
exports.version = "1.4.0";
JS
put mixed/modern.mjs <<'JS'
export const shout = (text) => `${text.toUpperCase()}!`;
JS
put mixed/use-legacy.mjs <<'JS'
import legacy, { greet } from "./legacy.cjs";
console.log(greet("ana"), legacy.version);
JS
put mixed/use-modern.cjs <<'JS'
const { shout } = require("./modern.mjs");
console.log(shout("ana"));
JS
block mixed
on 'node mixed/use-legacy.mjs'
on 'node mixed/use-modern.cjs'

put lazy/report.mjs <<'JS'
console.log("report.mjs loaded");
export function render(rows) {
  return rows.map((r) => `- ${r}`).join("\n");
}
JS
put lazy/main.mjs <<'JS'
const wantsReport = process.argv[2] === "report";
console.log("start");

if (wantsReport) {
  const { render } = await import("./report.mjs");
  console.log(render(["Iracema", "Dom Casmurro"]));
}
console.log("end");
JS
block lazy
on 'node lazy/main.mjs'
on 'node lazy/main.mjs report'
