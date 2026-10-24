---
title: The LCP image
version: 1
---

**Two attributes are left, and both are about the moment the picture arrives.**

## The room it will take

The CLS of the first run was the form moving down when the picture arrived, because until it did, the
browser did not know how tall it would be and gave it no room. **`width` and `height` on the `<img>`**
tell it: not the size it is drawn at, which the CSS decides, but the proportion, from which the browser
works out the height before a single byte of the picture has arrived. It is lesson 5's notice again,
solved by the markup instead of a guess in the CSS.

The simulated run cannot show the shift any more, because the layout shifts Lighthouse reports are the
ones that really happened while it loaded the page, and on one computer the picture arrives too soon.
So this section measures with `devtools`, which slows the browser for real. As it is now:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git --throttling-method=devtools >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP|CLS|insight|cover'
performance 99, throttling devtools
  LCP  1.5 s    weight 25
  CLS  0.061    weight 25
  insight: Use efficient cache lifetimes, Est savings of 45 KiB
  insight: Forced reflow
  insight: Improve image delivery, Est savings of 29 KiB
  insight: LCP request discovery
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 150 ms
  request /covers/git-800.avif         done at  1444 ms, 38255 B
```

**The shift is back**: with the network really slow, the picture arrives after the first paint.

## Its priority

**`fetchpriority="high"`** tells the browser that this request matters more than the others it found.
A browser gives images a low priority at first, because it cannot know which one will be large until
it has laid out the page; for the one picture that will be the LCP, the page knows better, and saying
so is what LCP request discovery asked for.

And never **`loading="lazy"`** on that picture. Lazy loading waits until an image is near the window
before requesting it at all, which is right for the pictures further down a long page and wrong for the
one at the top: it turns a request the browser would have started at once into one that waits for
layout.

In `src/view.ts`, replace the `<img>` line inside `cover` with these two:

```typescript
  <img class="cover" src="/covers/${slug}-800.jpg" srcset="${set("jpg")}" sizes="${sizes}" alt=""
    width="2400" height="1200" fetchpriority="high">
```

Only the `<img>` needs them: the `<source>` elements choose the file, and the `<img>` is the element the
page lays out, whichever file it shows. Build, restart, measure the same way:

```
ana@dev:~/planner$ npm run lighthouse -- http://localhost:3000/courses/git --throttling-method=devtools >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP|CLS|insight|cover'
performance 100, throttling devtools
  LCP  1.5 s    weight 25
  CLS  0        weight 25
  insight: Use efficient cache lifetimes, Est savings of 45 KiB
  insight: Improve image delivery, Est savings of 29 KiB
  insight: Network dependency tree
  insight: Render-blocking requests, Est savings of 670 ms
  request /covers/git-800.avif         done at  1434 ms, 38255 B
```

**The CLS is zero and LCP request discovery is gone.** The LCP did not move: with three requests
competing there is little to win by ordering them, and `fetchpriority` earns its place on a page with
dozens.

## One insight that stays

**Improve image delivery** still estimates a saving, and the HTML report says why: it compares the
800-pixel file with the 380 by 190 CSS pixels the picture is drawn at. But Lighthouse's phone has 1.75
device pixels for each CSS pixel, so the browser needed about 665 pixels and chose the 800, which is
what `srcset` is for. A 400 would have been blurry. An insight is a rule applied by a program, and this
one is right about most pages and wrong about this one.
