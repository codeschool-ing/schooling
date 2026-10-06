---
title: A promise nobody waited for
version: 1
---

The mistake `await` makes easy is **leaving it out**. Calling an `async` function without `await`
starts the work and carries straight on, and if the work fails, nothing is there to catch it:

```javascript
const save = async (book) => {
  await new Promise((ok) => setTimeout(ok, 50));
  throw new Error(`could not save ${book}`);
};

function onClick() {
  save("Iracema");
  console.log("saved!");
}

onClick();
```

```
ana@dev:~/js$ node forgot.mjs; echo "exit code: $?"
saved!
file:///home/ana/js/forgot.mjs:3
  throw new Error(`could not save ${book}`);
        ^

Error: could not save Iracema
    at save (file:///home/ana/js/forgot.mjs:3:9)

Node.js v22.22.0
exit code: 1
```

`onClick` printed **`saved!` before anything had been saved**, because `save` returned a pending
promise and nobody waited for it. Fifty milliseconds later the promise rejected, no `.catch` or `try`
was attached, and Node **ended the whole process with exit code 1**. That is Node's rule since
version 15: an unhandled rejection is treated like an uncaught exception, because the alternative is a
failure that happens and is never mentioned.

## In the browser

```html
<!doctype html>
<script>
  window.addEventListener("unhandledrejection", (event) => {
    console.log("nobody handled:", event.reason.message);
  });
  const save = async (book) => {
    throw new Error(`could not save ${book}`);
  };
  save("Iracema");
  console.log("saved!");
</script>
```

```
ana@dev:~/js$ page forgot.html
saved!
nobody handled: could not save Iracema
Uncaught Error: could not save Iracema
```

The page does not stop: it reports the rejection as uncaught, and fires an **`unhandledrejection`
event** on `window`, which the page used to log it. Error-reporting services listen for that event,
which is how a team finds out about failures nobody wrote a `catch` for.

## How to avoid it

- **`await` every promise you start, or return it to a caller that will.** A linter rule,
  `no-floating-promises` in TypeScript's tooling, flags the ones you missed;
- when you deliberately do not wait, as for a background save, **attach a `.catch` that does something
  visible**: log it, retry it, or tell the user;
- never print "saved!" before the save has resolved. The message is a claim, and only the promise
  knows whether it is true.
