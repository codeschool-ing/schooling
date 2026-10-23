---
title: A layout shift, made and removed
version: 1
---

**The notice arrives after the page has been painted, and pushes everything under it down.** On a
desktop window with everything on one computer, that happens too early to see. On a phone-sized
window with every request 300 milliseconds slower, it is a page that jumps:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git --phone --slow
[vitals] LCP 972 ms good #notice
[vitals] CLS 0.031 good #app
```

**Two metrics moved for one reason.** CLS is no longer zero, and the element that shifted was
`#app`, the whole page below the notice. And the LCP element is `#notice` itself: on a phone the two
lines of the notice are the largest block of text on the course page, so the largest content arrived
last, with a fetch that began only after the script had run. **A late element can be both the shift
and the largest paint**, and fixing one does not fix the other, as the two steps below show.

The CLS is under the 0.1 line. It is still a page whose content moves under the reader's finger, and
a second late element, a banner image, or a smaller screen would push it over.

## Step one: keep the room

The shift happens because the empty paragraph took no room. If it takes the room the notice will
need, nothing moves when the text arrives. Change the second rule in `src/style.css`:

```css
.notice:empty { min-height: 3rem; }
```

Three rems is two lines of text at this size, which is what the notice takes on a phone. Build,
restart, measure:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git --phone --slow
[vitals] LCP 956 ms good #notice
[vitals] CLS 0.000 good 
```

**CLS is zero and LCP has not moved.** Nothing shifts, because the box was there; the largest text
still arrives last, because the text was still fetched by the script. Keeping room is the right fix
for content whose size you know and whose arrival you cannot hurry, such as an advertisement. It is
also a guess: a notice of three lines on a narrow phone would still push the page by one.

## Step two: send it with the page

The notice is the same for everybody and it is a file on the server. There is no reason for the
browser to fetch it at all. `server.ts` can read it and write it into the paragraph, as it already
does with the plan, and `main.ts` then finds the paragraph full and fetches nothing. Replace
`server.ts`:

```typescript
// server.ts: the same planner, with each page drawn here before it is sent.
import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { extname, join } from "node:path";
import type { Plan } from "./src/planner.ts";
import { page } from "./src/view.ts";

const dist = join(import.meta.dirname, "dist");
const types: Record<string, string> = {
  ".js": "text/javascript", ".css": "text/css", ".json": "application/json", ".svg": "image/svg+xml",
};
const shell = await readFile(join(dist, "index.html"), "utf8");
const esc = (s: string) => s.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);

createServer(async (req, res) => {
  const { pathname } = new URL(req.url ?? "/", "http://localhost");
  if (extname(pathname)) {
    // A file the build wrote: a script, a stylesheet, the data.
    try {
      const body = await readFile(join(dist, pathname));
      res.writeHead(200, { "content-type": types[extname(pathname)] ?? "application/octet-stream" });
      res.end(body);
    } catch {
      res.writeHead(404).end();
    }
    return;
  }
  // A page: read the plan and the notice, and draw both into the shell the build wrote.
  const plan: Plan = JSON.parse(await readFile(join(dist, "courses.json"), "utf8"));
  const notice: { text: string } = JSON.parse(await readFile(join(dist, "notice.json"), "utf8"));
  // The plan goes into the page as data, so the browser does not fetch it again. A "<" is
  // written as \u003c, so no title can close the script element early.
  const data = JSON.stringify(plan).replace(/</g, "\\u003c");
  const html = shell
    .replace('<p class="notice" id="notice"></p>', `<p class="notice" id="notice">${esc(notice.text)}</p>`)
    .replace('<main id="app"></main>',
      `<main id="app">${page(plan, pathname)}</main><script type="application/json" id="plan">${data}</script>`);
  res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
  res.end(html);
}).listen(3000, () => console.log("planner on http://localhost:3000"));
```

The notice goes through `esc`, because it is text, exactly as every title in `view.ts` does. Restart
it, and measure again:

```
ana@dev:~/planner$ node tools/vitals.ts http://localhost:3000/courses/git --phone --slow
[vitals] LCP 648 ms good #notice
[vitals] CLS 0.000 good 
```

**LCP came forward by about three hundred milliseconds**, one round trip, and CLS stayed at zero. The
largest text now arrives with the HTML, so it is painted with the first paint. That is lesson 1's
argument for server rendering, found again from the other end: whatever the page needs to look
finished belongs in the first response.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Three measurements of the course page on a phone-sized window with every request 300 ms slower. As it was: LCP 972 ms and CLS 0.031. With room kept for the notice: LCP 956 ms and CLS 0.000. With the notice sent by the server: LCP 648 ms and CLS 0.000.\"><text x=\"188\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">as it was</text><rect x=\"200\" y=\"40\" width=\"320.76\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"528.76\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LCP 972 ms · CLS 0.031</text><text x=\"188\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">room kept</text><rect x=\"200\" y=\"96\" width=\"315.48\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"523.48\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LCP 956 ms · CLS 0.000</text><text x=\"188\" y=\"164\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sent by the server</text><rect x=\"200\" y=\"152\" width=\"213.84\" height=\"24\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"421.84000000000003\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">LCP 648 ms · CLS 0.000</text><text x=\"200\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">LCP, the bar; CLS beside it</text></svg>", "caption": "Keeping room stopped the movement; sending the notice with the page brought it forward."}
```
