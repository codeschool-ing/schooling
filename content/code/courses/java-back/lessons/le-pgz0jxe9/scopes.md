---
title: Scopes and authorities, and the difference between 401 and 403
version: 1
---

An **authority** is Spring Security's word for one thing a signed-in user may do, and it is only a
string. `SecurityConfig` gives ana `orders` and the clerk `orders` and `catalogue:write`;
`TokenController` copies them into the token's `scope` claim. On every later request the bearer
filter checks the token's signature and expiry, and then turns each word of `scope` into an authority
with the prefix `SCOPE_`. Ana's token becomes `SCOPE_orders`, and the rules in `apiChain` are written
against those names:

| request | rule | who passes |
|---|---|---|
| `GET /books`, `GET /books/**` | `permitAll()` | everybody, with no token at all |
| `POST /books` | `hasAuthority("SCOPE_catalogue:write")` | the clerk |
| `/orders`, `/orders/**` | `hasAuthority("SCOPE_orders")` | ana and the clerk |
| anything else | `authenticated()` | anybody with a valid token |

**The rules are read from the top, and the first one that matches decides.** A general rule above a
narrow one would hide it, which is why `anyRequest()` comes last; Spring refuses to start if anything
is written after it.

## Four answers

Here is the table at work. The clerk's token is fetched the same way as ana's, and its payload carries
both scopes:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/books/1
200
ana@vm:~/bookshop$ curl -si localhost:8080/orders/1
HTTP/1.1 401 
WWW-Authenticate: Bearer resource_metadata="http://localhost:8080/.well-known/oauth-protected-resource"
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Length: 0
Date: Thu, 22 Oct 2026 22:14:05 GMT

ana@vm:~/bookshop$ curl -s -u clerk:clerk-adds-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > clerk.token
ana@vm:~/bookshop$ cut -d. -f2 clerk.token | basenc -d --base64url; echo
{"iss":"bookshop","sub":"clerk","exp":1792708145,"iat":1792707245,"scope":"catalogue:write orders"}
ana@vm:~/bookshop$ curl -si -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
HTTP/1.1 403 
WWW-Authenticate: Bearer error="insufficient_scope", error_description="The request requires higher privileges than provided by the access token.", error_uri="https://tools.ietf.org/html/rfc6750#section-3.1"
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Length: 0
Date: Thu, 22 Oct 2026 22:14:06 GMT

ana@vm:~/bookshop$ curl -s -w '\n' -H "Authorization: Bearer $(cat clerk.token)" -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
{"id":7,"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}
```

A public book needs no token at all: 200. An order asked for with no token gets **401**, and its
`WWW-Authenticate: Bearer` says which kind of credential would do; `resource_metadata` is the
address of the document the metadata filter serves, which this course does not use. Ana's token is
valid, so the server knows who is asking, and the rule for `POST /books` asks for an authority she
does not have: **403**, with `insufficient_scope` in the header. The clerk's identical request is
accepted, and the book comes back with its new id, 7.

**Both refusals have an empty body**, not the problem detail of lesson 7. They are written by
`ExceptionTranslationFilter` inside the chain, and `ApiErrorHandler` belongs to Spring MVC, which
these requests never reached. An API that wants `application/problem+json` here gives the chain its
own `AuthenticationEntryPoint` and `AccessDeniedHandler`; the bookshop keeps Spring's defaults.

## The authority that is left out

Spring Security 7 adds something to every authentication that the user list never mentions. The token
controller filters it out. As a detour, delete the line with `FACTOR_` in `TokenController`, rebuild
and restart, and ask for a token; put the line back afterwards:

```
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' | cut -d. -f2 | basenc -d --base64url; echo
{"iss":"bookshop","sub":"ana","exp":1792708226,"iat":1792707326,"scope":"FACTOR_PASSWORD orders"}basenc: invalid input
```

**`FACTOR_PASSWORD`.** Spring Security 7 records, beside a user's authorities, how the user proved who
they are: one `FACTOR_` authority per factor, so that a rule can ask for two of them, such as a
password and a one-time code. On the request to `/auth/token` that is true and useful. In the token
it would be wrong. The `scope` claim says what the holder may do, and how ana signed in is a fact
about one earlier request. Copied into the token it would become the authority
`SCOPE_FACTOR_PASSWORD` on every request for fifteen minutes: a word that reads like a permission,
that no rule checks, and that a rule written as `hasAuthority("FACTOR_PASSWORD")` would never match,
because of the prefix. So `TokenController` drops whatever starts with `FACTOR_`.
