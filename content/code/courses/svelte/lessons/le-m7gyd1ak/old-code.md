---
title: Old code in a new project
version: 1
---

**Code copied from a tutorial, an old answer or a tool's suggestion is often older than the project it
is pasted into**, and the symptoms are worth recognising. Svelte 4 syntax in a runes project gives
the compiler errors of "A Svelte 4 component in the planner". SvelteKit 1 or 2 code in a SvelteKit 3
project fails differently, because the problem is not syntax but a module that no longer exists.

To see it without disturbing the planner, put the old code on a page of its own. A file at
`src/routes/old/+page.svelte` is a second page, at `/old`; lesson 12 is about how that works. This one
is written the way SvelteKit 2 documentation wrote it:

```html
<!-- src/routes/old/+page.svelte -->
<script>
	import { page } from '$app/stores';
	import { format } from '$lib/week.js';
</script>

<main>
	<h1>{$page.url.pathname}</h1>
	<p>{format('2026-10-19')}</p>
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/old
at /old
- heading "500" [level=1]
- paragraph: Internal Error
- text: "[plugin:vite:import-analysis] module_removed_lib `$lib` has been removed. Use `#lib` instead: https://svelte.dev/docs/kit/$lib. To keep using `$lib`, add `alias: { '$lib': 'src/lib' }` to your SvelteKit config. https://svelte.dev/e/kit/module_removed_lib +page.svelte:4:24 3 | import * as $ from 'svelte/internal/server'; 4 | import { page } from '$app/stores'; 5 | import { format } from '$lib/week.js'; | ^ 6 | 7 | function _page($$renderer, $$props) { Click outside, press Esc key, or fix the code to dismiss. You can also disable this overlay by setting"
- code: server.hmr.overlay
- text: to
- code: "false"
- text: in
- code: vite.config.js
- text: .
```

The page is SvelteKit's error page, and the development server's terminal has the reason:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:56:23 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 575 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
Internal server error: module_removed_lib
`$lib` has been removed. Use `#lib` instead: https://svelte.dev/docs/kit/$lib. To keep using `$lib`, add `alias: { '$lib': 'src/lib' }` to your SvelteKit config.
https://svelte.dev/e/kit/module_removed_lib
  Plugin: vite:import-analysis
  File: /home/ana/planner/src/routes/old/+page.svelte:4:24
  3  |  import * as $ from 'svelte/internal/server';
  4  |  import { page } from '$app/stores';
  5  |  import { format } from '$lib/week.js';
     |                          ^
  6  |  
  7  |  function _page($$renderer, $$props) {
500 GET /old
```

**`module_removed_lib` is SvelteKit 3 refusing the `$lib` alias**, before the page is even built, and
the message does two useful things: it names the replacement, `#lib`, and it says how to keep `$lib`
working in a project with a lot of old code, by declaring it as an alias in the configuration. For a
new project, change the import. That fixes this error and uncovers the next one:

```html
<!-- src/routes/old/+page.svelte -->
<script>
	import { page } from '$app/stores';
	import { format } from '#lib/week.js';
</script>

<main>
	<h1>{$page.url.pathname}</h1>
	<p>{format('2026-10-19')}</p>
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/old
at /old
- heading "500" [level=1]
- paragraph: Internal Error
```

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

7:56:30 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 536 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
SvelteKit error: app_stores_removed
`$app/stores` has been removed in favour of `$app/state`
https://svelte.dev/e/kit/app_stores_removed
    at eval (src/routes/old/+page.svelte:8:7)
    at eval (node_modules/svelte/src/internal/server/renderer.js:413:11)
    at Renderer.child (node_modules/svelte/src/internal/server/renderer.js:302:18)
    at Renderer.component (node_modules/svelte/src/internal/server/renderer.js:411:8)
    at _page (src/routes/old/+page.svelte:4:2)
500 GET /old
```

**`app_stores_removed` is a different kind of failure.** `$app/stores` still exists, so the import
succeeds; what it exports now throws as soon as the page reads it, while rendering, which is why the
terminal shows a stack trace through Svelte's server renderer this time. The fix is the other line of
the table:

```html
<!-- src/routes/old/+page.svelte -->
<script>
	import { page } from '$app/state';
	import { format } from '#lib/week.js';
</script>

<main>
	<h1>{page.url.pathname}</h1>
	<p>{format('2026-10-19')}</p>
</main>
```

```
ana@dev:~/planner$ look http://localhost:5173/old
at /old
- main:
  - heading "/old" [level=1]
  - paragraph: 19 Oct 2026
```

`$app/state` exports `page` as an object whose fields are reactive, the runes way, so it is read
directly as `page.url` rather than through a store's `$`. Delete the folder when you are done with it,
`rm -r src/routes/old`, so the planner keeps one page until lesson 12 gives it more.

## How to date a piece of code

When you find an example, a few words tell you which version it was written for, before you paste it:

- `export let`, `$:`, `on:click`, `<slot>`: Svelte 4 or earlier.
- `$app/stores`, `$lib/`, `throw error(`, `throw redirect(`: SvelteKit 2 or earlier.
- `$state`, `$props`, `onclick`, `{@render}`, `$app/state`: Svelte 5, and SvelteKit 2.12 or later.
- `#lib/`: SvelteKit 3.

**This matters most for code a tool generated.** A language model learnt Svelte from what was written
before it was trained, and most Svelte ever written is Svelte 4. Its suggestions mix the two eras in
one file, and the compiler errors of this lesson are what that mixture looks like. Read the error, find
the line in the table, and change the spelling.
