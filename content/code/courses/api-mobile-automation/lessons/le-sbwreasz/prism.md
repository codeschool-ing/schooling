---
title: Prism, a stand-in made from the contract
version: 1
---

**Prism reads an OpenAPI document and answers as the API it describes.** Nobody writes a mapping.
Every path, parameter and status code in `openapi.yaml` from lesson 2 becomes something Prism
answers, with bodies built from the schemas and their examples. It also checks every request against
the contract and refuses one that breaks it, saying exactly how. Prism is made by Stoplight, free
and open source, and runs on Node.

Who uses this is worth saying first, because it is not boxoffice's tester. **A mock of boxoffice
serves the people who call boxoffice.** The team building the Tickets app of lesson 14 can work
against Prism before boxoffice exists, or while it is down, or when they need an answer boxoffice
will not give on demand. The tester's interest is in what such a mock can and cannot promise them.

## Which Prism

Prism comes from npm, and its newest releases no longer run on the Node 22 this course uses. npm
can show what each version asks for:

```
ana@laptop:~/boxoffice$ npm view @stoplight/prism-cli@5.15.11 engines
{ node: '>=24.14.0' }
ana@laptop:~/boxoffice$ npm view @stoplight/prism-cli@5.14.2 engines
{ node: '>=18.20.1' }
```

So the course pins 5.14.2, the newest stable release that accepts Node 22. If you installed Node 24,
a newer Prism will do and should behave the same for this section. `npx --yes` downloads a pinned version
the first time and runs it, without adding it to the project.

## Starting it

Stop nothing: boxoffice stays on 8080, and Prism listens on 4010. In a terminal of its own, from
`~/boxoffice`:

```sh
npx --yes @stoplight/prism-cli@5.14.2 mock openapi.yaml
```

It prints one line for each operation it found in the contract, eight of them, and then
`Prism is listening on http://127.0.0.1:4010`. After that it prints a few lines for every request it
handles, saying what it checked and which response it chose. Those lines are worth reading when an
answer surprises you. They are not shown here, because Prism marks each one with symbols the
course's transcripts cannot draw.

## What it answers

The list of shows:

```
ana@laptop:~/boxoffice$ curl -s localhost:4010/v1/shows | jq
{
  "shows": [
    {
      "id": "sh-103",
      "title": "string",
      "starts_at": "2026-11-08T18:00:00-03:00",
      "price_cents": 0,
      "seats_left": 0
    }
  ]
}
```

**The shape is right and the content is invented.** One show, because the schema says `shows` is an
array and Prism makes the smallest one. The id and the date are the `example` values written in the
contract. The title is the word `string` and the numbers are `0`, because nothing better was written
down. An order:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'authorization: Bearer anything' -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}'; echo
HTTP/1.1 201 Created
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: *
Access-Control-Allow-Credentials: true
Access-Control-Expose-Headers: *
location: /v1/orders/ord-1001
Content-type: application/json
Content-Length: 102
Date: Sat, 10 Oct 2026 19:52:40 GMT
Connection: keep-alive
Keep-Alive: timeout=5

{"id":"ord-1001","show_id":"string","seats":1,"total_cents":0,"status":"confirmed","payment":"string"}
```

`201`, the `location` header from the contract's example, and an order for **one** seat of a show
called `string`, though the request asked for two of sh-103. Prism does not read the request to
build the answer. It builds the answer from the schema.

## What it cannot know

A mock made from a contract knows only what the contract says, and two answers make the limit
plain:

```
ana@laptop:~/boxoffice$ curl -s localhost:4010/v1/shows/sh-999; echo
{"id":"sh-103","title":"string","starts_at":"2026-11-08T18:00:00-03:00","price_cents":0,"seats_left":0}
ana@laptop:~/boxoffice$ curl -s localhost:4010/oauth/token -d grant_type=client_credentials -d client_id=nobody -d client_secret=wrong; echo
{"access_token":"string","token_type":"Bearer","expires_in":0,"scope":"orders:read orders:write"}
```

**sh-999 exists, and a client called `nobody` with a wrong secret gets a token.** The contract says
what a show and a token look like; it does not list the shows or the clients, so Prism has nothing
to refuse with. Nothing in a mock like this remembers either: no seat is ever sold, sh-103 never runs
out, and the same order can be placed forever. An app tested only against it has never seen `409
only 1 seat left`.

## What it checks

**The other half of Prism is a validator, and it is strict.** Seven seats, where the contract says at
most six:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'authorization: Bearer anything' -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":7}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 422 Unprocessable Entity
sl-violations: [{"location":["request","body","seats"],"severity":"Error","code":"maximum","message":"Request body property seats must be <= 6"}]
```

`422`, and the reason in a header of Prism's own, `sl-violations`: where in the request, which rule,
and the message. Without the `authorization` header:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 401 Unauthorized
sl-violations: [{"location":["request"],"severity":"Error","code":401,"message":"Invalid security scheme used"}]
```

`401`, because the contract puts `/v1/orders` behind the `oauth` scheme. Prism checks that a token is
there and in the right place; it cannot check that the token is good, since `Bearer anything` passed
above.

## Where the mock and boxoffice disagree

Two requests get different answers from the mock and from the real boxoffice, and **in both, the mock
is the one that follows the contract**. Lesson 2 found both disagreements by reading the contract
case by case; here they turn up on their own, the first time anybody calls the mock. A field nobody
declared:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'authorization: Bearer anything' -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2,"seat_class":"vip"}' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 422 Unprocessable Entity
sl-violations: [{"location":["request","body"],"severity":"Error","code":"additionalProperties","message":"Request body must NOT have additional properties; found 'seat_class'"}]
ana@laptop:~/boxoffice$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-103","seats":2,"seat_class":"vip"}'
201
```

Prism refuses `seat_class`, because the contract's `NewOrder` says `additionalProperties: false`;
boxoffice creates the order. A client team developing against Prism meets the stricter of the two,
so this disagreement would surprise nobody in production. It only hides that the real server lets
mistakes through. A date that is not a date:

```
ana@laptop:~/boxoffice$ curl -si 'localhost:4010/v1/shows?date=tomorrow' | grep -iE '^HTTP|^sl-violations'
HTTP/1.1 400 Bad Request
sl-violations: [{"location":["request","query","date"],"severity":"Error","code":"format","message":"Request query parameter date must match format \"date\""}]
ana@laptop:~/boxoffice$ curl -s 'localhost:8080/v1/shows?date=tomorrow'
{"shows":[]}
```

The contract declares `date` as `format: date` and lists a `400` for the list of shows, and Prism
answers it. boxoffice never checks the format: it answers `200` with an empty list, so a client that
sent `tomorrow` instead of `2026-11-07` is told there are no shows that day. **This one bites in
production**: an app built against Prism shows an error message for a malformed date that boxoffice
will never send. Either the code learns to refuse, or the contract stops promising. A tester's
report says which side disagreed and leaves the choice to whoever owns the contract.

## Choosing the answer

A client team needs the error answers too, and Prism gives one on request with the `Prefer` header:

```
ana@laptop:~/boxoffice$ curl -si localhost:4010/v1/orders -H 'authorization: Bearer anything' -H 'content-type: application/json' -H 'Prefer: code=409' -d '{"show_id":"sh-103","seats":2}' | head -1
HTTP/1.1 409 Conflict
```

Any status the contract lists for that operation can be asked for this way: `402`, `502`, `504`.
That is how an app's error screens get built before the server can produce any of them. Stop Prism
with Ctrl-C when you are done: section 06 starts it again, on the same port, in a different role.
