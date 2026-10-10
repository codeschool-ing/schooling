---
title: Tokens, and the endpoint that hands them out
version: 1
---

**A token is a short-lived credential that a program gets by presenting a long-lived one.** The
program proves who it is once, to a token endpoint, and receives a string that stands in for that
proof until it expires. Every later request carries the token, never the original secret. If a
token leaks, it is useful for minutes; if the secret leaked on every request, it would be useful
until somebody noticed.

boxoffice's orders work that way, using the OAuth 2.0 **client credentials** grant, the one meant
for a program acting on its own behalf with no person involved: a test suite, a nightly job, another
server. The program sends three form fields to `POST /oauth/token`: the grant type, its
`client_id` and its `client_secret`. boxoffice knows two clients, and lesson 1's one-liner used the
first:

| client | secret | scope |
|---|---|---|
| `ci-tests` | `ci-secret` | `orders:read orders:write` |
| `auditor` | `auditor-secret` | `orders:read` |

## The response, line by line

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret
HTTP/1.1 200 OK
content-type: application/json
cache-control: no-store
Date: Sat, 10 Oct 2026 19:43:07 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"access_token":"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjaS10ZXN0cyIsInNjb3BlIjoib3JkZXJzOnJlYWQgb3JkZXJzOndyaXRlIiwiaWF0IjoxNzkxNjYxMzg3LCJleHAiOjE3OTE2NjIyODd9.ZYNygARAi8VHK-A59GydT_uT2q6wG8ebDb8D67_sJQU","token_type":"Bearer","expires_in":900,"scope":"orders:read orders:write"}
```

The body has four fields, and each is something to check:

| field | says | what to test |
|---|---|---|
| `access_token` | the token itself, a long string section 04 takes apart | that it is accepted where it should be and nowhere else |
| `token_type` | how to send it: `Bearer` means in the `Authorization` header, as `Bearer <token>` | that it says `Bearer` |
| `expires_in` | how many seconds it lives, 900 here, a quarter of an hour | that it really stops working then; section 04 does |
| `scope` | what the token is allowed to do | that a token with less scope is refused the rest; section 05 does |

One header matters as much as the body. **`cache-control: no-store` forbids any cache from keeping
the response**, so no proxy between the program and the server holds a copy of a live token for the
next person to receive. OAuth requires it on this endpoint (RFC 6749, §5.1), and a token
response without it is a defect even when every field in the body is right. The same section also
asks for `Pragma: no-cache`, the HTTP/1.0 spelling of the same instruction, and boxoffice does not
send it; it only matters to caches old enough to ignore `cache-control`, and a report can call it
minor.

`expires_in` is relative: "900 seconds from now". A client works out when to fetch a new token from
the moment it received this one, which is why a well-behaved client asks again a little before the
time is up rather than waiting for a refusal.

## A wrong secret

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=wrong
{"error":"invalid_client"}
```

`invalid_client`, in OAuth's own error shape, which lesson 2 section 05 explained. The answer is the
same whether the client exists and the secret is wrong or the client does not exist at all, for the
same reason the staff key's refusals were the same in section 02.

## Keeping it in a variable

The token is long, so it goes in a shell variable, the way lesson 1 did, and the rest of the lesson
uses `$TOKEN`:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

`$(…)` runs the command inside and puts what it printed in its place; `jq -r .access_token` prints
the token without quotes. The variable lives until the terminal is closed. A token lasts fifteen
minutes, so if a request later in this lesson answers `token expired`, run this line again.
