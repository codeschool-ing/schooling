---
title: When the screen is drawn
version: 1
---

The figure in the last section had a step between the microtasks and the next task: **maybe draw a
frame**. The browser updates the screen at most once per turn of the loop, between tasks, typically
sixty times a second, and never while JavaScript is running. Two consequences follow, and both are
useful:

```html
<!doctype html>
<div id="bar" style="width: 0; height: 10px; background: teal"></div>
<script>
  const bar = document.querySelector("#bar");
  let frames = 0;

  function grow() {
    frames += 1;
    bar.style.width = `${frames * 10}px`;
    if (frames < 5) requestAnimationFrame(grow);
    else console.log("5 frames drawn, width", bar.style.width);
  }
  requestAnimationFrame(grow);

  bar.style.width = "100px";
  bar.style.width = "200px";
  bar.style.width = "0px";
  console.log("three widths set in one task; the screen only ever saw the last");
</script>
```

```
ana@dev:~/js$ page frames.html --wait 500
three widths set in one task; the screen only ever saw the last
5 frames drawn, width 50px
```

- **Changes made within one task are drawn together.** The script set the bar's width three times in
  a row; the screen was never drawn between them, so nobody saw 100 or 200 pixels. That is why a
  script can rebuild a whole list (lesson 11) without the page flickering through every step;
- **`requestAnimationFrame(fn)` runs `fn` just before the next frame is drawn.** `grow` asked for it
  five times, once per frame, and the bar grew ten pixels a frame. Animation code uses it so each
  change lands on exactly one frame.

## Fixing the frozen page

The page in section 02 froze because one task took two seconds, and no frame and no click
could happen until it ended. **The fix is to cut long work into short tasks**, so the loop gets a
turn between them:

```html
<!doctype html>
<button id="ping">Ping</button>
<script>
  const round = (ms) => Math.round(ms / 100) * 100;
  const started = performance.now();
  let done = 0;

  function work() {
    const sliceStart = performance.now();
    while (performance.now() - sliceStart < 50) {
      // one 50 ms slice of a long job
    }
    done += 1;
    if (done < 40) setTimeout(work, 0);
    else console.log("job finished after about", round(performance.now() - started), "ms");
  }
  setTimeout(work, 0);

  document.querySelector("#ping").addEventListener("click", () => {
    console.log("ping handled about", round(performance.now() - started), "ms in, after", done, "slices");
  });
</script>
```

```
ana@dev:~/js$ page chunks.html --do 'eval setTimeout(() => document.querySelector("#ping").click(), 100); undefined' --wait 2600
-- eval setTimeout(() => document.querySelector("#ping").click(), 100); undefined
ping handled about 300 ms in, after 6 slices
job finished after about 2200 ms
```

The same two seconds of work, done in forty slices of 50 ms, each slice scheduling the next with
`setTimeout`. **The ping was answered while the job was running, after 6 slices**, not after all 40:
between slices, the loop ran the click's task. The job took a little longer in total, because the
loop did other things in between, and that is the trade. For work that is heavy on calculation, a
**Web Worker** runs it on a separate thread with no access to the page, which is the other answer.
Lesson 15 has more on timers, and lesson 22 shows how to find which function is the slow one.
