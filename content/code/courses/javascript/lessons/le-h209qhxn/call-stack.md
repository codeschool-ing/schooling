---
title: The call stack
version: 1
---

To know what "the code that is running" means at any moment, the engine keeps a **call stack**: a
list of the functions that have been called and have not yet returned. Calling a function pushes a
frame on top; returning pops it. `console.trace` prints the stack at the line where it runs:

```javascript
function format(book) {
  console.trace("inside format");
  return `${book.title} (${book.year})`;
}

function render(books) {
  return books.map(format);
}

function main() {
  render([{ title: "Iracema", year: 1865 }]);
}

main();
```

```
ana@dev:~/js$ node stack.js 2>&1 | head -n 6
Trace: inside format
    at format (/home/ana/js/stack.js:2:11)
    at Array.map (<anonymous>)
    at render (/home/ana/js/stack.js:7:16)
    at main (/home/ana/js/stack.js:11:3)
    at Object.<anonymous> (/home/ana/js/stack.js:14:1)
```

**Read a stack from the top: the top line is where you are, and each line below is the call that led
there.** `format` was called by `map`, built into arrays and so shown as `<anonymous>`; `map` by
`render`; `render` by `main`; and `main` by the file's own top level. Every error in this course has
printed one of these under its message, and lesson 17 is about reading them.

## The stack has a size

```javascript
function countDown(n) {
  return n === 0 ? 0 : 1 + countDown(n - 1);
}
console.log(countDown(1000));
console.log(countDown(1_000_000));
```

```
ana@dev:~/js$ node overflow.js 2>&1 | head -n 6
1000
/home/ana/js/overflow.js:1
function countDown(n) {
                  ^

RangeError: Maximum call stack size exceeded
```

Each call that has not returned holds a frame, and **the stack has room for a limited number of
frames**. A thousand nested calls fitted; a million did not, and the engine stopped with
`RangeError: Maximum call stack size exceeded`. This is the same error lesson 7 got by spreading a
million arguments into one call. In practice it almost always means a recursion that never reaches
its end, such as walking a structure that points back at itself, which lesson 5's `WeakSet` guarded
against.

## Empty is the important state

**When the last frame returns, the stack is empty, and only then can anything else run.** That is the
moment the browser waits for: the click handler in the last section sat in a queue until the sort had
returned and the stack was empty. The event loop, two sections on, is the rule for what runs next.
