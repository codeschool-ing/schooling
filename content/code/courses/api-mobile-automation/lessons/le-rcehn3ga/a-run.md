---
title: A run, read line by line
version: 1
---

**A Newman run prints three things in order: every request with its tests, a table that counts
them, and the failures in detail.** The first part is for following a run as it happens, the table
is for knowing at a glance whether anything went wrong, and the last part is where you find out
what. With boxoffice running in its terminal:

```
ana@laptop:~/boxoffice$ npm run test:api

> boxoffice@1.0.0 test:api
> newman run postman/boxoffice.postman_collection.json -e postman/lab.postman_environment.json --disable-unicode

newman

boxoffice

Folder shows
Sub-folder List shows
  POST http://localhost:8080/oauth/token [200 OK, 479B, 39ms]
  GET http://localhost:8080/v1/shows [200 OK, 569B, 4ms]
  Pass  status is 200
  Pass  the body is JSON
  Pass  every show has a whole number of seats left

Sub-folder One show
  GET http://localhost:8080/v1/shows/sh-103 [200 OK, 312B, 4ms]
  Pass  status is 200
  Pass  it is the show asked for
  Pass  it carries an etag

Sub-folder HEAD one show
  HEAD http://localhost:8080/v1/shows/sh-103 [405 Method Not Allowed, 171B, 5ms]
  1. HEAD answers like GET

Folder auth
Sub-folder Get token
  POST http://localhost:8080/oauth/token [200 OK, 479B, 5ms]
  Pass  status is 200
  Pass  a bearer token comes back
  Pass  nobody may keep a copy of it

Folder orders
Sub-folder Create order
  POST http://localhost:8080/v1/orders [201 Created, 316B, 3ms]
  Pass  status is 201
  Pass  the order is for the show and the seat asked for
  Pass  location says where it lives

Sub-folder Read order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 3ms]
  Pass  status is 200
  Pass  it is the order just created

Sub-folder Cancel order
  DELETE http://localhost:8080/v1/orders/ord-1001 [204 No Content, 111B, 3ms]
  Pass  status is 204

Sub-folder Read cancelled order
  GET http://localhost:8080/v1/orders/ord-1001 [200 OK, 280B, 4ms]
  Pass  the order now says cancelled

Folder seat rules
Sub-folder Order seats
  POST http://localhost:8080/v1/orders [201 Created, 316B, 4ms]
  Pass  seats 1 answers 201

----------------------------------------------------------------
|                         |         executed |          failed |
--------------------------+------------------+------------------
|              iterations |                1 |               0 |
--------------------------+------------------+------------------
|                requests |               10 |               0 |
--------------------------+------------------+------------------
|            test-scripts |                9 |               0 |
--------------------------+------------------+------------------
|      prerequest-scripts |               11 |               0 |
--------------------------+------------------+------------------
|              assertions |               18 |               1 |
----------------------------------------------------------------
| total run duration: 309ms                                    |
----------------------------------------------------------------
| total data received: 1.55kB (approx)                         |
----------------------------------------------------------------
| average response time: 7ms [min: 3ms, max: 39ms, s.d.: 10ms] |
----------------------------------------------------------------

  #  failure         detail                                                
                                                                           
 1.  AssertionError  HEAD answers like GET                                 
                     expected response to have status code 200 but got 405 
                     at assertion:0 in test-script                         
                     inside "shows / HEAD one show"                        
```

## The requests

The two lines starting with `>` come from npm, not Newman: the script's name and the command it
runs. Then Newman names the collection and walks it in the order of the file, as lesson 4 section 06
said it would. Each request is one line of facts, such as the `GET` under **List shows**: the method,
the address after the variables were replaced, and in brackets the status, the size of the response
and how long it took. A line above it with no request of its own, the `POST` to
`/oauth/token` under **List shows**, is the collection's pre-request script fetching a token, which
lesson 5 section 05 explained. Under each request come its tests: `Pass` and the name, or a number
and the name for a failure.

## The table

| row | counts | here |
|---|---|---|
| `iterations` | passes through the whole collection; more than one only with a data file | 1 |
| `requests` | every request sent, including the one from `pm.sendRequest` | 10 |
| `test-scripts` | post-response scripts that ran | 9 |
| `prerequest-scripts` | pre-request scripts that ran: the collection's before each of 9 requests, plus 2 of the requests' own | 11 |
| `assertions` | `pm.test` calls, which is what people mean by tests | 18, 1 failed |

**The `failed` column of `requests` counts requests that could not be sent at all**, a refused
connection or a broken address, not requests that got an error status. A `405` is an answer, so
**HEAD one show** counts as a request that worked and an assertion that failed. A table with zeroes in
every `failed` cell except `assertions` says the server answered everything and disagreed with the
tests somewhere; a non-zero `requests` row says something more basic is wrong, such as boxoffice not
running.

The three lines under the table are timings and a size. `total run duration` is the whole run, and
`average response time` is over the requests, with the fastest, the slowest and the standard deviation
beside it. They change on every run and on every machine, so they belong in a report and not in an
assertion.

## The failures

The last block repeats each failed assertion with what Newman knows about it: the kind of error, the
test's name, the message, and where it happened, `inside "shows / HEAD one show"`, as folder and
request. This block is what you read first when a run fails, and what a pipeline's log shows at its
end, which is where people look.
