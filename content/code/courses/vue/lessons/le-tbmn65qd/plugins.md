---
title: A plugin of the planner's own
version: 1
---

**A Vite plugin is an object with a name and some functions, called *hooks*, that Vite calls at known
moments: when the build starts, when a file is asked for, when a file's code is about to be served.**
`@vitejs/plugin-vue` is one, and all it does to a `.vue` file happens in its hooks; Nuxt and Vitest add
much of what they do to Vite the same way, and so does Vue Router's file-based routing. The hooks are
Rollup's, the ones Rolldown kept, plus a few that only make sense in a dev server.

The planner's data has one way of being wrong that no screen reports: a session that names a course
`courses.json` does not have. The week list would show its id, the totals would count it under no
course, and nothing would fail. A plugin can refuse to start, or to build, while that is true:

```javascript
// plugins/check-planner-data.js: a Vite plugin that refuses to start, or to
// build, while courses.json has a session that names no course.
import { readFile } from 'node:fs/promises'

export function checkPlannerData() {
  return {
    name: 'check-planner-data',
    async buildStart() {
      const data = JSON.parse(await readFile('public/courses.json', 'utf8'))
      const ids = new Set(data.courses.map((course) => course.id))
      const orphans = data.sessions.filter((session) => !ids.has(session.course))
      if (orphans.length > 0) {
        const list = orphans.map((s) => `${s.id} (${s.course})`).join(', ')
        this.error(`courses.json: these sessions name a course that does not exist: ${list}`)
      }
    },
  }
}
```

`buildStart` runs once before any file is processed, in a build and when the dev server starts.
`this.error` stops whatever is running with that message and the plugin's name beside it. The
function around the object is the convention every plugin follows, `vue()` included, so that options
have somewhere to go. The configuration gets one import and one entry in `plugins`, and this is the
whole file now:

```javascript
// vite.config.js: how Vite serves and builds the planner.
import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { checkPlannerData } from './plugins/check-planner-data.js'

export default defineConfig({
  plugins: [vue(), checkPlannerData()],
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

With the data as it is, the build goes through:

```
ana@dev:~/vue/planner$ npm run build 2>&1 | tail -3
dist/assets/index-CNeZWQJG.js        122.37 kB │ gzip: 47.27 kB

✓ built in 542ms
```

## The plugin refusing

Give one session a course nobody has, `piano`, and build:

```
ana@dev:~/vue/planner$ sed -i 's/"course": "guitar"/"course": "piano"/' public/courses.json
ana@dev:~/vue/planner$ npm run build

> planner@0.0.0 build
> vue-tsc --noEmit && vite build

vite v8.3.5 building client environment for production...
✓ 0 modules transformed.
✗ Build failed in 58ms
error during build:
Build failed with 1 error:

[plugin check-planner-data]
RolldownError: courses.json: these sessions name a course that does not exist: s5 (piano)
    at error (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/logs-DyTyzzWG.mjs:164:24)
    at PluginContextImpl.error (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/bindingify-input-options-BMZwyvQ7.mjs:285:10)
    at PluginContextImpl.buildStart (file:///home/ana/vue/planner/node_modules/.vite-temp/vite.config.js.timestamp-1792800417300-5fd982b820031.mjs:15:10)
    at async plugin (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/bindingify-input-options-BMZwyvQ7.mjs:1606:3)
    at async plugin.<computed> (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/bindingify-input-options-BMZwyvQ7.mjs:2284:12)
    at aggregateBindingErrorsIntoJsError (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/error-D0SD8_tL.mjs:49:18)
    at unwrapBindingResult (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/error-D0SD8_tL.mjs:19:128)
    at #build (file:///home/ana/vue/planner/node_modules/rolldown/dist/shared/rolldown-CMhwwZPA.mjs:145:34)
    at async buildEnvironment (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:34849:66)
    at async Object.build (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:35270:19)
    at async Object.buildApp (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:35267:153)
    at async CAC.<anonymous> (file:///home/ana/vue/planner/node_modules/vite/dist/node/cli.js:790:3) {
  errors: [Getter/Setter]
}
```

**`[plugin check-planner-data]` and the message, above Rolldown's stack trace**, which says where in
Vite the error was raised and is of no use here; the one line that matters names the session and the
course. The dev server refuses in the same words:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite

error when starting dev server:
Error: courses.json: these sessions name a course that does not exist: s5 (piano)
    at PluginContext._formatLog (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8803:39)
    at PluginContext.error (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8800:14)
    at PluginContext.buildStart (file:///home/ana/vue/planner/node_modules/.vite-temp/vite.config.js.timestamp-1792800417896-caf4ea780060a.mjs:15:10)
    at async Promise.all (index 7)
    at async EnvironmentPluginContainer.hookParallel (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8437:3)
    at async file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8448:4
    at async EnvironmentPluginContainer.buildStart (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:8451:3)
    at async file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:25099:41
    at async httpServer.listen (file:///home/ana/vue/planner/node_modules/vite/dist/node/chunks/node.js:25110:5) {
  plugin: 'check-planner-data'
}
```

Put the course back, and both go through again:

```
ana@dev:~/vue/planner$ sed -i 's/"course": "piano"/"course": "guitar"/' public/courses.json
ana@dev:~/vue/planner$ npm run build 2>&1 | tail -3
dist/assets/index-CNeZWQJG.js        122.37 kB │ gzip: 47.27 kB

✓ built in 761ms
```

## What it does not catch

**`buildStart` runs when the dev server starts, not while it runs.** Break `courses.json` with the
server already up, and nothing says so until the next start or the next build. A plugin can watch a file
in the dev server too, with the `configureServer` hook, which hands it the server and its file watcher.
For a check like this one, the build is where it counts, because the build is what reaches students, and
the build always runs it. Other hooks do other jobs: `resolveId` and `load` invent a module that is not
on disk, and `transform` receives the code of every file before it is served and may change it, which is
how `plugin-vue` turns a `.vue` file into JavaScript.
