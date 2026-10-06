#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of javascript, as a script that
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

put proto.js <<'JS'
const reader = {
  greet() {
    return `hello from ${this.name}`;
  },
};

const ana = Object.create(reader);
ana.name = "ana";

console.log(ana.greet());
console.log(Object.getPrototypeOf(ana) === reader);
console.log(Object.hasOwn(ana, "greet"), "greet" in ana);
console.log(ana);

ana.greet = () => "my own greeting";
console.log(ana.greet());
delete ana.greet;
console.log(ana.greet());
JS
block proto
on 'node proto.js'

put shared.js <<'JS'
const reader = { shelves: [] };
const ana = Object.create(reader);
const bia = Object.create(reader);

ana.shelves.push("Romance");
console.log(bia.shelves);

bia.shelves = ["Poetry"];
console.log(ana.shelves, bia.shelves);
JS
block shared
on 'node shared.js'

put chain.js <<'JS'
const list = ["Iracema"];

let p = list;
const names = [];
while (p !== null) {
  p = Object.getPrototypeOf(p);
  names.push(p === Array.prototype ? "Array.prototype" : p === Object.prototype ? "Object.prototype" : String(p));
}
console.log(names.join("  ->  "));

console.log(Object.hasOwn(Array.prototype, "map"), Object.hasOwn(Object.prototype, "hasOwnProperty"));
console.log(list.map === Array.prototype.map);
console.log(list.missing);
JS
block chain
on 'node chain.js'

put constructor.js <<'JS'
"use strict";

function Book(title, year) {
  this.title = title;
  this.year = year;
}

Book.prototype.describe = function () {
  return `${this.title} (${this.year})`;
};

const b = new Book("Iracema", 1865);
console.log(b.describe());
console.log(Object.getPrototypeOf(b) === Book.prototype, b instanceof Book);
console.log(Object.keys(b));

const oops = Book("Dom Casmurro", 1899);
JS
block constructor
on 'node constructor.js 2>&1 | head -n 9'

put class.js <<'JS'
class Book {
  constructor(title, year) {
    this.title = title;
    this.year = year;
  }

  describe() {
    return `${this.title} (${this.year})`;
  }

  get age() {
    return 2026 - this.year;
  }

  static fromLine(line) {
    const [title, year] = line.split(";");
    return new Book(title, Number(year));
  }
}

const b = Book.fromLine("Dom Casmurro;1899");
console.log(b.describe(), b.age);
console.log(typeof Book, Object.getPrototypeOf(b) === Book.prototype);
console.log(Object.keys(b), Object.hasOwn(Book.prototype, "describe"));
console.log(b);
JS
block class-out
run 'node class.js'

put class-no-new.js <<'JS'
class Book {
  constructor(title) {
    this.title = title;
  }
}
const b = Book("Iracema");
JS
block class-no-new
on 'node class-no-new.js 2>&1 | head -n 5'

put inherit.js <<'JS'
class Book {
  constructor(title, year) {
    this.title = title;
    this.year = year;
  }
  describe() {
    return `${this.title} (${this.year})`;
  }
}

class EBook extends Book {
  constructor(title, year, sizeMb) {
    super(title, year);
    this.sizeMb = sizeMb;
  }
  describe() {
    return `${super.describe()}, ${this.sizeMb} MB`;
  }
}

const e = new EBook("Macunaíma", 1928, 2.4);
console.log(e.describe());
console.log(e instanceof EBook, e instanceof Book, e instanceof Object);
console.log(Object.getPrototypeOf(EBook.prototype) === Book.prototype);
console.log(e);
JS
block inherit
on 'node inherit.js'

put no-super.js <<'JS'
class Book {
  constructor(title) {
    this.title = title;
  }
}
class EBook extends Book {
  constructor(title, sizeMb) {
    this.sizeMb = sizeMb;
    super(title);
  }
}
new EBook("Macunaíma", 2.4);
JS
block no-super
on 'node no-super.js 2>&1 | grep Error'

put private.js <<'JS'
class Account {
  #balanceCents = 0;
  static #opened = 0;

  constructor(owner) {
    this.owner = owner;
    Account.#opened += 1;
  }

  deposit(cents) {
    if (cents <= 0) throw new RangeError("a deposit must be positive");
    this.#balanceCents += cents;
  }

  get balance() {
    return this.#balanceCents;
  }

  static count() {
    return Account.#opened;
  }

  static isAccount(value) {
    return #balanceCents in value;
  }
}

const acc = new Account("ana");
acc.deposit(1990);
console.log(acc.balance, Account.count());
console.log(acc, Object.keys(acc), JSON.stringify(acc));
acc.balance = 5;
console.log(acc.balance);
console.log(Account.isAccount(acc), Account.isAccount({ owner: "bia" }));
JS
block private
on 'node private.js'

put peek.js <<'JS'
class Account {
  #balanceCents = 0;
}
const acc = new Account();
console.log(acc.#balanceCents);
JS
block peek
on 'node peek.js 2>&1 | head -n 5'

put field-arrow.js <<'JS'
"use strict";

class Counter {
  count = 0;
  increment = () => {
    this.count += 1;
    return this.count;
  };
}

const c = new Counter();
const press = c.increment;
press();
press();
console.log(c.count, Object.hasOwn(c, "increment"));
console.log(new Counter().increment === c.increment);
JS
block field-arrow
on 'node field-arrow.js'
