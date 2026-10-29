---
title: Simulated, or slowed for real
version: 1
---

**Lighthouse did not load the page on a slow network.** Look at the requests in the last report: the
HTML finished in a few milliseconds, because `server.ts` is on the same computer. The default
*throttling method* is `simulate`: Lighthouse loads the page at full speed, records every request and
every task, and then **computes** how long the same load would have taken on its slow phone, with a
model of the network and the processor. It is fast and it gives the same answer twice, which is why it
is the default.

The other method is `devtools`, which really slows the browser down, with the same settings, and
measures what happens. Run each three times on the same page:

```
ana@dev:~/planner$ for m in simulate devtools; do for i in 1 2 3; do npm run lighthouse -- http://localhost:3000/ --throttling-method=$m >/dev/null && node tools/report.ts report.report.json | grep -E 'performance|LCP'; done; done
performance 75, throttling simulate
  LCP  4.3 s    weight 25
performance 75, throttling simulate
  LCP  4.3 s    weight 25
performance 75, throttling simulate
  LCP  4.3 s    weight 25
performance 100, throttling devtools
  LCP  1.3 s    weight 25
performance 100, throttling devtools
  LCP  1.3 s    weight 25
performance 100, throttling devtools
  LCP  1.3 s    weight 25
```

**Two things to read.** Each method agrees with itself, within a few points. And **the two disagree
with each other by three seconds of LCP**: about four for the model, a little over one when the
browser was really slowed, and so a score of 75 against one of 100.

## Which one was right

The last report is a `devtools` one, so its requests finished at the times the slowed browser saw:

```
ana@dev:~/planner$ node tools/report.ts report.report.json | grep 'request /'
  request /                            done at  4026 ms, 633040 B
  request /assets/index-C9VFYfGa.js    done at  1372 ms, 17819 B
  request /assets/index-CGM1waBA.css   done at  1198 ms, 538 B
  request /favicon.svg                 done at  4765 ms, 9695 B
```

**The HTML took four seconds to arrive and the page painted after one.** Nothing is wrong with that:
a browser does not wait for the end of a document to start drawing it. The notice, the heading and
the hundred courses are at the start of the HTML; the plan of five thousand courses, which is most of
the bytes, is at the end. The browser painted what it had while the rest was still on its way.

**The model does not see that.** It assumes the page cannot paint before its document has arrived,
which is true of most pages and false of this one. Here the real browser was right, and the
simulation was pessimistic by three seconds.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A timeline of the heavy home page on the slowed browser. The HTML took until 4026 ms to arrive. The stylesheet arrived at 1198 ms and the script at 1372 ms, and the page painted its largest content at about 1300 ms, while the HTML was still arriving. Lighthouse&#x27;s model put the same paint at about 4300 ms, after the whole document.\"><text x=\"110\" y=\"43\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the HTML</text><rect x=\"120.0\" y=\"34\" width=\"469.70000000000005\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"73\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">stylesheet</text><rect x=\"191.28333333333333\" y=\"64\" width=\"68.48333333333332\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"103\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">script</text><rect x=\"191.28333333333333\" y=\"94\" width=\"88.78333333333333\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><line x1=\"271.66666666666663\" y1=\"26\" x2=\"271.66666666666663\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></line><text x=\"271.66666666666663\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">painted, really · 1300 ms</text><line x1=\"621.6666666666667\" y1=\"26\" x2=\"621.6666666666667\" y2=\"140\" stroke=\"var(--amber)\" stroke-width=\"1.6\" stroke-dasharray=\"4 3\"></line><text x=\"621.6666666666667\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">painted, in the model · 4300 ms</text><line x1=\"120\" y1=\"196\" x2=\"680\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,196.0 672.6,199.1 672.6,192.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"680\" y=\"186\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ms</text></svg>", "caption": "The browser drew the top of the page while the bottom was still on its way."}
```

That does not make the four seconds meaningless. The planner's script is a module, and a module runs
after the whole document has been read, so on that slow phone the page looks ready after one second
and its buttons start working after four: lesson 4's dead window, three seconds long. The paint was
early; the page was not.

## What to take from it

- **Compare like with like.** A score from `simulate` and a score from `devtools` are not two
  measurements of one thing. Pick one method and keep it for a before-and-after.
- **Run more than once, and keep the median.** The spread here was small; on a busy laptop, or with
  `devtools` throttling, it can be ten points.
- **When a number surprises you, look at what it is made of**, here the requests and when they ended.
  A model can be wrong about one page in a way that is right for most.
