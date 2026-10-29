---
title: Three blocks in one file
version: 1
---

**A `.vue` file is one component, written in three blocks: the markup in `<template>`, the logic in
`<script setup>` and the look in `<style>`.** That is a single-file component, or SFC, and it is how
almost every Vue project is written. The browser has never heard of the format. Something has to turn
it into JavaScript first, and in this project that something is the Vue plugin inside Vite.

The common wrong picture is that the template is HTML which Vue fills in afterwards, like a page with
holes in it. It is not. **The template is compiled into a JavaScript function** before the browser
sees it, and the browser runs that function to build the page.

## The file create-vue wrote

```html
<script setup></script>

<template>
  <h1>You did it!</h1>
  <p>
    Visit <a href="https://vuejs.org/" target="_blank" rel="noopener">vuejs.org</a> to read the
    documentation
  </p>
</template>

<style scoped></style>
```

Each block has one job:

| block | what goes in it | how many |
|---|---|---|
| `<template>` | the markup, with Vue's syntax for values and conditions | at most one |
| `<script setup>` | the component's state and functions, run once for each copy of the component | at most one, plus an ordinary `<script>` if you need one |
| `<style>` | CSS; `scoped` limits it to this component | as many as you like |

The order is yours to choose. **Script first, then template, then style** is what create-vue writes
and what the Vue documentation recommends, because the template reads values the script declares,
and reading the declarations first is reading the file top to bottom.

## What the browser receives

With the dev server running, ask it for the file the way the browser does, and keep the function the
template became:

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/src/App.vue | grep -A 16 '^function _sfc_render'
function _sfc_render(_ctx, _cache) {
  return (_openBlock(), _createElementBlock(_Fragment, null, [
    _cache[0] || (_cache[0] = _createElementVNode("h1", null, "You did it!", -1 /* CACHED */)),
    _cache[1] || (_cache[1] = _createElementVNode("p", null, [
      _createTextVNode(" Visit "),
      _createElementVNode("a", {
        href: "https://vuejs.org/",
        target: "_blank",
        rel: "noopener"
      }, "vuejs.org"),
      _createTextVNode(" to read the documentation ")
    ], -1 /* CACHED */))
  ], 64 /* STABLE_FRAGMENT */))
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The journey of App.vue. On your machine, the Vue plugin inside Vite compiles the file into a JavaScript module whose template has become a render function. In the browser, running that function produces virtual nodes, plain objects that describe elements, and Vue&#x27;s runtime builds the real DOM elements from them.\"><rect x=\"10\" y=\"10\" width=\"330\" height=\"210\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">your machine: the dev server</text><rect x=\"380\" y=\"10\" width=\"330\" height=\"210\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"390\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the browser</text><rect x=\"30\" y=\"50\" width=\"120\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">App.vue</text><rect x=\"40\" y=\"84\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;script setup&gt;</text><rect x=\"40\" y=\"120\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;template&gt;</text><rect x=\"40\" y=\"156\" width=\"100\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;style scoped&gt;</text><line x1=\"152\" y1=\"125\" x2=\"192\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"192.0,125.0 184.6,128.1 184.6,121.9\" fill=\"var(--amber)\"></polygon><text x=\"172\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">compiles</text><rect x=\"196\" y=\"50\" width=\"128\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a JS module</text><text x=\"260\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">_sfc_main</text><text x=\"260\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">_sfc_render()</text><text x=\"260\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">p[data-v-…]</text><line x1=\"326\" y1=\"125\" x2=\"396\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"396.0,125.0 388.6,128.1 388.6,121.9\" fill=\"var(--amber)\"></polygon><text x=\"361\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">HTTP</text><rect x=\"400\" y=\"50\" width=\"140\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">virtual nodes</text><text x=\"470\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">{ type: \"h1\" }</text><text x=\"470\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">{ type: \"p\" }</text><text x=\"470\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">{ type: \"a\" }</text><line x1=\"542\" y1=\"125\" x2=\"572\" y2=\"125\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"572.0,125.0 564.6,128.1 564.6,121.9\" fill=\"var(--amber)\"></polygon><rect x=\"576\" y=\"50\" width=\"124\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"638\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the DOM</text><text x=\"638\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;h1&gt;</text><text x=\"638\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;p&gt;</text><text x=\"638\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&lt;a&gt;</text></svg>", "caption": "The template never reaches the browser as markup. It arrives as a function, and the page is built by running it."}
```

Three things in there are worth seeing once:

- **The markup is calls**, `_createElementVNode("h1", null, "You did it!")` and its neighbours. Each
  call describes one element as a plain object, a *virtual node*, and Vue builds the real elements from
  those descriptions.
- **`_cache[0] ||`** means the compiler noticed that nothing in this heading can ever change, so the
  node is made once and reused. The `-1 /* CACHED */` beside it says the same thing to the runtime. A
  template is a language the compiler can read, which is how it can find that out; lesson 2 explains
  what Vue does with the parts that *can* change.
- **The functions come from Vue**, imported at the top of the module, from an address the next
  command shows.

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/src/App.vue | grep -o 'from "/node_modules/[^"]*"'
from "/node_modules/.vite/deps/vue.js?v=ef542bd1"
```

In development Vite serves Vue as one ready-made module under `/node_modules/.vite/deps/`, and serves
your own files one by one as the browser asks for them.

`src/main.js`, the file `index.html` loads, is three lines:

```javascript
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
```

`createApp(App)` makes an application whose top component is `App`, and `.mount('#app')` hands it
the `<div id="app">` in `index.html`. Everything the application draws goes inside that one element,
which is why `look` prints the text of `#app` unless told otherwise.

## Why one file

React puts markup inside JavaScript, and Angular keeps a component's template and styles in separate
files beside its class. Vue's choice keeps the three together and keeps each one in its own language:
the template looks like HTML, the style is CSS, and the script is JavaScript. A designer can read the
template, and a CSS rule sits next to the markup it styles.

**The cost is a build step.** A `.vue` file cannot be opened by a browser as it is, so there is always a
compiler between you and the page. "A page at a time", three sections on, shows the one way to use Vue
without one, and why projects rarely do.
