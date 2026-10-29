---
title: writable, readable and derived
version: 1
---

**`svelte/store` provides three functions that build stores correctly, so that you do not have to.**
The hand-written clock of the previous section has a flaw: two components subscribing to it would
start two timers. A store built with these functions keeps one value and one source, however many
subscribers it has, and starts the source when the first arrives and stops it when the last leaves.

| function | makes | you can |
|---|---|---|
| `writable(initial)` | a store you set from outside | `.set(value)`, `.update((old) => new)`, subscribe |
| `readable(initial, start)` | a store that sets itself, from a source you start | subscribe only |
| `derived(stores, fn)` | a store computed from other stores | subscribe only |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The life of a readable store with two subscribers, along a time line. When the first subscriber, a component, subscribes, the store calls its start function, which starts the interval. A second subscriber joins and shares the same interval. The first leaves and the interval keeps running for the second. When the last subscriber leaves, the store calls the function start returned, which clears the interval.\"><line x1=\"40\" y1=\"200\" x2=\"690\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,200.0 682.6,203.1 682.6,196.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"690\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><rect x=\"120\" y=\"30\" width=\"300\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">subscriber A</text><rect x=\"260\" y=\"76\" width=\"340\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">subscriber B</text><rect x=\"120\" y=\"130\" width=\"480\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">one setInterval, shared by both</text><line x1=\"120\" y1=\"200\" x2=\"120\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"120.0,168.0 123.1,175.4 116.9,175.4\" fill=\"var(--amber)\"></polygon><text x=\"120\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">first in: start()</text><line x1=\"600\" y1=\"200\" x2=\"600\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"600.0,168.0 603.1,175.4 596.9,175.4\" fill=\"var(--amber)\"></polygon><text x=\"600\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">last out: what start() returned</text><line x1=\"260\" y1=\"196\" x2=\"260\" y2=\"204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"420\" y1=\"196\" x2=\"420\" y2=\"204\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line></svg>", "caption": "A readable store runs its source only while somebody is subscribed, and only once however many are."}
```

Rewrite `src/lib/timer.js` with them, and give it a start and a stop:

```schooling-example
{"language": "javascript", "file": "src/lib/timer.js", "parts": [
 {"code": "// timer.js: a study timer, made of three stores.\nimport { readable, writable, derived } from 'svelte/store';\n\nexport const now = readable(Date.now(), (set) => {\n\tconst id = setInterval(() => set(Date.now()), 250);\n\treturn () => clearInterval(id);\n});", "note": "`readable` takes the starting value and a function that starts the source. It runs when the first subscriber arrives; what it returns runs when the last one leaves."},
 {"code": "export const startedAt = writable(null);", "note": "`writable` is a value anybody may set: here, when the timer was started, or `null` while it is stopped."},
 {"code": "export const elapsed = derived([now, startedAt], ([$now, $startedAt]) =>\n\t$startedAt === null ? 0 : Math.floor(($now - $startedAt) / 1000)\n);", "note": "`derived` recalculates from the stores it lists whenever any of them changes. Its argument receives their values, in order."}
]}
```

```schooling-example
{"language": "html", "file": "src/routes/timer/+page.svelte", "parts": [
 {"code": "<script>\n\timport { startedAt, elapsed } from '#lib/timer.js';\n</script>\n\n<main>\n\t<h1>Study timer</h1>\n\t{#if $startedAt === null}\n\t\t<button onclick={() => startedAt.set(Date.now())}>Start</button>\n\t{:else}\n\t\t<button onclick={() => startedAt.set(null)}>Stop</button>\n\t{/if}\n\t<p>{$elapsed} s studied</p>\n</main>", "note": "Two stores read with `$`. The buttons call `set` on the writable one."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/timer --click Start --wait 2400
-- click Start
-- wait 2400
at /timer
- main:
  - heading "Study timer" [level=1]
  - button "Stop"
  - paragraph: 2 s studied
```

**The store outlives the page.** `startedAt` lives in the module, not in the component, so it keeps its
value if the timer page is left and opened again by a link inside the application; only reloading the
whole page starts it fresh. That is the reason stores were used for shared state, and it is also, on the
server, a problem the next lesson is about.

## Updating from the old value

`update` is `set` with a function, for when the new value depends on the old one: `count.update((n) =>
n + 1)`. Inside a component, `$count += 1` is shorthand for exactly that, and `$startedAt = null` for
`startedAt.set(null)`. The shorthand only exists where `$` does, in components.
