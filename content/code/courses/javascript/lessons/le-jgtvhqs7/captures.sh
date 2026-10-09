#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of javascript, as a script that
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
# Every request goes to serve.mjs with the api.mjs this lesson shows: started by page
# for the browser captures, and started by this script with serve, in the
# background, for the two programs run with node. Its /api/ answers are
# written in that file; /api/slow really waits, and /api/flaky fails its first
# requests on purpose. Times are rounded to the nearest 100 ms in the programs.
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

put json.js <<'JS'
const book = {
  title: "Iracema",
  year: 1865,
  tags: ["romance", "indianist"],
  isbn: undefined,
  describe() { return this.title; },
  added: new Date(Date.UTC(2026, 9, 6, 15, 0)),
  copiesBy: new Map([["ana", 1]]),
  rating: NaN,
};

const text = JSON.stringify(book);
console.log(text);
console.log(typeof text);

const back = JSON.parse(text);
console.log(typeof back.added, back.rating, "isbn" in back);
console.log(JSON.stringify({ title: "Iracema", year: 1865 }, null, 2));
JS
block json
on 'node json.js'

put reviver.js <<'JS'
const text = '{"title":"Iracema","added":"2026-10-06T15:00:00.000Z"}';
const book = JSON.parse(text, (key, value) => (key === "added" ? new Date(value) : value));
console.log(book.added instanceof Date, book.added.getUTCFullYear());

JSON.parse("{title: 'Iracema'}");
JS
block reviver
on 'node reviver.js 2>&1 | grep -v "^    at"'

put list.html <<'HTML'
<!doctype html>
<ul id="books"></ul>
<script type="module">
  const response = await fetch("/api/books");
  console.log(response.status, response.ok, response.headers.get("content-type"));

  const books = await response.json();
  console.log(Array.isArray(books), books.length);

  document.querySelector("#books").replaceChildren(
    ...books.map((b) => {
      const li = document.createElement("li");
      li.textContent = `${b.title} (${b.year})`;
      return li;
    }),
  );
</script>
HTML
block list
on "page list.html --network --dom '#books'"

put status.html <<'HTML'
<!doctype html>
<script type="module">
  for (const path of ["/api/books/2", "/api/books/9", "/api/broken"]) {
    try {
      const response = await fetch(path);
      const body = await response.json();
      console.log(path, "resolved:", response.status, response.ok, JSON.stringify(body));
    } catch (err) {
      console.log(path, "rejected:", err.name);
    }
  }
</script>
HTML
block status
on 'page status.html'

put get-json.js <<'JS'
export async function getJSON(url, options) {
  const response = await fetch(url, options);
  const type = response.headers.get("content-type") ?? "";
  if (!type.includes("application/json")) {
    throw new Error(`${url}: expected JSON, got ${response.status} ${type || "no type"}`);
  }
  const body = await response.json();
  if (!response.ok) {
    throw new Error(`${url}: ${response.status} ${body.error ?? ""}`.trim());
  }
  return body;
}
JS

put failures.html <<'HTML'
<!doctype html>
<script type="module">
  import { getJSON } from "./get-json.js";

  for (const url of ["/api/books/2", "/api/books/9", "/api/html", "http://127.0.0.1:8099/api/books"]) {
    try {
      const book = await getJSON(url);
      console.log("ok:", book.title);
    } catch (err) {
      console.log(`${err.name}: ${err.message}`);
    }
  }
</script>
HTML
block failures
on 'page failures.html'

put failures-node.mjs <<'JS'
for (const url of ["http://127.0.0.1:8080/api/books/2", "http://127.0.0.1:8099/api/books"]) {
  try {
    const response = await fetch(url);
    console.log("status", response.status);
  } catch (err) {
    console.log(`${err.name}: ${err.message}; cause: ${err.cause?.code}`);
  }
}
JS
block failures-node
lab exec ana 'setsid serve . 8080 >/dev/null 2>&1 </dev/null & echo $! > /tmp/jslab-serve.pid; sleep 1'
on 'node failures-node.mjs'

put timeout.mjs <<'JS'
const round = (ms) => Math.round(ms / 100) * 100;

let t = performance.now();
try {
  await fetch("http://127.0.0.1:8080/api/slow?ms=3000", { signal: AbortSignal.timeout(1000) });
} catch (err) {
  console.log(`${err.name} after about ${round(performance.now() - t)} ms: ${err.message}`);
}

const controller = new AbortController();
t = performance.now();
setTimeout(() => controller.abort(), 300);
try {
  await fetch("http://127.0.0.1:8080/api/slow?ms=3000", { signal: controller.signal });
} catch (err) {
  console.log(`${err.name} after about ${round(performance.now() - t)} ms: ${err.message}`);
}
JS
block timeout
on 'node timeout.mjs'
lab exec ana 'kill $(cat /tmp/jslab-serve.pid); rm -f /tmp/jslab-serve.pid'

put post.html <<'HTML'
<!doctype html>
<form id="add">
  <input name="title" value="Macunaíma">
  <input name="year" value="1928">
  <button>Add</button>
</form>
<script type="module">
  import { getJSON } from "./get-json.js";
  const form = document.querySelector("#add");

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    const fields = Object.fromEntries(new FormData(form));
    const book = { title: fields.title, year: Number(fields.year) };
    try {
      const saved = await getJSON("/api/books", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify(book),
      });
      console.log("saved as id", saved.id, JSON.stringify(saved));
    } catch (err) {
      console.log("not saved:", err.message);
    }
  });
</script>
HTML
block post
on "page post.html --network --do 'click button' --wait 500"
on "page post.html --do 'fill [name=title] ' --do 'click button' --wait 500"

put retry.html <<'HTML'
<!doctype html>
<script type="module">
  import { getJSON } from "./get-json.js";
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));

  async function withRetries(url, attempts = 4) {
    for (let i = 1; i <= attempts; i++) {
      try {
        return await getJSON(url);
      } catch (err) {
        console.log(`attempt ${i} failed: ${err.message}`);
        if (i === attempts) throw err;
        await wait(100 * 2 ** (i - 1));
      }
    }
  }

  const answer = await withRetries("/api/flaky?fails=2");
  console.log("answered on attempt", answer.attempt);
</script>
HTML
block retry
on 'page retry.html --wait 1500'
