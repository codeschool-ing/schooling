---
title: Errors are part of the contract
version: 1
---

**An error response is an answer like any other, and a client is written against its shape.** The
belief to drop is that errors are the unplanned part of an API, where anything goes as long as the
status code is right. An app that tells a user *"only 1 seat left"* is reading the body of a `409`;
if one endpoint puts the message in `detail` and another in `message`, the app shows an empty box
for one of them.

boxoffice answers every error in one shape, the one RFC 9457 defines under the name **problem
details**. Three errors from three different parts of the API:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows/sh-999
{"type":"about:blank","title":"Not Found","status":404,"detail":"there is no show sh-999"}
ana@laptop:~/boxoffice$ curl -s -X PUT localhost:8080/v1/shows
{"type":"about:blank","title":"Method Not Allowed","status":405,"detail":"PUT is not allowed here"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"no bearer token"}
```

A missing show, a wrong method, a missing token: three causes, and the same four fields every time.

| field | holds | read by |
|---|---|---|
| `type` | a URI naming the kind of problem; `about:blank` means "nothing more than the status code" | programs, to tell problems apart |
| `title` | a short summary of that kind, the same every time it happens | people |
| `status` | the status code again, inside the body | anything that only kept the body, a log for instance |
| `detail` | what went wrong with **this** request | people |

The RFC allows a fifth, `instance`, naming the occurrence, and any further field an API wants to
add; boxoffice uses neither. The split between `type` and `detail` is the one a tester cares about:
**a program branches on `status` and `type`, and never on the wording of `detail`.** boxoffice's
`type` is always `about:blank`, so here the status code is all a client can branch on. An API with
two kinds of `422` worth telling apart would give each a `type` of its own, and a test would check
the `type` rather than parse an English sentence that somebody will one day reword.

## The label on the body

A problem is labelled `application/problem+json`, not `application/json`. curl's `-w` can print the
label without the body:

```
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' localhost:8080/v1/shows/sh-999
404 application/problem+json
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code} %{content_type}\n' localhost:8080/v1/orders
401 application/problem+json
```

The label is part of the contract, and it catches tests out. **A test that checks the content type
starts with `application/json` fails on every error boxoffice gives**, and a client that parses
only bodies labelled exactly `application/json` ignores them. The body is still JSON; the `+json`
at the end of the label says so, and a check should accept it.

## The exception, and why it is allowed

One part of boxoffice does not use problem details. The token endpoint answers its errors in the
shape OAuth 2.0 prescribes for exactly that endpoint (RFC 6749, §5.2):

```
ana@laptop:~/boxoffice$ curl -s -w '%{http_code} %{content_type}\n' localhost:8080/oauth/token -d grant_type=password
{"error":"unsupported_grant_type"}
400 application/json
```

`{"error":"unsupported_grant_type"}` with `application/json`. This is not a defect: every OAuth
client library expects that shape from a token endpoint, and a problem document there would break
them. What would be a defect is the contract not saying so, which is why `openapi.yaml` gives the
token endpoint its own error response, `OAuthError`, apart from `Problem`. **Two shapes are fine; an
undocumented second shape is not**, because a client author finds it only when their code fails on
it.

## What to test in an error

For any error a test provokes, four checks, in this order:

1. the status code is the one the contract lists for that cause;
2. the content type is the one the contract names, `application/problem+json` here;
3. the body has the fields the contract requires, with `status` equal to the status code;
4. the body says nothing it should not: no stack trace, no file path, no SQL.

The fourth has nothing to do with shape and everything to do with what an error leaks. `detail`
is written for people, and a careless server puts its exception in it. Section 06 makes boxoffice
throw one, and it is worth checking what came back.
