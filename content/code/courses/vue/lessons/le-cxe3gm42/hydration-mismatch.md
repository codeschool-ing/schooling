---
title: When the server and the browser disagree
version: 1
---

**Hydration assumes that the browser, running the same components with the same data, draws exactly
what the server drew.** Vue walks the server's elements and the ones it would have made side by side,
and attaches itself; it does not draw the page again. When the two differ, that is a *hydration
mismatch*, and the planner has one waiting in its week page:

```typescript
const today = isoDate(new Date())
```

That line runs twice, once on the server and once in the browser, and each reads its own clock in its
own time zone. Most hosts run their servers in UTC, and the planner's reader is in São Paulo, three
hours behind it. For 21 hours of the day the two dates agree. **At half past eleven at night in São
Paulo, it is half past two the next morning in UTC.** The transcripts below are recorded at that moment,
with the server given the zone UTC, as a host would give it; on your own computer the server and the
browser share a zone, and you would need a server elsewhere to see this. The dev server first:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text 'main section:nth-child(3) ul'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
[warn] [Vue warn]: Hydration node mismatch:
- rendered on server: JSHandle@node  
- expected on client: strong 
  at <SessionRow key="s4" session= {id: s4, course: statistics, date: 2026-10-21, minutes: 60, done: false} title="Statistics"  ... > 
  at <PlannerPanel title="Week of 19 October 2026" > 
  at <Index onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouteProvider key="/" vnode= {__v_isVNode: true, __v_skip: true, type: Object, props: Object, key: null} route= {fullPath: /, hash: , query: Object, name: index, path: /}  ... > 
  at <RouterView name=undefined route=undefined > 
  at <NuxtPage> 
  at <Default ref=Ref< undefined > > 
  at <AsyncComponentWrapper ref=Ref< undefined > > 
  at <LayoutLoader key="default" layoutProps= {ref: RefImpl} name="default" > 
  at <NuxtLayoutProvider layoutProps= {ref: RefImpl} key="default" name="default"  ... > 
  at <NuxtLayout> 
  at <App key=4 > 
  at <NuxtRoot>
[error] Hydration completed but contains mismatches.
[warn] [Vue warn]: Hydration class mismatch on JSHandle@node 
  - rendered on server: class=""
  - expected on client: class="today"
  Note: this mismatch is check-only. The DOM will not be rectified in production due to performance overhead.
  You should fix the source of the mismatch. 
  at <SessionRow key="s4" session= {id: s4, course: statistics, date: 2026-10-21, minutes: 60, done: false} title="Statistics"  ... > 
  at <PlannerPanel title="Week of 19 October 2026" > 
  at <Index onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouteProvider key="/" vnode= {__v_isVNode: true, __v_skip: true, type: Object, props: Object, key: null} route= {fullPath: /, hash: , query: Object, name: index, path: /}  ... > 
  at <RouterView name=undefined route=undefined > 
  at <NuxtPage> 
  at <Default ref=Ref< undefined > > 
  at <AsyncComponentWrapper ref=Ref< undefined > > 
  at <LayoutLoader key="default" layoutProps= {ref: RefImpl} name="default" > 
  at <NuxtLayoutProvider layoutProps= {ref: RefImpl} key="default" name="default"  ... > 
  at <NuxtLayout> 
  at <App key=4 > 
  at <NuxtRoot>
