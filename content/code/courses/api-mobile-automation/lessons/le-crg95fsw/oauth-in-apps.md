---
title: OAuth in an app, which boxoffice does not have
version: 1
---

**An app on a phone cannot keep a secret, so it signs people in without one: the authorization code
flow with PKCE.** boxoffice implements only client credentials, the grant for programs, and nothing
in this section can be run against it. The section is here because lessons 14 to 22 test apps, and
every app that signs a person in with an account from somewhere else uses this flow. What follows is
the sequence and what a tester checks at each step.

The wrong picture is an app holding a `client_secret` the way `ci-tests` does. Anything shipped
inside an app can be pulled out of it: an Android package is a zip file, and the strings in it can
be listed in minutes. A secret in an app is a secret every user has a copy of. So the app is a
**public client**, it has an id and no secret, and it proves itself a different way, one login at a
time.

## The sequence

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 382\" role=\"img\" aria-label=\"A sequence between four parties: the app, the browser, the authorization server and the API. 1, the app makes a verifier, keeps it, and computes the challenge as its SHA-256. 2, the app opens the sign-in page in the browser, which sends the challenge, the state and the redirect_uri to the authorization server. 3, the person signs in. 4, the authorization server sends a code and the state back through the browser to the app. 5, the app sends the code and the verifier to the authorization server. 6, the server checks that the SHA-256 of the verifier equals the challenge, and answers with a token. 7, the app calls the API with Authorization: Bearer and the token.\"><defs><marker id=\"f03pkce-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the app</text><line x1=\"90\" y1=\"48\" x2=\"90\" y2=\"372\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"200\" y=\"14\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the browser</text><line x1=\"270\" y1=\"48\" x2=\"270\" y2=\"372\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"380\" y=\"14\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"450\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">authorization server</text><line x1=\"450\" y1=\"48\" x2=\"450\" y2=\"372\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><rect x=\"550\" y=\"14\" width=\"140\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the API</text><line x1=\"620\" y1=\"48\" x2=\"620\" y2=\"372\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></line><text x=\"98\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">1 a verifier, kept</text><text x=\"98\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">challenge = its SHA-256</text><line x1=\"92\" y1=\"112\" x2=\"268\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"180\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">2 open sign-in page</text><line x1=\"272\" y1=\"112\" x2=\"448\" y2=\"112\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"360\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">challenge, state, redirect_uri</text><text x=\"458\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">3 the person signs in</text><line x1=\"448\" y1=\"188\" x2=\"272\" y2=\"188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"360\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">4 code, state</text><line x1=\"268\" y1=\"188\" x2=\"92\" y2=\"188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"180\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">back to the app</text><line x1=\"92\" y1=\"234\" x2=\"448\" y2=\"234\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"100\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">5 code + verifier</text><text x=\"458\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">6 SHA-256 of the verifier</text><text x=\"458\" y=\"279\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">= the challenge?</text><line x1=\"448\" y1=\"302\" x2=\"92\" y2=\"302\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"100\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">token</text><line x1=\"92\" y1=\"340\" x2=\"618\" y2=\"340\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03pkce-ah)\"></line><text x=\"100\" y=\"331\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">7 Authorization: Bearer …</text></svg>", "caption": "The challenge travels through the browser; the verifier goes only from the app to the server, so an intercepted code is useless on its own."}
```

1. The app makes up a random string, the **code verifier**, and keeps it to itself. It computes the
   **code challenge**, the SHA-256 of the verifier in base64url.
2. It opens the system browser at the authorization server's sign-in page, sending its client id,
   the address to come back to (`redirect_uri`), a random `state`, and the challenge.
3. The person signs in and agrees, on the authorization server's own page; the app never sees the
   password.
4. The browser is sent back to the app's `redirect_uri` with a short-lived **authorization code** and
   the same `state`.
5. The app sends the code and the **verifier** to the token endpoint.
6. The server hashes the verifier, compares it with the challenge from step 2, and only if they match
   answers with a token. The app then calls the API with it, as `Bearer`, exactly as in section 05.

The trick is in steps 2 and 5. The challenge travelled through the browser, where other apps on the
phone might see it; the verifier never did. A thief who intercepts the code in step 4 does not have
the verifier, and the code alone buys nothing.

## Making a challenge

Steps 1 and 2 need nothing but Node, and seeing them makes the rest concrete. A verifier of 32
random bytes, in base64url, and its challenge:

```
ana@laptop:~/boxoffice$ VERIFIER=$(node -e 'console.log(require("crypto").randomBytes(32).toString("base64url"))')
ana@laptop:~/boxoffice$ echo "$VERIFIER"
HQlLaW4Kfn7xX4jhuZdsF6xQp-ppHCrVmd1ZjpL8ayg
ana@laptop:~/boxoffice$ node -e 'console.log(require("crypto").createHash("sha256").update(process.argv[1]).digest("base64url"))' "$VERIFIER"
k9BLhA-dAVMkLd_DRFx53uZKZrZgF_KtvnGNjYrX0Zs
```

The verifier is 43 characters, the shortest RFC 7636 allows, and is different on every run. The
challenge is what a hash always is: the same input gives the same output, and nothing about the
output gives the input back. Run the last line twice and it prints the same challenge; run the first
line again and everything changes.

## What a tester checks

None of this was run for this course, because boxoffice has no authorization server. Each item is a
request you can make against one that does, with the expected answer a refusal:

| check | how | expected |
|---|---|---|
| the code is used once | exchange the same code twice | the second exchange refused, `invalid_grant` |
| the verifier must match | exchange a code with a different verifier | refused, `invalid_grant` |
| the challenge is required | start the flow with no `code_challenge` | refused, if the server demands PKCE |
| `redirect_uri` matches exactly | ask for a code with an address one character different | refused, and no redirect to it |
| `state` is checked | return to the app with a `state` it did not send | the app ignores the response |
| no secret in the app | search the built app for anything named like a secret | nothing found |

The last two are tests of the app, not of the server, and they belong to the second half of this
course. The rest are tests of somebody else's authorization server, which a team rarely writes
itself. What a team does own is the configuration, the list of allowed `redirect_uri` values and the
lifetimes, and that is where these checks find something.
