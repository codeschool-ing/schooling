---
title: The same-origin policy, which CORS relaxes
version: 1
---

**A page's scripts may read responses only from the page's own origin, and an origin is three things
together: the scheme, the host and the port.** That rule is the same-origin policy, every browser has
enforced it since the 1990s, and it is the reason a page you open cannot quietly read your e-mail from
another tab's site with your cookies attached.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" data-fig=\"l07-origin\" aria-label=\"The address http://localhost:5173/api/plan?week=43 split into its parts. The scheme http, the host localhost and the port 5173 are bracketed together as the origin. The path /api/plan and the query ?week=43 are outside the bracket: they do not change the origin. Below, the API's address http://localhost:3000 has the same scheme and host and a different port, so it is a different origin.\"><rect x=\"60\" y=\"50\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">http://</text><text x=\"90.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">scheme</text><rect x=\"126\" y=\"50\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"171.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost</text><text x=\"171.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">host</text><rect x=\"222\" y=\"50\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"252.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:5173</text><text x=\"252.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">port</text><rect x=\"288\" y=\"50\" width=\"100\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"338.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">/api/plan</text><text x=\"338.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">path</text><rect x=\"394\" y=\"50\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"439.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">?week=43</text><text x=\"439.0\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">query</text><path d=\"M60 38 L60 30 L282 30 L282 38\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"171.0\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">the origin: all three must match</text><text x=\"386.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">not part of the origin</text><rect x=\"60\" y=\"140\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">http://</text><rect x=\"126\" y=\"140\" width=\"90\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"171.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost</text><rect x=\"222\" y=\"140\" width=\"60\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"252.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">:3000</text><text x=\"298\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">another origin: only the port differs</text></svg>", "caption": "Two addresses on one computer, and two origins. The browser compares the three parts as written, so a port, a scheme or a spelling of the host makes a stranger."}
```

The planner's page is served from `http://localhost:5173`. Measured against it:

| address | same origin? | because |
|---|---|---|
| `http://localhost:5173/api/plan` | yes | scheme, host and port all match |
| `http://localhost:3000/api/plan` | **no** | the port differs |
| `https://localhost:5173/` | no | the scheme differs |
| `http://127.0.0.1:5173/` | no | the host is written differently, and the browser compares the words, not the machine |
| `http://planner.localhost:5173/` | no | another host |

**The second row is the one every front-end developer meets.** The app on one port, the API on
another, both on your own computer, and the browser treats them as strangers.

## What the policy blocks, and what it does not

The policy is about **reading**. A page may still send requests to anywhere: a form may post to
another site, an `<img>` may load from another site, a script tag may run code from another site. What
the page's scripts may not do is read the answer to a request they made to another origin, unless that
origin says they may. That permission, given by the server in response headers, is **CORS**,
cross-origin resource sharing. It is a way for a server to relax the policy for origins it names, and
nothing else: **CORS never makes anything more secure than the same-origin policy already did.**
