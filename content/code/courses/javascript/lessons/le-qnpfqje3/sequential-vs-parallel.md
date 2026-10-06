---
title: One after another, or all at once
version: 1
---

`await` in a loop waits for each step before starting the next. **That is right when each step needs
the previous one's result, and slow when they are independent.** Four requests that each take 300 ms:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;
const fetchBook = (id) => new Promise((resolve) => setTimeout(() => resolve({ id }), 300));
const ids = [7, 12, 19, 21];

let t = performance.now();
const one = [];
for (const id of ids) {
  one.push(await fetchBook(id));
}
console.log("one after another:", one.length, "books in about", round(performance.now() - t), "ms");

t = performance.now();
const all = await Promise.all(ids.map((id) => fetchBook(id)));
console.log("all at once:      ", all.length, "books in about", round(performance.now() - t), "ms");
```

```
ana@dev:~/js$ node timing.mjs
one after another: 4 books in about 1200 ms
all at once:       4 books in about 300 ms
```

The loop took **about 1200 ms**, four times 300: each request started only after the previous one had
finished. **`Promise.all` took about 300 ms**: `ids.map(…)` started all four requests at once, and
`Promise.all` waited for the four promises together. The `round` function rounds to the nearest
100 ms in the program, because the exact figure changes from run to run; the factor of four does not.

## How to tell which you need

Ask whether a step uses what the step before it returned. **The book's author needs the book**, so
those two awaits are in order on purpose. Four books by id need nothing from each other, and waiting
for them one by one is time the user spends looking at a spinner.

**Start the work first, await afterwards.** Calling the function starts it, as the `map` did; it is
the `await` that waits. `const a = fetchBook(7); const b = fetchBook(12); await a; await b;` also runs
the two at once. What does not is `await fetchBook(7); await fetchBook(12);`, which looks almost the
same.

Starting everything at once has a limit. A thousand requests in one `Promise.all` can overwhelm a
server or hit a browser's cap on connections to one host; for large numbers, work in batches.
