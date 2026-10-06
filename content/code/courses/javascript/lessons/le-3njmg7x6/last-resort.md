---
title: The last line of defence
version: 1
---

Some errors will reach the top uncaught, because nobody predicts every bug. **Both hosts let a program
hear about them there**, which is where logging and error reports are attached:

```javascript
process.on("uncaughtException", (err) => {
  console.error(`fatal: ${err.name}: ${err.message}`);
  process.exitCode = 1;
});

setTimeout(() => {
  null.title;
}, 0);
console.log("started");
```

```
ana@dev:~/js$ node last-resort.js; echo "exit code: $?"
started
fatal: TypeError: Cannot read properties of null (reading 'title')
exit code: 1
```

`process.on("uncaughtException", …)` received the `TypeError` thrown in the timer. The handler logged
it in one line and **set the exit code to 1**, so whatever started the program, a terminal, a
deployment, a scheduler, knows it failed. That is all a handler like this should do. **The program is
in an unknown state after an uncaught error**: something was halfway through and never finished. The
safe response is to record what happened and stop, and let whatever supervises the process start a
fresh one.

```html
<!doctype html>
<script>
  window.addEventListener("error", (event) => {
    console.log("reported:", event.message, "at line", event.lineno);
  });
  setTimeout(() => {
    document.querySelector("#missing").textContent = "x";
  }, 0);
</script>
```

```
ana@dev:~/js$ page window-error.html
reported: Uncaught TypeError: Cannot set properties of null (setting 'textContent') at line 7
Uncaught TypeError: Cannot set properties of null (setting 'textContent')
```

In a page, the `error` event on `window` plays the same part. The handler received the message and
the line, and the browser still reported it as uncaught, as it should. **A page does not stop on an
uncaught error**: the rest of the page keeps working, and only the code that threw is abandoned.
Lesson 14 showed `unhandledrejection`, the same idea for promises, and error-reporting services
listen to both.

None of this replaces handling errors where they happen. **A global handler is for the errors nobody
expected**, so that each one is seen once, and becomes a bug report rather than a mystery.
