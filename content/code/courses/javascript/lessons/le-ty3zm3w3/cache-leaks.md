---
title: The cache that only grows
version: 1
---

A cache keeps answers so they need not be computed again (lesson 6's `memoize` was one). **A cache
with no limit is a leak with a good excuse**: every new key adds an entry, and nothing ever removes
one. A server rendering a fragment per book, with new books every hour:

```javascript
const mb = () => {
  globalThis.gc();
  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
};

const cache = new Map();
function render(bookId) {
  if (!cache.has(bookId)) cache.set(bookId, `<li>book ${bookId}</li>`.repeat(20));
  return cache.get(bookId);
}

for (let hour = 1; hour <= 4; hour++) {
  for (let i = 0; i < 50_000; i++) render(`${hour}-${i}`);
  console.log(`hour ${hour}: ${cache.size} entries, ${mb()} MB`);
}
```

```
ana@dev:~/js$ node --expose-gc cache-leak.js
hour 1: 50000 entries, 17 MB
hour 2: 100000 entries, 31 MB
hour 3: 150000 entries, 46 MB
hour 4: 200000 entries, 58 MB
```

**Fifty thousand entries an hour, 12 to 15 MB an hour, and no end.** Nothing is wrong with any single
line, and the collector is right to keep all of it: the `Map` is reachable from the module, and the
`Map` holds every entry. A server like this does not crash on the first day; it slows down as the
collector works harder, and falls over some days later, at an hour nobody chose.

## A cache with a limit

```schooling-example
{
  "language": "javascript",
  "file": "cache-bounded.js",
  "parts": [
    {
      "code": "const mb = () => {\n  globalThis.gc();\n  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);\n};",
      "note": "The same measurement."
    },
    {
      "code": "const LIMIT = 1000;\nconst cache = new Map();",
      "note": "The limit is the decision the first version never made: at most 1000 entries."
    },
    {
      "code": "function render(bookId) {\n  if (cache.has(bookId)) {\n    const value = cache.get(bookId);\n    cache.delete(bookId);\n    cache.set(bookId, value);\n    return value;\n  }",
      "note": "A hit moves the entry to the end, by deleting and setting it again. A `Map` keeps keys in the order they were set (lesson 5), so the end of the `Map` is always the most recently used entry."
    },
    {
      "code": "  const value = `<li>book ${bookId}</li>`.repeat(20);\n  cache.set(bookId, value);\n  if (cache.size > LIMIT) cache.delete(cache.keys().next().value);\n  return value;\n}",
      "note": "A miss computes the value and stores it. If that takes the cache over its limit, the first key in the `Map`, the least recently used, is removed."
    },
    {
      "code": "for (let hour = 1; hour <= 4; hour++) {\n  for (let i = 0; i < 50_000; i++) render(`${hour}-${i}`);\n  console.log(`hour ${hour}: ${cache.size} entries, ${mb()} MB`);\n}",
      "note": "The same four hours of traffic."
    }
  ],
  "output": "hour 1: 1000 entries, 4 MB\nhour 2: 1000 entries, 4 MB\nhour 3: 1000 entries, 4 MB\nhour 4: 1000 entries, 4 MB"
}
```

**The cache stayed at 1000 entries and 4 MB through four hours.** This kind of cache is called **LRU**,
least recently used: when it is full, it forgets what nobody has asked for in the longest time. The
limit is a judgement about how much memory the answers are worth, and any limit beats none.

Two other answers fit other cases: **a `WeakMap`** (lesson 5) when the keys are objects whose lifetime
should decide the entry's, and **an expiry time** when an answer goes stale, such as prices.
