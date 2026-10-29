---
title: The window where clicks are lost
version: 1
---

**Between the moment a server-rendered page appears and the moment its script takes it over, every
button on it is a picture of a button.** A click in that window reaches an element with no listener,
does nothing, and is forgotten. On a fast laptop the window is a few milliseconds and nobody finds
it. On a slow phone it is seconds.

`tools/hydrate.ts` can make it seconds on purpose: `--script-delay 2000` holds back every script for
two seconds, and `--click-at 300` clicks *Mark done* 300 milliseconds after the page arrived, when
the page is already painted and the script is still on its way:

```
ana@dev:~/planner$ node tools/hydrate.ts http://localhost:3000/courses/git --script-delay 2000 --click-at 300
clicked Mark done 300 ms after the page arrived
painted at 52 ms, taken over by the script at 2049 ms
Sat 2026-10-24 · 25 min Mark done
Tue 2026-10-27 · 40 min Mark done
```

**The click happened, and the session is still not done.** The page had painted long before, and the
script took over about two seconds later, so the click fell in between. Nothing in the page said it
was not ready, and nothing afterwards said a click had been lost.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline in milliseconds. The page painted at 52, the click on Mark done happened at 300, and the script took the page over at 2049. The click fell inside the window between paint and takeover, and was lost.\"><line x1=\"40\" y1=\"120\" x2=\"680\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"680.0,120.0 672.6,123.1 672.6,116.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"680\" y=\"138\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ms</text><rect x=\"54.654545454545456\" y=\"92\" width=\"562.790909090909\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"396.04999999999995\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">visible, not working</text><line x1=\"54.654545454545456\" y1=\"68\" x2=\"54.654545454545456\" y2=\"118\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></line><text x=\"54.654545454545456\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">painted · 52</text><line x1=\"124.54545454545455\" y1=\"44\" x2=\"124.54545454545455\" y2=\"118\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><text x=\"124.54545454545455\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">click: lost · 300</text><line x1=\"617.4454545454545\" y1=\"68\" x2=\"617.4454545454545\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><text x=\"617.4454545454545\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">taken over · 2049</text><text x=\"40\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The script was held back two seconds on purpose, as on a slow connection.</text></svg>", "caption": "Everything that happens to the page between its paint and its takeover happens to a picture."}
```

## Three ways to close it

**Make the window short.** Less JavaScript before hydration, and a server close to the person. That
is lessons 7 and 8, and it is the only fix that also helps everything else.

**Make the page say it is not ready.** A button rendered `disabled` by the server and enabled by the
script cannot be pressed in the window, and looks pressable only when it is. It costs a flash of
greyed-out controls and it tells the truth.

**Record the clicks and play them back.** Angular does this with the `withEventReplay()` in lesson 2's
`app.config.ts`: a small script inline in the page, before anything else, records events on the
whole document, and hydration replays them to the components that now exist. The page Angular sent in lesson 2 carries
that script, `ng-event-dispatch-contract`. React, from version 18, replays some events that land
inside a part of the page still hydrating. **A form with a real `action` is the
oldest version of the idea**: a submit before hydration still goes to the server, and works.

The planner has a form, and its *Add session* would post to the server if it were pressed in the
window; `server.ts` has no handler for that, and lesson 1 said so. The *Mark done* buttons have no
fallback at all.
