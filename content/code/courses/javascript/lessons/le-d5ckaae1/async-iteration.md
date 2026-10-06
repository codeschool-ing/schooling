---
title: Waiting between items
version: 1
---

So far every value was ready the moment it was asked for. Data from a network is not: the second page
of results arrives some time after you ask for it. **An async generator is a generator that can wait
between values, and `for await…of` is the loop that waits with it**:

```javascript
const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function* fetchPages(total) {
  for (let page = 1; page <= total; page += 1) {
    await wait(50);
    yield { page, titles: [`book ${page * 2 - 1}`, `book ${page * 2}`] };
  }
}

for await (const { page, titles } of fetchPages(3)) {
  console.log(page, titles);
}
console.log("all pages read");
```

```
ana@dev:~/js$ node async-pages.mjs
1 [ 'book 1', 'book 2' ]
2 [ 'book 3', 'book 4' ]
3 [ 'book 5', 'book 6' ]
all pages read
```

`fetchPages` pretends to be an API: it waits 50 milliseconds before each page, which a real one would
spend on the network. **The loop received one page, printed it, and only then asked for the next**,
and `all pages read` came after the third, because the loop had waited for each.

Three new pieces of syntax are in this file, and lessons 13 and 14 are where they belong:

- `async function*` makes an async generator, and **`await` inside it pauses until something
  finishes**, here a timer;
- `new Promise(…)` is how `wait` turns a timer into something `await` can wait for;
- `for await…of`, at the top level of an ES module (lesson 9), asks for each item and waits for it
  to arrive.

**The shape is what to take from this lesson**: the same pull-one-at-a-time conversation as `for…of`,
with a pause between the asking and the answer. Lesson 16 uses it on the lab's server, where the
pause is a real request.
