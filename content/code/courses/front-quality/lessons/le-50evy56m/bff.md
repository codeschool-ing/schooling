---
title: When there are tokens, keep them off the page
version: 1
---

**An app that signs people in through OAuth receives tokens, and the safest place for a token is
somewhere the page's scripts cannot reach at all: a small server of the app's own.** The pattern has a
name, **backend for frontend**, BFF, and the current IETF guidance for browser apps, *OAuth 2.0 for
Browser-Based Applications*, puts it first among the arrangements it describes.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-bff\" aria-label=\"Three boxes from left to right. The browser, running the planner's page, holds only an HttpOnly, Secure session cookie, and no script on the page can read it. It sends every request, with the cookie, to the BFF, a small server of the app's own. The BFF holds the access token and the refresh token, and attaches the access token to each request it passes on to the API. The identity provider sits above the BFF, which talks to it to exchange the code and to refresh tokens. A dashed line marks the boundary of what a script on the page can reach: only the browser box.\"><defs><marker id=\"l06-bff-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"92\" width=\"196\" height=\"126\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></rect><text x=\"110\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">what a script on the page can reach</text><text x=\"110\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the browser</text><rect x=\"26\" y=\"122\" width=\"168\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the planner's page</text><text x=\"110.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">holds: __Host-sid cookie</text><text x=\"390\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the BFF</text><rect x=\"300\" y=\"122\" width=\"180\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the app's own server</text><text x=\"390.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">holds: access token,</text><text x=\"390.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">refresh token</text><text x=\"630\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the API</text><rect x=\"570\" y=\"122\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">checks the</text><text x=\"630.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">access token</text><rect x=\"300\" y=\"14\" width=\"180\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the identity provider</text><path d=\"M194 157 L300 157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-bff-ah-paper-dim)\"></path><text x=\"247\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">request + cookie</text><path d=\"M480 157 L570 157\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-bff-ah-paper-dim)\"></path><text x=\"525\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8\" fill=\"var(--paper-dim)\">request + access token</text><path d=\"M450 122 L450 48\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-bff-ah-paper-dim)\" marker-start=\"url(#l06-bff-ah-paper-dim)\"></path><text x=\"458\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">code, refresh</text></svg>", "caption": "The tokens live on a server; the browser holds a cookie that means nothing to any script. A script on the page can still send requests while it runs, but it leaves with nothing."}
```

The BFF does steps 4 and 5 of lesson 5's flow on the server: it receives the code, exchanges it with
the verifier, and keeps the access token and the refresh token. The browser gets what it got in this
lesson, an `HttpOnly`, `Secure`, `__Host-` session cookie. Each request from the page goes to the BFF
with that cookie, and the BFF attaches the access token on the way to the API. **A script on the page
can make requests through the BFF while it runs, and cannot take the tokens away with it**, which is
the difference between a bad afternoon and a stolen account.

## When the page has to hold one

Some apps cannot have a server of their own in front of their API. The guidance for those is a set of
limits, each of which narrows what a stolen token is worth:

- **Keep the access token in memory**, in a variable, never in `localStorage` or `sessionStorage`. A
  reload loses it, and the app gets a new one.
- **Make it short-lived**: minutes, not hours. The provider sets this, and asking for less is allowed.
- **Rotate the refresh token.** Each time the app uses a refresh token to get a new access token, the
  provider issues a new refresh token too and refuses the old one from then on. A refresh token stolen
  and used twice shows the provider that two parties hold it, and it ends the whole family.
- **Bind tokens to the browser that got them** where the provider supports it, with DPoP (RFC 9449): a
  key pair made in the browser, and every request signed with it, so a token copied elsewhere is
  useless without the key.

None of these is as strong as the BFF, because each assumes that a script on the page will one day run
there and asks only how much it can take. That is the right assumption, and lesson 9 is about making it
less likely.

## The planner's own arrangement

The planner has no OAuth, so it needs no BFF: its own server is the one that checks the password and
holds the login, and the browser holds a cookie that means nothing to any script. **That is the
arrangement every one of the stronger ones is trying to get back to.** The tests of this lesson hold it
in place: one in the browser, that the cookie is not readable; three on the server, that it is marked
correctly, that signing out ends it, and that it ends on its own.
