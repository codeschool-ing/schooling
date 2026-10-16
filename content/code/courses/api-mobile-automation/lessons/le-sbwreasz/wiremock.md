---
title: WireMock, stand-ins described in files
version: 1
---

**WireMock is a stand-in server whose answers are written as data rather than code.** Each answer is
a *mapping*, a JSON file that says which requests it matches and what to send back. WireMock reads a
directory of them, answers what matches, records everything it receives, and tells you in detail
when a request matched nothing. It is written in Java and is free and open source, under the Apache
licence. It runs as a library inside a Java test, as the REST Assured tests of lesson 7 could use
it, or as a server on its own, which is how this section runs it.

## Two mappings

The stub of section 03 changed its answer when you told it to. WireMock can also choose its answer
from the request itself, and two mappings are enough to show it: charges approved, unless the amount
is over R$ 400,00. Make the directory with `mkdir -p ~/boxoffice/wiremock/mappings`. The first mapping
approves; save it as `wiremock/mappings/charge-approved.json`:

```json
{
  "priority": 5,
  "request": {
    "method": "POST",
    "url": "/charges",
    "headers": { "Content-Type": { "contains": "application/json" } },
    "bodyPatterns": [{ "matchesJsonPath": "$.amount_cents" }]
  },
  "response": {
    "status": 201,
    "headers": { "Content-Type": "application/json" },
    "jsonBody": { "id": "ch-wm-1", "status": "approved" }
  }
}
```

The second declines the large ones; save it as `wiremock/mappings/charge-declined.json`:

```json
{
  "priority": 1,
  "request": {
    "method": "POST",
    "url": "/charges",
    "bodyPatterns": [{ "matchesJsonPath": "$[?(@.amount_cents > 40000)]" }]
  },
  "response": {
    "status": 201,
    "headers": { "Content-Type": "application/json" },
    "jsonBody": { "id": "ch-wm-2", "status": "declined" }
  }
}
```

A mapping has a `request`, which is a pattern, and a `response`, which is what to send. Read the
patterns line by line:

| field | in these files | matches |
|---|---|---|
| `method`, `url` | `POST`, `/charges` | exactly that method and path; `urlPath` would ignore a query string |
| `headers` | `Content-Type` contains `application/json` | a header by name, in any case, compared by `equalTo`, `contains`, `matches` and others |
| `bodyPatterns` | `matchesJsonPath` | a body in which that JSONPath finds something: a field that exists, or a filter that holds |
| `priority` | 1 and 5 | when two mappings match, **the lower number wins** |

The order of six seats of sh-101, 48000 cents, matches both files. Priority 1 picks the decline, and
without it WireMock would choose by its own rule, the mapping added most recently, which is not a
rule you want a test to depend on.

## Starting it

WireMock runs on the Java 21 that lesson 7 installed. Download the standalone jar, the whole server
in one file, from Maven Central. curl's `-f` makes a refused download fail loudly instead of saving
an error page under the jar's name:

```
ana@laptop:~/boxoffice$ curl -fsSL -o wiremock/wiremock-standalone-3.13.2.jar https://repo1.maven.org/maven2/org/wiremock/wiremock-standalone/3.13.2/wiremock-standalone-3.13.2.jar
ana@laptop:~/boxoffice$ ls -lh wiremock/*.jar
-rw-r--r-- 1 ana ana 19M Oct 10 16:52 wiremock/wiremock-standalone-3.13.2.jar
```

Start it in a terminal of its own. `--root-dir` names the directory that holds `mappings`, and
`--disable-banner` leaves out the large logo it prints otherwise:

```
ana@laptop:~/boxoffice$ java -jar wiremock/wiremock-standalone-3.13.2.jar --port 8091 --root-dir wiremock --disable-banner

The WireMock server is started .....
version:                      3.13.2
port:                         8091
enable-browser-proxying:      false
disable-banner:               true
no-request-journal:           false
verbose:                      false

extensions:                   response-template,webhook
```

From another terminal, a charge of R$ 160,00 and one of R$ 480,00:

