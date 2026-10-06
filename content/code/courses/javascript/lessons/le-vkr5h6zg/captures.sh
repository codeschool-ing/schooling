#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of javascript, as a script that
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

put function-scope.js <<'JS'
function shelve() {
  if (true) {
    var label = "fiction";
    let shelf = 3;
  }
  console.log(label);
  console.log(typeof shelf);
}

shelve();
console.log(typeof label);
JS
block function-scope
on 'node function-scope.js'

put redeclare.js <<'JS'
console.log("first line");

var copies = 1;
var copies = 2;

let title = "Iracema";
let title = "Dom Casmurro";
JS
block redeclare
on 'node redeclare.js 2>&1 | head -n 5'

put hoist-var.js <<'JS'
console.log(title);
var title = "Iracema";
console.log(title);
JS
block hoist-var
on 'node hoist-var.js'

put hoist-function.js <<'JS'
console.log(greet("ana"));

function greet(name) {
  return `hello, ${name}`;
}

console.log(typeof later);
later();

var later = function () {
  return "too late";
};
JS
block hoist-function
on 'node hoist-function.js 2>&1 | head -n 7'

put tdz.js <<'JS'
console.log(typeof missing);
console.log(typeof title);
let title = "Iracema";
JS
block tdz
on 'node tdz.js 2>&1 | head -n 6'

put tdz-read.js <<'JS'
console.log(title);
let title = "Iracema";
JS
put not-declared.js <<'JS'
console.log(title);
JS
block tdz-read
on 'node tdz-read.js 2>&1 | grep Error'
on 'node not-declared.js 2>&1 | grep Error'

put shadow.js <<'JS'
const year = 1899;

function check() {
  console.log(year);
  const year = 1865;
}

check();
JS
block shadow
on 'node shadow.js 2>&1 | head -n 5'

put loop-var.js <<'JS'
for (var i = 0; i < 3; i++) {
  setTimeout(() => console.log("var", i), 0);
}
JS
put loop-let.js <<'JS'
for (let i = 0; i < 3; i++) {
  setTimeout(() => console.log("let", i), 0);
}
JS
block loops
on 'node loop-var.js'
on 'node loop-let.js'

put loop-iife.js <<'JS'
for (var i = 0; i < 3; i++) {
  (function (j) {
    setTimeout(() => console.log("old fix", j), 0);
  })(i);
}
JS
block loop-iife
on 'node loop-iife.js'

put globals.html <<'HTML'
<!doctype html>
<script>
  var shelfCount = 12;
  let readerName = "ana";
  function openShelf() {}

  console.log(window.shelfCount, window.readerName, typeof window.openShelf);
</script>
<script>
  console.log(shelfCount, readerName);
</script>
HTML
block globals-page
on 'page globals.html'

put collide.html <<'HTML'
<!doctype html>
<script>
  var name = 42;
  var top = "the top shelf";
  console.log(typeof name, name);
  console.log(top === window);
</script>
HTML
block collide
on 'page collide.html'

put globals.js <<'JS'
var shelfCount = 12;
console.log(globalThis.shelfCount);
JS
block globals-node
on 'node globals.js'

put implicit.js <<'JS'
function countBooks() {
  total = 7;
}

countBooks();
console.log(total, globalThis.total);
JS
block implicit
on 'node implicit.js'
