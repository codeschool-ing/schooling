---
title: The Console, and the errors a test should not ignore
version: 1
---

The **Console** tab does two jobs. It shows what the page writes, its own messages and the
browser's complaints about it, and it runs any JavaScript you type, inside the page, against the
live DOM. A tester uses the second job to ask questions and the first to notice what nobody asked
about.

## Asking the page questions

Type this into the Console on the shop's page and press Enter:

```javascript
document.querySelectorAll('#products li').length
```

The answer is `8`, one for each product in `app/store.js`. Any expression works here, and the
Console offers two short forms of its own: `$$('button')` lists every element a CSS selector
matches, and `$0` is the element currently selected in the Elements panel. Asking the page *how
many of these are there, right now?* before writing a test is the same check as the search box in
the Elements panel, with the whole language behind it.

## A page that fails quietly

Most broken pages do not look broken. Here is the shop with one mistake that happens all the time
in a project built by copying files: the script was saved as `App.js` with a capital A, and the
page asks for `app.js`. `look.mjs` loads it:

```
ana@laptop:~/quitanda$ node look.mjs
   12 ms  200 GET /  (document)
   21 ms  200 GET /style.css  (stylesheet)
   23 ms  404 GET /app.js  (script)
   23 ms  console.error: Failed to load resource: the server responded with a status of 404 (Not Found)
```

On screen, the heading and the empty basket appear and the list never fills: nothing says
*error*. The Network line says `404` and the Console carries the browser's own complaint, **Failed
to load resource**. On Windows and macOS, whose disks usually ignore the case of a file name, the same mistake works
on your own computer and breaks on a Linux server.

Now the file is back, but one address inside it is wrong: `/api/product`, without the `s`:

```
ana@laptop:~/quitanda$ node look.mjs
   14 ms  200 GET /  (document)
   22 ms  200 GET /style.css  (stylesheet)
   23 ms  200 GET /app.js  (script)
   51 ms  404 GET /api/product  (fetch)
   54 ms  console.error: Failed to load resource: the server responded with a status of 404 (Not Found)
   56 ms  uncaught error: Unexpected token 'o', "not found" is not valid JSON
```

Three lines describe one defect, and each is a different kind of evidence. The server answered
`404`. The browser logged the failed request. And the script, which expected JSON, tried to read
`not found` as JSON and **threw an error nobody caught**. In the Console that last line is red and
says *Uncaught*. On screen, again, an empty list.

## Why a test should listen

A test that checks only what it can see would report the first of these pages as *the list is
empty* and stop there, which is true and unhelpful. The console line and the uncaught error say
**why**, in the same run, at no cost. Playwright gives a test both, as the `console` and
`pageerror` events `look.mjs` listens to, and lesson 16 builds them into the evidence a failing
test leaves behind.

There is a stronger position, and many teams take it: **an uncaught error on a page fails the test
that saw it**, whether or not the thing the test checks still looks right. A page can throw and
still draw its heading; a test that ignores that passes on a broken page. Where to draw that line
is a decision, and the Console is where the evidence for it comes from.
