#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of javascript, as a script that
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

put tree.html <<'HTML'
<!doctype html>
<html lang="en">
<head><title>Shelf</title></head>
<body>
  <h1>My shelf</h1>
  <ul id="books">
    <li class="book">Iracema</li>
    <li class="book read">Dom Casmurro</li>
  </ul>
  <script>
    function walk(node, depth) {
      const pad = "  ".repeat(depth);
      if (node.nodeType === Node.TEXT_NODE) {
        if (node.textContent.trim()) console.log(pad + "#text " + JSON.stringify(node.textContent));
        return;
      }
      if (node.nodeType === Node.ELEMENT_NODE && node.tagName !== "SCRIPT") {
        console.log(pad + node.tagName.toLowerCase());
        for (const child of node.childNodes) walk(child, depth + 1);
      }
    }
    walk(document.documentElement, 0);
    console.log(document.body.childNodes.length, document.body.children.length);
  </script>
</body>
</html>
HTML
block tree
on 'page tree.html'

put select.html <<'HTML'
<!doctype html>
<h1>My shelf</h1>
<ul id="books">
  <li class="book">Iracema</li>
  <li class="book read">Dom Casmurro</li>
</ul>
<script>
  console.log(document.querySelector(".book").textContent);
  console.log(document.querySelector("#books .read").textContent);
  console.log(document.querySelector(".missing"));

  const all = document.querySelectorAll(".book");
  const live = document.getElementsByClassName("book");
  console.log(all.length, live.length);

  const li = document.createElement("li");
  li.className = "book";
  li.textContent = "Macunaíma";
  document.getElementById("books").append(li);
  console.log(all.length, live.length);
</script>
HTML
block select
on 'page select.html'

put change.html <<'HTML'
<!doctype html>
<h1 id="title">My shelf</h1>
<li id="book" class="book" data-book-id="42" style="color: rebeccapurple">Iracema</li>
<input id="copies" value="1">
<script>
  const title = document.querySelector("#title");
  title.textContent = "Ana's shelf";

  const book = document.querySelector("#book");
  book.classList.add("read");
  book.classList.toggle("lent");
  console.log(book.className, book.classList.contains("read"));

  console.log(book.dataset.bookId, typeof book.dataset.bookId);
  book.dataset.lentTo = "bia";

  book.style.fontWeight = "bold";
  console.log(book.style.color, getComputedStyle(book).color);
</script>
HTML
block change
on "page change.html --dom '#book'"

block value
on "page change.html --do 'fill #copies 3' --do 'eval [document.querySelector(\"#copies\").value, document.querySelector(\"#copies\").getAttribute(\"value\")].join(\" / \")'"

put read.html <<'HTML'
<!doctype html>
<li id="book"><span class="title">Iracema</span> <small>1865</small></li>
<script>
  const book = document.querySelector("#book");
  console.log(JSON.stringify(book.textContent));
  console.log(book.innerHTML);
</script>
HTML
block read
on 'page read.html'

put create.html <<'HTML'
<!doctype html>
<ul id="books"></ul>
<template id="row">
  <li class="book"><span class="title"></span> <small class="year"></small></li>
</template>
<script>
  const books = [
    { title: "Iracema", year: 1865 },
    { title: "Dom Casmurro", year: 1899 },
    { title: "Macunaíma", year: 1928 },
  ];
  const list = document.querySelector("#books");
  const template = document.querySelector("#row");

  const rows = books.map((b) => {
    const row = template.content.cloneNode(true);
    row.querySelector(".title").textContent = b.title;
    row.querySelector(".year").textContent = b.year;
    return row;
  });
  list.replaceChildren(...rows);

  list.querySelector("li:nth-child(2)").remove();
  console.log(list.children.length);
</script>
HTML
block create
on "page create.html --dom '#books'"

put traverse.html <<'HTML'
<!doctype html>
<ul id="books">
  <li class="book" data-id="7"><span class="title">Iracema</span> <button class="lend">Lend</button></li>
  <li class="book" data-id="12"><span class="title">Dom Casmurro</span> <button class="lend">Lend</button></li>
</ul>
<script>
  const button = document.querySelectorAll(".lend")[1];
  const row = button.closest(".book");
  console.log(row.dataset.id, row.querySelector(".title").textContent);
  console.log(button.parentElement === row, row.parentElement.id);
  console.log(row.previousElementSibling.dataset.id, row.nextElementSibling);
  console.log(button.matches(".lend"), button.closest("table"));
  console.log(row.childNodes.length, row.children.length);
</script>
HTML
block traverse
on 'page traverse.html'
