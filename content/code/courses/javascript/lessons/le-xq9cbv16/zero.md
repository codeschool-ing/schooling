---
title: What zero really means
version: 1
---

`setTimeout(fn, 0)` does not mean "now". **It means: as a new task, after everything currently
running and every microtask** (lesson 13). People use it to push work to "right after this",
for example to let the browser draw a change before a slow step. There is one more thing zero does
not mean, and only a measurement shows it:

```html
<!doctype html>
<script>
  const gaps = [];
  let last = performance.now();
  function step() {
    const now = performance.now();
    gaps.push(now - last);
    last = now;
    if (gaps.length < 8) setTimeout(step, 0);
    else gaps.forEach((g, i) => console.log(`level ${i + 1}: ${g < 4 ? "under 4 ms" : "4 ms or more"}`));
  }
  setTimeout(step, 0);
</script>
```

```
ana@dev:~/js$ page nested.html --wait 500
level 1: under 4 ms
level 2: under 4 ms
level 3: under 4 ms
level 4: under 4 ms
level 5: under 4 ms
level 6: under 4 ms
level 7: 4 ms or more
level 8: 4 ms or more
```

Each `step` schedules the next with a zero delay, so every timer is nested inside the one before.
**The first six came back in under 4 ms; from the seventh on, each took 4 ms or more.** That is
deliberate: the HTML standard tells browsers to clamp the delay of deeply nested timers to at least
4 ms, so that a page that schedules itself endlessly with zero delays cannot keep the processor at
full speed. The program prints a category rather than milliseconds, because the category is what
stays the same between runs.

## What to take from it

- **zero is "soon", and "soon" depends on what else is queued.** Code that needs something to happen
  before the next frame uses `requestAnimationFrame`; code that needs it before any other task uses a
  microtask, `queueMicrotask` or `await`;
- **a chain of zero-delay timers is slower than it looks**: a thousand of them take at least four
  seconds in a browser. Lesson 13's slicing used them for the opposite reason, to give the page room
  between slices, and that is their honest use;
- Node has its own minimum of one millisecond for timers and no 4 ms rule. **The language says
  nothing about timers at all**: `setTimeout` is part of what each host adds, which is why the two
  differ here.