[warn] [Vue warn]: Hydration node mismatch:
- rendered on server: JSHandle@node  
- expected on client: Symbol(v-cmt) 
  at <SessionRow key="s5" session= {id: s5, course: guitar, date: 2026-10-22, minutes: 20, done: false} title="Guitar"  ... > 
  at <PlannerPanel title="Week of 19 October 2026" > 
  at <Index onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouteProvider key="/" vnode= {__v_isVNode: true, __v_skip: true, type: Object, props: Object, key: null} route= {fullPath: /, hash: , query: Object, name: index, path: /}  ... > 
  at <RouterView name=undefined route=undefined > 
  at <NuxtPage> 
  at <Default ref=Ref< undefined > > 
  at <AsyncComponentWrapper ref=Ref< undefined > > 
  at <LayoutLoader key="default" layoutProps= {ref: RefImpl} name="default" > 
  at <NuxtLayoutProvider layoutProps= {ref: RefImpl} key="default" name="default"  ... > 
  at <NuxtLayout> 
  at <App key=4 > 
  at <NuxtRoot>
[warn] [Vue warn]: Hydration class mismatch on JSHandle@node 
  - rendered on server: class="today"
  - expected on client: class=""
  Note: this mismatch is check-only. The DOM will not be rectified in production due to performance overhead.
  You should fix the source of the mismatch. 
  at <SessionRow key="s5" session= {id: s5, course: guitar, date: 2026-10-22, minutes: 20, done: false} title="Guitar"  ... > 
  at <PlannerPanel title="Week of 19 October 2026" > 
  at <Index onVnodeUnmounted=fn<onVnodeUnmounted> onVnodeMounted=fn<onVnodeSettled> onVnodeUpdated=fn<onVnodeSettled>  ... > 
  at <RouteProvider key="/" vnode= {__v_isVNode: true, __v_skip: true, type: Object, props: Object, key: null} route= {fullPath: /, hash: , query: Object, name: index, path: /}  ... > 
  at <RouterView name=undefined route=undefined > 
  at <NuxtPage> 
  at <Default ref=Ref< undefined > > 
  at <AsyncComponentWrapper ref=Ref< undefined > > 
  at <LayoutLoader key="default" layoutProps= {ref: RefImpl} name="default" > 
  at <NuxtLayoutProvider layoutProps= {ref: RefImpl} key="default" name="default"  ... > 
  at <NuxtLayout> 
  at <App key=4 > 
  at <NuxtRoot>
== the text of main section:nth-child(3) ul
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

**Four warnings and an error, and the warnings say it all.** The server drew the 22nd as today, with a
`class="today"` on the guitar row and no `(today)` on the 21st; the browser, in São Paulo, expected
the opposite. In development Vue fixes what it can, so the list at the end looks right. The note in the
middle is the part to believe: *the DOM will not be rectified in production*. The built server, in
UTC, at the same moment:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text 'li.today'
[error] Hydration completed but contains mismatches.
== the text of li.today
 22 October 2026, Guitar, 20 minutes
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text 'li:has(strong)'
[error] Hydration completed but contains mismatches.
== the text of li:has(strong)
 21 October 2026, Statistics, 60 minutes (today)
```

**One row is highlighted as today, and another row says `(today)`.** In production Vue only reports that
a mismatch happened, with one line and no detail, and repairs only what it must. A missing element is
made, so the browser's `(today)` appeared on the 21st, and an attribute is left alone, so the server's
highlight stayed on the 22nd. Nothing else is wrong on the page, and nobody would report it as an error;
a student would just see two todays, three hours every evening, and stop trusting the planner.

## Where mismatches come from

The rule is simple to state: **anything a component reads that is not the same on the server and in
the browser** is a mismatch waiting for the day it differs. The usual ones:

- the clock and the time zone, as here, and anything formatted from them;
- `Math.random()` and ids made by a counter, where `useId()`, lesson 14's, gives the same id on both;
- `window`, `localStorage`, the window's width, which do not exist on the server at all;
- the reader's language and their settings, unless the server is told them in the request.

The fix is always the same in kind: decide such a value in one place only. Either the server decides
it and the browser receives it, which is what `useFetch` does for the data, or the browser decides it
after hydration, and the server draws the page without it. For the reader's day only the second is
right, because only the browser knows where the reader is. The section on client-only rendering does
it, after two more ways of making pages, each of which turns out to have the same line in its way.
