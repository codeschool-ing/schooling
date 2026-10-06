#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of javascript, as a script that
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

put sloppy.js <<'JS'
function countBooks() {
  totl = 7;
}
countBooks();
console.log("no error; a global called totl now exists:", globalThis.totl);
JS
put strict.js <<'JS'
"use strict";

function countBooks() {
  totl = 7;
}
countBooks();
JS
block undeclared
on 'node sloppy.js'
on 'node strict.js 2>&1 | head -n 5'

put silent.js <<'JS'
const frozen = Object.freeze({ title: "Iracema" });
frozen.title = "Ubirajara";
console.log(frozen.title);

class Account {
  #cents = 1990;
  get balance() { return this.#cents; }
}
const acc = new Account();
acc.balance = 5;
console.log(acc.balance);

"Iracema".year = 1865;
console.log(delete Object.prototype);
JS
block silent
on 'node silent.js'

put loud.mjs <<'JS'
const attempts = {
  "assign to a frozen object": () => { Object.freeze({ title: "Iracema" }).title = "Ubirajara"; },
  "assign to a getter-only property": () => {
    class Account { get balance() { return 1990; } }
    new Account().balance = 5;
  },
  "set a property on a string": () => { "Iracema".year = 1865; },
  "delete Object.prototype": () => { delete Object.prototype; },
};
for (const [what, attempt] of Object.entries(attempts)) {
  try {
    attempt();
    console.log(`${what}: silently ignored`);
  } catch (err) {
    console.log(`${what}: ${err.name}: ${err.message}`);
  }
}
JS
block loud
on 'node loud.mjs'

put this-check.js <<'JS'
function sloppyThis() {
  return this === globalThis;
}
function strictThis() {
  "use strict";
  return this;
}
console.log(sloppyThis(), strictThis());
JS
block this
on 'node this-check.js'

put removed-with.js <<'JS'
"use strict";
const book = { title: "Iracema" };
with (book) {
  console.log(title);
}
JS
put removed-octal.js <<'JS'
"use strict";
const shelf = 010;
JS
put removed-params.js <<'JS'
"use strict";
function lend(book, book) {}
JS
block removed
on 'node removed-with.js 2>&1 | grep SyntaxError'
on 'node removed-octal.js 2>&1 | grep SyntaxError'
on 'node removed-params.js 2>&1 | grep SyntaxError'

put arguments.js <<'JS'
function sloppy(copies) {
  arguments[0] = 99;
  return copies;
}
function strict(copies) {
  "use strict";
  arguments[0] = 99;
  return copies;
}
console.log(sloppy(1), strict(1));

eval("var leaked = 'from sloppy eval'");
console.log(typeof leaked);
(function () {
  "use strict";
  eval("var kept = 'from strict eval'");
  console.log(typeof kept);
})();
JS
block arguments
on 'node arguments.js'

put where.html <<'HTML'
<!doctype html>
<button onclick="console.log('inline handler strict?', this === undefined || (function () { return this === undefined; })())">Check</button>
<script>
  console.log("classic script strict?", (function () { return this === undefined; })());
</script>
<script type="module">
  console.log("module strict?", (function () { return this === undefined; })());
</script>
HTML
block where-page
on "page where.html --do 'click button'"

put where-node.cjs <<'JS'
console.log("CommonJS strict?", (function () { return this === undefined; })());
class Probe {
  static check() {
    return (function () { return this === undefined; })();
  }
}
console.log("inside a class strict?", Probe.check());
JS
put where-node.mjs <<'JS'
console.log("ES module strict?", (function () { return this === undefined; })());
JS
block where-node
on 'node where-node.cjs'
on 'node where-node.mjs'
