---
title: The profiler
version: 2
---

**A profiler samples the call stack thousands of times a second and counts where the program
was.** A function that shows up in many samples is where the time goes. This page sorts twenty
thousand titles, ignoring accents and case, and `sort.html` loads it with one `<script>` tag:

```javascript
const words = ["Sertão", "Estrela", "Casmurro", "Veredas", "Iracema", "Macunaíma", "Sagarana", "Capitães"];
const titles = Array.from({ length: 20000 }, (_, i) => `${words[i % 8]} ${words[(i * 7) % 8]} ${i}`);

function key(title) {
  return title.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function byTitle(list) {
  return [...list].sort((a, b) => key(a).localeCompare(key(b)));
}

const sorted = byTitle(titles);
console.log(sorted[0], "|", sorted.at(-1));
```

```
ana@dev:~/js$ page sort.html --profile
Capitães Estrela 10007 | Veredas Macunaíma 9995
share  self time  function
  67%     124 ms  key  sort.js:4
  10%      18 ms  (anonymous)  sort.js:9
   6%      11 ms  byTitle  sort.js:8
   6%      11 ms  (program)
   6%      11 ms  (garbage collector)
          186 ms  busy in total
```

`--profile` records a CPU profile with a sample every 0.1 ms and lists the five functions
with the most **self time**. The milliseconds are this run's and move by a few between runs. `key`
came first in every run made for this lesson; the rows below it changed places.

## Self time

**Self time is the time a function spent running its own code, not the code of the functions it
called.** `byTitle` was on the stack for the whole sort, but it called `sort`, which called the
comparator, which called `key`; almost none of that time is its own. `key` is the opposite: every
sample that landed on it was its own work.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Three functions from the sorting page, each as a bar for the time spent while it was on the stack. byTitle&#x27;s bar is the longest, but almost all of it is time spent in the functions it called; the comparator&#x27;s bar is shorter and mostly calls to key; key&#x27;s bar is all its own time. The profiler&#x27;s self time is the solid part of each bar, which is why key, not byTitle, tops the list.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">byTitle</text><rect x=\"20\" y=\"40\" width=\"660\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"20\" y=\"40\" width=\"30\" height=\"26\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">(a, b) =&gt; …</text><rect x=\"70\" y=\"90\" width=\"590\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"70\" y=\"90\" width=\"50\" height=\"26\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">key</text><rect x=\"120\" y=\"140\" width=\"430\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><rect x=\"120\" y=\"140\" width=\"430\" height=\"26\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"200\" y=\"186\" width=\"18\" height=\"14\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"226\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">self time</text><rect x=\"340\" y=\"186\" width=\"18\" height=\"14\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"366\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">time in the functions it called</text></svg>", "caption": "Self time is what a function did itself; the rest of its bar belongs to the functions it called."}
```

The Performance panel in DevTools shows both views: **Bottom-Up** sorts by self time, as here, and
**Call Tree** starts from the top and shows total time, which includes what each function called.
Bottom-Up is where a slow page usually gives itself away.

The entries in parentheses are the engine's own work: `(program)` is the browser outside any
JavaScript function, and `(garbage collector)` is memory being reclaimed, as lesson 19 showed.

## Reading the cause

`key` took 67% of the busy time. The comparator calls it twice for every comparison, and sorting
twenty thousand items takes a few hundred thousand comparisons, so each title was normalised again
and again. The fix is to compute each key once, in `sort-fixed.js`, loaded by a `sort-fixed.html`
that differs from `sort.html` only in that name:

```javascript
const words = ["Sertão", "Estrela", "Casmurro", "Veredas", "Iracema", "Macunaíma", "Sagarana", "Capitães"];
const titles = Array.from({ length: 20000 }, (_, i) => `${words[i % 8]} ${words[(i * 7) % 8]} ${i}`);

function key(title) {
  return title.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function byTitle(list) {
  const keyed = list.map((title) => [key(title), title]);
  keyed.sort((a, b) => a[0].localeCompare(b[0]));
  return keyed.map(([, title]) => title);
}

const sorted = byTitle(titles);
console.log(sorted[0], "|", sorted.at(-1));
```

```
ana@dev:~/js$ page sort-fixed.html --profile
Capitães Estrela 10007 | Veredas Macunaíma 9995
share  self time  function
  23%      16 ms  (anonymous)  sort-fixed.js:10
  20%      14 ms  key  sort-fixed.js:4
  17%      11 ms  (garbage collector)
  17%      11 ms  (program)
  11%       8 ms  byTitle  sort-fixed.js:8
           68 ms  busy in total
```

Same result, and the busy time went from 186 ms to 68 ms in these two runs. `key` now runs twenty
thousand times instead of hundreds of thousands, and the work is spread across the comparator,
`key` and the engine. **No one function dominating is what a profile looks like when there is
nothing obvious left to fix.**

Measure before optimising, and measure after. The change above was worth making because the profile
pointed at it. A guess about what is slow is wrong often enough that the profiler, not the guess,
should choose what to change.
