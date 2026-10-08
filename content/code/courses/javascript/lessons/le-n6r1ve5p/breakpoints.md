---
title: Breakpoints: stopping the page
version: 2
---

**A breakpoint pauses the program on a line, before that line runs, and leaves everything as it
was.** While it is paused, you can read every variable in scope and the chain of calls that led
there. This page has a bug:

```html
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Shelf</title></head>
<body>
  <ul id="books"></ul>
  <script src="shelf.js"></script>
</body>
</html>
```

```javascript
async function load() {
  const res = await fetch("/api/books");
  const books = await res.json();
  render(books);
}

function render(books) {
  const list = document.querySelector("#books");
  for (let i = 0; i <= books.length; i++) {
    const book = books[i];
    const item = document.createElement("li");
    item.textContent = `${book.title} (${book.year})`;
    list.append(item);
  }
}

load();
```

```
ana@dev:~/js$ page shelf.html --dom '#books'
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

**The page looks right and is wrong.** All three books were rendered, and then the script threw.
Nobody looking only at the screen would know, which is why the console is the first thing to open
when a page misbehaves. The message names a property, `title`, and a value, `undefined`, but not
which book or why.

## Pausing on the error

In DevTools, the Sources panel has a switch to **pause on uncaught exceptions**. `page` can ask
Chromium for the same thing once one more file sits beside it in `~/js-tools`. Save this as
`devtools.mjs`:

```javascript
// devtools.mjs: what page.mjs needs to pause, step and measure a page. It
// asks Chromium through the Chrome DevTools Protocol, the same channel the
// developer tools panel uses. page.mjs loads it when it sits beside it.
//
//   --break F:LINE   pause at a line, print the stack and the local scope
//   --break debugger pause only at `debugger;` statements in the page
//   --break uncaught pause where an exception nobody catches is thrown
//   --if COND        only pause there when COND is true (a conditional breakpoint)
//   --step KIND      after a pause, step over|into|out and print again
//   --profile        record a CPU profile and print where the busy time went,
//                    by function: its own time, not the time of what it called
//   --waterfall      at the end, every request on a time line from the first
//                    one, rounded to 100 ms: when it started and how long it
//                    took, drawn as a bar of # (one per 100 ms)
import path from "node:path";

// A value as the Scope pane draws it: an object with its first properties,
// an array with its length, an element by its tag.
function shown(v) {
  if (!v) return "(uninitialised)";
  if (v.type === "undefined") return "undefined";
  if (v.type === "string") return JSON.stringify(v.value);
  if (v.type !== "object" || v.subtype === "null") return v.description ?? String(v.value);
  const pv = v.preview;
  if (!pv || v.subtype === "node") return v.description;
  const item = (p) => (p.type === "string" ? JSON.stringify(p.value) : p.type === "object" ? "{…}" : p.value);
  const more = pv.overflow ? ", …" : "";
  if (v.subtype === "array") return `${v.description} [${pv.properties.map(item).join(", ")}${more}]`;
  return `{${pv.properties.map((p) => `${p.name}: ${item(p)}`).join(", ")}${more}}`;
}

