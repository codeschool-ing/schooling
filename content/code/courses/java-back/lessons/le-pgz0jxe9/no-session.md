---
title: No session, no recall, and why CSRF is off
version: 1
---

The first transcript of this lesson came back with a `JSESSIONID` cookie. That is Spring Security's
default: after one successful sign-in it keeps the user in an `HttpSession` on the server, and the
cookie is how the browser finds it again. Both of the bookshop's chains say
`SessionCreationPolicy.STATELESS` instead, so Spring Security neither creates a session nor reads
one. The headers of a token request show it:

```
ana@vm:~/bookshop$ curl -s -D - -o /dev/null -u ana:ana-reads-books -X POST localhost:8080/auth/token
HTTP/1.1 200 
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Type: application/json
Content-Length: 298
Date: Thu, 22 Oct 2026 22:48:31 GMT
```

No `Set-Cookie`. The client gets nothing to send back except the token itself, and every request
proves itself again. That has a consequence beyond tidiness: a second instance of the bookshop
accepts a token the first one signed, as long as both hold the same secret.

## What the server does not remember

**The server keeps no record of the tokens it hands out.** It checks a signature and a date, and that
is all. Expiry is therefore the one way a token stops working on its own. To watch it happen without
waiting fifteen minutes, start the application with a two-second lifetime. A property given on the
command line wins over the file (lesson 4):

```sh
java -jar target/bookshop-0.1.0.jar --bookshop.jwt.lifetime=2s
```

```
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > ana.token
ana@vm:~/bookshop$ cut -d. -f2 ana.token | basenc -d --base64url; echo
{"iss":"bookshop","sub":"ana","exp":1792709320,"iat":1792709318,"scope":"orders"}
ana@vm:~/bookshop$ sleep 5; curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat ana.token)" localhost:8080/books/1
200
ana@vm:~/bookshop$ sleep 60; curl -si -H "Authorization: Bearer $(cat ana.token)" localhost:8080/books/1 | head -2
HTTP/1.1 401 
WWW-Authenticate: Bearer error="invalid_token", error_description="An error occurred while attempting to decode the Jwt: Jwt expired at 2026-10-22T22:48:40Z", error_uri="https://tools.ietf.org/html/rfc6750#section-3.1", resource_metadata="http://localhost:8080/.well-known/oauth-protected-resource"
```

The payload says `exp` is two seconds after `iat`, and five seconds later the token still worked.
Spring Security's decoder allows **60 seconds of clock skew** past `exp` by default, because the
machine that issues a token and the machine that checks it rarely agree to the second. A minute
later it was refused, with the moment it expired in the header. The book is public, and the answer
was still 401: **a token that fails its check is refused wherever it is sent**, even where no token is
needed, because the bearer filter checks any token it is given before the rules are read.

The other side of the same fact: **a JWT cannot be revoked.** A token copied
off somebody's machine is good until its `exp`, and nothing the server holds can be crossed out,
because the server holds nothing. Signing out, with tokens like these, means the client throws its
copy away. Three defences exist, and each one costs something:

- a **short lifetime**, which is why the bookshop's is fifteen minutes and not a week; the price is
  that the client asks again more often;
- **a new secret**, which ends every token at once, everybody's;
- a **list of revoked tokens**, checked on every request, usually by a `jti` claim that gives each
  token an id. It works, and it brings back the state on the server that the token was meant to
  remove.

## CSRF, and the condition for turning it off

Both chains call `csrf.disable()`, and that reads like a weakness. It is right here for one reason,
which is worth knowing exactly, because the reason can stop being true.

**Cross-site request forgery** uses a habit of browsers: they attach a site's cookies to every request
to that site, including a request that a page on another site triggers. If a cookie signed ana in to
the bookshop, a hostile page she visited could submit a hidden form to `/orders`, and her browser
would send it with her cookie attached. Spring Security's defence is a **CSRF token**, a value the
bookshop's own pages would have to send back and that another site cannot read.

Nothing in this bookshop authenticates with a cookie. The token travels in an `Authorization`
header, which a browser never adds on its own, so a forged request from another site arrives with no
credentials and gets 401. **The day a cookie authenticates anything** (a login form backed by a
session, or the JWT moved into a cookie to keep it away from JavaScript) **CSRF protection goes back
on.**
