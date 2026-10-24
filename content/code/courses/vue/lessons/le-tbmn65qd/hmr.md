---
title: Hot module replacement
version: 1
---

**When you save a file, the dev server tells the open page which module changed, and the page swaps
that module for the new one without reloading.** That is *hot module replacement*, HMR, and it is the
reason a change appears in the browser before your hand is off the keyboard. The `[vite] connecting...`
and `[vite] connected.` lines every `look` has printed since lesson 1 are the page opening the channel
it is told on, a WebSocket to the dev server.

What a swap keeps depends on which part of a component changed, and `look` can show it: its `run`
action runs a command while the page is open, here a `sed` that edits a file the way your editor
would. Go to next week, then change the heading in `HomeView.vue`'s template:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i "s#<h1>This week</h1>#<h1>This study week</h1>#" src/views/HomeView.vue' --do 'wait 1000' --text 'main h1' --html 'main section:nth-child(3) h2'
[vite] connecting...
[vite] connected.
-- click text=Next week
-- run sed -i "s#<h1>This week</h1>#<h1>This study week</h1>#" src/views/HomeView.vue
[vite] hot updated: /src/views/HomeView.vue
-- wait 1000
== the HTML of main section:nth-child(3) h2
<h2 data-v-0710be83="">Week of 26 October 2026</h2>
== the text of main h1
This study week
```

**The heading is the new one and the week is still the 26th.** A change to the template only replaces
the render function, and the component instance, with its `monday` ref set by the click, stays where it
was. Now the same click, and a change to the script, a comment above `monday`:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i "s#^const monday = ref#// The Monday whose week the page shows.\nconst monday = ref#" src/views/HomeView.vue' --do 'wait 1000' --text 'main h1' --html 'main section:nth-child(3) h2'
[vite] connecting...
[vite] connected.
-- click text=Next week
-- run sed -i "s#^const monday = ref#// The Monday whose week the page shows.\nconst monday = ref#" src/views/HomeView.vue
[vite] hot updated: /src/views/HomeView.vue
-- wait 1000
== the HTML of main section:nth-child(3) h2
<h2 data-v-0710be83="">Week of 19 October 2026</h2>
== the text of main h1
This study week
```

**Back to the 19th**, though the change was only a comment. A change to `<script setup>` makes the
component's setup run again, because Vite cannot know that the new setup would build the same state
as the old one, so the component is created anew, with `monday` from `weekStart(new Date())`. Only
this component starts again: the store, which lives in its own module, keeps its sessions, and so does
everything above `HomeView` in the page.

## When nothing can take the change

The last case is `planner.ts`, the plain module of dates and totals that several components import. A
comment at its top:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Next week' --do 'run sed -i "1s#^#// Dates, weeks and totals.\n#" src/planner.ts' --do 'wait 1000' --text - --html 'main section:nth-child(3) h2'
[vite] connecting...
[vite] connected.
-- click text=Next week
-- run sed -i "1s#^#// Dates, weeks and totals.\n#" src/planner.ts
[vite] connecting...
[vite] connected.
-- wait 1000
== the HTML of main section:nth-child(3) h2
<h2 data-v-0710be83="">Week of 19 October 2026</h2>
```

**A second `[vite] connecting...`: the page reloaded.** A `.vue` file *accepts* its own updates, which
means it can be swapped. A plain module that does not accept them passes the update up to every module
that imports it, and each of those does the same, until something accepts it. `HomeView` imports
`planner.ts` and would take the update, but the store imports it too, the router imports the store,
and `main.ts` imports the router, and nobody imports `main.ts`. On that path the update reaches the top
with nobody to take it, and when any path does, a full reload is all that is left. The dev server's
own terminal says which of the two happened each time:

```
ana@dev:~/vue/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 401 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
9:06:09 PM [vite] (client) hmr update /src/views/HomeView.vue
9:06:12 PM [vite] (client) hmr update /src/views/HomeView.vue
9:06:15 PM [vite] (client) page reload src/planner.ts
```

The two edits to `HomeView` were each an `hmr update`, the one to `planner.ts` a `page reload`. When a
change does not seem to appear, this log is the first place to look, and a reload of the page is the
second, because HMR is a convenience of the development server and a reload is what a student opening
the page sees.
