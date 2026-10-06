#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of javascript, as a script that
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

put call.js <<'JS'
"use strict";

function describe(open, close) {
  return `${open}${this.title}, ${this.year}${close}`;
}

const iracema = { title: "Iracema", year: 1865 };
const casmurro = { title: "Dom Casmurro", year: 1899 };

console.log(describe.call(iracema, "[", "]"));
console.log(describe.call(casmurro, "(", ")"));
console.log(describe.apply(casmurro, ["<", ">"]));
console.log(describe("{", "}"));
JS
block call
on 'node call.js 2>&1 | head -n 9'

put spread-instead.js <<'JS'
const years = [1899, 1865, 1928];
console.log(Math.max.apply(null, years));
console.log(Math.max(...years));

const many = Array.from({ length: 1_000_000 }, (_, i) => i);
console.log(many.reduce((a, b) => Math.max(a, b)));
console.log(Math.max(...many));
JS
block spread-instead
on 'node spread-instead.js 2>&1 | head -n 8'

put bind.js <<'JS'
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

const label = shelf.label.bind(shelf);
console.log(label("Iracema"));
console.log(["Iracema", "Dom Casmurro"].map(label));
console.log(label.name, label === shelf.label);

const other = { prefix: "Shelf B" };
console.log(label.call(other, "Macunaíma"));
console.log(label.bind(other)("Macunaíma"));
JS
block bind
on 'node bind.js'

put partial.js <<'JS'
function price(currency, cents) {
  return `${currency} ${(cents / 100).toFixed(2)}`;
}

const inReais = price.bind(null, "BRL");
const inEuros = price.bind(null, "EUR");
console.log(inReais(1990), "/", inEuros(1990));
console.log(inReais.length);

const inDollars = (cents) => price("USD", cents);
console.log(inDollars(1990));
JS
block partial
on 'node partial.js'

put arguments.js <<'JS'
function oldStyle() {
  console.log(Array.isArray(arguments), arguments.length);
  const list = Array.prototype.slice.call(arguments);
  console.log(list);
  console.log(Array.from(arguments));
}

function newStyle(...titles) {
  console.log(Array.isArray(titles), titles);
}

oldStyle("Iracema", "Dom Casmurro");
newStyle("Iracema", "Dom Casmurro");
JS
block arguments
on 'node arguments.js'

put hasown.js <<'JS'
const record = { title: "Iracema", hasOwnProperty: "yes, a field called that" };
const dictionary = Object.create(null);
dictionary.title = "Dom Casmurro";

console.log(Object.prototype.hasOwnProperty.call(record, "title"));
console.log(Object.prototype.hasOwnProperty.call(dictionary, "title"));
console.log(Object.hasOwn(record, "title"), Object.hasOwn(dictionary, "title"));
console.log(record.hasOwnProperty("title"));
JS
block hasown
on 'node hasown.js 2>&1 | head -n 8'

put tostring.js <<'JS'
const tag = (v) => Object.prototype.toString.call(v);
console.log(tag([]), tag({}), tag(null), tag(new Date(0)), tag(new Map()));
console.log(String([]), String({}));
console.log(Array.prototype.map.call("abc", (c) => c.toUpperCase()));
JS
block tostring
on 'node tostring.js'

put nodelist.html <<'HTML'
<!doctype html>
<ul>
  <li>Iracema</li>
  <li>Dom Casmurro</li>
  <li>Macunaíma</li>
</ul>
<script>
  const items = document.querySelectorAll("li");
  console.log(typeof items.forEach, typeof items.map);
  console.log(Array.prototype.map.call(items, (li) => li.textContent.length));
  console.log(Array.from(items, (li) => li.textContent.length));
  console.log(items.map((li) => li.textContent));
</script>
HTML
block nodelist
on 'page nodelist.html'

put listeners.html <<'HTML'
<!doctype html>
<button id="ring">Ring</button>
<script>
  "use strict";

  class Bell {
    constructor(name) {
      this.name = name;
      this.boundRing = this.ring.bind(this);
    }
    ring() {
      console.log(`${this.name} rang`);
    }
  }

  const bell = new Bell("front door");
  const button = document.querySelector("#ring");

  button.addEventListener("click", bell.ring.bind(bell));
  button.addEventListener("click", bell.boundRing);

  button.addEventListener("click", () => {
    button.removeEventListener("click", bell.ring.bind(bell));
    button.removeEventListener("click", bell.boundRing);
    console.log("removed both, supposedly");
  });
</script>
HTML
block listeners
on "page listeners.html --do 'click #ring' --do 'click #ring'"
