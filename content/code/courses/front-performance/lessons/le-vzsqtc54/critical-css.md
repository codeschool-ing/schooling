---
title: The stylesheet, inside the page
version: 1
---

**Lighthouse has said since lesson 6 that the stylesheet blocks the first paint**, and that is true of
every stylesheet a page links to: the browser asks for it once it has read the `<link>`, and paints
nothing until it has it. On a slow phone that is a round trip with a blank screen. Measure it as it is:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|FCP|LCP|insight'
performance 100, throttling simulate
  FCP  1.0 s    weight 10
  LCP  1.6 s    weight 25
  insight: Use efficient cache lifetimes, Est savings of 90 KiB
  insight: Improve image delivery, Est savings of 29 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
```

**The CSS that a page needs to draw its first screen is called its critical CSS**, and the fix is to put
it in the HTML, in a `<style>` element, so it arrives with the page and blocks nothing. The planner's
stylesheet is all critical, and small, so the whole of it can go in.

`server.ts` reads the shell the build wrote once, at start-up. Replace that line with these, which find
the `<link>` the build wrote, read the file it names, and put its contents in the shell's place:

```typescript
// The shell the build wrote, with its stylesheet inlined: the CSS is small, and inside
// the HTML it arrives with it rather than one round trip later. The replacement is a
// function so that a "$" in the CSS is not read as part of a pattern.
const built = await readFile(join(dist, "index.html"), "utf8");
const link = built.match(/<link rel="stylesheet"[^>]*href="([^"]+)">/)!;
const css = await readFile(join(dist, link[1]), "utf8");
const shell = built.replace(link[0], () => `<style>${css}</style>`);
```

Build, restart, measure:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|FCP|LCP|insight'
performance 100, throttling simulate
  FCP  0.8 s    weight 10
  LCP  1.4 s    weight 25
  insight: Use efficient cache lifetimes, Est savings of 89 KiB
  insight: Improve image delivery, Est savings of 29 KiB
  insight: Network dependency tree
```

**Render-blocking requests is gone, and the first paint came forward.** The waterfall shows why, on a
slowed network: the stylesheet is not a request any more.

```
ana@dev:~/planner$ node tools/waterfall.ts http://localhost:3000/courses/git --slow
/courses/git                   306 ms    1302 B  ######
/fonts/plex-400.woff2          623 ms   22611 B        ######
/fonts/plex-700.woff2          624 ms   22842 B        ######
/assets/index-yh2nfJj3.js      628 ms    6918 B        #######
/covers/git-800.avif           629 ms   38037 B        #######
```

## What inlining costs

- **It is sent again on every page.** A linked stylesheet is downloaded once and kept in the cache, which
  lesson 9 sets up; an inlined one is part of every HTML response. For half a kilobyte that is nothing.
  For a stylesheet of a hundred kilobytes it is a hundred kilobytes on every page.
- So for a large stylesheet the technique is to **inline only the critical part** and load the rest
  without blocking. Tools do the extracting: they render the page, see which rules apply to what is on
  the first screen, and inline those. Beasties is one, and Angular runs it on every production build.
- **The CSS is in two places now**: the file the build wrote, and the page. `server.ts` reads the file
  the build named, so they cannot drift apart, which is the reason to read it rather than copy it.
