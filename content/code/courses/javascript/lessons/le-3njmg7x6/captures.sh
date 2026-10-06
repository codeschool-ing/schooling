#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of javascript, as a script that
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

put throw.js <<'JS'
function lend(book, copies) {
  if (copies < 1) {
    throw new RangeError(`cannot lend ${copies} copies of ${book}`);
  }
  return `${copies} x ${book}`;
}

function checkout() {
  console.log(lend("Iracema", 1));
  console.log(lend("Dom Casmurro", 0));
  console.log("never reached");
}

checkout();
JS
block throw
on 'node throw.js 2>&1 | head -n 9'

put throw-string.js <<'JS'
function lend(copies) {
  if (copies < 1) throw "no copies";
}
try {
  lend(0);
} catch (err) {
  console.log(typeof err, err, err.stack);
}
try {
  lend2(0);
} catch (err) {
  console.log(typeof err, err.name, "|", err.message);
}
function lend2(copies) {
  if (copies < 1) throw new Error("no copies");
}
JS
block throw-string
on 'node throw-string.js'

put finally.js <<'JS'
function readShelf(name) {
  console.log(`open ${name}`);
  try {
    if (name === "missing") throw new Error(`no shelf called ${name}`);
    return `contents of ${name}`;
  } catch (err) {
    console.log("caught:", err.message);
    return null;
  } finally {
    console.log(`close ${name}`);
  }
}

console.log(readShelf("romance"));
console.log(readShelf("missing"));

function surprising() {
  try {
    return "from try";
  } finally {
    return "from finally";
  }
}
console.log(surprising());
JS
block finally
on 'node finally.js'

put types.js <<'JS'
const attempts = [
  () => null.title,
  () => undefinedName,
  () => new Array(-1),
  () => JSON.parse("{oops"),
  () => decodeURIComponent("%"),
];
for (const attempt of attempts) {
  try {
    attempt();
  } catch (err) {
    console.log(err.constructor.name.padEnd(14), err instanceof Error, "|", err.message);
  }
}
JS
block types
on 'node types.js'

put custom.js <<'JS'
class LoanError extends Error {
  constructor(message, options) {
    super(message, options);
    this.name = "LoanError";
  }
}

class OverdueError extends LoanError {
  constructor(reader, days) {
    super(`${reader} has a book ${days} days overdue`);
    this.name = "OverdueError";
    this.reader = reader;
    this.days = days;
  }
}

function lend(reader) {
  if (reader === "bia") throw new OverdueError("bia", 12);
  try {
    JSON.parse("{not json");
  } catch (err) {
    throw new LoanError(`could not read ${reader}'s card`, { cause: err });
  }
}

for (const reader of ["bia", "ana"]) {
  try {
    lend(reader);
  } catch (err) {
    console.log(err.name, err instanceof LoanError, err instanceof OverdueError, "|", err.message);
    if (err.cause) console.log("  caused by:", err.cause.name, "|", err.cause.message);
    if (err instanceof OverdueError) console.log("  days:", err.days);
  }
}
JS
block custom
on 'node custom.js'

put swallow.js <<'JS'
function loadSettings(text) {
  try {
    return JSON.parse(text);
  } catch {
    return {};
  }
}

const settings = loadSettings('{"perPage": 50,}');
console.log(settings.perPage ?? 20);
JS
block swallow
on 'node swallow.js'

put rethrow.js <<'JS'
class NotFound extends Error {
  name = "NotFound";
}

function findBook(id) {
  if (id === 9) throw new NotFound(`no book ${id}`);
  if (id === 13) throw new TypeError("Cannot read properties of undefined (reading 'shelf')");
  return { id, title: "Iracema" };
}

function titleOrPlaceholder(id) {
  try {
    return findBook(id).title;
  } catch (err) {
    if (err instanceof NotFound) return "(no such book)";
    throw err;
  }
}

console.log(titleOrPlaceholder(7));
console.log(titleOrPlaceholder(9));
console.log(titleOrPlaceholder(13));
JS
block rethrow
on 'node rethrow.js 2>&1 | head -n 9'

put async-callback.js <<'JS'
try {
  setTimeout(() => {
    throw new Error("thrown inside a timer");
  }, 0);
  console.log("the try block finished");
} catch (err) {
  console.log("caught?", err.message);
}
JS
put async-await.mjs <<'JS'
async function later() {
  await new Promise((ok) => setTimeout(ok, 10));
  throw new Error("thrown after an await");
}

try {
  await later();
} catch (err) {
  console.log("caught:", err.message);
}
JS
block async-errors
on 'node async-callback.js 2>&1 | head -n 6'
on 'node async-await.mjs'

put last-resort.js <<'JS'
process.on("uncaughtException", (err) => {
  console.error(`fatal: ${err.name}: ${err.message}`);
  process.exitCode = 1;
});

setTimeout(() => {
  null.title;
}, 0);
console.log("started");
JS
block last-resort
on 'node last-resort.js; echo "exit code: $?"'

put window-error.html <<'HTML'
<!doctype html>
<script>
  window.addEventListener("error", (event) => {
    console.log("reported:", event.message, "at line", event.lineno);
  });
  setTimeout(() => {
    document.querySelector("#missing").textContent = "x";
  }, 0);
</script>
HTML
block window-error
on 'page window-error.html'
