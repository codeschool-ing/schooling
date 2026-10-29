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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Where an edit to planner.ts goes. planner.ts accepts no updates of its own, so the update passes up to every module that imports it. HomeView.vue imports it, and a vue file accepts its own updates, so it would take the update. But the store imports it too, the router imports the store, and main.ts imports the router; nobody imports main.ts. On that path the update reaches the top with nobody to take it, and the page reloads: the dev server logs page reload src/planner.ts.\"><rect x=\"20\" y=\"100\" width=\"130\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"85\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">planner.ts</text><text x=\"85\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">edited</text><rect x=\"210\" y=\"30\" width=\"160\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">HomeView.vue</text><text x=\"290\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">accepts: would take it</text><rect x=\"210\" y=\"170\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the store</text><rect x=\"390\" y=\"170\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the router</text><rect x=\"560\" y=\"170\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">main.ts</text><line x1=\"152\" y1=\"110\" x2=\"206\" y2=\"62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"206.0,62.0 202.6,69.2 198.4,64.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"152\" y1=\"134\" x2=\"206\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"206.0,180.0 198.4,177.6 202.4,172.9\" fill=\"var(--wire)\"></polygon><line x1=\"352\" y1=\"190\" x2=\"386\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"386.0,190.0 378.6,193.1 378.6,186.9\" fill=\"var(--wire)\"></polygon><line x1=\"532\" y1=\"190\" x2=\"556\" y2=\"190\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"556.0,190.0 548.6,193.1 548.6,186.9\" fill=\"var(--wire)\"></polygon><text x=\"178\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">imported by</text><line x1=\"630\" y1=\"168\" x2=\"630\" y2=\"106\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"630.0,106.0 633.1,113.4 626.9,113.4\" fill=\"var(--amber)\"></polygon><text x=\"622\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nobody imports it</text><rect x=\"540\" y=\"50\" width=\"160\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">page reload</text><text x=\"620\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the whole page again</text></svg>", "caption": "An update climbs the importers until something accepts it; a path that reaches main.ts reloads the page."}
```

The two edits to `HomeView` were each an `hmr update`, the one to `planner.ts` a `page reload`. When a
change does not seem to appear, this log is the first place to look, and a reload of the page is the
second, because HMR is a convenience of the development server and a reload is what a student opening
the page sees.
