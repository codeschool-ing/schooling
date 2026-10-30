---
title: What a build produces
version: 1
---

**A build turns the project into files that any web server can send.** Lesson 13 looked at it to see
the code split; this time, the whole of `dist/`:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 264 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                         0.45 kB │ gzip:   0.29 kB
dist/assets/index-ims8OhNo.css          0.57 kB │ gzip:   0.31 kB
dist/assets/CourseScreen-jvv40fJe.js  111.82 kB │ gzip:  34.97 kB
dist/assets/index-R8L4SX4s.js         356.86 kB │ gzip: 112.08 kB

✓ built in 622ms
ana@dev:~/planner$ ls dist dist/assets
dist:
assets
courses.json
favicon.svg
index.html

dist/assets:
CourseScreen-jvv40fJe.js
index-R8L4SX4s.js
index-ims8OhNo.css
ana@dev:~/planner$ cat dist/index.html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>planner</title>
    <script type="module" crossorigin src="/assets/index-R8L4SX4s.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-ims8OhNo.css">
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
```

Three kinds of file:

- **`index.html`**, rewritten. The `<script>` that pointed at `/src/main.tsx` now points at
  `/assets/index-R8L4SX4s.js`, and the stylesheet that `main.tsx` imported became a `<link>`, so the
  browser starts fetching it before any JavaScript runs. The `<title>` is still `planner`, from the
  template: the planner sets the tab's title itself, from lesson 5's effect.
- **`assets/`, with a hash in every name.** The JavaScript, split where lesson 17 split it, and the
  CSS. A new build with any change gives the changed file a new name, so a server can tell browsers to
  keep these files for a year.
- **`courses.json` and `favicon.svg`**, which were in `public/`. **Everything in `public/` is copied as
  it is**, under the same name and with no hash, for files whose address must not change: an icon, a
  `robots.txt`, the seed data lesson 5 fetched.

A deployment of the planner is these files on a server that sends `index.html` for any address that is
not a file, as lesson 17 said, plus the API somewhere the browser can reach at `/api`. Nothing in `dist/`
runs on the server: it is all for the browser.
