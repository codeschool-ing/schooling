---
title: Modules in the browser
version: 2
---

The same `import` and `export` work in a page. **A script tag with `type="module"` loads a module**,
and it imports the others itself:

```javascript
export function label(title, year) {
  return `${title} (${year})`;
}
```

```javascript
import { label } from "./format.js";

const heading = document.querySelector("h1");
console.log(heading.textContent, "/", label("Iracema", 1865));
console.log(typeof this, typeof window.label, document.readyState);
```

```html
<!doctype html>
<head>
  <script type="module" src="app.js"></script>
</head>
<body>
  <h1>Catalogue</h1>
</body>
```

```
ana@dev:~/js$ cd web && page index.html
Catalogue / Iracema (1865)
undefined undefined interactive
ana@dev:~/js$ cd web && page index.html --file
[error] Access to script at 'file:///home/ana/js/web/app.js' from origin 'null' has been blocked by CORS policy: Cross origin requests are only supported for protocol schemes: chrome, chrome-untrusted, data, http, https.
[error] Failed to load resource: net::ERR_FAILED
```

## Four differences from a classic script

The first run shows three of them:

- **a module script is deferred.** It sat in the `<head>`, above the `<h1>`, and still found the
  heading: the browser waits until the page has been read before running modules, and
  `document.readyState` says `interactive`, the moment between reading the page and finishing
  every image. A classic script in the same place would have run before the `<h1>` existed;
- **it has its own scope**, so `label` did not become `window.label`;
- **its `this` is `undefined`**, as in Node.

The second run, with `--file`, opened the same page from `file://`, which is what double-clicking an
HTML file on your desktop does:

- **a module will not load from `file://`.** The browser treats a file opened from disk as having no
  origin, and refuses to fetch modules for it. The page loaded and the script did not, with an error
  in the console and nothing on the page to say so. `page` serves `~/js` over
  `http://127.0.0.1:8080` for exactly this reason, and so does `node ~/js-tools/serve.mjs` for your
  own browser; any small static server does the same, and editors often have one built in.

## Paths in the browser

`./format.js` is a URL, relative to the module that imports it, and **the browser fetches it as
written**: there is no searching, no guessing of extensions and no `node_modules`. A bare name such
as `import { x } from "lodash"` fails in a browser unless an **import map** in the page says which
URL that name stands for. Most projects never write one, because a build tool (the frameworks in the
next courses each come with one) turns many modules into a few files before the page is served.