```
ana@laptop:~/boxoffice$ curl -si localhost:8091/charges -H 'content-type: application/json' -d '{"amount_cents":16000,"reference":"ord-1001"}'
HTTP/1.1 201 Created
Content-Type: application/json
Matched-Stub-Id: d43d7556-9f26-49ab-9b6b-13ab3823ba2c
Transfer-Encoding: chunked

{"id":"ch-wm-1","status":"approved"}
ana@laptop:~/boxoffice$ curl -s localhost:8091/charges -H 'content-type: application/json' -d '{"amount_cents":48000,"reference":"ord-1002"}'; echo
{"id":"ch-wm-2","status":"declined"}
```

`Matched-Stub-Id` names the mapping that answered, an id WireMock gave each file when it read the
directory, so yours will differ. The second charge came back declined: the filter held, and
priority 1 won.

## A request that matches nothing

**This is where WireMock pays for itself.** A hand-written stub that receives a request it was not
written for usually answers something unhelpful, or answers as if everything were fine. WireMock
answers `404` and says which mapping came closest and why it was refused. Send a charge the way a
client with a small bug would, with the amount in a field called `amount`:

```
ana@laptop:~/boxoffice$ curl -si localhost:8091/charges -H 'content-type: application/json' -d '{"amount":16000,"reference":"ord-1003"}'
HTTP/1.1 404 Not Found
Content-Type: text/plain;charset=UTF-8
Transfer-Encoding: chunked


                                               Request was not matched
                                               =======================

-----------------------------------------------------------------------------------------------------------------------
| Closest stub                                             | Request                                                  |
-----------------------------------------------------------------------------------------------------------------------
                                                           |
POST                                                       | POST
/charges                                                   | /charges
                                                           |
$[?(@.amount_cents > 40000)]                               | {"amount":16000,"reference":"ord-1003"}             <<<<< Body does not match
                                                           |
-----------------------------------------------------------------------------------------------------------------------
```

The left column is the closest mapping, the right column is the request, and the line with `<<<<<`
is the difference. WireMock picked the declining mapping as the closest because it has fewer
conditions to fail, and both mappings refused the body for the same reason: neither JSONPath finds
an `amount_cents`. When a test fails because the stand-in "did not answer", this report is the first
thing to read, and it usually turns the problem into a one-word fix.

## boxoffice, pointed at WireMock

Empty the journal of what curl sent, so what follows is only boxoffice's. The journal is WireMock's
record of every request it received:

```
ana@laptop:~/boxoffice$ curl -s -X DELETE localhost:8091/__admin/requests; echo
{}
```

Stop boxoffice with Ctrl-C and start it again with the new address:

```
ana@laptop:~/boxoffice$ PAYMENTS_URL=http://localhost:8091 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Your token from section 03 still works, though boxoffice restarted: a token is checked by its
signature and its expiry, and nothing about it was kept in the memory the restart wiped. Order two seats, then six:

```
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":2}'
{"id":"ord-1001","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-wm-1"}
ana@laptop:~/boxoffice$ curl -s localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":6}'
{"type":"about:blank","title":"Payment Required","status":402,"detail":"the payment was declined"}
```

`201` with `ch-wm-1` from the first mapping, and `402` from the second.

## Asking what it received

**A stand-in that records is a spy, and WireMock's admin API is how a test reads the record.** Every
admin address starts with `/__admin`. `requests/count` counts the requests that match a pattern
written in the same language as a mapping's `request`, and `requests` returns the journal itself,
newest first:

```
ana@laptop:~/boxoffice$ curl -s localhost:8091/__admin/requests/count -d '{"method":"POST","url":"/charges"}'; echo
{
  "count" : 2,
  "requestJournalDisabled" : false
}
ana@laptop:~/boxoffice$ curl -s localhost:8091/__admin/requests | jq -c '.requests[].request | {key: .headers["idempotency-key"], body}'
{"key":"ord-1002","body":"{\"amount_cents\":48000,\"reference\":\"ord-1002\"}"}
{"key":"ord-1001","body":"{\"amount_cents\":16000,\"reference\":\"ord-1001\"}"}
```

Two charges, the amounts a test would expect, and the idempotency key boxoffice sent with each. A
test that asserts "boxoffice charged 48000 for six seats" is now one request, and that assertion
cannot be made against a real provider at all.