export async function attach({ context, page, opt, say, origin }) {
  const timeline = [];
  if (opt.waterfall) {
    const t = new Map();
    page.on("request", (r) => t.set(r, { start: Date.now(), r }));
    const end = (r) => { const e = t.get(r); if (e) { e.end = Date.now(); timeline.push(e); } };
    page.on("requestfinished", end);
    page.on("requestfailed", end);
  }

  let cdp;
  if (opt.break || opt.profile) cdp = await context.newCDPSession(page);

  async function scopeOf(frame) {
    const out = [];
    for (const s of frame.scopeChain) {
      if (s.type === "global") continue;
      const { result } = await cdp.send("Runtime.getProperties", { objectId: s.object.objectId, ownProperties: true, generatePreview: true });
      const vars = result.map((p) => `${p.name} = ${shown(p.value)}`);
      out.push(`  ${s.type} scope: ${vars.join(", ") || "(empty)"}`);
    }
    return out;
  }

  if (opt.break) {
    const [bf, bl] = opt.break.split(":");
    const urls = new Map();
    cdp.on("Debugger.scriptParsed", (ev) => urls.set(ev.scriptId, ev.url));
    await cdp.send("Debugger.enable");
    if (opt.break === "uncaught") await cdp.send("Debugger.setPauseOnExceptions", { state: "uncaught" });
    else if (opt.break !== "debugger")
      await cdp.send("Debugger.setBreakpointByUrl", { lineNumber: Number(bl) - 1, urlRegex: `${bf.replace(/[.]/g, "\\.")}$`, condition: opt.if ?? "" });
    const steps = [...opt.step];
    cdp.on("Debugger.paused", async (ev) => {
      const top = ev.callFrames[0];
      const at = (f) => `${path.basename(urls.get(f.location.scriptId) ?? "")}:${f.location.lineNumber + 1}`;
      say(`paused at ${at(top)}${ev.reason === "exception" || ev.reason === "promiseRejection" ? `, on ${ev.data?.description?.split("\n")[0]}` : ""}`);
      say("  call stack: " + ev.callFrames.map((f) => `${f.functionName || "(anonymous)"} ${at(f)}`).join("  <  "));
      for (const l of await scopeOf(top)) say(l);
      const next = steps.shift();
      if (next) { say(`-- step ${next}`); await cdp.send(`Debugger.step${next[0].toUpperCase()}${next.slice(1)}`); }
      else await cdp.send("Debugger.resume");
    });
  }

  if (opt.profile) {
    await cdp.send("Profiler.enable");
    await cdp.send("Profiler.setSamplingInterval", { interval: 100 });
    await cdp.send("Profiler.start");
  }

  async function finish() {
    if (opt.profile) {
      const { profile } = await cdp.send("Profiler.stop");
      const self = new Map();
      const byId = new Map(profile.nodes.map((n) => [n.id, n]));
      const dt = profile.timeDeltas;
      profile.samples.forEach((id, i) => {
        const n = byId.get(id);
        const name = n.callFrame.functionName || `(${n.callFrame.url ? "anonymous" : n.callFrame.functionName || "program"})`;
        const where = n.callFrame.url ? `${path.basename(n.callFrame.url)}:${n.callFrame.lineNumber + 1}` : "";
        const k = `${name}  ${where}`.trim();
        self.set(k, (self.get(k) || 0) + (dt[i] || 0));
      });
      // Time the page spent waiting for something to do is not time anything
      // cost, so the shares are of the time the browser was busy.
      self.delete("(idle)");
      const busy = [...self.values()].reduce((a, b) => a + b, 0);
      say("share  self time  function");
      for (const [k, us] of [...self].sort((a, b) => b[1] - a[1]).slice(0, 5))
        say(`${String(Math.round((100 * us) / busy)).padStart(4)}%  ${(us / 1000).toFixed(0).padStart(6)} ms  ${k}`);
      say(`       ${(busy / 1000).toFixed(0).padStart(6)} ms  busy in total`);
    }
    if (opt.waterfall) {
      const first = Math.min(...timeline.map((e) => e.start));
      const tenth = (ms) => Math.round(ms / 100);
      say("start  took    request");
      for (const e of timeline.sort((a, b) => a.start - b.start)) {
        const s0 = tenth(e.start - first), d = tenth(e.end - e.start);
        const what = `${e.r.method()} ${e.r.url().replace(origin, "")}`;
        say(`${String(s0 * 100).padStart(5)}  ${String(d * 100).padStart(4)}  ${what.padEnd(28)} ${" ".repeat(s0)}${"#".repeat(Math.max(d, 1))}`);
      }
    }
  }
  return { finish };
}
```

It talks to Chromium through the **Chrome DevTools Protocol**, the same channel the DevTools window
uses, and gives `page` the five options at the top of the file. If you have a desktop, do each step
of this lesson in DevTools as well: the transcripts are the same pause, printed as text. With the
file in place, `--break uncaught`:

```
ana@dev:~/js$ page shelf.html --break uncaught
paused at shelf.js:12, on TypeError: Cannot read properties of undefined (reading 'title')
  call stack: render shelf.js:12  <  load shelf.js:4
  block scope: book = undefined, item = li
  block scope: i = 3
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A paused page, drawn as three panes. On the left, render&#x27;s code with line 12 marked as the line the browser stopped on, the template string that reads book.title. Top right, the call stack: render at line 12, called by load at line 4. Below it, the scopes: book is undefined, i is 3, books holds three items. The three facts together explain the error: the loop asked for a fourth book.\"><defs><marker id=\"paused-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"400\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shelf.js</text><text x=\"48\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><text x=\"56.0\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">function render(books) {</text><text x=\"48\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"66.8\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const list = document.querySelector(&quot;#books&quot;);</text><text x=\"48\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><text x=\"66.8\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">for (let i = 0; i &lt;= books.length; i++) {</text><text x=\"48\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><text x=\"77.6\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const book = books[i];</text><text x=\"48\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11</text><text x=\"77.6\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">const item = document.createElement(&quot;li&quot;);</text><rect x=\"26\" y=\"164\" width=\"388\" height=\"20\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"174\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">12</text><text x=\"77.6\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">item.textContent = `${book.title} (${book.year})`;</text><text x=\"48\" y=\"196\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><text x=\"77.6\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">list.append(item);</text><text x=\"48\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><text x=\"66.8\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">}</text><text x=\"48\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><text x=\"56.0\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">}</text><rect x=\"450\" y=\"20\" width=\"250\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Call stack</text><text x=\"462\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">render   shelf.js:12</text><text x=\"462\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">load     shelf.js:4</text><rect x=\"450\" y=\"136\" width=\"250\" height=\"124\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"462\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Scope</text><text x=\"462\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">book  = undefined</text><text x=\"462\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">i     = 3</text><text x=\"462\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">books = Array(3)</text><text x=\"462\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">list  = ul#books</text><path d=\"M420 174 L446 180\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#paused-ah-amber)\"></path></svg>", "caption": "Where it stopped, how it got there, and what every variable held at that moment."}
```

Three facts, read off one pause:

- **where**: line 12, the template string that reads `book.title`;
- **how it got there**: `render`, called by `load` at line 4. That list is the **call stack**,
  newest call first;
- **what everything held**: `book` is `undefined`, `i` is `3`, and `books` has three items. Index 3
  of a three-item array does not exist.

The scopes come in layers, the scope chain of lesson 6: two **block** scopes, one for the loop's
body and one for the loop's `i`, then the function's **local** scope. The cause is now one sentence:
the loop runs while `i <= books.length`, so it asks for one book too many.

## A breakpoint on a line, with a condition

Pausing on the error works when there is an error. More often there is only a wrong value, and you
pause on a line you choose. In DevTools you click the line number in the Sources panel. A plain
breakpoint on line 11 would pause four times, once per pass of the loop. A **conditional
breakpoint** pauses only when an expression is true:

```
ana@dev:~/js$ page shelf.html --break shelf.js:11 --if 'book === undefined'
paused at shelf.js:11
  call stack: render shelf.js:11  <  load shelf.js:4
  block scope: book = undefined, item = li
  block scope: i = 3
  local scope: books = Array(3) [{…}, {…}, {…}], list = ul#books
Uncaught TypeError: Cannot read properties of undefined (reading 'title')
```

The condition ran on every pass and was true only on the last. This is the tool for a bug in the
900th item of a list: you write down what "wrong" looks like and let the browser wait for it.

## The fix

```
ana@dev:~/js$ sed -i 's/i <= books.length/i < books.length/' shelf.js
ana@dev:~/js$ sed -n 9p shelf.js
  for (let i = 0; i < books.length; i++) {
ana@dev:~/js$ page shelf.html --dom '#books'
<ul id="books"><li>Dom Casmurro (1899)</li><li>Grande Sertão: Veredas (1956)</li><li>A Hora da Estrela (1977)</li></ul>
```

No error, and the same three books. The fix is one character, and finding it took two runs and no
edit to the code.
