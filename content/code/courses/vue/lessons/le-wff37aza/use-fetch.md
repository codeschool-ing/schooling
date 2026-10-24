---
title: useFetch, and where the request is made
version: 1
---

**`useFetch(url)` fetches the data a page needs, once, on whichever side renders the page first, and
hands the result to the other side.** That has been the first line of both of the planner's pages since
lesson 18, and lesson 19 showed what it bought: a page that arrives drawn, and a browser that never asks
for `/api/courses` when the page is first loaded. This lesson takes it apart, and the first step is to
see every request that reaches the API. A file in `server/middleware/` runs before every route of the
server, and this one only prints:

```typescript
// server/middleware/log.ts: a line in the server's terminal for every request to the API.
export default defineEventHandler((event) => {
  if (event.path.startsWith('/api/')) console.log(`api: ${event.method} ${event.path}`)
})
```

It returns nothing, so the request goes on to its route as before. One more change first: lesson 19
left `swr` on the course pages and argued against it, and it goes now, because a cached page would
hide requests this lesson wants to count. `nuxt.config.ts` without it:

```typescript
// nuxt.config.ts: the study planner, made by Nuxt.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  // Off, as lesson 1 left Vue's: a button and requests of their own in every page.
  devtools: { enabled: false },
  css: ['~/assets/main.css'],
  app: {
    head: { htmlAttrs: { lang: 'en' }, title: 'Study planner' },
  },
  routeRules: {
    // Drawn once, by the build: nothing on it changes between two deploys.
    '/about': { prerender: true },
    // No cache between the server and the browser may keep an answer of the API.
    '/api/**': { headers: { 'cache-control': 'no-store' } },
  },
})
```

Start the dev server, open the week, and list what the browser asks the API for:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --text - | grep '/api/'
```

**Nothing.** And the server's terminal, at the end of its start-up lines:

```
ana@dev:~/vue/planner-nuxt$ npm run dev

> dev
> nuxt dev

● Starting Nuxt...
● Nuxt 4.6.2 (with Nitro 2.13.5, Vite 8.3.5 and Vue 3.5.44)

  ➜ Local:    http://localhost:3000/
  ➜ Network:  use --host to expose

● Setting up modules
● Preparing app
● Generating types
● Bundling app
✔ Vite client built in 48ms
✔ Vite server built in 18ms
● Building server
[nitro] ✔ Nuxt Nitro server built in 1322ms
◆ Ready in 2.63s  → http://localhost:3000/
  config 230ms · modules 81ms · app 349ms · types 358ms · bundle 204ms · server 1.41s
(node:29149) [UNDICI-EHPA] Warning: EnvHttpProxyAgent is experimental, expect them to change at any time.
(Use node --trace-warnings ... to show where the warning was created)
api: GET /api/courses
```

**One request, made by the server while it rendered the page.** The browser received the answer
inside the page, in the payload, and `useFetch` in the browser found it there instead of asking. Now
click a course, a navigation inside the running page:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --network --do 'click text=Spanish' --text - | grep '/api/'
net  GET /api/courses  200
```

**This time the browser asked.** No server renders a page that the router changes in place, so the
`useFetch` of the course page runs in the browser, and the browser makes the request. Either way it
happens once per page shown, which is the whole job of the function.

## What it gives back

```typescript
const { data, status, error, refresh } = await useFetch('/api/courses')
```

- `data` is a ref holding the parsed JSON, `undefined` until it arrives. Its type comes from the server
  route: Nuxt reads what `courses.get.ts` returns, so `data.value?.sessions` is a list of `Session`
  with nothing declared on this side.
- `status` is `'idle'`, `'pending'`, `'success'` or `'error'`.
- `error` holds the error when the request failed, and the section on errors uses it.
- `refresh()` asks again, as the planner does after every tick.

The `await` matters. On the server, rendering waits for it, so the HTML is drawn with the data; without
it the server would send the page before the answer came back. Lesson 15's `<Suspense>` is what lets a
page's setup be `async` at all, and Nuxt wraps every page in one.
