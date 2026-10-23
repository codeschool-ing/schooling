---
title: A router, installed
version: 1
---

**A router maps the address in the browser's bar to the components on the screen, and changes the
screen when the address changes, without loading a new page.** The planner has had one screen so far.
From this lesson it has three kinds of page: the week, a course, and a page for an address that leads
nowhere. Each has its own address, so it can be bookmarked, shared, and reached with the browser's back
button, which is what makes an application feel like the web rather than like a program that happens
to be in a browser.

Vue's router is **Vue Router**, from the Vue team. Version 5 is the current one; its API for writing
routes by hand, which this lesson uses, is the API of version 4, and most of what you read online about
version 4 applies unchanged. What version 5 added is routing by file, where the folder structure of
`src/pages` writes the routes for you; Nuxt does that too, and lesson 18 meets the idea there.

Stop the planner's dev server, and install the router, pinned like everything else:

```
ana@dev:~/vue/planner$ npm install --save-exact vue-router@5.4.0

added 44 packages, and audited 81 packages in 6s

23 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

`package.json` gains `"vue-router": "5.4.0"` under `dependencies`, with no caret, and the lockfile
records it. Start the dev server again.

## Giving the application a router

A router is a plugin: an object the application installs once, with `app.use()`, which makes it
available to every component. `main.js` gains two lines:

```javascript
// src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import { router } from './router.js'
import './main.css'

createApp(App).use(router).mount('#app')
```

`app.use(router)` does three things. It registers the two components every routed application uses,
`<RouterView>` and `<RouterLink>`; it provides the router to every component, through lesson 8's
`provide`, so that `useRouter()` and `useRoute()` can find it; and it starts listening to the address
bar, so that the first screen drawn is the one the address names.

The router itself is defined in `src/router.js`, the next section's subject. The order matters only in
one way: `createRouter` must have run before `app.use(router)`, which an import at the top of `main.js`
guarantees.

## What changes for the student

The student who opens `http://localhost:5173/` sees what they saw before. What is new is invisible
until they click: the course titles become links, a course has its own page at
`/courses/statistics`, the back button returns to the week, and a mistyped address says so instead of
showing the week as if nothing were wrong. Every one of those is a section of this lesson.
