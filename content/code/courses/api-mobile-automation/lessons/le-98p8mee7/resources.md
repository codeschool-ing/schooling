---
title: Resources, addresses, and a request that stands alone
version: 1
---

**REST is a way of laying out an API: every thing the API knows about is a resource, every
resource has an address, and the methods of HTTP are the only verbs.** It is a style, described by
Roy Fielding in 2000, and not a standard anybody certifies. Most APIs that call themselves REST
follow part of it, and that part is the one a tester meets every day: nouns in the path, verbs in
the method.

A common first picture is an API as a list of functions with odd names, `getShows`,
`createOrder`, `cancelOrder`. boxoffice has no such names anywhere. It has things, and you act on
them with the method:

| address | what it is | methods |
|---|---|---|
| `/v1/shows` | the **collection** of shows | `GET` |
| `/v1/shows/sh-103` | one show, an **item** of that collection | `GET` |
| `/v1/orders` | the collection of orders | `POST` adds one |
| `/v1/orders/ord-1001` | one order | `GET` reads it, `DELETE` cancels it |

The `v1` at the front is the version of the API. A change that would break existing clients
goes under `/v2/`, and the old address keeps answering for the clients nobody can update, such as
an app on a phone that was never upgraded.

## A collection, and a filter on it

A `GET` to a collection lists its items. jq can pull one field out of each, which is the quickest
way to see what a collection holds:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/shows | jq '.shows[].id'
"sh-101"
"sh-102"
"sh-103"
```

The query string narrows a collection without changing what the address names. `?date=` keeps the
shows of one day:

```
ana@laptop:~/boxoffice$ curl -s 'localhost:8080/v1/shows?date=2026-11-07' | jq -c '.shows[] | {id, starts_at}'
{"id":"sh-102","starts_at":"2026-11-07T20:00:00-03:00"}
```

The path says *which* resource; the query says *which part of it*. A tester treats each query
parameter as an input of its own, with valid values, invalid ones and a boundary, and section 06
comes back to this one.

## Creating, and being told where

Ordering takes a token, the same one lesson 1 fetched. Lesson 3 explains it; for now, ask for one
again:

```
ana@laptop:~/boxoffice$ TOKEN=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
```

A `POST` to the collection creates an item, and the server chooses its address. Only the status
line and the `location` header matter here, so `grep` keeps those two:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}' | grep -iE '^HTTP|^location'
HTTP/1.1 201 Created
location: /v1/orders/ord-1001
```

The new order is a resource in its own right now, at the address the server named.

## Every request carries everything

**A REST server keeps no memory of the conversation between requests.** That property is called
statelessness, and the wrong picture of it is a website you log in to once, after which every page
knows who you are. boxoffice knows who you are only for the length of one request, and only
because that request said so:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1001 -H "authorization: Bearer $TOKEN"
{"id":"ord-1001","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-local-ord-1001"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders/ord-1001
{"type":"about:blank","title":"Unauthorized","status":401,"detail":"no bearer token"}
```

The same address, one request after the other, from the same terminal. The first request carried the token and
got the order; the second did not, and boxoffice had no idea it had just answered the same client.
Nothing about the first request survived into the second.

**This is what makes an API test possible on its own.** Every request holds the whole question,
so it can be sent by any program, in any order, any number of times, and its answer depends only on
what it says and on the data the server holds, never on which request came before it. A test of
`GET /v1/orders/ord-1001` needs a token and an order to exist; it does not need a sequence of
screens replayed to reach the right state.

The data is the half that can still bite. The order above exists because an earlier request
created it, so a test that reads it depends on that earlier request having run. Lesson 12 is about
what goes wrong when tests share data that way, and how to stop it.
