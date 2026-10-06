---
title: Iterables, for of and for in
version: 1
---

**Arrays, strings, `Map`, `Set`, the `arguments` object and the `NodeList` of a page are iterable.**
Plain objects are not. And `for…of` has an older cousin, `for…in`, which looks almost the same and
does something else:

```javascript
const shelf = ["Iracema", "Dom Casmurro"];
Array.prototype.extra = "added by some library";

for (const i in shelf) {
  console.log("in:", i, typeof i);
}
for (const title of shelf) {
  console.log("of:", title);
}

const loans = new Map([["Iracema", 3]]);
for (const [title, n] of loans) {
  console.log(title, n);
}
```

```
ana@dev:~/js$ node of-in.js
in: 0 string
in: 1 string
in: extra string
of: Iracema
of: Dom Casmurro
Iracema 3
```

**`for…in` walks property names**, and for an array those are the indexes, as strings: `"0"`, `"1"`.
It also includes **enumerable properties inherited through the prototype chain** (lesson 8), which is
how `extra`, added to `Array.prototype` the way some old libraries did, turned up as a third
"index". `for…of` asked the array's iterator, which gives the items and nothing else.

**Use `for…of` for the items of anything iterable.** `for…in` belongs to plain objects, if anywhere,
and even there `Object.keys` or `Object.entries` (lesson 4) are clearer because they list only the
object's own properties.

## Plain objects

```javascript
const book = { title: "Iracema", year: 1865 };
for (const [key, value] of Object.entries(book)) {
  console.log(key, value);
}
for (const part of book) {
  console.log(part);
}
```

```
ana@dev:~/js$ node not-iterable.js 2>&1 | head -n 7
title Iracema
year 1865
/home/ana/js/not-iterable.js:5
for (const part of book) {
                   ^

TypeError: book is not iterable
```

A plain object has no `Symbol.iterator`, so `for…of` refused it with **`book is not iterable`**.
That is deliberate: an object could reasonably iterate over its keys, its values or its entries, and
the language does not choose for you. `Object.entries(book)` returns an array of pairs, which is
iterable, and destructuring each pair gave the name and the value.

## Who else uses the protocol

```javascript
const noisy = {
  [Symbol.iterator]() {
    let n = 0;
    return {
      next() {
        n += 1;
        console.log(`  next() call ${n}`);
        return n <= 2 ? { value: n * 10, done: false } : { value: undefined, done: true };
      },
    };
  },
};

console.log("spread:", [...noisy]);
console.log("destructuring:");
const [first] = noisy;
console.log(first);
console.log("Array.from:", Array.from(noisy));
```

```
ana@dev:~/js$ node consumers.js
  next() call 1
  next() call 2
  next() call 3
spread: [ 10, 20 ]
destructuring:
  next() call 1
10
  next() call 1
  next() call 2
  next() call 3
Array.from: [ 10, 20 ]
```

`noisy` is a hand-made iterable that prints each time it is asked for an item. **Spread and
`Array.from` asked until the iterator said done**, three calls for two items. **Destructuring one
name asked once and stopped**, because it had what it needed. `new Map(…)`, `new Set(…)`,
`Promise.all` (lesson 14) and `yield*` later in this lesson consume iterables the same way.
