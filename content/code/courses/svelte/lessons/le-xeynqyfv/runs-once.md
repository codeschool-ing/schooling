---
title: The script runs once
version: 1
---

**A Svelte component's `<script>` runs once, when the component is created, and never again.** In
React the component function runs on every change, so everything inside it, every variable and
every function, is made again each time. In Svelte the script sets things up and is done; after
that, only the small effects the compiler wrote run, each when something it read has changed.

That is easiest to believe by watching it. Change lesson 1's `Counter` so that it says when its
script runs and when an effect runs. `$effect` is lesson 3's subject; here it is a probe, a function
that runs once when the component appears and again whenever a value it read changes:

```schooling-example
{"language": "html", "file": "src/lib/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n\tconsole.log('the script ran');", "note": "The `console.log` is in the script itself, so it prints each time the script runs."},
 {"code": "\t$effect(() => {\n\t\tconsole.log(`the effect ran: minutes is ${minutes}`);\n\t});\n</script>", "note": "The effect reads `minutes`, so it runs again every time `minutes` changes."},
 {"code": "<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<p>{minutes} minutes this week</p>", "note": "The markup is lesson 1's, unchanged."}
]}
```

And put the counter on the planner's page for this lesson, under the heading. `#lib` is a name for
`src/lib` that the project's `package.json` declares, so the import does not depend on where the
importing file sits:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport Counter from '#lib/Counter.svelte';\n</script>", "note": "An import in a component's script brings in another component, used as a tag."},
 {"code": "<main>\n\t<h1>Study planner</h1>\n\t<Counter />\n</main>", "note": "Lesson 3 replaces this page with the real planner; for now the counter sits under the heading."}
]}
```

Now open the page, press the button three times, and print the browser's console:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Add 30 minutes' --click 'Add 30 minutes' --click 'Add 30 minutes'
console: [vite] connecting...
console: [vite] connected.
console: the script ran
console: the effect ran: minutes is 0
-- click Add 30 minutes
console: the effect ran: minutes is 30
-- click Add 30 minutes
console: the effect ran: minutes is 60
-- click Add 30 minutes
console: the effect ran: minutes is 90
at /
- main:
  - heading "Study planner" [level=1]
  - button "Add 30 minutes"
  - paragraph: 90 minutes this week
```

The first two lines are Vite's own: the page connecting back to the development server, which is how
a saved file reaches an open browser. After them, **`the script ran` is printed once.** Three presses later, the script has not run again; the effect
has, once for the first appearance and once per press. The variable `minutes` was never declared a
second time, and nothing re-created the button's click handler.

## And on the server

The terminal running `npm run dev` has something to add:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:32:06 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 486 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
the script ran
200 GET /
```

The line before the last is the same `console.log`, printed by the server while it rendered the page
into HTML, and `200 GET /` is the request it was answering.
So the script ran **twice in total: once on the server and once in the browser**, and each time
exactly once. The effect did not print on the server at all. **Effects never run during server
rendering**, because nothing there will ever change: the server builds a string, sends it and forgets
it. Lesson 1 saw the same thing from the other side, in the server output, where `$state` was an
ordinary `let`.

## Why "runs once" matters

Everything that follows in this course leans on it. A function declared in a Svelte script is the
same function for the life of the component, so there is nothing like React's `useCallback` to keep
it stable. A value computed in the script is not recomputed on the next change unless you ask for
that with `$derived`, which is lesson 3's. And code that should run again when something changes has
to say so, by being in an effect or a derived value or the markup, because nothing else re-runs.

That last point is where people coming from React get caught. They write a calculation in the script
and expect it to follow the state, because in React the whole function would have run again:

```schooling-example
{"language": "html", "file": "src/lib/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n\tlet hours = minutes / 60;\n</script>", "note": "This runs once, when `minutes` is 0, and `hours` stays 0 for ever."},
 {"code": "<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<p>{hours} hours this week</p>", "note": "The paragraph shows `hours`, which never changes, so pressing the button changes nothing on screen."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Add 30 minutes' --click 'Add 30 minutes'
-- click Add 30 minutes
-- click Add 30 minutes
at /
- main:
  - heading "Study planner" [level=1]
  - button "Add 30 minutes"
  - paragraph: 0 hours this week
```

Two presses, an hour of study, and the paragraph still says `0`. The compiler warns about it in the
terminal running `npm run dev`, but only while you happen to be looking there. The `hmr update` line
under the first warning is Vite sending the changed file to the open browser:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:32:06 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 486 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
the script ran
200 GET /
7:32:10 PM [vite-plugin-svelte] src/lib/Counter.svelte:3:13 This reference only captures the initial value of `minutes`. Did you mean to reference it inside a closure instead?
https://svelte.dev/e/state_referenced_locally
7:32:10 PM [vite] (client) hmr update /src/lib/Counter.svelte
7:32:10 PM [vite] (ssr) page reload src/lib/Counter.svelte
7:32:10 PM [vite] (ssr) program reload
7:32:10 PM [vite-plugin-svelte] src/lib/Counter.svelte:3:13 This reference only captures the initial value of `minutes`. Did you mean to reference it inside a closure instead?
https://svelte.dev/e/state_referenced_locally
200 GET /
7:32:12 PM [vite-plugin-svelte] src/lib/Counter.svelte:3:13 This reference only captures the initial value of `minutes`. Did you mean to reference it inside a closure instead?
https://svelte.dev/e/state_referenced_locally
```

**`state_referenced_locally` is the compiler telling you that you read a reactive value once, in a
place that will never read it again.** It is a warning rather than an error because reading the
initial value on purpose is sometimes right. Here it is the bug, and lesson 3 fixes it in one word:
`let hours = $derived(minutes / 60)`. Put the counter back to the version at the top of this section
before going on.
