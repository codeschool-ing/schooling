---
title: csr = false, and a page with no JavaScript
version: 1
---

**`export const csr = false` is the opposite trade: the server renders the page, and no JavaScript is
sent with it.** The components still run, on the server, to produce the HTML; the browser receives the
HTML and the CSS and nothing to run. For About, which has nothing to do but be read, that is the whole
page. Replace `src/routes/(info)/about/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(info)/about/+page.js", "parts": [
 {"code": "// +page.js: page options for About."},
 {"code": "export const csr = false;", "note": "The server renders it; the browser gets no script. The `<script>` of every component on the page, the layout's included, runs on the server only."}
]}
```

Build, restart, and count the `<script>` tags in what the server sends, for About and for the week:

```
ana@dev:~/planner$ curl -s http://localhost:3000/about | grep -c '<script'
0
ana@dev:~/planner$ curl -s http://localhost:3000/ | grep -c '<script'
1
```

**None for About, one for the week.** The one on the week page is the inline script the previous
section showed, which imports SvelteKit's router and the app: the code lesson 1 found to be most of the
33 kB its first page cost. A page with `csr = false` does without all of it. The stylesheet is still linked, so the
page looks the same.

What About gives up is everything the browser's code did:

- **Its links are ordinary links.** "Back to the planner" loads the week as a new page, with a request
  for the whole HTML, rather than as a client-side navigation, because there is no router on About to
  intercept the click.
- **Nothing on it can react.** A button with an `onclick` would do nothing, exactly as with JavaScript
  switched off, because for this page, it is.
- **The dev server stops updating it as you save**, since that update is JavaScript too. A reload shows
  the change.

```
ana@dev:~/planner$ look http://localhost:3000/about --click 'Back to the planner' | head -4
-- click Back to the planner
at /
title: 255 min this week · Study planner
- main:
```

The link works, as any link does. **`csr = false` is safe exactly where JavaScript off is**, which for
the planner's own pages is now everywhere, after lesson 14. They keep it on because the planner is
faster and smoother with it, and with it off would still work.
