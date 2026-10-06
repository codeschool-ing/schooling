#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of javascript, as a script that
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
# contents the lesson shows in full, and one command run with a PATH that has
# no node on it, which is how the lab plays a computer where Node.js was never
# installed.
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

block version
on 'node --version'

put hello.js <<'JS'
console.log("Hello from Node");
console.log(2 + 3);
JS
block hello-node
on 'node hello.js'

put hello.html <<'HTML'
<!doctype html>
<title>Hello</title>
<script>
  console.log("Hello from the browser");
  console.log(2 + 3);
</script>
HTML
block hello-page
on 'page hello.html'

block print
on "node -p '2 ** 10'"

put where.js <<'JS'
console.log(typeof process, typeof document);
JS
put where.html <<'HTML'
<!doctype html>
<script src="where.js"></script>
HTML
block where
on 'node where.js'
on 'page where.html'

block no-node
on 'PATH=/usr/bin:/bin node --version'

block typo
on 'node helo.js'

put quotes.js <<'JS'
console.log(“Hello”);
JS
block quotes
on 'node quotes.js 2>&1 | head -n 5'

block html-in-node
on 'node hello.html 2>&1 | head -n 5'

put asi-return.js <<'JS'
function book() {
  return
  {
    title: "Dom Casmurro"
  };
}

console.log(book());
JS
block asi-return
on 'node asi-return.js'

put asi-join.js <<'JS'
const shelf = "fiction"
const label = shelf
(function () {
  console.log("sorting the shelf")
})()
JS
block asi-join
on 'node asi-join.js 2>&1 | head -n 5'

put const.js <<'JS'
const title = "Dom Casmurro";
title = "Iracema";
JS
block const
on 'node const.js 2>&1 | head -n 5'

put const-array.js <<'JS'
const shelf = ["Dom Casmurro"];
shelf.push("Iracema");
console.log(shelf);

let read = 0;
read = read + 1;
console.log(read);
JS
block const-array
on 'node const-array.js'

put block.js <<'JS'
const year = 1899;
if (year < 1900) {
  let century = "nineteenth";
  console.log(century);
}
console.log(century);
JS
block block
on 'node block.js 2>&1 | head -n 6'

put shelf.js <<'JS'
function double(n) {
  return n * 2;
}

const triple = function (n) {
  return n * 3;
};

const half = (n) => n / 2;

const square = n => n * n;

const describe = (title, year = "unknown") => {
  const age = typeof year === "number" ? 2026 - year : "?";
  return title + " (" + year + "), " + age + " years old";
};

console.log(double(4), triple(4), half(4), square(4));
console.log(describe("Dom Casmurro", 1899));
console.log(describe("Iracema"));
JS
block shelf-out
run 'node shelf.js'

put object-arrow.js <<'JS'
const wrong = (title) => { title: title };
const right = (title) => ({ title: title });

console.log(wrong("Iracema"));
console.log(right("Iracema"));
JS
block object-arrow
on 'node object-arrow.js'

put new-arrow.js <<'JS'
const Shelf = () => {};
const s = new Shelf();
JS
block new-arrow
on 'node new-arrow.js 2>&1 | head -n 5'

put template.js <<'JS'
const title = "Dom Casmurro";
const year = 1899;

console.log("'" + title + "' came out in " + year + ", " + (2026 - year) + " years ago.");
console.log(`'${title}' came out in ${year}, ${2026 - year} years ago.`);
console.log(`${title.toUpperCase()} has ${title.length} characters`);
console.log(`Is it old? ${year < 1950 ? "yes" : "no"}`);
JS
block template-out
run 'node template.js'

put multiline.js <<'JS'
const card = `Title:  Dom Casmurro
Author: Machado de Assis
Year:   1899`;

console.log(card);
console.log(card.split("\n").length, "lines");
JS
block multiline
on 'node multiline.js'

put tagged.js <<'JS'
console.log(`C:\notes\today`);
console.log(String.raw`C:\notes\today`);

function shout(strings, ...values) {
  console.log(strings);
  console.log(values);
  return strings.reduce((out, s, i) => out + s + (i < values.length ? String(values[i]).toUpperCase() : ""), "");
}

const who = "ana";
console.log(shout`hello ${who}, it is ${2026}`);
JS
block tagged
on 'node tagged.js'
