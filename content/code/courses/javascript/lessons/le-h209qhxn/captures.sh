#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of javascript, as a script that
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
# Two programs measure time, and their numbers are rounded IN THE PROGRAM to
# the nearest 100 ms, because the exact milliseconds move on every run. The
# rounding is in the source the lesson shows.
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

put stack.js <<'JS'
function format(book) {
  console.trace("inside format");
  return `${book.title} (${book.year})`;
}

function render(books) {
  return books.map(format);
}

function main() {
  render([{ title: "Iracema", year: 1865 }]);
}

main();
JS
block stack
on 'node stack.js 2>&1 | head -n 6'

put overflow.js <<'JS'
function countDown(n) {
  return n === 0 ? 0 : 1 + countDown(n - 1);
}
console.log(countDown(1000));
console.log(countDown(1_000_000));
JS
block overflow
on 'node overflow.js 2>&1 | head -n 6'

put freeze.html <<'HTML'
<!doctype html>
<button id="sort">Sort 2 seconds' worth</button>
<button id="ping">Ping</button>
<script>
  const round = (ms) => Math.round(ms / 100) * 100;
  let busyFrom = 0;

  document.querySelector("#sort").addEventListener("click", () => {
    busyFrom = performance.now();
    while (performance.now() - busyFrom < 2000) {
      // pretend to sort a very large list
    }
    console.log("sorting finished after about", round(performance.now() - busyFrom), "ms");
  });

  document.querySelector("#ping").addEventListener("click", () => {
    console.log("ping handled about", round(performance.now() - busyFrom), "ms after sorting began");
  });
</script>
HTML
block freeze
on "page freeze.html --do 'eval setTimeout(() => document.querySelector(\"#sort\").click()); setTimeout(() => document.querySelector(\"#ping\").click(), 100); undefined' --wait 2600"

put run-to-completion.js <<'JS'
console.log("1. the program starts");

setTimeout(() => console.log("4. the timer's callback"), 0);

for (let i = 0; i < 3; i++) {
  console.log(`2. loop, turn ${i}`);
}

console.log("3. the program's last line");
JS
block rtc
on 'node run-to-completion.js'

put order.js <<'JS'
console.log("A: synchronous");

setTimeout(() => console.log("B: task (setTimeout)"), 0);

Promise.resolve().then(() => console.log("C: microtask (promise)"));

queueMicrotask(() => console.log("D: microtask (queueMicrotask)"));

setTimeout(() => {
  console.log("E: second task");
  Promise.resolve().then(() => console.log("F: microtask queued by a task"));
}, 0);

setTimeout(() => console.log("G: third task"), 0);

console.log("H: synchronous, last line");
JS
block order-node
on 'node order.js'

put order.html <<'HTML'
<!doctype html>
<script src="order.js"></script>
HTML
block order-page
on 'page order.html'

put chained.js <<'JS'
setTimeout(() => console.log("task"), 0);

let n = 0;
function again() {
  n += 1;
  if (n < 5) queueMicrotask(again);
  else console.log("5 microtasks ran first");
}
queueMicrotask(again);
JS
block chained
on 'node chained.js'

put frames.html <<'HTML'
<!doctype html>
<div id="bar" style="width: 0; height: 10px; background: teal"></div>
<script>
  const bar = document.querySelector("#bar");
  let frames = 0;

  function grow() {
    frames += 1;
    bar.style.width = `${frames * 10}px`;
    if (frames < 5) requestAnimationFrame(grow);
    else console.log("5 frames drawn, width", bar.style.width);
  }
  requestAnimationFrame(grow);

  bar.style.width = "100px";
  bar.style.width = "200px";
  bar.style.width = "0px";
  console.log("three widths set in one task; the screen only ever saw the last");
</script>
HTML
block frames
on 'page frames.html --wait 500'

put chunks.html <<'HTML'
<!doctype html>
<button id="ping">Ping</button>
<script>
  const round = (ms) => Math.round(ms / 100) * 100;
  const started = performance.now();
  let done = 0;

  function work() {
    const sliceStart = performance.now();
    while (performance.now() - sliceStart < 50) {
      // one 50 ms slice of a long job
    }
    done += 1;
    if (done < 40) setTimeout(work, 0);
    else console.log("job finished after about", round(performance.now() - started), "ms");
  }
  setTimeout(work, 0);

  document.querySelector("#ping").addEventListener("click", () => {
    console.log("ping handled about", round(performance.now() - started), "ms in, after", done, "slices");
  });
</script>
HTML
block chunks
on "page chunks.html --do 'eval setTimeout(() => document.querySelector(\"#ping\").click(), 100); undefined' --wait 2600"
