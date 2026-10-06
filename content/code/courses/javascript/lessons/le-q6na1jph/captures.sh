#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of javascript, as a script that
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

put types.js <<'JS'
const values = [42, 3.14, "Dom Casmurro", true, undefined, null, 10n, Symbol("id"), {}, [], () => {}];

for (const v of values) {
  console.log(typeof v);
}
console.log(Array.isArray([]), Array.isArray({}));
JS
block types
on 'node types.js'

block float
on "node -p '0.1 + 0.2'"
on "node -p '0.1 + 0.2 === 0.3'"
on "node -p '(0.1 + 0.2).toFixed(2)'"

put cents.js <<'JS'
const priceCents = 1990;    // R$ 19,90
const quantity = 3;
const totalCents = priceCents * quantity;

console.log(totalCents);
console.log((totalCents / 100).toFixed(2));
console.log(0.1 * 3, 1 * 3 / 10);
JS
block cents
on 'node cents.js'

put special.js <<'JS'
console.log(1 / 0, -1 / 0, 0 / 0);
console.log(typeof NaN);
console.log(Number.MAX_SAFE_INTEGER);
console.log(2 ** 53, 2 ** 53 + 1);
console.log(2n ** 53n + 1n);
console.log(7 % 3, -7 % 3);
console.log(Number.isInteger(5.0), Number.isInteger(5.5));
JS
block special
on 'node special.js'

put convert.js <<'JS'
const inputs = ["42", "42px", "3.14", "1,5", "", " ", "0x1A", "08", null, undefined, true, []];

console.log("input".padEnd(11), "Number()".padEnd(10), "parseInt()".padEnd(11), "parseFloat()");
for (const v of inputs) {
  const shown = typeof v === "string" ? JSON.stringify(v) : Array.isArray(v) ? "[]" : String(v);
  console.log(
    shown.padEnd(11),
    String(Number(v)).padEnd(10),
    String(parseInt(v, 10)).padEnd(11),
    String(parseFloat(v)),
  );
}
JS
block convert
on 'node convert.js'

put to-string.js <<'JS'
const n = 42;
console.log(String(n), n.toString(), `${n}`);
console.log(n.toString(2), n.toString(16));
console.log((1234.5).toFixed(2), (1234.5).toLocaleString("pt-BR"));
console.log(Number("1,5".replace(",", ".")));
JS
block to-string
on 'node to-string.js'

put coerce.js <<'JS'
console.log("5" + 3);
console.log("5" - 3);
console.log("5" * "2");
console.log(true + 1);
console.log(null + 1, undefined + 1);
console.log([] + []);
console.log([1, 2] + [3]);
console.log({} + "!");
console.log("3" > "12", 3 > "12");
JS
block coerce
on 'node coerce.js'

put form.html <<'HTML'
<!doctype html>
<label>Copies <input id="copies" value="10"></label>
<script>
  const copies = document.querySelector("#copies").value;
  console.log(typeof copies);
  console.log(copies + 5);
  console.log(Number(copies) + 5);
</script>
HTML
block form
on 'page form.html'

put equality.js <<'JS'
console.log(0 == "", 0 == "0", "" == "0");
console.log(0 === "", 0 === "0", "" === "0");
console.log(null == undefined, null === undefined);
console.log(null == 0, null >= 0);
console.log(1 == true, 2 == true);
console.log([1] == 1, [1] === 1);
JS
block equality
on 'node equality.js'

put nan.js <<'JS'
const parsed = Number("forty");
console.log(parsed);
console.log(parsed === NaN, parsed == NaN);
console.log(Number.isNaN(parsed), Object.is(parsed, NaN));
console.log(0 === -0, Object.is(0, -0));
JS
block nan
on 'node nan.js'

put objects-equal.js <<'JS'
const a = { title: "Iracema" };
const b = { title: "Iracema" };
const c = a;
console.log(a === b, a == b, a === c);
console.log(a.title === b.title);
JS
block objects-equal
on 'node objects-equal.js'

put falsy.js <<'JS'
const values = [false, 0, -0, 0n, "", null, undefined, NaN, "0", "false", " ", [], {}, -1];

for (const v of values) {
  const shown = typeof v === "string" ? JSON.stringify(v) : Array.isArray(v) ? "[]" : typeof v === "object" && v ? "{}" : Object.is(v, -0) ? "-0" : typeof v === "bigint" ? `${v}n` : String(v);
  console.log(shown.padEnd(10), Boolean(v));
}
JS
block falsy
on 'node falsy.js'

put defaults.js <<'JS'
function shelfSize(settings) {
  const withOr = settings.perShelf || 20;
  const withNullish = settings.perShelf ?? 20;
  console.log(withOr, withNullish);
}

shelfSize({ perShelf: 35 });
shelfSize({ perShelf: 0 });
shelfSize({});
JS
block defaults
on 'node defaults.js'

put andor.js <<'JS'
console.log("Iracema" && 1865);
console.log("" && 1865);
console.log(null || "no title");
console.log(!!"Iracema", !!"");
JS
block andor
on 'node andor.js'
