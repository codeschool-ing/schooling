---
title: Talking back to a generator
version: 1
---

`yield` is a two-way door. **The value passed to `next(value)` becomes the result of the `yield`
expression the generator is paused on**, so a generator can receive answers as well as produce
values:

```javascript
function* conversation() {
  const name = yield "What is your name?";
  const book = yield `Hello, ${name}. Which book?`;
  return `${name} is reading ${book}`;
}

const c = conversation();
console.log(c.next().value);
console.log(c.next("ana").value);
console.log(c.next("Iracema"));
```

```
ana@dev:~/js$ node talk.js
What is your name?
Hello, ana. Which book?
{ value: 'ana is reading Iracema', done: true }
```

The first `next()` ran to the first `yield` and brought back the question; whatever it was passed
would have been thrown away, because no `yield` was waiting for it yet. **`next("ana")` resumed the
paused `yield` with `"ana"` as its value**, so `name` became `"ana"`, and the body ran to the second
question. `next("Iracema")` answered that one, and the `return` finished the conversation.

## Stopping early, and cleaning up

```javascript
function* pages() {
  try {
    yield "page 1";
    yield "page 2";
    yield "page 3";
  } finally {
    console.log("closing the file");
  }
}

for (const p of pages()) {
  console.log(p);
  if (p === "page 2") break;
}

function* everything() {
  yield* ["cover", "contents"];
  yield* pages();
  yield "back cover";
}
console.log([...everything()]);
```

```
ana@dev:~/js$ node cleanup.js
page 1
page 2
closing the file
closing the file
[ 'cover', 'contents', 'page 1', 'page 2', 'page 3', 'back cover' ]
```

The loop stopped at `page 2` with `break`, and **`closing the file` still printed**. When a
`for…of` loop leaves early, it tells the generator by calling its `return()` method, and the
generator runs any `finally` block it is inside before finishing. That is how a generator that opened
a file or a connection gets to close it, however the loop that used it ended.

The second half shows **`yield*`, which hands over to another iterable** and yields everything it
produces: the two strings of an array, then every page of a fresh `pages()` generator, then one more
value. That second `pages()` ran to its end, so its `finally` printed `closing the file` a second
time, right before the list.
