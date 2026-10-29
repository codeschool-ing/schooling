---
title: vite.config.js
version: 1
---

**Vite works with no configuration file at all, and `vite.config.js` is where a project says what it
does differently.** Lesson 1 went through the one `create-vue` wrote: the Vue plugin and the `@` alias.
The file is a JavaScript module that runs in Node, before the server starts or the build begins, so it
may import packages, read files and compute values, and `defineConfig` only gives the editor the list
of options to suggest.

The planner's gains two lines, one for each of Vite's servers:

```javascript
// vite.config.js: how Vite serves and builds the planner.
import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  // Fail instead of quietly taking the next port (lesson 1's "Port 5173 is in use").
  server: { port: 5173, strictPort: true },
  preview: { port: 4173, strictPort: true },
})
```

Lesson 1 showed what happens when a second dev server starts while the first is still running: it
says `Port 5173 is in use, trying another one...` and takes `5174`, and the browser tab still open on
`5173` keeps talking to the first server. With `strictPort`, the second one refuses:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite

error when starting dev server:
Error: Port 5173 is already in use
    at httpServerStart (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:14661:10)
    at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
    at async startServer (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:25127:30)
    at async Object.listen (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:24933:4)
    at async CAC.<anonymous> (file:///home/ana/vue/planner/node_modules/vite/dist/node/cli.js:735:3)
```

**An error that stops you is better than a server that works on a port you are not looking at.** The
same is set for `vite preview` on its own port, `4173`. The server needs no restart for this: Vite
watches its configuration file, and a change to it restarts the server on its own.

One file beside it has outlived its job. `jsconfig.json`, from lesson 1, told the editor about the `@`
alias in a JavaScript project, and since lesson 16 `tsconfig.json` says the same in its `paths`, so
the old file can go:

```
ana@dev:~/vue/planner$ rm jsconfig.json
```

## The options worth knowing

The configuration has a few hundred options and most projects set five. These are the ones a Vue
project meets first, all in the same file:

| option | what it decides |
| --- | --- |
| `plugins` | what Vite understands beyond JavaScript, CSS and HTML: `vue()` for `.vue` files |
| `resolve.alias` | short names for folders, the `@` for `src` |
| `server.port`, `server.strictPort`, `server.host` | where the dev server listens, and whether other computers may reach it |
| `server.proxy` | addresses the dev server passes on to another server, so `/api` reaches a backend on another port |
| `base` | the path the built site lives under, `/planner/` if it is not at the root of its domain |
| `build.outDir` | where the build goes, `dist` unless you say otherwise |

`server.proxy` is the one the planner will not need and many projects do. A backend running on
`localhost:3000` and a page on `localhost:5173` are two origins, so the browser applies CORS between
them; with `proxy: { '/api': 'http://localhost:3000' }` the page asks its own server, and Vite passes
the request on. The proxy belongs to Vite's two servers, `dev` and `preview`, and to nothing else. A
build is a folder of files, and in production the same job falls to the host or to whatever sits in
front of the backend.
