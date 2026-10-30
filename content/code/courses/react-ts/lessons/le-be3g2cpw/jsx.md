---
title: JSX is a function call
version: 1
---

**JSX looks like HTML inside JavaScript, and it is neither.** It is a shorter way to write calls to
a function that builds a description of an element. The browser never sees it: Vite turns every
`<tag>` into a call before the file is sent. Holding that picture explains every rule JSX has, so
this section starts with the call and comes back to the rules.

Here is the planner's first component. It receives a Monday and that week's sessions, and draws the
two lines at the top of the screen. Save it as `src/WeekSummary.tsx`:

```tsx
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const done = sessions.filter((s) => s.done)
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>
        {minutes(done)} of {minutes(sessions)} minutes done
      </p>
    </section>
  )
}
```

## What the browser receives

The development server answers for any file under `src/`, translated the way the browser will get
it. Ask for this one:

```
ana@dev:~/planner$ curl -s http://localhost:5173/src/WeekSummary.tsx | head -n 24
import { createHotContext as __vite__createHotContext } from "/@vite/client";import.meta.hot = __vite__createHotContext("/src/WeekSummary.tsx");const _jsxDEV = __vite__cjsImport1_react_jsxDevRuntime["jsxDEV"];import { formatWeek, minutes } from "/src/week.ts";
var _jsxFileName = "/home/ana/planner/src/WeekSummary.tsx";
import __vite__cjsImport1_react_jsxDevRuntime from "/node_modules/.vite/deps/react_jsx-dev-runtime.js?v=2f28d197";
export function WeekSummary({ monday, sessions }) {
	const done = sessions.filter((s) => s.done);
	return /* @__PURE__ */ _jsxDEV("section", {
		"aria-label": "This week",
		children: [/* @__PURE__ */ _jsxDEV("p", { children: ["Week of ", formatWeek(monday)] }, void 0, true, {
			fileName: _jsxFileName,
			lineNumber: 13,
			columnNumber: 7
		}, this), /* @__PURE__ */ _jsxDEV("p", { children: [
			minutes(done),
			" of ",
			minutes(sessions),
			" minutes done"
		] }, void 0, true, {
			fileName: _jsxFileName,
			lineNumber: 14,
			columnNumber: 7
		}, this)]
	}, void 0, true, {
		fileName: _jsxFileName,
		lineNumber: 12,
```

The types are gone, the imports point at real paths, and **every tag has become a call to
`_jsxDEV`**: the first argument is what to make, `"section"` or `"p"`; the second holds the
attributes and, under `children`, whatever sat between the tags. The text `Week of ` and the value
of `formatWeek(monday)` are two children of the first `p`. The rest, `fileName` and `lineNumber`,
is there so that React's error messages can point at your source; a production build uses a smaller
function, `jsx`, without them.

```schooling-figure
{"svg": "<svg data-fig=\"jsx-call\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Three stages of one paragraph. On the left the JSX as written, a p element containing the text Week of and an expression. In the middle the call Vite turns it into, with the type p and a props object whose children are the text and the expression. On the right the plain object the call returns, with a type and props, and nothing on the page yet.\"><text x=\"110\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what you write</text><text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what runs</text><text x=\"610\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what it returns</text><rect x=\"10\" y=\"40\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"22\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;p&gt;</text><text x=\"34\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Week of</text><text x=\"34\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{formatWeek(monday)}</text><text x=\"22\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;/p&gt;</text><line x1=\"212\" y1=\"100\" x2=\"248\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,100.0 240.5,103.2 240.5,96.8\" fill=\"var(--wire)\"></polygon><rect x=\"250\" y=\"40\" width=\"220\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">_jsxDEV(&quot;p&quot;, {</text><text x=\"274\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">children: [</text><text x=\"286\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&quot;Week of &quot;,</text><text x=\"286\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">formatWeek(monday)</text><text x=\"274\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">] })</text><line x1=\"472\" y1=\"100\" x2=\"508\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"508.0,100.0 500.5,103.2 500.5,96.8\" fill=\"var(--wire)\"></polygon><rect x=\"510\" y=\"40\" width=\"200\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"522\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{ type: &quot;p&quot;,</text><text x=\"534\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">props: {</text><text x=\"546\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">children: [</text><text x=\"558\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">&quot;Week of &quot;, &quot;19 Oct 2026&quot;</text><text x=\"534\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">] } }</text><text x=\"610\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">not on the page yet</text></svg>", "caption": "JSX is written, the call is what runs, and the object is what React receives."}
```

Calling that function does not touch the page. **It returns a plain object that describes the
element**, its type and its props, and a component returns a tree of those objects. Putting them on
the page is React's job, and lesson 3 is about how it does it.

## The rules, read through the call

Every rule of JSX is a consequence of it being an argument list:

- **One root.** A function returns one value, so a component returns one element. Wrap siblings in
  a parent, or in `<>…</>`, a fragment, which groups without adding an element to the page.
- **Curly braces hold an expression**, anything that produces a value: `{minutes(done)}`, a ternary,
  a call to `map`. An `if` statement is not an expression, so it cannot go inside braces; lesson 8
  shows what to write instead.
- **Attributes are property names.** `class` is a reserved word in JavaScript, so the attribute is
  `className`; `for` becomes `htmlFor`. Attributes with a dash keep it, as `aria-label` did above,
  and they reach the page exactly as written.
- **Every tag is closed**, `<br />` included, because the call has to know where its children end.

`aria-label="This week"` is worth a second look. The section element has no visible heading, so
the label is what a screen reader announces when it arrives there, and it is what `look` will print
as the region's name.
