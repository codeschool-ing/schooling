---
title: Status codes, read as a tester reads them
version: 1
---

**A status code is three digits, and the first one alone says who should act.** There are dozens
of codes and nobody memorises them all. What a tester needs is the first digit, a dozen codes that
turn up every week, and the habit of asking whether the code a server chose was the right one.

| class | means | who should act |
|---|---|---|
| `2xx` | it worked | nobody |
| `3xx` | look elsewhere, or use what you have | the client, following a redirect or its cache |
| `4xx` | the request is wrong | the client: sending the same request again will fail again |
| `5xx` | the server failed | the server; the same request may work later |

The line between `4xx` and `5xx` is the one that matters most. A `4xx` blames the request and a
`5xx` blames the server, so **a server that answers `500` to a malformed request has two defects**:
it crashed on bad input, and it told the client to try again when trying again cannot help.

## Making boxoffice say each one

curl can print only the code, which is how a quick check looks. `-o /dev/null` throws the body away
and `-w '%{http_code}\n'` writes the status code and a new line:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/shows
200
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/shows/sh-999
404
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/orders
401
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' -X PUT localhost:8080/v1/shows
405
```

`200` for the list, `404` for a show that does not exist, `401` for orders without a token, and
`405` for a method the list does not accept. Orders need a token, a key that says which program is
asking. Lesson 3 explains tokens; for now, this one line asks boxoffice for one and keeps it in a
variable called `TOKEN`:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

With it, an order for three seats of the small show is accepted:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":3}'
HTTP/1.1 201 Created
content-type: application/json
location: ]8;;http://localhost:8080/v1/orders/ord-1001\/v1/orders/ord-1001
]8;;\Date: Sat, 10 Oct 2026 07:13:50 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

{"id":"ord-1001","show_id":"sh-103","seats":3,"total_cents":19500,"status":"confirmed","payment":"ch-local-ord-1001"}
```

`201 Created` rather than `200`, because something new exists now, and the `location` header says
where it lives. The same request again finds one seat left, then the requests with mistakes in
them, one per line:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}'
{"type":"about:blank","title":"Conflict","status":409,"detail":"only 1 seat left"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":0}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103"'
{"type":"about:blank","title":"Bad Request","status":400,"detail":"the body is not valid JSON"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -d 'show_id=sh-103&seats=2'
{"type":"about:blank","title":"Unsupported Media Type","status":415,"detail":"send the order as application/json"}
```

Four requests, four different codes, and each one is a claim a test can check:

| code | here because | the client should |
|---|---|---|
| `409 Conflict` | the request is fine, but the state of the server forbids it: 1 seat left, 2 asked | ask for fewer, or choose another show |
| `422 Unprocessable Content` | the JSON is valid and its content breaks a rule: 0 seats | fix the value |
| `400 Bad Request` | the body is not JSON at all; the closing `}` is missing | fix the syntax |
| `415 Unsupported Media Type` | the body is a form, not JSON | send JSON, labelled as JSON |

boxoffice titles the `422` *Unprocessable Entity*, the name Node gives it; RFC 9110 renamed it
*Unprocessable Content* in 2022. The number is what a client reads, and it did not change.

Those distinctions are not pedantry. A client that gets `409` can tell the user *"only 1 seat
left"*; one that gets `400` for the same situation has nothing useful to say. **Choosing the right
code is part of the API's contract**, and lesson 2 says what a contract is.

## The codes that turn up every week

| code | meaning | where you will meet it |
|---|---|---|
| `200` OK | here is what you asked for | most GETs |
| `201` Created | something new exists, at `location` | a POST that created |
| `204` No Content | done, and nothing to send back | a DELETE |
| `304` Not Modified | what you already have is still current | section 09 |
| `400` Bad Request | the request cannot be read | malformed JSON |
| `401` Unauthorized | who are you? no valid credentials | lesson 3 |
| `403` Forbidden | I know who you are, and you may not | lesson 3 |
| `404` Not Found | nothing at that address | a wrong id |
| `405` Method Not Allowed | that verb is not accepted here | section 07 |
| `409` Conflict | the state of the server forbids it | sold out |
| `422` Unprocessable Content | readable, and breaks a rule | 0 seats |
| `429` Too Many Requests | slow down | lesson 13 |
| `500` Internal Server Error | the server broke | never on purpose |
| `502` / `504` | a server behind this one failed or did not answer | lesson 13 |
| `503` Service Unavailable | not now, try later | lesson 13 |

`401` is named *Unauthorized* and means *unauthenticated*: the server does not know who you are.
`403` means it knows, and the answer is no. The names are a historical accident everybody lives
with, and lesson 3 tests the difference.
