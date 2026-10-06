#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of javascript, as a script that
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

put objects.js <<'JS'
const field = "year";
const book = {
  title: "Dom Casmurro",
  author: "Machado de Assis",
  [field]: 1899,
  "page count": 256,
  describe() {
    return `${this.title}, ${this.year}`;
  },
};

console.log(book.title, book["author"], book[field]);
console.log(book["page count"]);
console.log(book.describe());
console.log(book.isbn);

book.isbn = "978-85-359-0277-8";
delete book["page count"];
console.log("isbn" in book, "page count" in book);
console.log(Object.keys(book));
JS
block objects
on 'node objects.js'

put shorthand.js <<'JS'
const title = "Iracema";
const year = 1865;
const book = { title, year };
console.log(book);
console.log(Object.entries(book));
JS
block shorthand
on 'node shorthand.js'

put references.js <<'JS'
const original = { title: "Iracema", copies: 3 };
const alias = original;
alias.copies = 0;
console.log(original.copies);

function lend(book) {
  book.copies = book.copies - 1;
}
const other = { title: "Dom Casmurro", copies: 2 };
lend(other);
console.log(other.copies);
JS
block references
on 'node references.js'

put copies.js <<'JS'
const book = { title: "Iracema", author: { name: "José de Alencar" } };

const shallow = { ...book };
shallow.title = "Ubirajara";
shallow.author.name = "J. de Alencar";
console.log(book.title, "/", book.author.name);

const deep = structuredClone(book);
deep.author.name = "Alencar";
console.log(book.author.name, "/", deep.author.name);
JS
block copies
on 'node copies.js'

put arrays.js <<'JS'
const shelf = ["Iracema", "Dom Casmurro", "O Cortiço"];
console.log(shelf[0], shelf.length, shelf[shelf.length - 1], shelf.at(-1));
console.log(shelf[10]);

shelf.push("Macunaíma");
const removed = shelf.shift();
console.log(removed, shelf);

console.log(shelf.includes("O Cortiço"), shelf.indexOf("Iracema"));
console.log(shelf.slice(0, 2), shelf.length);
shelf.splice(1, 1);
console.log(shelf);
JS
block arrays
on 'node arrays.js'

put sort.js <<'JS'
const years = [1899, 1865, 1928, 1890];
const sizes = [10, 9, 1, 100];

console.log(sizes.sort());
console.log(sizes.sort((a, b) => a - b));

const sorted = years.toSorted((a, b) => a - b);
console.log(sorted, years);

const authors = ["Érico", "Clarice", "Jorge", "Ana"];
console.log(authors.toSorted());
console.log(authors.toSorted((a, b) => a.localeCompare(b, "pt-BR")));
JS
block sort
on 'node sort.js'

put methods.js <<'JS'
const books = [
  { title: "Iracema", year: 1865, pages: 112 },
  { title: "Dom Casmurro", year: 1899, pages: 256 },
  { title: "Macunaíma", year: 1928, pages: 208 },
  { title: "O Cortiço", year: 1890, pages: 304 },
];

const titles = books.map((b) => b.title);
console.log(titles);

const older = books.filter((b) => b.year < 1900);
console.log(older.length);

const first = books.find((b) => b.pages > 250);
console.log(first.title);

console.log(books.some((b) => b.year > 1920), books.every((b) => b.pages > 100));

const totalPages = books.reduce((sum, b) => sum + b.pages, 0);
console.log(totalPages);

const report = books
  .filter((b) => b.year < 1900)
  .toSorted((a, b) => a.year - b.year)
  .map((b) => `${b.year} ${b.title}`);
console.log(report);
JS
block methods-out
run 'node methods.js'

put foreach.js <<'JS'
const titles = ["Iracema", "Dom Casmurro"];
const result = titles.forEach((t) => t.toUpperCase());
console.log(result);

for (const t of titles) {
  console.log(t.length);
}
JS
block foreach
on 'node foreach.js'

put spread.js <<'JS'
const fiction = ["Iracema", "Dom Casmurro"];
const poetry = ["Lira dos Vinte Anos"];
const all = [...fiction, ...poetry, "Macunaíma"];
console.log(all);

const years = [1899, 1865, 1928];
console.log(Math.max(...years));

const defaults = { theme: "light", perPage: 20, language: "en" };
const chosen = { perPage: 50, language: "pt" };
console.log({ ...defaults, ...chosen });
console.log({ ...chosen, ...defaults });

function total(label, ...amounts) {
  return `${label}: ${amounts.reduce((a, b) => a + b, 0)}`;
}
console.log(total("pages", 112, 256, 208));
JS
block spread
on 'node spread.js'

put destructuring.js <<'JS'
const book = { title: "Dom Casmurro", year: 1899, author: { name: "Machado de Assis" } };

const { title, year } = book;
console.log(title, year);

const { title: name, pages = 0, isbn } = book;
console.log(name, pages, isbn);

const { author: { name: authorName } } = book;
console.log(authorName);

const [first, , third = "none", ...rest] = ["a", "b", "c", "d", "e"];
console.log(first, third, rest);

let left = "Iracema";
let right = "Ubirajara";
[left, right] = [right, left];
console.log(left, right);

function label({ title, year = "?" }) {
  return `${title} (${year})`;
}
console.log(label(book), label({ title: "Iracema" }));
JS
block destructuring
on 'node destructuring.js'

put missing.js <<'JS'
const fromApi = { title: "Iracema", reviews: [] };
console.log(fromApi.author);
console.log(fromApi.author.name);
JS
block missing
on 'node missing.js 2>&1 | head -n 6'

put optional.js <<'JS'
const fromApi = { title: "Iracema", reviews: [] };

console.log(fromApi.author?.name);
console.log(fromApi.author?.name ?? "unknown author");
console.log(fromApi.reviews?.[0]?.stars);
console.log(fromApi.format?.());

const withAuthor = { title: "Iracema", author: { name: "José de Alencar" } };
console.log(withAuthor.author?.name);
JS
block optional
on 'node optional.js'
