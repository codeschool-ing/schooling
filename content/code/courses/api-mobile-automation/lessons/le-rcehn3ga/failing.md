---
title: Failing, and the number a pipeline reads
version: 1
---

**Newman's exit code is the whole interface between a run and whatever started it.** A program that
ends with 0 succeeded and anything else failed, by a convention every shell and every pipeline obeys.
Newman exits 1 when any assertion fails or any request could not be sent, and 0 otherwise. The
pretty table is for you; the number is for the machine.

## Seeing the number

`> /dev/null` throws away what the run prints, and `$?` is the exit code of the command before it:

```
ana@laptop:~/boxoffice$ npm run test:api > /dev/null; echo "exit code $?"
exit code 1
ana@laptop:~/boxoffice$ npm run test:api -- --folder orders > /dev/null; echo "exit code $?"
exit code 0
```

The whole collection exits 1, because **HEAD one show** fails. The `orders` folder alone exits 0,
because every test in it passes. The second line is worth a moment: it is how a folder of tests that
are known to pass can gate something while another folder carries a known defect. This course keeps
one run and lets it fail, because hiding a real defect from the pipeline is exactly what a pipeline
is there to prevent.

**A run with no tests exits 0.** Lesson 4's collection had no scripts, so every one of its requests
could have answered `401` and the run would still have counted zero failures: nothing asserted
anything. A green pipeline says only that the tests that exist passed, and a collection without tests
has none.

## Stopping at the first failure

`--bail` ends the run at the first failure instead of finishing it. Its terminal output carries a
character the course's transcripts cannot show. So this run writes the JSON report of section 05
instead, and jq lists the requests that were actually sent:

```
ana@laptop:~/boxoffice$ npm run test:api -- --bail --reporters json --reporter-json-export results/bail.json > /dev/null; echo "exit code $?"
exit code 1
ana@laptop:~/boxoffice$ jq -r '.run.executions[].item.name' results/bail.json
List shows
List shows
One show
HEAD one show
```

The run stopped after **HEAD one show**, the third request, and never reached the token or the
orders. `List shows` appears twice because the collection's pre-request script sent its token request
from inside it. Stopping early is useful when the first failure makes the rest meaningless, as in
lesson 5 section 02, where a missing token turned one failure into ten. It is wrong as a habit: a run
that stops early hides every failure after the first, and the second may be the one that matters.
**Leave `--bail` out of the pipeline.**

## Reading one failure

A failure is read the way lesson 1 read a response: what was asked, what was expected, what came
back. For the one this collection always has:

| part | says |
|---|---|
| `AssertionError` | an assertion failed, as opposed to a script that crashed |
| `HEAD answers like GET` | the claim, the test's name |
| `expected response to have status code 200 but got 405` | the evidence |
| `inside "shows / HEAD one show"` | where: folder, then request |

A `TypeError` or a `JSONError` in that first column means the script broke before it could judge
anything, usually because the answer was not the shape it expected. Those are worth reading twice:
the test did not say the API was wrong, it said the test could not tell.
