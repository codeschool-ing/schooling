---
title: Nuxt
version: 1
---

**In Nuxt a file under `app/pages/` is an address.** `app/pages/index.vue` answers `/`, and
`app/pages/courses/[slug].vue` answers `/courses/` followed by anything, with `slug` as the
parameter. A page is an ordinary Vue component; Nuxt renders it on the server for the first
request and hydrates it in the browser. Data the server provides lives in a separate folder,
`server/`, which never reaches the browser at all.

The data is an endpoint of the project's own server. Save this as `server/api/plan.get.ts`; the
folder makes it `/api/plan`, and `.get` makes it answer only `GET`:

```typescript
// server/api/plan.get.ts: the planner's data, read on the server, at /api/plan.
import { readFile } from "node:fs/promises";

export default defineEventHandler(async () => JSON.parse(await readFile("courses.json", "utf8")));
```

`defineEventHandler` is not imported: Nuxt imports its own functions for you, in the server and in
the pages. The page around every route replaces the maker's `app/app.vue`, and `<NuxtPage />` is
where the page for the address goes:

```html
<!-- app/app.vue: the page around every route. -->
<template>
  <main>
    <NuxtPage />
  </main>
</template>
```

The home page, in a new `app/pages/index.vue`. **`useFetch` is the line that decides how this page
renders**: on the server it calls `/api/plan` directly, without going over the network, and puts
the result in the page it sends; in the browser it finds that result already there and does not
fetch again:

```html
<!-- app/pages/index.vue: the address /. -->
<script setup lang="ts">
const { data: plan } = await useFetch("/api/plan");
</script>

<template>
  <h1>Study planner</h1>
  <ul>
    <li v-for="c in plan.courses" :key="c.slug">
      <NuxtLink :to="`/courses/${c.slug}`">{{ c.title }}</NuxtLink> ·
      {{ plan.sessions.filter((s) => s.course === c.slug).length }} sessions
    </li>
  </ul>
</template>
```

And a course, in `app/pages/courses/[slug].vue`. `createError` with a status of 404 makes the
server answer an unknown course with a 404 page:

```html
<!-- app/pages/courses/[slug].vue: the address /courses/<slug>. -->
<script setup lang="ts">
const slug = useRoute().params.slug as string;
const { data: plan } = await useFetch("/api/plan");
const course = plan.value.courses.find((c) => c.slug === slug);
if (!course) throw createError({ statusCode: 404 });
</script>

<template>
  <p><NuxtLink to="/">All courses</NuxtLink></p>
  <h1>{{ course.title }}</h1>
  <ul>
    <li v-for="s in plan.sessions.filter((s) => s.course === slug)" :key="s.id">
      {{ s.date }} · {{ s.minutes }} min{{ s.done ? " · done" : "" }}
    </li>
  </ul>
</template>
```

Last, the configuration, replacing `nuxt.config.ts`, which gives every page the same title and
language as the planner:

```typescript
// nuxt.config.ts
export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  app: { head: { title: "Study planner", htmlAttrs: { lang: "en" } } },
});
```

`compatibilityDate` came from the maker and stays. It tells Nuxt and its server which behaviour to
keep when a later version changes a default, so the project behaves as it did on the day it was
made until somebody moves the date.

## Building and serving

`npm run build` writes everything into `.output/`: the browser's files in `.output/public` and a
server in `.output/server`. It prints a long list of the files it wrote, which is not reproduced
here, so this build sends it nowhere and looks at what it made instead:

```
ana@dev:~/meta/nuxt$ npm run build >/dev/null 2>&1; ls .output .output/server
.output:
nitro.json
public
server

.output/server:
chunks
index.mjs
index.mjs.map
node_modules
package.json
```

**The built server carries the few packages it needs in a `node_modules` of its own**, a few
megabytes, so `.output` can be copied to another computer as it is, without the 200 MB the project
installed. **Nuxt renders on the server for every request by default**; nothing
here was rendered at build time, and the section "Rendering mode, per route" shows the switch that
changes that. Start it in the second terminal:

```sh
PORT=3002 node .output/server/index.mjs
```
