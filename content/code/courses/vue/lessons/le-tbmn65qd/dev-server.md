---
title: The development server
version: 1
---

**`npm run dev` starts a server that has converted nothing yet.** It is ready in under half a second,
and that number does not grow with the application, because the work happens later, a file at a time,
when the browser asks:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 401 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

The `Network` line means the server answers only this computer. `npm run dev -- --host` would let a
phone on the same network open the page, and it would let anybody else on that network open it as
well, which is why it is off until you ask.

## One request per module

Count the requests the week page makes:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --network --text - | grep -c '^net'
33
```

Thirty-three, and lesson 13 printed a list like it: the page, `main.ts`, every component, every
component's style, the store, the router, `planner.ts`, the composables, Vue and the data. **Each file
the browser imports is one request, and Vite converts each file when that request arrives.** Ask for
`planner.ts` the way the browser does:

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/src/planner.ts | head -24
// A date as YYYY-MM-DD, in the computer's own time zone.
export function isoDate(date) {
	const y = date.getFullYear();
	const m = String(date.getMonth() + 1).padStart(2, "0");
	const d = String(date.getDate()).padStart(2, "0");
	return `${y}-${m}-${d}`;
}
// The date n days after a YYYY-MM-DD date (before it, if n is negative).
export function addDays(iso, n) {
	const [y, m, d] = iso.split("-").map(Number);
	return isoDate(new Date(y, m - 1, d + n));
}
// The Monday of the week a date falls in, as YYYY-MM-DD.
export function weekStart(date) {
	const daysSinceMonday = (date.getDay() + 6) % 7;
	return addDays(isoDate(date), -daysSinceMonday);
}
// "19 October 2026", for people.
export function formatDay(iso) {
	const [y, m, d] = iso.split("-").map(Number);
	return new Date(y, m - 1, d).toLocaleDateString("en-GB", {
		day: "numeric",
		month: "long",
		year: "numeric"
```

The file is TypeScript on disk and JavaScript on the wire. The types from lesson 16 are gone,
`isoDate(date)` with no `: Date`, and the code has been printed again by the converter, with tabs and
double quotes, which is how you can tell it is no longer the file you wrote. **Nothing checked the
types on the way.** Vite strips them, which takes a moment per file, and leaves checking to `vue-tsc`,
which takes seconds for the project; that is why lesson 16's `type-check` script exists apart from
`dev`. A `.vue` file is converted the same way, by `@vitejs/plugin-vue`, into a JavaScript module and a
separate request per `<style>` block.

## What happens to the imports

Now the first lines of `main.ts`, as the browser receives them:

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/src/main.ts | grep '^import'
import { createApp } from "/node_modules/.vite/deps/vue.js?v=a419e1e3";
import { createPinia } from "/node_modules/.vite/deps/pinia.js?v=a419e1e3";
import App from "/src/App.vue";
import { router } from "/src/router.ts";
import "/src/main.css";
```

Two kinds of rewriting have happened. `'./router.js'` became `"/src/router.ts"`: the file was renamed
to `.ts` in lesson 16 and the import was not, and Vite found the file anyway, as TypeScript does. And
`'vue'`, a bare package name, became a path under `/node_modules/.vite/deps/`. A browser cannot load a
bare name, it has no idea where `vue` lives, so the server replaces every bare name with an address
it can serve.

## Pre-bundling the dependencies

That address points at a folder Vite filled the first time the server started:

```
ana@dev:~/vue/planner$ ls node_modules/.vite/deps
_metadata.json
dist-BZygRcNR.js
dist-BZygRcNR.js.map
package.json
pinia.js
pinia.js.map
vue-router.js
vue-router.js.map
vue.js
vue.runtime.esm-bundler-CWNVreLk.js
vue.runtime.esm-bundler-CWNVreLk.js.map
```

**Vue, Pinia and Vue Router were bundled, once, into a file each**, with a shared chunk for the code
two of them have in common. Your own files are served one by one because you edit them; a
dependency does not change between two saves, and it can be made of hundreds of internal modules, a
request each if it were served the way your files are. Some packages on npm are also written in
CommonJS, `require()` and `module.exports`, which no browser loads, and pre-bundling converts them.
The `?v=a419e1e3` at the end of each address changes when the dependencies do, so the browser may keep
these files in its cache without asking again. When you install a package, Vite notices the lockfile
changed and bundles the dependencies again on the next start.
