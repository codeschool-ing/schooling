---
title: The build, and what it leaves in dist
version: 1
---

**`npm run build` turns what the dev server sent in thirty-three requests into a handful of files that
any web server can send.**
Since lesson 16 the script type-checks first and only then runs `vite build`:

```
ana@dev:~/vue/planner$ npm run build

> planner@0.0.0 build
> vue-tsc --noEmit && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 61 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                        0.43 kB │ gzip:  0.28 kB
dist/assets/CourseView-7bymtRQi.css    0.06 kB │ gzip:  0.08 kB
dist/assets/index-iufgghmN.css         1.34 kB │ gzip:  0.61 kB
dist/assets/CourseAll-DhFoYFUW.js      0.53 kB │ gzip:  0.36 kB
dist/assets/CourseWeek-CqqcOOPL.js     0.59 kB │ gzip:  0.40 kB
dist/assets/CourseView-CUyh3DIL.js     0.84 kB │ gzip:  0.51 kB
dist/assets/index-BPp-uHAO.js        122.34 kB │ gzip: 47.25 kB

✓ built in 615ms
```

Sixty-one modules went in, counting Vue's and the router's own, and the list names seven files. **The
three small JavaScript files are the routes lesson 12 made lazy**, `CourseView` and its two children,
split off because the router imports them with `import()`; a student who never opens a course never
downloads them. Everything else is in one `index` file of 122 kB, 47 kB once compressed, most of which
is Vue, the router and Pinia. The two CSS files are every component's `<style>` joined, again one for
the lazy routes. Here is the folder:

```
ana@dev:~/vue/planner$ ls -R dist
dist:
assets
courses.json
favicon.ico
index.html

dist/assets:
CourseAll-DhFoYFUW.js
CourseView-7bymtRQi.css
CourseView-CUyh3DIL.js
CourseWeek-CqqcOOPL.js
index-BPp-uHAO.js
index-iufgghmN.css
```

`courses.json` and `favicon.ico` came from `public/`, which is copied as it is: a file in `public` keeps
its name and is never processed, which is why the store can fetch `/courses.json` by that address.
Everything in `assets` has a **hash in its name**, `index-BPp-uHAO.js`, computed from its contents. A
change to the code gives the file a new name, so a server may tell browsers to keep these files for a
year, and a deploy still reaches everybody at once, through the one file whose name never changes:

```
ana@dev:~/vue/planner$ cat dist/index.html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="/favicon.ico">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-BPp-uHAO.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-iufgghmN.css">
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

That is the `index.html` of the project with the development `<script>` replaced by the built one and
the stylesheet added.

## Looking at the build

`dist` is a static folder, and any web server can send it. Vite has one for checking a build on your
own computer, `vite preview`, which `create-vue` put in the scripts:

```
ana@dev:~/vue/planner$ npm run preview

> planner@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

It listens on another port, `4173`, so it can run beside the dev server. The week page, from it:

```
ana@dev:~/vue/planner$ look http://localhost:4173/ --network --text '#app > footer'
net  GET /  200
net  GET /assets/index-iufgghmN.css  200
net  GET /assets/index-BPp-uHAO.js  200
net  GET /courses.json  200
== the text of #app > footer
Built with Vue 3.5.44
```

**Four requests where the development server needed thirty-three**: the page, the stylesheet, the
script and the data. No `[vite] connecting...` either, because a build has no HMR client in it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The same planner reaching the browser two ways. On the left, npm run dev: the browser asks for main.ts, App.vue, HomeView.vue, planner.ts, the store and the rest one by one, thirty-three requests, and the dev server converts each file when it is asked for; only the dependencies, Vue, Pinia and Vue Router, were bundled ahead of time. On the right, npm run build: Rolldown reads the sixty-one modules once and writes dist, an index.html, one script, one stylesheet and the lazy chunks of the course routes. The week page then takes four requests: the page, the script, the stylesheet and the data.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">npm run dev</text><rect x=\"110\" y=\"34\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">browser</text><rect x=\"30\" y=\"100\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">main.ts</text><rect x=\"190\" y=\"100\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">App.vue</text><rect x=\"30\" y=\"134\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">HomeView.vue</text><rect x=\"190\" y=\"134\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">planner.ts</text><rect x=\"30\" y=\"168\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">stores/planner.ts</text><rect x=\"190\" y=\"168\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">router.ts</text><rect x=\"30\" y=\"202\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">SessionRow.vue</text><rect x=\"190\" y=\"202\" width=\"140\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">deps/vue.js</text><line x1=\"180\" y1=\"66\" x2=\"180\" y2=\"96\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,96.0 176.9,88.6 183.1,88.6\" fill=\"var(--phosphor)\"></polygon><text x=\"180\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">33 requests, each file converted when asked for</text><line x1=\"360\" y1=\"20\" x2=\"360\" y2=\"255\" stroke=\"var(--scan)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></line><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">npm run build</text><rect x=\"400\" y=\"40\" width=\"110\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">src/</text><text x=\"455\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">61 modules</text><line x1=\"512\" y1=\"72\" x2=\"548\" y2=\"72\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"548.0,72.0 540.6,75.1 540.6,68.9\" fill=\"var(--amber)\"></polygon><rect x=\"550\" y=\"54\" width=\"140\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Rolldown</text><line x1=\"620\" y1=\"92\" x2=\"620\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"620.0,116.0 616.9,108.6 623.1,108.6\" fill=\"var(--amber)\"></polygon><rect x=\"520\" y=\"120\" width=\"170\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">index.html</text><rect x=\"520\" y=\"150\" width=\"170\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">assets/index-….js</text><rect x=\"520\" y=\"180\" width=\"170\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">assets/index-….css</text><rect x=\"520\" y=\"210\" width=\"170\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">assets/CourseView-….js</text><text x=\"540\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the week page: 4 requests</text></svg>", "caption": "In development nothing is bundled but the dependencies; the build bundles everything once."}
```

`vite preview` is for looking, not for serving students; it is a small server with none of the work a
real host does. Putting `dist` on a host, the free tiers and how a deploy reaches them, is
`front-delivery` lesson 1. One rule of that host matters here already: the planner uses
`createWebHistory`, so an address like `/courses/spanish` must answer with `index.html` and let the
router take it from there. `vite preview` does that:

```
ana@dev:~/vue/planner$ curl -sI http://localhost:4173/courses/spanish | head -3
HTTP/1.1 200 OK
Vary: Origin
Content-Type: text/html
```

There is no file called `courses/spanish` in `dist`, and the answer is a `200` with HTML, the
`index.html`. A host has to be told to do the same, or the address works when clicked inside the
planner and fails when typed or reloaded; that is the redirects of `front-delivery` lesson 4.
