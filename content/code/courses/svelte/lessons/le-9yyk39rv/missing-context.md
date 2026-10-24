---
title: When nothing above has set it
version: 1
---

**`getPlanner()` throws when no component above has called `setPlanner()`.** That is a feature of
`createContext`, and an improvement on the older `getContext(key)`, which quietly returned `undefined`
and let the component fail later, somewhere less helpful. To see it, use `Days` where there is no
planner: on a page of its own, `src/routes/days/+page.svelte`, with nothing around it:

```html
<!-- src/routes/days/+page.svelte -->
<script>
	import Days from '#lib/Days.svelte';
</script>

<main>
	<Days />
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/days
at /days
- heading "500" [level=1]
- paragraph: Internal Error
```

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

8:53:23 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 680 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
Svelte error: missing_context
Context was not set in the current component or any of its ancestors
https://svelte.dev/e/missing_context
    at eval (src/lib/Days.svelte:5:18)
    at eval (node_modules/svelte/src/internal/server/renderer.js:413:11)
    at Renderer.child (node_modules/svelte/src/internal/server/renderer.js:302:18)
    at Renderer.component (node_modules/svelte/src/internal/server/renderer.js:411:8)
    at Days (src/lib/Days.svelte:3:2)
    at eval (src/routes/days/+page.svelte:2:1)
500 GET /days
```

**`missing_context` says what is wrong in its first line**, and the stack under it says which
component asked: `Days.svelte`, called from the page. The fix is never in `Days`; it is to render it
inside something that set the context, which is the whole contract. Delete the folder,
`rm -r src/routes/days`, when you have seen it.

## When a context is optional

Sometimes a component works with or without its context: a list that highlights the selected course
when there is a planner around it, and shows plain rows when there is not. `createContext` returns a
third function for that, which says whether the context was set:

```javascript
export const [getPlanner, setPlanner, hasPlanner] = createContext();
```

and the component asks before it gets: `const planner = hasPlanner() ? getPlanner() : null;`. The
planner's components all require one, so they get it unconditionally and let the error speak.

## Only while the component is being created

**Context is read and written during a component's creation, at the top level of its script**, and
nowhere else. Calling `getPlanner()` inside an event handler, a `setTimeout` or an effect that runs
later fails, because by then Svelte no longer knows which component is asking. The planner's
components call it once, at the top, and keep the result in a constant, which is the pattern to copy:
get it early, use it whenever.
