#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of javascript, as a script that
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

put values.js <<'JS'
function shout(text) {
  return text.toUpperCase() + "!";
}

const say = shout;
console.log(say("hello"));

function applyTwice(fn, value) {
  return fn(fn(value));
}
console.log(applyTwice(shout, "hi"));

function makeGreeting(greeting) {
  return (name) => `${greeting}, ${name}`;
}
const hello = makeGreeting("Hello");
const ola = makeGreeting("Olá");
console.log(hello("ana"), "/", ola("ana"));

console.log(typeof shout, shout.name, shout.length);
JS
block values
on 'node values.js'

put scope-chain.js <<'JS'
const library = "City Library";

function openShelf(shelfName) {
  const opened = "09:00";

  function describeBook(title) {
    return `${title} on ${shelfName}, ${library}, open since ${opened}`;
  }

  return describeBook("Iracema");
}

console.log(openShelf("Romance"));

function lookForIt() {
  return readerCount;
}
console.log(lookForIt());
JS
block scope-chain
on 'node scope-chain.js 2>&1 | head -n 7'

put counter.js <<'JS'
function makeCounter() {
  let count = 0;
  return function increment() {
    count = count + 1;
    return count;
  };
}

const visits = makeCounter();
const loans = makeCounter();

console.log(visits(), visits(), visits());
console.log(loans());
console.log(visits());
console.log(typeof count);
JS
block counter
on 'node counter.js'

put live.js <<'JS'
let message = "first";
const read = () => message;

console.log(read());
message = "changed later";
console.log(read());
JS
block live
on 'node live.js'

put once.js <<'JS'
function once(fn) {
  let done = false;
  let result;
  return (...args) => {
    if (!done) {
      done = true;
      result = fn(...args);
    }
    return result;
  };
}

const connect = once(() => {
  console.log("connecting...");
  return "connection 1";
});

console.log(connect());
console.log(connect());
console.log(connect());
JS
block once
run 'node once.js'

put memo.js <<'JS'
function memoize(fn) {
  const cache = new Map();
  return (n) => {
    if (cache.has(n)) return cache.get(n);
    const value = fn(n);
    cache.set(n, value);
    return value;
  };
}

let calls = 0;
const slowSquare = (n) => {
  calls = calls + 1;
  return n * n;
};

const square = memoize(slowSquare);
console.log(square(12), square(12), square(5), square(12));
console.log("slowSquare ran", calls, "times");
JS
block memo
on 'node memo.js'

put account.js <<'JS'
function makeAccount(owner) {
  let balanceCents = 0;
  return {
    owner,
    deposit(cents) {
      if (cents <= 0) throw new RangeError("a deposit must be positive");
      balanceCents += cents;
    },
    balance() {
      return balanceCents;
    },
  };
}

const acc = makeAccount("ana");
acc.deposit(1990);
acc.balanceCents = 1000000;
console.log(acc.balance(), acc.balanceCents);
JS
block account
on 'node account.js'

put this-rules.js <<'JS'
"use strict";

const book = {
  title: "Iracema",
  describe() {
    return this;
  },
};

function plain() {
  return this;
}

function Shelf(name) {
  this.name = name;
}

const arrow = () => this;

console.log(book.describe() === book);
console.log(plain());
console.log(new Shelf("Romance"));
console.log(arrow());
JS
block this-rules
on 'node this-rules.js'

put losing-this.js <<'JS'
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

console.log(shelf.label("Iracema"));

const label = shelf.label;
console.log(label("Iracema"));
JS
block losing-this
on 'node losing-this.js 2>&1 | head -n 7'

put callbacks-this.js <<'JS'
"use strict";

const shelf = {
  prefix: "Shelf A",
  label(title) {
    return `${this.prefix}: ${title}`;
  },
};

const titles = ["Iracema", "Dom Casmurro"];

console.log(titles.map((t) => shelf.label(t)));
console.log(titles.map(shelf.label));
JS
block callbacks-this
on 'node callbacks-this.js 2>&1 | head -n 7'

put arrow-inside.js <<'JS'
const shelf = {
  name: "Classics",
  titles: ["Iracema", "Dom Casmurro"],
  withFunction() {
    return this.titles.map(function (t) {
      return `${this?.name}: ${t}`;
    });
  },
  withArrow() {
    return this.titles.map((t) => `${this.name}: ${t}`);
  },
};

console.log(shelf.withFunction());
console.log(shelf.withArrow());
JS
block arrow-inside
on 'node arrow-inside.js'
