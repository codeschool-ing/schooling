---
title: prerender, and pages written once at build time
version: 1
---

**`export const prerender = true` renders a page while the application is being built and saves the
HTML to a file**, which the server then sends as it is, without running any component or load function
for the request. About says the same thing to everybody, every time, so the result of rendering it on
each request is the same file every time. Render it once. Replace `src/routes/(info)/about/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(info)/about/+page.js", "parts": [
 {"code": "// +page.js: page options for About."},
 {"code": "export const prerender = true;\nexport const csr = false;", "note": "Rendered once, when `npm run build` runs, and saved as a file."}
]}
```

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A1 Prerendering
Prerendering
```

```
ana@dev:~/planner$ find build -name '*.html'
build/prerendered/about.html
```

**`build/prerendered/about.html`.** `adapter-node` serves it for `/about`, ahead of the routes it renders
on demand, and any static file server could serve it too. Prerendering is how a SvelteKit site with no
server at all is made, which the next section looks at, and the rule for which pages may be prerendered
is the one the documentation states plainly: **any two people asking for the page must get the same
content.**

## The planner's pages may not

Try the opposite end, and ask for every page to be prerendered. A page option in the root layout
applies to every page under it, so save this as `src/routes/+layout.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/+layout.js", "parts": [
 {"code": "// +layout.js: a trial. Prerender every page. (Deleted again below.)\nexport const prerender = true;", "note": "In the root layout, a page option applies to every page of the application."}
]}
```

```
ana@dev:~/planner$ ORIGIN=http://localhost:3000 npm run build 2>&1 | grep -A2 'SvelteKit error'
SvelteKit error: url_search_unavailable_prerender
Cannot access `url.searchParams` on a page with prerendering enabled
https://svelte.dev/e/kit/url_search_unavailable_prerender
```

**The build fails, and it is right to.** The week page reads `?week` from the address, and a page
rendered at build time has no address to read: nobody has asked for it yet. The week is the first
reason the planner's pages cannot be files, and not the only one. Their content changes every time a
session is added, which a file written at build time would not see. And their forms post to actions,
which need a server listening when the form arrives. Delete the trial file:

```
ana@dev:~/planner$ rm src/routes/+layout.js
```

`prerender = 'auto'` exists for the middle ground, a route that should be prerendered for the
addresses the build can find and rendered on demand for the rest, which suits a blog with a thousand
posts more than it suits a planner.
