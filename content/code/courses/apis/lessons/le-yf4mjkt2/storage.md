---
title: Where a browser should keep it
version: 1
---

A session id and a JWT are both **bearer credentials**: whoever presents one is treated as its
owner, with no further question. Neither is tied to a device or to the person who logged in. So the
real question about storing one is not where it is convenient, but **who else can read it there**.

The usual advice for single-page applications was to put the token in `localStorage`, on the
reasoning that other sites cannot read it. That half is true: storage belongs to one origin. What it
leaves out is that every script running inside your page can read it. That includes a script an
attacker managed to inject, the attack called cross-site scripting or XSS, and any third-party
library your page loads that somebody has tampered with. Lesson 13 is about keeping such scripts out. This
section is about how much they get when they do get in.

| where | page scripts can read it | sent by the browser on its own | what an injected script can do |
|---|---|---|---|
| cookie with `HttpOnly` | no | yes, so it needs the defences against CSRF | act as the user while the page is open; it cannot copy the credential out |
| `localStorage` | yes | no | read the token and send it anywhere, to be used later from another machine |
| a variable in the page's memory | yes, with effort | no | the same, but the token is gone when the tab closes |

**`HttpOnly` is the one place a page's own scripts cannot reach.** The jar in the section on sessions
recorded the flag as `#HttpOnly_localhost`; a browser enforces it, and `document.cookie` simply does
not list such a cookie. An injected script can still send requests while the user has the page open,
and the cookie rides along. That is bad. It is bounded, though: it stops when the tab closes, and
the credential never leaves the browser, where `localStorage` hands it over to be used from anywhere
until it expires.

Three habits follow:

- **For a browser application talking to its own API, keep the credential in an `HttpOnly`,
  `Secure`, `SameSite` cookie**, and defend the cookie against CSRF as `sessions.py` does. This holds
  whether the cookie carries a session id or a JWT.
- **Never put a token in a URL.** Addresses end up in server logs, browser history and the `Referer`
  header of the next request, all places nobody treats as secret.
- **A native mobile app is not a browser.** It has no cookies to steal through a page and no XSS in
  the same sense, and it keeps tokens in the system's protected store, the iOS Keychain or Android's
  Keystore, rather than in a file.
