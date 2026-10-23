---
title: Async components, four ways
version: 1
---

**An async component is one that needs to wait for something before it can render, and a framework
lets the rest of the page go ahead without it.** It is `stream.ts` written as a component: the
framework sends a placeholder where the component goes and fills it in when its data arrives. Two of
the four meta-frameworks of lesson 2 fill it in later in the same response, and they do it in two
different ways.

## Next.js: `<Suspense>` streams the HTML

Wrap a component that waits in `<Suspense>`, give it a `fallback`, and Next.js sends the fallback with
the rest of the page and the component's HTML later. In the Next.js project, save this as
`app/slow/page.tsx`; the second's wait stands for a slow query, as in `stream.ts`:

```tsx
// app/slow/page.tsx: a page with one part that takes a second to arrive.
import { Suspense } from "react";

async function Sessions() {
  await new Promise((done) => setTimeout(done, 1000)); // stands for a slow query
  return <ul><li>Sat 2026-10-24 · 25 min</li><li>Tue 2026-10-27 · 40 min</li></ul>;
}

export default function Slow() {
  return (
    <>
      <h1>Git</h1>
      <Suspense fallback={<p>Loading sessions…</p>}>
        <Sessions />
      </Suspense>
    </>
  );
}
```

Build, start it on port 3001, and look at the pieces:

```
ana@dev:~/planner$ node tools/chunks.ts http://localhost:3001/slow
87 ms  status 200
122 ms  1302 bytes  <!DOCTYPE html><html lang="en"><head><meta charSet="utf-8"/>
132 ms  4127 bytes  <script>(self.__next_f=self.__next_f||[]).push([0])</script>
133 ms  4030 bytes  <script>self.__next_f.push([1,"1a:o1,~1a:o40d,2:\"$Sreact.fr
1101 ms  211 bytes  <script>self.__next_f.push([1,"a:[\"$\",\"ul\",null,{\"child
1101 ms  73 bytes  <script src="/_next/static/chunks/0cz1d0mv5g_q7.js" noModule
1103 ms  964 bytes  <div hidden id="S:0"><ul><li>Sat 2026-10-24 · 25 min</li><li
1104 ms  14 bytes  </body></html>
```

The first pieces arrived together, the page and the fallback, and the sessions came a second later
as HTML in a hidden `<div>`, with the React payload for them just before. The build listed `/slow`
with a `◐`: its shell is prerendered, and the part inside `<Suspense>` is rendered per request.

## SvelteKit: a promise streams the data

In SvelteKit, a `load` function on the server may return a promise **without waiting for it**. The
page renders at once with the promise still pending, and SvelteKit sends its value later in the same
response. The page itself decides what to show meanwhile, with `{#await}`. Two new files in the
SvelteKit project; the first switches off lesson 3's prerender for this one route, because a page
built ahead of time cannot wait for anything:

```typescript
// src/routes/slow/+page.server.ts: a page with one part that takes a second to arrive.
export const prerender = false;

export function load() {
  const sessions = new Promise<string[]>((done) =>
    setTimeout(() => done(["Sat 2026-10-24 · 25 min", "Tue 2026-10-27 · 40 min"]), 1000)); // stands for a slow query
  return { sessions };
}
```

```html
<!-- src/routes/slow/+page.svelte: the title at once, the sessions when they come. -->
<script lang="ts">
  let { data } = $props();
</script>

<h1>Git</h1>
{#await data.sessions}
  <p>Loading sessions…</p>
{:then sessions}
  <ul>
    {#each sessions as s}<li>{s}</li>{/each}
  </ul>
{/await}
```

```
ana@dev:~/planner$ node tools/chunks.ts http://localhost:3003/slow
69 ms  status 200
70 ms  4519 bytes  <!doctype html> <html lang="en"> <head> <meta charset="utf-8
1054 ms  113 bytes  <script>__sveltekit_1k3z5ml.resolve(1, () => [["Sat 2026-10-
```

**The second piece is not HTML but data**: a call to a function SvelteKit put in the page, with the
two sessions as its argument. The script renders them into the page. So in SvelteKit the sessions
only ever appear with JavaScript, where in Next.js they arrive as HTML and need JavaScript only to be
moved into place.

## Nuxt and Angular

**On the server, Nuxt renders a page once its data is in**, and its `lazy` option for `useFetch`
changes what happens on navigations in the browser, where the new page can show before its data
arrives. Angular's `@defer` block renders its placeholder on the server, and the block itself is
loaded and rendered in the browser. Neither sends a slow part later in the same response, in the
versions of this lesson. Both still keep a slow part from holding up the rest of the page; the
difference is where the slow part is finally drawn, and whether a crawler ever sees it.

| | the slow part arrives as | in the first response? | without JavaScript |
|---|---|---|---|
| `stream.ts` | HTML, in a template | yes, later in it | the placeholder stays |
| Next.js `<Suspense>` | HTML, in a hidden element | yes, later in it | the placeholder stays |
| SvelteKit streamed promise | data, rendered by the script | yes, later in it | the placeholder stays |
| Nuxt `lazy` | data, fetched on navigation in the browser | the server waited for it | on the first page, yes |
| Angular `@defer` | a component, loaded in the browser | the placeholder only | the placeholder stays |
