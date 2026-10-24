---
title: History modes, and the server's part
version: 1
---

**The router writes the address in one of two ways, and one of them needs the server's help.** With
`createWebHistory()`, the planner's addresses are ordinary paths, `/courses/spanish`. With
`createWebHashHistory()`, they are written after a `#`, `/#/courses/spanish`. They look like a matter
of taste, and the difference is in who answers when the student reloads the page.

## A real path asks the server

When the student clicks a `<RouterLink>`, no new page is requested, at most the code and data the next
screen needs, as the lazy-loading section showed: the router changes the address with the
browser's History API and draws the page. When the student **reloads**, or opens a bookmark, the browser
asks the server for `/courses/spanish`, and the server must answer with the application, the same
`index.html` it gives for `/`, so that the router can start and draw the course.

The dev server does that, and lesson 2 met it doing so for a missing data file:

```
ana@dev:~/vue/planner$ curl -s http://localhost:5173/courses/spanish | grep -E '<title>|id="app"'
    <title>Study planner</title>
    <div id="app"></div>
```

**It answered `/courses/spanish` with `index.html`.** Every address it has no file for gets the
application, which is the **fallback** a router with real paths needs.

A static host does not always do that. Serve the built files with a plain web server, the one Python
ships with, and ask for the same address:

```
ana@dev:~/vue/planner$ cd dist && python3 -m http.server 8000 > /dev/null 2>&1 &
ana@dev:~/vue/planner$ sleep 1; curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/
200
ana@dev:~/vue/planner$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8000/courses/spanish
404
ana@dev:~/vue/planner$ kill %1
bash: line 9: kill: %1: no such job
```

The root answers 200, with the built `index.html`. **The course page answers 404.** There is no file
called `courses/spanish` in `dist`, and a plain server answers only for files that exist. The
application works when the student starts at `/` and clicks, and breaks the moment they reload a course
page or share its address. The last line stopped the server.

## The two fixes

- **Configure the server to fall back to `index.html`** for any path that is not a file. Every host that
  serves single-page applications has a setting for it, under a name like *rewrites*, *redirects* or
  *SPA mode*, and `front-delivery` lessons 1 and 4 cover hosting and redirects. `npm run preview`, which serves the build
  with Vite, does it already.
- **Use `createWebHashHistory()`.** The part after `#` is never sent to the server, so every address is
  a request for `/`, and no server needs configuring. The cost is the `#` in every address, which
  looks dated and which search engines read as one page.

**The planner uses real paths**, as almost every Vue application does, and its server, in development
and from lesson 18 in Nuxt, is one that falls back. Choose the hash only when you cannot configure the
server at all, such as an application opened as a file from disk.
