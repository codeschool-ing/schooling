---
title: One thing at a time
version: 1
---

**A page's JavaScript runs on one thread**: one sequence of instructions, one at a time. While a
function is running, nothing else in that page's JavaScript can run, and that includes the handlers
for the user's clicks. A button that starts a long job shows it:

```html
<!doctype html>
<button id="sort">Sort 2 seconds' worth</button>
<button id="ping">Ping</button>
<script>
  const round = (ms) => Math.round(ms / 100) * 100;
  let busyFrom = 0;

  document.querySelector("#sort").addEventListener("click", () => {
    busyFrom = performance.now();
    while (performance.now() - busyFrom < 2000) {
      // pretend to sort a very large list
    }
    console.log("sorting finished after about", round(performance.now() - busyFrom), "ms");
  });

  document.querySelector("#ping").addEventListener("click", () => {
    console.log("ping handled about", round(performance.now() - busyFrom), "ms after sorting began");
  });
</script>
```

```
ana@dev:~/js$ page freeze.html --do 'eval setTimeout(() => document.querySelector("#sort").click()); setTimeout(() => document.querySelector("#ping").click(), 100); undefined' --wait 2600
-- eval setTimeout(() => document.querySelector("#sort").click()); setTimeout(() => document.querySelector("#ping").click(), 100); undefined
sorting finished after about 2000 ms
ping handled about 2000 ms after sorting began
```

`page` clicked Sort, and a tenth of a second later clicked Ping. **Ping was handled only when the
sort had finished, two seconds in.** The click itself happened on time; the browser noted it and put
it in a queue. Its handler could not run until the code already running had returned, because there
is only one thread to run it on. For those two seconds the page could not react to anything, and a
real browser would also have stopped drawing it.

## Why one thread

Two threads touching the same page at once would need locks around every element, and every script
on the web would have to be written with them in mind. **One thread means a function, once started,
runs to its end without anything else changing the page under it.** That guarantee is called
**run-to-completion**, and it is what makes ordinary page code simple:

```javascript
console.log("1. the program starts");

setTimeout(() => console.log("4. the timer's callback"), 0);

for (let i = 0; i < 3; i++) {
  console.log(`2. loop, turn ${i}`);
}

console.log("3. the program's last line");
```

```
ana@dev:~/js$ node run-to-completion.js
1. the program starts
2. loop, turn 0
2. loop, turn 1
2. loop, turn 2
3. the program's last line
4. the timer's callback
```

The timer was set for 0 milliseconds, before the loop, and **its callback still ran last**. Nothing
interrupts code that is running; the callback waited for the whole program to finish. The rest of this
lesson is about that waiting: where callbacks wait, in what order they come out, and what the browser
does in between.
