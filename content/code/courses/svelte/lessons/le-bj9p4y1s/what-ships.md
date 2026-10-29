---
title: What is left for the browser
version: 1
---

**`npm run build` produces what you would deploy, and its last lines say how much JavaScript the
browser downloads.** The development server compiles on demand and adds tools for hot replacement;
a build compiles everything once, splits it into files named by their content, and minifies them.
Stop the development server with Ctrl-C first, then:

```
ana@dev:~/planner$ npm run build

> planner@0.0.1 build
> vite build

vite v8.3.5 building ssr environment for production...
transforming...
✓ 136 modules transformed.
rendering chunks...
computing gzip size...
.svelte-kit/output/server/.vite/manifest.json                  2.29 kB │ gzip:  0.43 kB
.svelte-kit/output/server/entries/pages/_page.svelte.js        0.28 kB │ gzip:  0.23 kB │ map:   0.28 kB
.svelte-kit/output/server/env.js                               0.29 kB │ gzip:  0.18 kB │ map:   0.57 kB
.svelte-kit/output/server/entries/fallbacks/error.svelte.js    1.02 kB │ gzip:  0.41 kB │ map:   2.58 kB
.svelte-kit/output/server/index.js                             2.24 kB │ gzip:  0.90 kB │ map:   3.32 kB
.svelte-kit/output/server/entries/pages/_layout.svelte.js      2.58 kB │ gzip:  1.06 kB │ map:   2.67 kB
.svelte-kit/output/server/chunks/server-errors.js             23.96 kB │ gzip:  4.49 kB │ map:  34.73 kB
.svelte-kit/output/server/chunks/server.js                    42.83 kB │ gzip: 11.91 kB │ map: 125.48 kB
.svelte-kit/output/server/remote-entry.js                     54.22 kB │ gzip: 11.79 kB │ map:  89.77 kB
.svelte-kit/output/server/chunks/internal.js                  86.95 kB │ gzip: 23.79 kB │ map: 191.42 kB
.svelte-kit/output/server/chunks/instance.js                 117.43 kB │ gzip: 31.63 kB │ map: 239.38 kB

✓ built in 206ms
Analysing routes
Building app
vite v8.3.5 building client environment for production...
transforming...
✓ 173 modules transformed.
rendering chunks...
computing gzip size...
.svelte-kit/output/client/_app/version.json                          0.02 kB │ gzip:  0.04 kB
.svelte-kit/output/client/.vite/manifest.json                        3.14 kB │ gzip:  0.55 kB
.svelte-kit/output/client/_app/immutable/entry/payload.DSmR2FwN.js   0.06 kB │ gzip:  0.07 kB
.svelte-kit/output/client/_app/immutable/nodes/2.DUiUs12v.js         0.21 kB │ gzip:  0.19 kB
.svelte-kit/output/client/_app/immutable/nodes/1.CJmELmRf.js         0.32 kB │ gzip:  0.24 kB
.svelte-kit/output/client/_app/immutable/entry/start.SwYmm2vB.js     0.52 kB │ gzip:  0.31 kB
.svelte-kit/output/client/_app/immutable/entry/app.Bx4PHhS8.js       1.06 kB │ gzip:  0.53 kB
.svelte-kit/output/client/_app/immutable/chunks/Bjy-W4x2.js          1.36 kB │ gzip:  0.65 kB
.svelte-kit/output/client/_app/immutable/chunks/CRzLMJPS.js          1.53 kB │ gzip:  0.80 kB
.svelte-kit/output/client/_app/immutable/nodes/0.D6mfru_B.js         2.38 kB │ gzip:  0.97 kB
.svelte-kit/output/client/_app/immutable/chunks/BxxUQ32s.js          4.29 kB │ gzip:  1.93 kB
.svelte-kit/output/client/_app/immutable/chunks/CyvJ4pxs.js         33.19 kB │ gzip: 12.89 kB
.svelte-kit/output/client/_app/immutable/chunks/DA9qkyNS.js         39.71 kB │ gzip: 14.64 kB

✓ built in 176ms

Run npm run preview to preview your production build locally.

> Using @sveltejs/adapter-auto
Could not detect a supported production environment. See https://svelte.dev/docs/kit/adapters to learn how to configure your app to run on the platform of your choosing
✔ done
```

It builds twice, as the two `building … environment` lines say: the **ssr** environment is the code
that renders pages on the server, and the **client** environment is what browsers download. The
`gzip` column is the size that actually crosses the network, since every web server compresses
JavaScript.

The last paragraph is not an error. `adapter-auto` looks for a hosting platform it knows, finds
none on your computer, and builds nothing deployable; lesson 15 replaces it with an adapter that
produces a server you can run. Everything above that paragraph is the build, and it succeeded.

## Adding it up

The client files are what this page costs a visitor. Their gzip sizes add up to about **33 kB** for
a page with a heading and a sentence. That sounds like a lot for so little, so it is worth knowing
where it goes. **Two files are four fifths of it**, and neither is yours:

| file | gzip | what is in it |
|---|---|---|
| the larger chunk | 14.64 kB | SvelteKit's client: the router, `history`, `popstate`, preloading the next page |
| the next one | 12.89 kB | Svelte's runtime: signals, effects, and the code that hydrates the server's HTML |
| `nodes/2…js` | 0.19 kB | the planner's page |

Both large files are the same size whether the app has one page or fifty. What grows with the app
is the `nodes` folder, one file per page or layout, each a component compiled:

```
ana@dev:~/planner$ ls .svelte-kit/output/client/_app/immutable/nodes
0.D6mfru_B.js
1.CJmELmRf.js
2.DUiUs12v.js
ana@dev:~/planner$ cat .svelte-kit/output/client/_app/immutable/nodes/2.*.js
import{h as e,p as t}from"../chunks/CyvJ4pxs.js";var n=e(`<main><h1>Study planner</h1> <p>Three courses, six sessions, and one week to fit them in.</p></main>`);function r(e){var r=n();t(e,r)}export{r as component};
```

**That one line is the whole page.** It imports two helpers from the runtime chunk, `h` and `p`
after minifying, which are the `from_html` and `append` of the previous section; it holds the
markup as a template; and it exports a component that copies the template onto the page. Nothing
in it describes the page a second time, and nothing reads the markup at runtime.

That is the honest version of the claim in this lesson's first section. Svelte's runtime is small
because the compiler did the work, so a component costs roughly what its own logic costs. A
SvelteKit application still ships a router, and lesson 15 shows the one setting that ships no
JavaScript at all for a page that does not need any.

Commit what you have before the drill:

```sh
git add -A && git commit -m "Lesson 1: the planner page, Counter and compile.mjs"
```
