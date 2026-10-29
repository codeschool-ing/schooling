---
title: SvelteKit
version: 1
---

**In SvelteKit a folder under `src/routes/` is an address, and the files in it divide the page by
where they run.** `+page.svelte` is the component, which runs on the server and again in the
browser. `+page.server.ts` beside it holds a `load` function that runs **only on the server**, and
whatever it returns becomes the component's `data`. `src/routes/courses/[slug]/` answers
`/courses/` followed by anything.

The data is read in one place. Save it as `src/lib/plan.ts`, and delete the `src/lib/index.ts` the
maker left there, which nothing uses:

```typescript
// src/lib/plan.ts: the planner's data, read on the server.
import { readFile } from "node:fs/promises";

export interface Plan {
  courses: { slug: string; title: string }[];
  sessions: { id: number; course: string; date: string; minutes: number; done: boolean }[];
}

export async function getPlan(): Promise<Plan> {
  return JSON.parse(await readFile("courses.json", "utf8"));
}
```

The home page's data, in `src/routes/+page.server.ts`. The import says `#lib/plan.ts`: SvelteKit 3
reaches `src/lib` through the `#lib` entry the maker wrote into `package.json`, and an older
tutorial's `$lib` is refused at build time with a message that says so.

```typescript
// src/routes/+page.server.ts: the data for the address /, loaded on the server.
import { getPlan } from "#lib/plan.ts";

export async function load() {
  return { plan: await getPlan() };
}
```

The home page itself replaces `src/routes/+page.svelte`. `$props()` hands it what `load` returned:

```html
<!-- src/routes/+page.svelte: the address /. -->
<script lang="ts">
  let { data } = $props();
</script>

<svelte:head><title>Study planner</title></svelte:head>
<h1>Study planner</h1>
<ul>
  {#each data.plan.courses as c (c.slug)}
    <li>
      <a href="/courses/{c.slug}">{c.title}</a> ·
      {data.plan.sessions.filter((s) => s.course === c.slug).length} sessions
    </li>
  {/each}
</ul>
```

**A plain `<a>` is enough.** SvelteKit catches clicks on links to its own routes and navigates in
the browser, as `mount` did in lesson 1, without a component of its own for links. A course's data,
in `src/routes/courses/[slug]/+page.server.ts`, where `error(404)` answers an unknown slug:

```typescript
// src/routes/courses/[slug]/+page.server.ts: the data for /courses/<slug>.
import { error } from "@sveltejs/kit";
import { getPlan } from "#lib/plan.ts";

export async function load({ params }) {
  const plan = await getPlan();
  const course = plan.courses.find((c) => c.slug === params.slug);
  if (!course) error(404);
  return { course, sessions: plan.sessions.filter((s) => s.course === params.slug) };
}
```

And its page, `src/routes/courses/[slug]/+page.svelte`. **This `load` returns only the one course and
its sessions**, so that is all the data the browser receives with this page. The section "What each
one sends besides the HTML" compares that with the other three:

```html
<!-- src/routes/courses/[slug]/+page.svelte: the address /courses/<slug>. -->
<script lang="ts">
  let { data } = $props();
</script>

<svelte:head><title>Study planner</title></svelte:head>
<p><a href="/">All courses</a></p>
<h1>{data.course.title}</h1>
<ul>
  {#each data.sessions as s (s.id)}
    <li>{s.date} · {s.minutes} min{s.done ? " · done" : ""}</li>
  {/each}
</ul>
```

`params` and `data` are typed without a line of yours: SvelteKit writes the types for each route as
it builds, and `npm run check` writes them first and then checks every file against them.

## Building and serving

A SvelteKit project is turned into something a host can run by an **adapter**. The maker's
`--add sveltekit-adapter="adapter:node"` chose the one that writes a Node server into `build/`, and
put it in `vite.config.ts`. The build is Vite's, and prints Vite's list of files; the last four
lines are the adapter's:

```
ana@dev:~/meta/svelte$ npm run check 2>&1 | tail -1
svelte-check found 0 errors and 0 warnings
ana@dev:~/meta/svelte$ npm run build 2>&1 | tail -4
> Using @sveltejs/adapter-node
Copying assets
Compressing and hashing assets
✔ done
ana@dev:~/meta/svelte$ ls build build/client
build:
adapter-node.js
client
handler.js
index.js
server

build/client:
_app
robots.txt
robots.txt.br
robots.txt.gz
```

The adapter also wrote each file again compressed, as `.br` and `.gz`, so the server can send a
compressed copy without compressing on every request. Start it in the second terminal:

```sh
PORT=3003 node build
```
