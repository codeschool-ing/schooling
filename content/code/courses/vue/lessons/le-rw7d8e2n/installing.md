---
title: Installing Vitest, and a first run
version: 1
---

**Vitest is a test runner built on Vite: it reads the same `vite.config.js`, uses the same plugins,
and so runs a `.vue` file in a test exactly as the dev server serves it.** That is why it is the one
this lesson uses, and why there is almost nothing to configure. Two more packages go with it:
**Vue Test Utils**, Vue's own library for mounting a component in a test and acting on it, and
**jsdom**, a browser's document written in JavaScript, so that a component has elements to draw into
without a browser. The tests are for the Vite planner, `~/vue/planner`, whose rules lesson 3 wrote
for exactly this. Stop its dev server if it is running, and install the three, pinned and for
development only:

```
ana@dev:~/vue/planner$ npm install --save-dev --save-exact vitest@5.0.5 @vue/test-utils@2.5.1 jsdom@30.1.3

added 71 packages, and audited 163 packages in 3s

39 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

jsdom 30 asks for Node 22.22.2 or later, which lesson 18's update already provides. The configuration
gets one line, `test`, which only Vitest reads, and a reference at the top that tells TypeScript the
option exists:

```javascript
// vite.config.js: how Vite serves, builds and tests the planner.
/// <reference types="vitest/config" />
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
  // Tests run in jsdom, a document without a browser, so components have somewhere to draw.
  test: { environment: 'jsdom' },
})
```

And a script, so that `npm test` runs it:

```
ana@dev:~/vue/planner$ npm pkg set scripts.test='vitest'
```

```
ana@dev:~/vue/planner$ npx vitest run

 RUN  v5.0.5 /home/ana/vue/planner

No test files found, exiting with code 1

include: **/*.{test,spec}.?(c|m)[jt]s?(x)
exclude:  **/node_modules/**, **/.git/**

```

**No test files, and exit code 1**: Vitest looked for files whose names end in `.test.ts` or
`.spec.ts`, among others, found none, and counts that as a failure, so a CI job pointed at the wrong
folder cannot pass by testing nothing. `vitest run` runs once and stops; `vitest` on its own, which
`npm test` runs, stays open and runs again whenever a file changes, which is how it is used while
working. The test files go beside the files they test, `planner.test.ts` next to `planner.ts`.
