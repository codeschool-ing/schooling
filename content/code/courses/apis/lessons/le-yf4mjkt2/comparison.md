---
title: Sessions or tokens
version: 1
---

Put side by side, the two are less different than the arguments about them suggest, and the
differences that remain point in a clear direction. The table is the lesson in one place, and the
default under it is where to start.

| | session cookie | JWT |
|---|---|---|
| ending a login | delete the row, effective at once | wait for `exp`, or keep a denylist checked on every request |
| what the server stores | a row per login | the key; plus refresh tokens and a denylist once revocation matters |
| several servers | all of them read one session store | any server with the key verifies alone |
| size on every request | 43 characters here | 240 characters here, and growing with every claim |
| reading the contents | nothing to read: the id is random | anyone holding the token reads the payload |
| other domains and services | a cookie stays with its host | a header goes wherever the client sends it |
| clients that are not browsers | possible, but cookies are a browser's habit | natural: one header |
| CSRF | exposed, so `SameSite` and a CSRF token | not exposed, while it travels in a header |
| XSS | `HttpOnly` keeps the id out of reach | exposed wherever a script can read it |
| a leak of the server's storage | hashed ids are useless | a leaked key signs tokens for anybody |

The two sizes are this lesson's own tokens, ana's session id and her access token:

```
ana@api:~/shelf$ awk '$6 == "sid" {printf "%s", $7}' kept.txt | wc -c
43
ana@api:~/shelf$ jq -j .access_token login.json | wc -c
240
```

Each claim added to the token, a name, a role, a list of permissions, makes every request longer.
And a token holding permissions carries a copy of them, which keeps saying the old thing until `exp`
after the real ones change.

## The default

**For a browser application talking to its own API, use a session cookie.** It is revoked by deleting
a row, it keeps nothing readable in the browser, and the lookup it costs is one indexed read, which is
cheap next to everything else a request does. Every language of the back-end track has a well-worn
library for it.

**Reach for signed tokens when the request crosses a boundary**: between your own services, where a
service can verify a token without calling back to the one that issued it; across domains, where a
cookie does not follow; and for clients that are not browsers. Keep the lifetime short, pin the
algorithm, require the claims, and add refresh with rotation when users must stay signed in.

And when the user signs in somewhere else entirely, with a Google or a Microsoft account, or an app
acts on the user's behalf with their consent, the tokens are issued by somebody else and the rules
for them have a name. **Lesson 9 is OAuth 2.0 and OpenID Connect**, where the JWT returns as the ID
token and every check in this lesson applies to it.
