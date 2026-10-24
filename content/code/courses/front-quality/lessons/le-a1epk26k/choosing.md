---
title: Session or token, for an app like this one
version: 1
---

**For a browser app that talks to its own server, a session in an `HttpOnly` cookie is the simpler
and the safer default.** That runs against a lot of tutorials, which reach for a JWT in `localStorage`
first, so here is the comparison the choice rests on:

| | session id in a cookie | JWT carried by the page |
|---|---|---|
| what the browser holds | a random id that means nothing alone | the claims themselves, readable by anybody holding it |
| can a script on the page read it | not with `HttpOnly`, which is the point | yes, wherever the page keeps it |
| signing out, or blocking an account | delete one entry; it stops working at once | it works until `exp`, unless every server keeps a deny list |
| sent with requests | automatically, by the browser, to the site that set it | by your code, in an `Authorization` header |
| many servers checking it | they need a shared store | each checks the signature alone |
| the attack to defend against | another site making the browser send it (CSRF, lesson 9) | a script on the page reading it (XSS, lesson 9) |

**The last row decides most cases.** A cookie the browser sends on its own invites requests that
another site starts, and `SameSite` and lesson 9's checks shut that door. A token the page holds is
exactly as safe as the page is free of injected scripts, and lesson 9 shows how one stray `innerHTML`
lets text become a script. A cookie marked `HttpOnly` cannot be read by any script at all, however it
got there.

## Where tokens are right

Tokens earn their place where the server cannot be one process with one memory: several services,
each checking requests on its own, or an API called by apps that are not browsers. They are also what
OAuth hands back, which is the next section. In those cases, keep the access token short-lived and
out of storage a script can read, and lesson 6 shows the arrangement that does both, a small server
of the app's own holding the tokens while the browser holds only a cookie.
