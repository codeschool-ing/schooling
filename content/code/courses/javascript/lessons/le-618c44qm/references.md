---
title: Two names, one object
version: 1
---

**A variable does not contain an object. It holds a reference to one**, an arrow pointing at where
the object lives. Assigning an object to a second name copies the arrow, not the object:

```javascript
const original = { title: "Iracema", copies: 3 };
const alias = original;
alias.copies = 0;
console.log(original.copies);

function lend(book) {
  book.copies = book.copies - 1;
}
const other = { title: "Dom Casmurro", copies: 2 };
lend(other);
console.log(other.copies);
```

```
ana@dev:~/js$ node references.js
0
1
```

`alias.copies = 0` changed the one object both names point at, so `original.copies` is 0 too. The
same happens across a function call: **`lend` was given a reference, and changed the caller's
object through it.** A primitive does not behave like this, because a primitive cannot be changed
at all (lesson 2): a function that receives a number and adds to it changes its own copy and
nothing else.

This is the most useful fact in the lesson, because it explains a family of bugs that look
unrelated. A list that changes "by itself" after being passed to a helper. A default settings object
that slowly fills with one user's choices because every user shares it. A test that passes alone
and fails after another test, because both changed the same fixture.

## Copying an object

To get a second object, you make one. The spread syntax, `{ ...book }`, which the spread section
covers properly, builds a new object with the same properties:

```javascript
const book = { title: "Iracema", author: { name: "José de Alencar" } };

const shallow = { ...book };
shallow.title = "Ubirajara";
shallow.author.name = "J. de Alencar";
console.log(book.title, "/", book.author.name);

const deep = structuredClone(book);
deep.author.name = "Alencar";
console.log(book.author.name, "/", deep.author.name);
```

```
ana@dev:~/js$ node copies.js
Iracema / J. de Alencar
J. de Alencar / Alencar
```

`shallow.title = "Ubirajara"` left `book.title` alone: the two outer objects are separate. **But
`shallow.author.name` changed `book.author.name` too**, because the copy is shallow. It copied each
property's value, and the value of `author` is a reference, so both objects point at the same
author:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two names, book and shallow, each point at its own outer object, made by spreading book into a new one. Both outer objects have an author property, and both point at the same inner author object, which is why changing shallow.author.name changed book&#x27;s too. A third name, deep, made with structuredClone, points at an outer object with its own author.\"><defs><marker id=\"shallow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><defs><marker id=\"shallow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"shallow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">book</text><rect x=\"20\" y=\"120\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shallow</text><rect x=\"20\" y=\"200\" width=\"90\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">deep</text><path d=\"M110 55 L170 55\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-paper-dim)\"></path><path d=\"M110 135 L170 135\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-paper-dim)\"></path><path d=\"M110 215 L170 215\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-paper-dim)\"></path><rect x=\"170\" y=\"30\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title: …</text><text x=\"182\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author:</text><rect x=\"170\" y=\"110\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title: …</text><text x=\"182\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author:</text><rect x=\"170\" y=\"190\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">title: …</text><text x=\"182\" y=\"224\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">author:</text><rect x=\"470\" y=\"60\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{ name: &quot;J. de Alencar&quot; }</text><rect x=\"470\" y=\"190\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">{ name: &quot;Alencar&quot; }</text><path d=\"M370 64 L466 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-amber)\"></path><path d=\"M370 144 L466 90\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-amber)\"></path><path d=\"M370 224 L466 214\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#shallow-ah-phosphor)\"></path><text x=\"580\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">shared by book and shallow</text><text x=\"580\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">deep has its own</text></svg>", "caption": "A spread copies one level. The objects inside are shared; structuredClone copies all the way down."}
```

`structuredClone` copies **all the way down**, so `deep.author` is a third, independent object.
It is built into Node and every current browser. It copies data, meaning plain objects, arrays,
dates, maps and sets; it refuses functions and some other values, and the error says which one.

Which copy you need depends on what you will change. **If you will change only top-level
properties, a spread is enough. If you will change something nested, clone it**, or build the new
nested object by hand.
