---
title: What the compiler writes
version: 1
---

**A component is a description, and the compiler turns it into two programs**: one that builds the
HTML on the server, as a string, and one that makes that HTML live in the browser. The fastest way
to believe it is to run the compiler yourself, on one small component, and read both.

Here is the component. It is not part of the planner; it is the smallest thing that has state, an
event and text that depends on the state. Save it in the project as `src/lib/Counter.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/Counter.svelte", "parts": [
 {"code": "<script>\n\tlet minutes = $state(0);\n</script>", "note": "The script runs once, when the component is created. `$state(0)` marks `minutes` as a value the page depends on."},
 {"code": "<button onclick={() => (minutes += 30)}>Add 30 minutes</button>\n<p>{minutes} minutes this week</p>", "note": "Markup is HTML with expressions in braces. `onclick` is an ordinary attribute whose value is a function."}
]}
```

The compiler is a function, `compile`, exported by the `svelte` package the project already has.
This script, saved as `compile.mjs` at the top of the project, reads a component, compiles it and
prints the JavaScript it produced:

```javascript
// compile.mjs: compile one component and print the JavaScript it becomes.
//   node compile.mjs FILE.svelte [client|server]
import { compile } from "svelte/compiler";
import fs from "node:fs";

const [file, generate = "client"] = process.argv.slice(2);
const { js } = compile(fs.readFileSync(file, "utf8"), { filename: file, generate });
console.log(js.code);
```

## The browser's half

```
ana@dev:~/planner$ node compile.mjs src/lib/Counter.svelte
import 'svelte/internal/disclose-version';
import * as $ from 'svelte/internal/client';

var root = $.from_html(`<button>Add 30 minutes</button> <p> </p>`, 1);

export default function Counter($$anchor) {
	let minutes = $.state(0);
	var fragment = root();
	var button = $.first_child(fragment);
	var p = $.sibling(button, 2);
	var text = $.only_child(p);

	$.template_effect(() => $.set_text(text, `${$.get(minutes) ?? ''} minutes this week`));
	$.delegated('click', button, () => $.set(minutes, $.get(minutes) + 30));
	$.append($$anchor, fragment);
}

$.delegate(['click']);
```

Read it from the top, because each line is something the browser does not have to work out:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One file, Counter.svelte, goes into the compiler and comes out as two programs. The client program has the markup as a template, minutes as a signal read with get and written with set, one effect that sets the text of the paragraph, and one delegated click listener. The server program has minutes as a plain variable and pushes one string of HTML with the value escaped. What neither has is a description of the page kept to compare with the next one.\"><rect x=\"20\" y=\"110\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"135\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Counter.svelte</text><text x=\"95\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what you write</text><line x1=\"170\" y1=\"145\" x2=\"218\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"218.0,145.0 210.6,148.1 210.6,141.9\" fill=\"var(--paper-dim)\"></polygon><rect x=\"220\" y=\"115\" width=\"110\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">compile()</text><text x=\"275\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">on your computer</text><path d=\"M330 135 C 360 135, 360 70, 390 70\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"388\" y1=\"70\" x2=\"396\" y2=\"70\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"396.0,70.0 388.6,73.1 388.6,66.9\" fill=\"var(--phosphor)\"></polygon><path d=\"M330 155 C 360 155, 360 225, 390 225\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"388\" y1=\"225\" x2=\"396\" y2=\"225\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"396.0,225.0 388.6,228.1 388.6,221.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"398\" y=\"18\" width=\"302\" height=\"118\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">client: runs in the browser</text><text x=\"410\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$.from_html(`&lt;button&gt;…`)</text><text x=\"410\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">let minutes = $.state(0)</text><text x=\"410\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$.template_effect(() =&gt; $.set_text(…))</text><text x=\"410\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$.delegated('click', button, …)</text><rect x=\"398\" y=\"168\" width=\"302\" height=\"92\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">server: builds the HTML once</text><text x=\"410\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">let minutes = 0</text><text x=\"410\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">$$renderer.push(`&lt;button&gt;…</text><text x=\"410\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">  ${$.escape(minutes)}…`)</text><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">neither keeps a copy of the page to compare with the next one</text></svg>", "caption": "One component, two programs: a live one for the browser and a string builder for the server."}
```

- **The markup became a template string**, `root`, parsed once into DOM nodes and copied every
  time a `Counter` is made. The `<p>` holds a single space where the text will go.
- **`minutes` became `$.state(0)`**, and every read of it became `$.get(minutes)` and every write
  `$.set(minutes, …)`. That is the whole trick of `$state`: the compiler rewrote your variable into
  a signal, a value that knows who reads it. Lesson 2 is about what that buys.
- **One `template_effect` sets one text node.** It is the only code that runs when `minutes`
  changes, and it changes exactly the text inside the `<p>`. Nothing else on the page is looked at.
- **`onclick` became `$.delegated('click', …)`**, one listener on the document root handling
  clicks for every button that asked for one. Lesson 7 comes back to it.

What is missing is the point. There is no description of the page kept in memory to compare with
the next one, and nothing walks the markup at runtime to find out what changed. The compiler worked
that out once, from the source, and wrote down the answer.

## The server's half

```
ana@dev:~/planner$ node compile.mjs src/lib/Counter.svelte server
import * as $ from 'svelte/internal/server';

export default function Counter($$renderer) {
	let minutes = 0;

	$$renderer.push(`<button>Add 30 minutes</button> <p>${$.escape(minutes)} minutes this week</p>`);
}
```

**On the server, `$state` disappears completely.** `minutes` is an ordinary `let`, because a page
rendered on the server is a string sent once and never updated there; there is nothing to
react to. The component is a function that pushes HTML into `$$renderer`, with `$.escape` around
the value so that text which looks like markup cannot become markup. When the browser receives that
HTML, the client half finds the nodes already on the page instead of creating them, and attaches
itself to them. That step is called **hydration**, and lesson 15 opens it up.

You will not run `compile.mjs` again in this course; Vite calls the same function every time you
save a file. Keep it, though. When a component behaves in a way you cannot explain, compiling it and
reading what came out is a legitimate way to find out why.
