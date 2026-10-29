---
title: Why not a module, on the server
version: 1
---

**A value exported from a module exists once per process, and on the server one process answers every
visitor.** In the browser that is fine: the browser holds one page for one person, so a module-level
value is that person's. During server rendering, every request runs the same imported module, and a
value one request changes is the value the next request finds. That is the reason context exists
alongside modules, and the reason the planner sets its instance in context instead of exporting it.

Here is the mistake in its smallest form. A module holds a visitor's name, and a page sets it from the
address and greets whoever it holds. Save the module as `src/lib/visitor.svelte.js`:

```javascript
// visitor.svelte.js: one visitor's name, in a module. This is the mistake.
export const visitor = $state({ name: null });
```

and the page as `src/routes/hello/+page.svelte`:

```html
<!-- src/routes/hello/+page.svelte -->
<script>
	import { page } from '$app/state';
	import { visitor } from '#lib/visitor.svelte.js';

	const name = page.url.searchParams.get('name');
	if (name) visitor.name = name;
</script>

<main>
	<p>Hello, {visitor.name ?? 'stranger'}.</p>
</main>
```

`page` from `$app/state` is the current page, and `page.url.searchParams` reads `?name=…` from the
address. Now be two people. Ana opens the page with her name; a moment later somebody else opens it
with none:

```
ana@dev:~/planner$ curl -s 'http://localhost:5173/hello?name=Ana' | grep -o 'Hello[^<]*'
Hello, Ana.
ana@dev:~/planner$ curl -s http://localhost:5173/hello | grep -o 'Hello[^<]*'
Hello, Ana.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"One server process answering two visitors. On the left, with a module: both requests import the same module, which holds one visitor object; Ana&#x27;s request sets its name, and the stranger&#x27;s request, a moment later, reads the same object and is greeted as Ana. On the right, with context: each request creates its own page component, and each component sets its own visitor in context, so each greeting reads its own.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">a module: one for every request</text><rect x=\"20\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">?name=Ana</text><rect x=\"190\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"265\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no name</text><rect x=\"80\" y=\"130\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">visitor.svelte.js</text><text x=\"180\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">{ name: 'Ana' }</text><line x1=\"95\" y1=\"80\" x2=\"150\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"150.0,128.0 142.4,125.5 146.5,120.8\" fill=\"var(--paper-dim)\"></polygon><line x1=\"265\" y1=\"80\" x2=\"210\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"210.0,128.0 213.5,120.8 217.6,125.5\" fill=\"var(--paper-dim)\"></polygon><text x=\"95\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hello, Ana.</text><text x=\"265\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Hello, Ana.</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">context: one per request</text><rect x=\"380\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">?name=Ana</text><rect x=\"550\" y=\"40\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no name</text><rect x=\"380\" y=\"130\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">its own context</text><text x=\"455\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">{ name: 'Ana' }</text><line x1=\"455\" y1=\"80\" x2=\"455\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"455.0,128.0 451.9,120.6 458.1,120.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"455\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hello, Ana.</text><rect x=\"550\" y=\"130\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"625\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">its own context</text><text x=\"625\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">{ name: null }</text><line x1=\"625\" y1=\"80\" x2=\"625\" y2=\"128\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"625.0,128.0 621.9,120.6 628.1,120.6\" fill=\"var(--paper-dim)\"></polygon><text x=\"625\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Hello, stranger.</text><text x=\"360\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same code, the same server: only where the value lives differs</text></svg>", "caption": "A module-level value is shared by every request the server answers. A context belongs to one."}
```

**The second visitor was greeted as Ana.** The first request set `visitor.name` in the server's one copy
of the module, and the second request, from somebody else entirely, rendered with it. Replace a name
with a student's sessions, or anything private, and this is a data leak between strangers, produced by
code that worked perfectly while one person tested it in one browser.

## The same page, with context

Context is created per component instance, and on the server every request creates its own component
instances, so a value in context belongs to one request. The fix keeps the module but makes it export
a pair of functions instead of an instance:

```javascript
// visitor.svelte.js: one visitor's name, in context, so one per request.
import { createContext } from 'svelte';

export const [getVisitor, setVisitor] = createContext();
```

```html
<!-- src/routes/hello/+page.svelte -->
<script>
	import { page } from '$app/state';
	import { setVisitor } from '#lib/visitor.svelte.js';

	const visitor = $state({ name: page.url.searchParams.get('name') });
	setVisitor(visitor);
</script>

<main>
	<p>Hello, {visitor.name ?? 'stranger'}.</p>
</main>
```

```
ana@dev:~/planner$ curl -s 'http://localhost:5173/hello?name=Ana' | grep -o 'Hello[^<]*'
Hello, Ana.
ana@dev:~/planner$ curl -s http://localhost:5173/hello | grep -o 'Hello[^<]*'
Hello, stranger.
```

Each request made its own visitor, and the stranger is a stranger. Delete the experiment,
`rm -r src/routes/hello src/lib/visitor.svelte.js`.

**The rule that follows is short: on a page that renders on the server, nothing that belongs to one
person goes in a module-level variable.** Modules are for things that are the same for everybody: a
function, a constant, a store that reads the time. State that belongs to one visitor is created in a
component, and shared with context.
