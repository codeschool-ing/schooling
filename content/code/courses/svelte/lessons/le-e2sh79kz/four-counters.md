---
title: One counter, four times
version: 1
---

**The smallest honest comparison is the same small component, built for production by each framework's
own tools, and weighed.** The component is lesson 1's counter: a button that adds thirty minutes and a
sentence that says how many there are. These four were built on the course's computer for this lesson,
each as a minimal project made with that framework's usual setup, Vite for three of them and the Angular
CLI for the fourth. They are not part of the planner, and nothing here asks you to rebuild them; the
course for each framework sets up its own project in its first lesson.

The Svelte one is lesson 1's, word for word:

```schooling-example
{"language": "html", "file": "src/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n</script>\n\n<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<p>{minutes} minutes this week</p>", "note": "State with `$state`, an event with `onclick`, and the value in the markup. The compiler turns this into the few lines of DOM code lesson 1 read."}
]}
```

React writes a component as a function that returns JSX, and keeps state with a hook:

```schooling-example
{"language": "javascript", "file": "src/Counter.jsx", "parts": [
 {"code": "import { useState } from 'react';\n"},
 {"code": "export default function Counter() {\n\tconst [minutes, setMinutes] = useState(0);\n\treturn (\n\t\t<>\n\t\t\t<button onClick={() => setMinutes(minutes + 30)}>Add 30 minutes</button>\n\t\t\t<p>{minutes} minutes this week</p>\n\t\t</>\n\t);\n}", "note": "The whole function runs again every time `minutes` changes, and React compares the result with the previous one to find what to update."}
]}
```

Vue's single-file component is the closest in shape to Svelte's:

```schooling-example
{"language": "html", "file": "src/Counter.vue", "parts": [
 {"code": "<script setup>\nimport { ref } from 'vue';\n\nconst minutes = ref(0);\n</script>\n\n<template>\n\t<button @click=\"minutes += 30\">Add 30 minutes</button>\n\t<p>{{ minutes }} minutes this week</p>\n</template>", "note": "`ref(0)` is a reactive box whose value is `minutes.value` in the script; the template unwraps it, so it writes `minutes`."}
]}
```

Angular's is a class, with the template in a decorator and the state in a signal:

```schooling-example
{"language": "typescript", "file": "src/app/app.ts", "parts": [
 {"code": "import { Component, signal } from '@angular/core';\n"},
 {"code": "@Component({\n  selector: 'app-root',\n  template: `\n    <button (click)=\"minutes.update((m) => m + 30)\">Add 30 minutes</button>\n    <p>{{ minutes() }} minutes this week</p>\n  `\n})\nexport class App {\n  protected readonly minutes = signal(0);\n}", "note": "`minutes()` reads the signal and `minutes.update(…)` changes it, which is the same idea as Svelte's `$state` with the calls written out."}
]}
```

## What each one sends

```
ana@dev:~/compare/svelte$ npm run build 2>&1 | grep -E 'dist/assets'
dist/assets/index-BZBVjdq2.js  25.43 kB │ gzip: 10.22 kB
```

```
ana@dev:~/compare/vue$ npm run build 2>&1 | grep -E 'dist/assets'
dist/assets/index-DrPfUyhY.js  62.45 kB │ gzip: 24.63 kB
```

```
ana@dev:~/compare/react$ npm run build 2>&1 | grep -E 'dist/assets'
dist/assets/index-BXCyrcOt.js  219.71 kB │ gzip: 68.68 kB
```

```
ana@dev:~/compare/angular$ npm run build 2>&1 | grep -E 'main-|Initial total'
main-ZIINQJYK.js    | main          | 96.72 kB |                29.06 kB
                    | Initial total | 96.72 kB |                29.06 kB
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A bar chart of the compressed JavaScript each framework&#x27;s production build sends for the same counter: Svelte 10.22 kB, Vue 24.63 kB, Angular 29.06 kB, React 68.68 kB. The Svelte bar is about a seventh as long as the React one.\"><text x=\"138\" y=\"45\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Svelte 5.57</text><rect x=\"150\" y=\"30\" width=\"76.65\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"234.65\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10.22 kB</text><text x=\"138\" y=\"91\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Vue 3.5</text><rect x=\"150\" y=\"76\" width=\"184.725\" height=\"30\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"342.725\" y=\"91\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">24.63 kB</text><text x=\"138\" y=\"137\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Angular 21.2</text><rect x=\"150\" y=\"122\" width=\"217.95\" height=\"30\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"375.95\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">29.06 kB</text><text x=\"138\" y=\"183\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">React 19.3</text><rect x=\"150\" y=\"168\" width=\"515.1\" height=\"30\" rx=\"2\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"673.1\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">68.68 kB</text><text x=\"360\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">gzip, one counter, a production build with each framework's usual tools</text></svg>", "caption": "Almost all of each bar is the framework's runtime, not the counter."}
```

**About 10 kB for Svelte, 25 for Vue, 29 for Angular and 69 for React**, compressed, for the same button.
Almost none of it is the counter: each number is the framework's runtime, the code that must be in the
browser before any component can run, and it is the floor every page built with that framework stands
on. Svelte's floor is lowest because the compiler did at build time much of what the others do in the
browser, which is the claim lesson 1 made and lesson 2 explained.

**What these numbers do not say** matters as much. They do not grow at the same rate: a large
application's own code soon outweighs any of these runtimes, and Svelte's compiled components are
somewhat larger than the templates they replace, so the gap narrows as an application grows. They are
client-only builds, without the application frameworks; SvelteKit's router adds to Svelte's figure, as
lesson 1 measured, and Next.js and Nuxt add to theirs. And they say nothing about how fast each one
updates the page, which for an application like the planner is quick in all four. Angular was built with
version 21, because Angular 22 asks for a newer Node 22 than the one this catalogue installs.
