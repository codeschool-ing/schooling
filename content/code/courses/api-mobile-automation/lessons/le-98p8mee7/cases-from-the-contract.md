---
title: Test cases, read off the contract
version: 1
---

**Every clause of a contract is a source of test cases, and reading them off is mechanical.** The
techniques are the ones `manual-testing` taught for a form on a screen: split the inputs into
classes that should behave alike, take one value from each, and add the values on every edge. What
changes is where the rules come from. On a screen you guess them from the labels; here they are
written down, in `NewOrder`, one per line:

| clause in `NewOrder` | cases it gives |
|---|---|
| `seats: { type: integer, minimum: 1, maximum: 6 }` | 0 and 7 just outside, 1 and 6 just inside; a fraction; the number as text |
| `required: [show_id, seats]` | each field left out in turn |
| `additionalProperties: false` | a field the contract does not name |
| `type: object` | a body that is valid JSON and not an object at all |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 220\" role=\"img\" aria-label=\"A number line of seats from 0 to 7. The stretch from 1 to 6 is marked valid, answered 201; 0 and 7, just outside it, are answered 422; 1 and 6 are marked just inside. Below, four values that are not on the line: 2.5 answered 422, the text &quot;2&quot; answered 422, 2.0 answered 201 because it is the same number as 2, and an order with seats missing answered 422.\"><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">seats in one order, against the rule of 1 to 6</text><rect x=\"136\" y=\"56\" width=\"398\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"335\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">valid: 201</text><text x=\"90\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">422</text><text x=\"580\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">422</text><line x1=\"60\" y1=\"96\" x2=\"610\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></line><line x1=\"90\" y1=\"91\" x2=\"90\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"90\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0</text><line x1=\"160\" y1=\"91\" x2=\"160\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"160\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><line x1=\"230\" y1=\"91\" x2=\"230\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"230\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><line x1=\"300\" y1=\"91\" x2=\"300\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"300\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><line x1=\"370\" y1=\"91\" x2=\"370\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"370\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><line x1=\"440\" y1=\"91\" x2=\"440\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"440\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><line x1=\"510\" y1=\"91\" x2=\"510\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"510\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><line x1=\"580\" y1=\"91\" x2=\"580\" y2=\"101\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"580\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"90\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">just outside</text><text x=\"160\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">just inside</text><text x=\"510\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">just inside</text><text x=\"580\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">just outside</text><text x=\"350\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">values that are not on the line at all</text><rect x=\"30\" y=\"166\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"105\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.5</text><text x=\"105\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">422</text><rect x=\"195\" y=\"166\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"270\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">\"2\"</text><text x=\"270\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">422</text><rect x=\"360\" y=\"166\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"435\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.0</text><text x=\"435\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">201, the same number as 2</text><rect x=\"525\" y=\"166\" width=\"150\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"600\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">seats missing</text><text x=\"600\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">422</text></svg>", "caption": "The cases a range gives: the two values on each edge, and the values that are not points on the line at all."}
```

Every case has an expected answer before it is sent, and the contract gives it: a `201` for the
valid ones, a `422` for content that breaks a rule, a `400` for a body that cannot be read as an
order. A case with no expected answer is not a test, it is a look around.

## A function, to keep the requests short

Each case is the same request with a different body. A shell function saves typing it out each
time; type this once in your terminal, after the `TOKEN` of section 02:

```
ana@laptop:~/boxoffice$ order() { curl -s -w '%{http_code}\n' localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d "$1"; }
```

`order` sends its argument as the body of an order and prints the status code on the line after
the answer. It lasts until the terminal is closed. All the cases below use `sh-101`, the show with
120 seats, so none of them fails for lack of seats.

## The boundaries

```
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":0}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":1}'
{"id":"ord-1002","show_id":"sh-101","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-local-ord-1002"}
201
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":6}'
{"id":"ord-1003","show_id":"sh-101","seats":6,"total_cents":48000,"status":"confirmed","payment":"ch-local-ord-1003"}
201
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":7}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
```

`0` and `7` refused with `422`, `1` and `6` accepted. That is the rule exactly as written, on both
edges, and it is the result a tester most wants and least often gets: a limit coded as `< 6` instead
of `<= 6` shows up here and nowhere else.

## The wrong kind of value

```
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":2.5}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":"2"}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":2.0}'
{"id":"ord-1004","show_id":"sh-101","seats":2,"total_cents":16000,"status":"confirmed","payment":"ch-local-ord-1004"}
201
```

A fraction and a number written as text are refused, which is right. `2.0` is accepted, and
**that is right too**, not a defect to report: section 03 showed that `2.0` and `2` are the same JSON
number, and the contract's `integer` is a rule about the value. A report saying "boxoffice accepts
decimals" would be closed as not a defect, and it would cost the tester some credibility.

## The fields that are required

```
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101"}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"seats must be a whole number from 1 to 6"}
422
ana@laptop:~/boxoffice$ order '{"seats":2}'
{"type":"about:blank","title":"Unprocessable Entity","status":422,"detail":"there is no show undefined"}
422
```

Both refused with `422`, the code the contract lists. The second answer has a flaw of its own, in
the text: **`there is no show undefined`**. `undefined` is a word from inside JavaScript, the value
of a field that was never sent, and it has leaked into a sentence written for a person. The status
is right and a program would cope. A person reading it in an app would not know that they had
forgotten to choose a show. It is a small defect and a real one, and the fix is to check for a
missing `show_id` before looking it up.

## A field nobody asked for

```
ana@laptop:~/boxoffice$ order '{"show_id":"sh-101","seats":1,"price_cents":1}'
{"id":"ord-1005","show_id":"sh-101","seats":1,"total_cents":8000,"status":"confirmed","payment":"ch-local-ord-1005"}
201
```

The contract says `additionalProperties: false`: no field beyond the two it names. boxoffice
accepted `price_cents` without a word and created the order. Here no harm came of it, because
boxoffice ignored the field and charged the real price of 8000 cents. The danger is the client that
sent it. **A client that sends a field the server ignores believes it was obeyed**: an app that
sends `"seats_preferred": "front row"` and gets a `201` has every reason to think the front row was
booked. Refusing unknown fields with `422` turns that misunderstanding into an error somebody sees
during development. This is a disagreement between the contract and the code, and the report says
so. The team may decide the contract is the one to change, and that is a fine outcome too.

## Valid JSON that is not an order

The word `null` is a complete, valid JSON document. It is not an object, so the contract's answer
is a `400` or a `422`:

```
ana@laptop:~/boxoffice$ order 'null'
{"type":"about:blank","title":"Internal Server Error","status":500,"detail":"something broke on our side"}
500
```

**A `500`.** boxoffice crashed on a request a client could send by mistake, and its answer tells
that client the fault was on the server's side and that trying again might help, both of them
untrue. Lesson 1 called that two defects in one. The second terminal shows what happened inside:

```
TypeError: Cannot read properties of null (reading 'show_id')
    at file:///home/ana/boxoffice/boxoffice.mjs:121:49
    at Array.find (<anonymous>)
    at createOrder (file:///home/ana/boxoffice/boxoffice.mjs:121:22)
    at process.processTicksAndRejections (node:internal/process/task_queues:105:5)
POST /v1/orders 500
```

The program read `.show_id` from `null`, which JavaScript refuses. Notice what reached the client:
`something broke on our side`, and none of these lines. **The error body did not leak the stack
trace**, which is the fourth check of section 05, and it passed. The log is where the trace belongs.

## The query parameter

The contract says `date` is a `format: date`, a day written as `2026-11-08`, and lists a `400` for
a request it cannot read. A date written the way a person in Brazil might type it:

```
ana@laptop:~/boxoffice$ curl -s -w '%{http_code}\n' 'localhost:8080/v1/shows?date=8-11-2026'
{"shows":[]}
200
```

A `200` and an empty list. boxoffice does not check the format at all; it keeps the shows whose
start begins with the text sent, and no show starts with `8-11-2026`. A client with a typo is told
the theatre has nothing on that day, which is a believable answer and a wrong one.

## What the cases found

| case | contract says | boxoffice answered | verdict |
|---|---|---|---|
| 0, 1, 6, 7 seats | `422`, `201`, `201`, `422` | the same | as promised |
| 2.5 and `"2"` seats | `422` | `422` | as promised |
| `2.0` seats | `201` | `201` | as promised |
| no `seats` | `422` | `422` | as promised |
| no `show_id` | `422` | `422`, *there is no show undefined* | defect in the message |
| `price_cents` added | `422` | `201` | disagrees with the contract |
| `null` as the body | `400` or `422` | `500` | defect |
| `date=8-11-2026` | `400` | `200`, empty list | disagrees with the contract |

Four findings from twelve requests, none of them visible from any screen, and each with its
evidence in the transcript above it. Write each one up the way `manual-testing` taught: the request,
the answer, the clause of the contract it breaks, and the transcript. The contract is what makes
the third part possible. Without it, "boxoffice accepted an unknown field" is an opinion; with it,
it breaks a line of `openapi.yaml` that anybody can point at.
