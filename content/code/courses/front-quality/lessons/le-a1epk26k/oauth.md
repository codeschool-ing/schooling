---
title: OAuth 2.0, when somebody else checks the password
version: 1
---

**OAuth 2.0 lets an app act for a person without ever seeing that person's password**: the person
signs in at a provider they already trust, and the provider gives the app a token saying what it may
do. "Sign in with" buttons are this, with OpenID Connect on top, and the planner could add one without
storing a single password of its own.

*Nothing in this section was run against a real provider.* Every provider needs an account, a
registered app and a public address to send people back to, none of which a course can hand out, and
each has its own console that changes more often than this page would. What follows is the protocol
itself, from RFC 6749 and the current security advice for it, RFC 9700, published in January 2025;
the provider's own documentation says where each value goes on its side.

## The flow a browser app uses

A single-page app is a **public client**: its code is delivered to every visitor, so it cannot keep a
secret, and any "client secret" in it is printed in the page's JavaScript for anybody to read. The flow
for a public client is the **authorization code flow with PKCE**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l05-oauth\" aria-label=\"A sequence diagram with three lifelines: the planner in the browser, the identity provider, and the planner's API. 1: the planner makes a random code verifier and sends the browser to the provider's authorize address with its client id, its redirect address, a random state and the SHA-256 of the verifier, the code challenge. 2: the person signs in at the provider and agrees. 3: the provider sends the browser back to the redirect address with a one-time code and the same state. 4: the planner checks the state is the one it sent, and posts the code and the verifier to the provider's token address. 5: the provider checks that the SHA-256 of the verifier is the challenge it was given, and answers with an access token and, with OpenID Connect, an ID token. 6: the planner calls its API with the access token in the Authorization header.\"><defs><marker id=\"l05-oauth-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-oauth-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the planner, in the browser</text><path d=\"M110 42 L110 315\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"280\" y=\"12\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"370.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the identity provider</text><path d=\"M370 42 L370 315\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"520\" y=\"12\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"27.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">the planner's API</text><path d=\"M610 42 L610 315\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M110 70 L370 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-paper-dim)\"></path><text x=\"240.0\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">1  /authorize?…&amp;state&amp;code_challenge</text><text x=\"380\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">2  the person signs in, and agrees</text><path d=\"M370 150 L110 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-paper-dim)\"></path><text x=\"240.0\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">3  back to redirect_uri?code=…&amp;state=…</text><path d=\"M110 190 L370 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-paper-dim)\"></path><text x=\"240.0\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">4  POST /token: code + code_verifier</text><path d=\"M370 230 L110 230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-paper-dim)\"></path><text x=\"240.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">5  access token (and an ID token)</text><path d=\"M110 270 L610 270\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-oauth-ah-amber)\"></path><text x=\"360.0\" y=\"261\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">6  Authorization: Bearer &lt;access token&gt;</text><text x=\"118\" y=\"302\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">the verifier never travelled until step 4</text></svg>", "caption": "The authorization code flow with PKCE. A code stolen at step 3 is worthless without the verifier, which stayed in the planner until the code was exchanged."}
```

Three values in it do the defending, and each answers one attack:

- **`redirect_uri` must match exactly** what was registered with the provider. Otherwise the code in
  step 3 could be sent to an address of somebody else's choosing.
- **`state`** is a random value the planner makes, keeps, and checks when the browser comes back. A
  response whose `state` the planner did not send is one it did not ask for, and it is dropped: that
  stops another site from starting a sign-in in your name.
- **The PKCE pair** makes the code useless to anybody who intercepts it, which is the next section.

## What not to use

Two older flows are still in tutorials. **The implicit flow** returned the access token straight in
the address, in step 3, where it lands in browser history and server logs; RFC 9700 says not to use
it. **The password grant** has the app collect the person's password and send it on, which is the one
thing OAuth exists to avoid; RFC 9700 forbids it. If a library offers either, it is out of date.

## Where the token goes after step 5

The provider's answer is a token, and the app has to keep it somewhere and send it with requests to
its API. That decision is the subject of lesson 6, and the arrangement it recommends for a browser app
keeps the token off the page altogether.
