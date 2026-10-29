---
title: What the server sends today
version: 1
---

**So far the planner's HTML has been empty, and the browser has built every word of it.** The dev
server sends `index.html` with an `<app-root>` that has nothing in it, and two scripts. The page
appears only after those scripts have arrived, been run, asked `/api/planner` for the data and
drawn the result. A browser with JavaScript turned off shows what the server sent, and that is
nothing:

```
ana@dev:~/planner$ look http://localhost:4200/ --no-js --text body
```

`curl` shows the same thing as text, because it fetches the page and runs no script:

```
ana@dev:~/planner$ curl -s http://localhost:4200/ | sed -n '/<body>/,/<\/body>/p'
<body>
  <app-root></app-root>
<script src="polyfills.js" type="module"></script><script src="main.js" type="module"></script></body>
```

For a person on a good connection the wait is short, and nobody notices it. Others do notice:

- **A slow phone** waits for the whole script before showing one word. The script for this planner
  is small; a large application's is not, and until it has run, the screen is blank.
- **A search engine, or a chat app making a link preview,** may not run scripts at all, or may run
  them later and less often. What it reads of an empty `<app-root>` is a title and nothing else.
- **A person with JavaScript blocked** gets an empty page, which tells them nothing about why.

**Server-side rendering runs the same application on the server, once per request, and sends the
HTML it produced.** The browser shows that HTML at once. Then the scripts arrive, and Angular in the
browser takes over the page instead of drawing it again; that step is called hydration, and this
lesson's fifth section is about it.

It costs something, and the cost is the reason it is a choice rather than a default:

| | rendered in the browser | rendered on the server |
| --- | --- | --- |
| what serves the page | any web server, from files | a Node.js program that runs Angular |
| the first HTML | an empty `<app-root>` | the page, with its text |
| where the code runs | the browser | the server first, then the browser |
| what the code may assume | a browser: `window`, `localStorage`, focus | nothing the server does not have |

The last row is the expensive one. Code that runs in two places has to be correct in both, and the
planner already has code that only makes sense in a browser. This lesson finds it.
