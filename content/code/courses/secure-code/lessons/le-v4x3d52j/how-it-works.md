---
title: A real request with somebody else's intention
version: 1
---

Lessons 10 to 13 made sure the portal knows **who** sends a request and **what** they may do. Cross-site
request forgery, **CSRF**, is the case where both answers are right and the request is still not what
the person wanted.

It rests on one browser behaviour, and the behaviour is not a bug. **A browser attaches a site's
cookies to every request it sends to that site**, whichever page caused the request. That is what
keeps you signed in when you follow a link from an e-mail into your bank. It also means that a page on
any other site, which lucia happens to have open, can make her browser send a request to the portal,
and the portal's session cookie goes with it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l09-cross\" aria-label=\"How a forged request reaches the portal. lucia's browser has two tabs: in one she is signed in to the portal, in the other she is reading a page on another site. That page contains a form addressed to the portal's change-e-mail route. When the form is submitted, the browser sends the request to the portal and attaches the portal's session cookie, because it attaches a site's cookies to every request to that site. The portal sees a valid session and a well-formed change, and cannot tell that lucia never saw the form.\"><defs><marker id=\"l09-cross-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lucia's browser</text><rect x=\"20\" y=\"34\" width=\"260\" height=\"180\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"36\" y=\"48\" width=\"228\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tab 1: the portal, signed in</text><rect x=\"36\" y=\"108\" width=\"228\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"150.0\" y=\"127.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tab 2: a page on another site</text><text x=\"150.0\" y=\"140.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">holds a form aimed at the portal</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the portal</text><rect x=\"520\" y=\"70\" width=\"170\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"605.0\" y=\"100.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">valid session</text><text x=\"605.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">well-formed change</text><text x=\"605.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\"></text><text x=\"605.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">whose intention?</text><path d=\"M264 134 L520 134\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l09-cross-ah-amber)\"></path><text x=\"392\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /account/email</text><text x=\"392\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">+ the portal's cookie, attached by the browser</text></svg>", "caption": "The browser attaches the portal's cookie to every request to the portal, whichever page started it."}
```

From the portal's side, the request is perfect: a valid session, a well-formed form, a signed-in
patient asking to change her e-mail address. **The portal cannot tell that lucia never saw the
form.** If the change goes through, the other site has chosen her e-mail address, and the next
"forgot my password" message goes to an inbox she does not own.

### What it needs, and what it does not

A forged request works when three things are true together:

1. **The action changes something** the other site benefits from: an e-mail address, a phone number,
   a password, a booking, a payment.
2. **The session travels in a cookie** the browser attaches automatically. An application that sends
   its credentials in a header its own JavaScript sets, such as `Authorization`, is not exposed in the
   same way, because another site's page cannot make the browser add that header.
3. **Every value the request needs is predictable.** The e-mail field is whatever the other site
   wants; nothing in the form is a secret.

CSRF does **not** let the other site read the answer. The browser keeps responses from one site away
from another site's scripts. It is a **write** flaw: whatever the forged request does is done, and
nobody sees the result.

### The three defences

Each defence breaks one of those three conditions, and this lesson builds all of them:

- **A token** breaks the third: every form carries a random value the portal gave its own page, and
  a request without it is refused.
- **`SameSite`** breaks the second: the browser stops attaching the cookie to requests another site
  starts.
- **An origin check** reads the `Origin` header the browser adds to the request, and refuses a change
  whose origin is not the portal's.

The first condition is a design rule rather than a defence: **a `GET` request never changes
anything.** Links, images and prefetches all send `GET`, and each one is a request the person did not
choose. Everything in this lesson protects the other methods: `POST`, `PUT`, `PATCH`, `DELETE`.
