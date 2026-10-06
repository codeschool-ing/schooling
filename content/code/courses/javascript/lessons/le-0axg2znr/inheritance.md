---
title: extends and super
version: 1
---

**`extends` makes one class's prototype chain pass through another's.** An `EBook` is a `Book` with
a file size, and it should reuse what `Book` already does:

```javascript
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
```

```
ana@dev:~/js$ node inherit.js
Macunaíma (1928), 2.4 MB
true true true
true
EBook { title: 'Macunaíma', year: 1928, sizeMb: 2.4 }
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The prototype chain of an EBook instance. The instance holds title, year and sizeMb. Its prototype is EBook.prototype, holding describe. That one&#x27;s prototype is Book.prototype, holding another describe. Then Object.prototype, holding hasOwnProperty and toString. Then null, where the lookup stops.\"><defs><marker id=\"proto-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><defs><marker id=\"proto-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"12\" y=\"50\" width=\"138\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"81.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">e</text><text x=\"26\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title</text><text x=\"26\" y=\"116.275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">year</text><text x=\"26\" y=\"132.55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sizeMb</text><path d=\"M150 110 L172 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-amber)\"></path><rect x=\"174\" y=\"50\" width=\"138\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"243.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">EBook.prototype</text><text x=\"188\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">describe</text><path d=\"M312 110 L334 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-amber)\"></path><rect x=\"336\" y=\"50\" width=\"138\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"405.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Book.prototype</text><text x=\"350\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">describe</text><path d=\"M474 110 L496 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-amber)\"></path><rect x=\"498\" y=\"50\" width=\"138\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"567.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Object.prototype</text><text x=\"512\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hasOwnProperty</text><text x=\"512\" y=\"116.275\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">toString</text><rect x=\"660\" y=\"92\" width=\"50\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"685.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">null</text><path d=\"M636 110 L658 110\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-amber)\"></path><text x=\"12\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e.describe() finds this one first</text><path d=\"M120 34 L220 52\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#proto-ah-paper-dim)\"></path><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each arrow is [[Prototype]], read with Object.getPrototypeOf</text></svg>", "caption": "A property is looked for on the object, then along its prototypes, and the first one found wins."}
```

The figure is the whole of inheritance. `EBook.prototype`'s own prototype is `Book.prototype`, so a
lookup on an e-book that misses on `EBook.prototype` carries on into `Book`'s methods, and then to
`Object.prototype`. **`instanceof` walks the same chain**, which is why `e` is an `EBook`, a `Book`
and an `Object` at once.

## `super`

`super` means "the class I extend", in two places:

- **`super(title, year)` in the constructor runs `Book`'s constructor** on the object being built,
  which sets `title` and `year`. A derived class's constructor has to call it, and has to call it
  before touching `this`;
- **`super.describe()` in a method calls `Book`'s version of `describe`**, so `EBook` adds to it
  instead of rewriting it. Defining `describe` on `EBook` at all is called **overriding**: the
  lookup finds `EBook.prototype.describe` first and stops there, which is shadowing again.

```javascript
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
```

```
ana@dev:~/js$ node no-super.js 2>&1 | grep Error
ReferenceError: Must call super constructor in derived class before accessing 'this' or returning from derived constructor
```

The message is long and says exactly what happened: **`this` was used before `super` had run**.
Until the parent's constructor has run, the object does not exist yet, so there is no `this` to set
`sizeMb` on.

## How deep to go

One level, as here, is common and easy to follow. **Deep hierarchies are not**: a method found five
prototypes up, overridden at three of them, is hard to reason about and harder to change. Most
modern JavaScript keeps inheritance shallow and composes behaviour from smaller objects and
functions instead; frameworks that use classes typically ask you to extend one of theirs, one level
deep, and no further.
