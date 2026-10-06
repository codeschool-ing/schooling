---
title: Lazy sequences
version: 1
---

Because a generator only runs when asked, **it can describe a sequence that never ends**, and only the
part somebody actually takes is ever computed. That is called **laziness**, and it lets a program
build a pipeline of steps without building every intermediate list:

```javascript
let produced = 0;

function* naturals() {
  let n = 1;
  while (true) {
    produced += 1;
    yield n++;
  }
}

function* filter(items, keep) {
  for (const item of items) {
    if (keep(item)) yield item;
  }
}

function* map(items, change) {
  for (const item of items) yield change(item);
}

function* take(items, count) {
  if (count <= 0) return;
  for (const item of items) {
    yield item;
    if (--count === 0) return;
  }
}

const result = take(map(filter(naturals(), (n) => n % 7 === 0), (n) => n * n), 4);
console.log([...result]);
console.log("numbers produced:", produced);
```

```
ana@dev:~/js$ node lazy.js
[ 49, 196, 441, 784 ]
numbers produced: 28
```

`naturals` is an infinite loop, and the program finished. **The pipeline pulled values through one at
a time**: `take` asked `map` for a value, `map` asked `filter`, `filter` asked `naturals` until it
got a multiple of 7, and the square came back up. When `take` had four, it returned, and nobody
asked `naturals` for anything again.

`numbers produced: 28` is the point. **Four results needed exactly 28 natural numbers, because 28 is
the fourth multiple of 7**, and that is how many were made. The same pipeline written with arrays,
`filter` then `map` then `slice`, would have needed a finite array to start from, and would have
built every intermediate array in full.

## When this is worth it

Laziness pays when the source is large, slow or endless: lines of a big file, rows from a database,
pages from an API, the moves of a game. **For an array of a hundred items already in memory, the
array methods of lesson 4 are simpler and fast enough**, and that is what most code should use. The
generator pipeline is the tool for when building the whole list first is the problem.
