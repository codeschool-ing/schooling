---
title: What each one costs
version: 1
---

**On your own computer the two servers are both instant, which is exactly why measuring them there
tells you nothing.** Every request in the planner travels a few centimetres. A phone on a mobile
network waits a tenth of a second or more for each round trip before a single byte comes back, and
the difference between the two ways of rendering is a count of those round trips.

`look.ts --slow` makes the browser wait 300 milliseconds longer for every request, which is what
Chromium's developer tools call **latency**: the time before the first byte, not the speed of the
download. Both servers are still running from the previous sections, the preview on port 4173 and
`server.ts` on 3000. Start the preview again in a third terminal if you stopped it.

## Client-rendered, slowed down

```
ana@dev:~/planner$ node tools/look.ts http://localhost:4173/ --slow
requests: / /assets/index-Dv4jVJdV.js /assets/index-1yLCgpWc.css /courses.json
first contentful paint: 948 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
```

## Server-rendered, slowed down

```
ana@dev:~/planner$ node tools/look.ts http://localhost:3000/ --slow
requests: / /assets/index-Dv4jVJdV.js /assets/index-1yLCgpWc.css /courses.json
first contentful paint: 640 ms
text on the screen:
Study planner
HTML and CSS · 2 sessions
JavaScript · 2 sessions
Git · 2 sessions
Weeks
Week of 2026-10-19: 210 min, 105 done
Week of 2026-10-26: 40 min, 0 done
```

**The server-rendered page painted first, and the reason is in the request list, not in the
servers.** Both made the same four requests. The client-rendered page could not paint before the
HTML, then the script, then the data had come back, one after the other, because each was only
discovered when the one before it arrived. The server-rendered page painted as soon as the HTML
and its stylesheet were there, and the script and the data arrived afterwards, with nothing
waiting on them. **948 milliseconds against 640 is about three waits of 300 against two**, plus the
few milliseconds the work itself took.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two request waterfalls with 300 milliseconds added to every request. Client-side: the HTML, then the script and stylesheet, then the data, three waits in a row, and the first paint at 948 milliseconds. Server-side: the HTML, then the stylesheet, and the first paint at 640 milliseconds, while the script and the data arrive after it.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">client-side</text><rect x=\"150.0\" y=\"46\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/</text><rect x=\"305.0\" y=\"69\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"311.0\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">index-….js</text><rect x=\"305.0\" y=\"92\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"311.0\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">index-….css</text><rect x=\"460.0\" y=\"115\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"466.0\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/courses.json</text><line x1=\"624.0\" y1=\"40\" x2=\"624.0\" y2=\"135\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></line><text x=\"618.0\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">paint 948 ms</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">server-side</text><rect x=\"150.0\" y=\"176\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/</text><rect x=\"305.0\" y=\"199\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"311.0\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">index-….css</text><rect x=\"305.0\" y=\"222\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"311.0\" y=\"231\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">index-….js</text><rect x=\"460.0\" y=\"245\" width=\"146.0\" height=\"18\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"466.0\" y=\"254\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">/courses.json</text><line x1=\"470.0\" y1=\"170\" x2=\"470.0\" y2=\"268\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></line><text x=\"476.0\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">paint 640 ms</text></svg>", "caption": "Both pages made the same requests. Only the client-rendered one had to wait for the third before it could draw. The bars are drawn 300 ms long; the two paints are the measured ones."}
```

The numbers are this machine's, on this day. On yours they will differ by tens of milliseconds;
what will not differ is that the client-rendered paint waits for one more round trip, and that a
real data request from a real database adds its own time to that trip.

## The server's half of the bill

Server rendering moved work, it did not remove it. `curl` can say how long a server took before
its first byte, which it calls `time_starttransfer`:

```
ana@dev:~/planner$ for i in 1 2 3; do curl -s -o /dev/null -w '%{time_starttransfer}\n' http://localhost:3000/; done
0.002319
0.001859
0.001862
```

About two milliseconds, for three courses read from a file on a fast disk. **What grows is not
this number but how often it is paid**: once per page view, by your server, where a
client-rendered page cost the server nothing beyond handing out a file. A page that needs a slow
database query to render makes every first view wait for that query before the first byte, which
is the one moment where client rendering can paint something, a spinner or an empty frame, sooner.

## The summary

| | first paint waits for | the server does per view | a crawler sees | a cache can keep the page |
|---|---|---|---|---|
| client-side | the HTML, the script and the data, in turn | hands out files | an empty page | yes, the same files for everybody |
| server-side | the HTML and its stylesheet | renders the page | the page | only if it is the same for everybody |
| hybrid | the HTML and its stylesheet | renders the first page | the page | as server-side |
| build time (lesson 3) | the HTML and its stylesheet | hands out files | the page | yes |
