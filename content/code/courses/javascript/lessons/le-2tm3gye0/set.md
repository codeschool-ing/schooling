---
title: Set: each value once
version: 1
---

**A `Set` is a collection where each value appears at most once.** Adding a value it already
holds does nothing. That makes it the shortest way to remove duplicates, and a fast way to ask
"have I seen this?":

```javascript
const tags = ["novel", "classic", "novel", "romance", "classic"];
const unique = new Set(tags);
console.log(unique, unique.size);
console.log([...unique]);

unique.add("novel");
unique.add("poetry");
console.log(unique.has("poetry"), unique.size);

console.log(new Set([NaN, NaN, 0, -0]).size);
console.log(new Set([{ id: 1 }, { id: 1 }]).size);
```

```
ana@dev:~/js$ node set.js
Set(3) { 'novel', 'classic', 'romance' } 3
[ 'novel', 'classic', 'romance' ]
true 4
2
2
```

- `new Set(tags)` kept three of the five tags, **in the order each first appeared**. `[...unique]`
  turns it back into an array, which is the usual one-line deduplication;
- adding `"novel"` again changed nothing; adding `"poetry"` made four;
- a `Set` decides "the same" almost like `===`, with one difference: **it treats `NaN` as equal to
  itself**, so two `NaN` were one, and `0` and `-0` were one too. That made two;
- two objects with the same contents are still **two objects**, so the last set has two items.
  Lesson 2's equality section is why.

`has` on a `Set` stays fast however large the set grows, while `includes` on an array checks the
items one by one. **For a long list you ask "is this in it?" many times, build a `Set` once.**

## Set operations

```javascript
const ana = new Set(["Iracema", "Dom Casmurro", "Macunaíma"]);
const bia = new Set(["Dom Casmurro", "O Cortiço"]);

console.log(ana.union(bia));
console.log(ana.intersection(bia));
console.log(ana.difference(bia));
console.log(ana.isSupersetOf(new Set(["Iracema"])));
```

```
ana@dev:~/js$ node set-ops.js
Set(4) { 'Iracema', 'Dom Casmurro', 'Macunaíma', 'O Cortiço' }
Set(1) { 'Dom Casmurro' }
Set(2) { 'Iracema', 'Macunaíma' }
true
```

Since 2024 a `Set` has the operations from mathematics: **union** is everything in either,
**intersection** is what both share, **difference** is what the first has and the second does
not. Node 22 has them, as do current browsers; this is one of the features lesson 1 meant when it
said to install 22 or newer. Before them, the same was written with `filter` and `has`:
`[...ana].filter((t) => bia.has(t))` is the intersection.
