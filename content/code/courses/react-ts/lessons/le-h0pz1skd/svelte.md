---
title: Svelte, a compiler
version: 1
---

**Svelte is a compiler more than a library.** A `.svelte` file is turned at build time into JavaScript
that creates the page and updates it directly, with no comparing step in the browser. The project:

```
ana@dev:~$ npm create vite@9.3.1 sessions-svelte -- --template svelte-ts --no-interactive > /dev/null && cd sessions-svelte && npm config set save-exact true --location=project && npm install --silent --save-dev svelte@5.57.2 @sveltejs/vite-plugin-svelte@7.3.1 @tsconfig/svelte@5.0.8 @types/node@22.20.5 svelte-check@4.7.7 typescript@6.0.3 vite@8.3.5 && rm src/lib/Counter.svelte && grep -A 9 "\"devDependencies\"" package.json
  "devDependencies": {
    "@sveltejs/vite-plugin-svelte": "7.3.1",
    "@tsconfig/svelte": "5.0.8",
    "@types/node": "22.20.5",
    "svelte": "5.57.2",
    "svelte-check": "4.7.7",
    "typescript": "6.0.3",
    "vite": "8.3.5"
  }
}
```

**Everything is under `devDependencies`**, `svelte` included, because Svelte is mostly a tool that runs
while you build. The small part of it the compiled code needs at run time is copied into the bundle by
the build, like any other import. `src/lib/Sessions.svelte`:

```html
<script lang="ts">
  type Session = { id: string; course: string; minutes: number; done: boolean }

  let sessions = $state<Session[]>([
    { id: 's1', course: 'Statistics', minutes: 40, done: true },
    { id: 's2', course: 'Python', minutes: 35, done: false },
    { id: 's3', course: 'Statistics', minutes: 45, done: false },
  ])
  const done = $derived(sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0))
  const total = $derived(sessions.reduce((sum, s) => sum + s.minutes, 0))
  console.log('Sessions ran')
</script>

<section>
  <h1>This week</h1>
  <p>{done} of {total} minutes done</p>
  <ul>
    {#each sessions as s (s.id)}
      <li>
        <button aria-pressed={s.done} onclick={() => (s.done = !s.done)}>
          {s.course} · {s.minutes} min
        </button>
      </li>
    {/each}
  </ul>
</section>
```

- The **`<script>`** runs once, when the component is created, like Vue's.
- **`$state`** makes a reactive value, and **`$derived`** one worked out from others. Svelte calls them
  **runes**: they look like functions, but the compiler reads them and writes the code that tracks them.
  There is no `.value` here; `sessions` is read and written like any variable.
- The click handler writes **`s.done = !s.done`** straight into the array, as Vue's did, for the same
  reason: `$state` wrapped it in a proxy.
- The markup follows the script, with no `return`. **`{#each sessions as s (s.id)}`** repeats it, with the
  key in parentheses; **`onclick`** is the attribute every browser already knows, given a function.

`src/App.svelte`:

```html
<script lang="ts">
  import Sessions from './lib/Sessions.svelte'
</script>

<Sessions />
```

Build, serve, click:

```
ana@dev:~/sessions-svelte$ npm run build

> sessions-svelte@0.0.0 build
> vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 112 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                  0.46 kB │ gzip:  0.29 kB
dist/assets/index-CsUDhMuy.css   4.10 kB │ gzip:  1.46 kB
dist/assets/index-zq9nADzc.js   33.37 kB │ gzip: 13.22 kB

✓ built in 234ms
ana@dev:~/sessions-svelte$ look http://localhost:4173/ --do 'click button Python · 35 min' --do 'click button Statistics · 45 min'
Sessions ran
-- click button Python · 35 min
-- click button Statistics · 45 min
- heading "This week" [level=1]
- paragraph: 120 of 120 minutes done
- list:
  - listitem:
    - button "Statistics · 40 min" [pressed]
  - listitem:
    - button "Python · 35 min" [pressed]
  - listitem:
    - button "Statistics · 45 min" [pressed]
```

**`Sessions ran` once again**, and this time even the template does not run again in any form you would
recognise. The compiler wrote, for each place that reads `done`, `total` or `s.done`, a small piece of code
that updates that one text or attribute, and a click runs those pieces and nothing else.

`112 modules transformed`, against React's 17, is the compiler at work: the parts of Svelte's run time this
component needs, each a small module, put together. Svelte's `build` script does not check types, as the
Vue one does; that is the separate `npm run check`, which runs `svelte-check`.
