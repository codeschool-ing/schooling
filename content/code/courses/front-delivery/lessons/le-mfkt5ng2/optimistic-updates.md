---
title: Optimistic updates, and taking them back
version: 1
---

**An optimistic update draws the result of a change before the server confirms it, and a client that
keeps the cache can take it back when the server refuses.** Lesson 9's planner already drew first and
saved second, and when the save failed the screen stayed wrong. With Apollo, `optimisticResponse` makes
the cache itself change at once, in a separate layer, and Apollo removes that layer when the real answer
arrives: replaced by the server's answer if the mutation worked, dropped if it failed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A timeline of an optimistic update that fails. The press of Mark done adds an optimistic layer to the cache at once, and the row shows done. The mutation reaches the proxy, which answers 502 because the server is down. Apollo drops the optimistic layer, the cache answers as before, and the row shows its button again.\"><line x1=\"40\" y1=\"100\" x2=\"690\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,100.0 682.6,103.1 682.6,96.9\" fill=\"var(--wire)\"></polygon><text x=\"690\" y=\"86\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><rect x=\"30\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">press</text><line x1=\"90\" y1=\"80\" x2=\"90\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"90\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Mark done</text><rect x=\"190\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"250\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">optimistic layer</text><line x1=\"250\" y1=\"80\" x2=\"250\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"250\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">done: true</text><rect x=\"370\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the proxy answers</text><line x1=\"430\" y1=\"80\" x2=\"430\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"430\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">502</text><rect x=\"540\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">layer dropped</text><line x1=\"600\" y1=\"80\" x2=\"600\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"600\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">done: false</text><rect x=\"170\" y=\"140\" width=\"340\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"340\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the row shows done</text><rect x=\"530\" y=\"140\" width=\"150\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"605\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the button is back</text></svg>", "caption": "The optimistic answer lives in a layer of its own, so a refusal removes it and the cache's older truth shows through."}
```

## Watching it fail

Start both servers again, the GraphQL one and the planner's `npm run dev`, and open the JavaScript course.
Then stop the GraphQL server with Ctrl-C, and press **Mark done** on the session of 15 October. The row
turns into *done* at once. Vite's terminal says why that cannot last:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.0 dev
> vite


  VITE v8.3.5  ready in 380 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
9:38:26 PM [vite] (client) [optimizer] scanning dependencies...
9:38:28 PM [vite] http proxy error: /graphql
Error: connect ECONNREFUSED 127.0.0.1:4000
    at TCPConnectWrap.afterConnect [as oncomplete] (node:net:1637:16)
```

The proxy could not reach the server and answered the page with a 502, and Apollo turned that into an
error for the mutation. **A moment later the row has its button back**: Apollo dropped the optimistic
layer, the cache answered as it did before the press, and `watchPlanner` drew that. The browser's console
has the planner's message, *Could not save*, with Apollo's `ServerError` and the status code.

Nobody wrote code to undo the press. The planner's own `done` changed its list, and the cache's answer,
drawn after it, put back what the server still holds. **The cache is the truth the screen returns to.**

## What the person sees

A row that flips back with no explanation is honest but unfriendly. A real app says something when it
takes a change back: a short notice near the row, *not saved, try again*. The planner only logs the
error, and lesson 11 sends what the console says to a place where somebody who runs the planner will see
it, which is the other half of the same problem.

## When not to be optimistic

An optimistic update is right when the server almost always agrees and the change is easy to take back:
marking a session done, liking a post. It is wrong when failure is common or when drawing success early
misleads: a payment, a booking against limited places, anything that sends an e-mail. There, a screen
that waits for the server and says it is waiting is the correct one.
