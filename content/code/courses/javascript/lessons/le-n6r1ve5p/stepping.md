---
title: Stepping, and the debugger statement
version: 1
---

**Once the page is paused, you can move it forward one step at a time and watch the state change.**
DevTools has three buttons for it, and the lab's `--step` takes the same three words:

- **step over** runs the current line, calls included, and stops at the next line of the same
  function;
- **step into** follows the call on the current line into the function it calls;
- **step out** runs the rest of the current function and stops back in the caller.

Here ana pauses on the call to `render` in the fixed page and uses all three:

```
ana@dev:~/js$ page shelf.html --break shelf.js:4 --step into --step over --step out
paused at shelf.js:4
  call stack: load shelf.js:4
  local scope: res = {type: "basic", url: "http://127.0.0.1:8080/api/books", redirected: false, status: 200, ok: true, …}, books = Array(3) [{…}, {…}, {…}]
-- step into
paused at shelf.js:8
  call stack: render shelf.js:8  <  load shelf.js:4
  local scope: books = Array(3) [{…}, {…}, {…}], list = (uninitialised)
-- step over
paused at shelf.js:9
  call stack: render shelf.js:9  <  load shelf.js:4
  block scope: i = (uninitialised)
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
-- step out
paused at shelf.js:5
  call stack: load shelf.js:5
  local scope: res = {type: "basic", url: "http://127.0.0.1:8080/api/books", redirected: false, status: 200, ok: true, …}, books = Array(3) [{…}, {…}, {…}]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two functions side by side, load and render, with the four places the paused page stopped. It paused at load line 4, on the call to render. Step into followed the call to render line 8. Step over ran line 8 and stopped at line 9 of the same function. Step out ran the rest of render and stopped back in load, at line 5.\"><defs><marker id=\"steps-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><defs><marker id=\"steps-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">load</text><text x=\"40\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2  const res = await fetch(…);</text><text x=\"40\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3  const books = await res.json();</text><text x=\"40\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4  render(books);</text><text x=\"40\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5  }</text><text x=\"412\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">render</text><text x=\"420\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8  const list = document.query…</text><text x=\"420\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9  for (let i = 0; …) {</text><text x=\"420\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">   …</text><text x=\"420\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 }</text><rect x=\"34\" y=\"116\" width=\"160\" height=\"20\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"34\" y=\"146\" width=\"40\" height=\"20\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"414\" y=\"56\" width=\"200\" height=\"20\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"414\" y=\"86\" width=\"160\" height=\"20\" rx=\"2\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M194 126 L360 126 L360 66 L410 66\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#steps-ah-phosphor)\"></path><text x=\"300\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">step into</text><path d=\"M640 66 L660 66 L660 92 L578 96\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#steps-ah-phosphor)\"></path><text x=\"682\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">over</text><path d=\"M560 106 L560 176 L110 176 L110 160 L78 156\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#steps-ah-amber)\"></path><text x=\"330\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">step out</text></svg>", "caption": "Into follows a call, over stays in the function, out finishes it and goes back to the caller."}
```

Step into moved the stack from one frame to two. Step out moved it back. At line 8 `list` is
**uninitialised**: the line that creates it has not run yet, and a `const` before its declaration
is in the temporal dead zone of lesson 3. One step over later, it holds the list.

Step over is the one you will press most. **Step into the calls you wrote and over the ones you
did not**: stepping into `querySelector` or `fetch` takes you into the browser's own code, or into
a library, and the bug is rarely there.

## The debugger statement

A breakpoint can also be written into the code. The statement `debugger;` pauses the program
exactly as a breakpoint would, **but only while developer tools are open**. Otherwise it does
nothing. `find.html` loads this script with one `<script>` tag, as `shelf.html` does:

```javascript
const books = [
  { title: "Dom Casmurro", year: 1899 },
  { title: "Grande Sertão: Veredas", year: 1956 },
  { title: "A Hora da Estrela", year: 1977 },
];

function after(year) {
  const found = books.filter((book) => book.year > year);
  debugger;
  return found;
}

console.log(after(1950).length, "books after 1950");
```

```
ana@dev:~/js$ page find.html
2 books after 1950
ana@dev:~/js$ page find.html --break debugger
paused at find.js:9
  call stack: after find.js:9  <  (anonymous) find.js:13
  local scope: year = 1950, found = Array(2) [{…}, {…}]
  script scope: books = Array(3) [{…}, {…}, {…}]
2 books after 1950
```

The first run is a page with nobody watching: the statement was ignored and the count printed. In
the second, the lab's `--break debugger` attaches the debugger first, as opening DevTools would.
The page paused at line 9, with `found` already computed. The **script** scope holds the file's
top-level `const books`.

`debugger;` is useful when the line is hard to find in the Sources panel, inside a callback in a
long file for instance. It must not be committed, because a teammate with DevTools open would stop
there too. ESLint's `no-debugger` rule exists to catch the one that slipped through.

## Node has the same debugger

`node --inspect app.js` starts a program with the same protocol open, and Chrome's
`chrome://inspect` page attaches its DevTools to it, breakpoints and all. That was not run in this
lab, which has no desktop to open a DevTools window on.
