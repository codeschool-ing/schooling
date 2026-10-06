#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of javascript, as a script that
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
# Timers are measured, and exact milliseconds move on every run, so every
# program here prints a category or a rounded figure, computed in its own
# source: "under 4 ms" or "4 ms or more", or the nearest 100 ms.
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

put timeout.js <<'JS'
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();

const id = setTimeout((title, copies) => {
  console.log(`reminder after about ${round(performance.now() - start)} ms: return ${title} (${copies})`);
}, 300, "Iracema", 2);
console.log("timer id:", typeof id);

const cancelled = setTimeout(() => console.log("never printed"), 200);
clearTimeout(cancelled);

const busyUntil = performance.now() + 500;
while (performance.now() < busyUntil) {}
console.log("busy loop finished after about", round(performance.now() - start), "ms");
JS
block timeout
on 'node timeout.js'

put nested.html <<'HTML'
<!doctype html>
<script>
  const gaps = [];
  let last = performance.now();
  function step() {
    const now = performance.now();
    gaps.push(now - last);
    last = now;
    if (gaps.length < 8) setTimeout(step, 0);
    else gaps.forEach((g, i) => console.log(`level ${i + 1}: ${g < 4 ? "under 4 ms" : "4 ms or more"}`));
  }
  setTimeout(step, 0);
</script>
HTML
block nested
on 'page nested.html --wait 500'

put interval.js <<'JS'
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
let ticks = 0;

const id = setInterval(() => {
  ticks += 1;
  const busyUntil = performance.now() + 150;
  while (performance.now() < busyUntil) {}
  console.log(`tick ${ticks} ended at about ${round(performance.now() - start)} ms`);
  if (ticks === 4) clearInterval(id);
}, 100);
JS
block interval
on 'node interval.js'

put chained-timeout.js <<'JS'
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
let ticks = 0;

function tick() {
  ticks += 1;
  const busyUntil = performance.now() + 150;
  while (performance.now() < busyUntil) {}
  console.log(`tick ${ticks} ended at about ${round(performance.now() - start)} ms`);
  if (ticks < 4) setTimeout(tick, 100);
}
setTimeout(tick, 100);
JS
block chained-timeout
on 'node chained-timeout.js'

put search.html <<'HTML'
<!doctype html>
<input id="q" placeholder="Search the shelf">
<script>
  function debounce(fn, ms) {
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => fn(...args), ms);
    };
  }

  const search = (text) => console.log(`searching for "${text}"`);
  const searchSoon = debounce(search, 300);
  let keystrokes = 0;

  document.querySelector("#q").addEventListener("input", (event) => {
    keystrokes += 1;
    searchSoon(event.target.value);
  });
  window.report = () => console.log("keystrokes:", keystrokes);
</script>
HTML
block search
on "page search.html --do 'focus #q' --do 'press i' --do 'press r' --do 'press a' --do 'press c' --do 'press e' --do 'wait 400' --do 'press m' --do 'press a' --do 'wait 400' --do 'eval report()'"

put alive.js <<'JS'
const reminder = setTimeout(() => console.log("this would print after a minute"), 60_000);
reminder.unref();

const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
process.on("exit", () => console.log("process ended after about", round(performance.now() - start), "ms"));

const poll = setInterval(() => console.log("still polling"), 1000);
setTimeout(() => {
  clearInterval(poll);
  console.log("stopped the poll; nothing is left to wait for");
}, 2500);
JS
block alive
on 'node alive.js'
