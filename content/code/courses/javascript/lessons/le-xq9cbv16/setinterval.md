---
title: setInterval, and the timeout that repeats itself
version: 1
---

**`setInterval(fn, ms)` runs `fn` every `ms` milliseconds until `clearInterval` stops it.** It keeps
its own schedule, and that is a problem when the work takes longer than the interval. Each tick here
does 150 ms of work, every 100 ms:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
let ticks = 0;

const id = setInterval(() => {
  ticks += 1;
  const busyUntil = performance.now() + 150;
  while (performance.now() < busyUntil) {}
  console.log(`tick ${ticks} ended at about ${round(performance.now() - start)} ms`);
  if (ticks === 4) clearInterval(id);
}, 100);
```

```
ana@dev:~/js$ node interval.js
tick 1 ended at about 300 ms
tick 2 ended at about 400 ms
tick 3 ended at about 600 ms
tick 4 ended at about 700 ms
```

The same work, with each tick scheduling the next one when it has finished:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;
const start = performance.now();
let ticks = 0;

function tick() {
  ticks += 1;
  const busyUntil = performance.now() + 150;
  while (performance.now() < busyUntil) {}
  console.log(`tick ${ticks} ended at about ${round(performance.now() - start)} ms`);
  if (ticks < 4) setTimeout(tick, 100);
}
setTimeout(tick, 100);
```

```
ana@dev:~/js$ node chained-timeout.js
tick 1 ended at about 300 ms
tick 2 ended at about 500 ms
tick 3 ended at about 800 ms
tick 4 ended at about 1000 ms
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two timelines of four ticks, each tick doing 150 ms of work. With setInterval every 100 ms, the next tick is already due when one ends, so the ticks run back to back with no gap. With setTimeout scheduled again at the end of each tick, there is always a 100 ms gap between the end of one tick and the start of the next.\"><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">setInterval</text><rect x=\"190.0\" y=\"45\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"227.5\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"265.0\" y=\"45\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"302.5\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"340.0\" y=\"45\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"377.5\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"415.0\" y=\"45\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"452.5\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">setTimeout</text><rect x=\"190.0\" y=\"115\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"227.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1</text><rect x=\"315.0\" y=\"115\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"352.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">2</text><rect x=\"440.0\" y=\"115\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"477.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">3</text><rect x=\"565.0\" y=\"115\" width=\"75.0\" height=\"26\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.5\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">4</text><path d=\"M140 175 L690.0 175\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M140.0 170 L140.0 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"140.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M390.0 170 L390.0 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"390.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">500 ms</text><path d=\"M640.0 170 L640.0 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><text x=\"640.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1000 ms</text><text x=\"290.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100 ms gap</text></svg>", "caption": "setInterval keeps its schedule even when the work is longer than the interval; a chained setTimeout always leaves the gap."}
```

**With `setInterval`, four ticks ended by about 700 ms**: each time a tick finished, the next was
already overdue, so they ran back to back and the page got no breathing room between them. **With
the chained `setTimeout`, they ended by about 1000 ms**, and there were always 100 ms between the end
of one tick and the start of the next.

## Which to use

- **a chained `setTimeout` for anything whose work can be slow**, and above all for anything that
  waits on a network: polling a server every few seconds with `setInterval` sends the next request
  while the last may still be waiting for its answer;
- `setInterval` for something short and regular, such as a clock ticking once a second, where the
  work is far shorter than the interval;
- `requestAnimationFrame` (lesson 13) for anything that moves on screen, never either timer: it runs
  once per frame the screen actually draws.

Browsers also **slow timers down in tabs nobody is looking at**, often to once a second or less, to
save battery. That was not captured here, since a headless browser has no hidden tab; it is the
reason a countdown written with `setInterval` drifts when the user switches tabs, and why a clock
should read the time on each tick rather than count ticks.
