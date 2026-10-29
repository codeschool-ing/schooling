---
title: What a store is
version: 1
---

**A store is any object with a `subscribe` method**: you call `subscribe` with a function, the store
calls that function at once with its current value and again every time the value changes, and
`subscribe` returns a function that stops it. That is the whole contract, and it is older than runes:
Svelte 3 and 4 used stores for every piece of state shared between components, and a great deal of
code still does.

Stores are worth knowing for two reasons. You will read them in any Svelte code older than 2025, and
they remain the right tool for one kind of value: one that **arrives over time from outside**, like a
clock, a connection or a sensor, and that should only be listened to while somebody is looking.

## A store written by hand

The clearest example is a clock. This one is written against the contract directly, with no library,
so that every part of it is visible. Save it as `src/lib/timer.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/timer.js", "parts": [
 {"code": "// timer.js: a clock, as a store written by hand.\nexport const now = {\n\tsubscribe(run) {", "note": "A store is an object with `subscribe`. Nothing else is required."},
 {"code": "\t\trun(Date.now());\n\t\tconst id = setInterval(() => run(Date.now()), 250);", "note": "The contract: call the subscriber at once with the current value, then again on every change."},
 {"code": "\t\treturn () => clearInterval(id);\n\t}\n};", "note": "What `subscribe` returns stops the subscription. Here that also stops the timer, so a clock nobody watches costs nothing."}
]}
```

And a page to watch it. The timer is not part of the planner, so it gets a page of its own at `/timer`,
as lessons 4 and 8 did for their experiments:

```schooling-example
{"language": "html", "file": "src/routes/timer/+page.svelte", "parts": [
 {"code": "<script>\n\timport { now } from '#lib/timer.js';\n\n\tconst opened = Date.now();\n</script>", "note": "A `$` in front of a store's name, in a component, subscribes to it when the component is created and unsubscribes when it is destroyed."},
 {"code": "<main>\n\t<h1>Study timer</h1>\n\t<p>{Math.floor(($now - opened) / 1000)} s on this page</p>\n</main>", "note": "`$now` reads the store's current value, and the paragraph updates each time the store calls back."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/timer --wait 2400
-- wait 2400
at /timer
- main:
  - heading "Study timer" [level=1]
  - paragraph: 2 s on this page
```

Two seconds, after a wait of 2.4: the clock ticks every quarter of a second, and the page shows whole
seconds. **The `$` prefix is what makes a store pleasant to use**: without it you would call
`subscribe` yourself, keep the value in a variable, and remember to call the function it returns when
the component goes away. The compiler writes all three for you whenever a component
reads `$now`.

## The rules of `$`

`$store` works in a component's script and markup, for a store imported or declared at the top level
of that component. It does not work in a plain `.js` module, which the compiler does not rewrite, and
it does not work for a store created inside a function, because the compiler has to know at build time
which name to subscribe to. In those places, `get(store)` from `svelte/store` reads the value once, and
`subscribe` is always there.
