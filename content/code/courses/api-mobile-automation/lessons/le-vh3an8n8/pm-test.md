---
title: pm.test, and what an assertion says
version: 1
---

**A test is a name and a function, and it fails when the function throws.** That is the whole
mechanism. `pm.test('status is 200', fn)` runs `fn`. If nothing inside it complains, Newman prints
`Pass  status is 200`; if something does, it prints a number and lists the failure at the end.
Everything else in a Postman test is a way of complaining clearly.

It helps to drop one belief early: a script that runs without error is not a passing test. Lines
outside any `pm.test` run too, and an assertion there that fails breaks the whole script with no name
on it. **Every check goes inside a `pm.test`**, so that each one passes or fails on its own and says
which it was.

## One script, piece by piece

The script on **List shows** has three tests, and between them they use most of what this lesson
needs:

```schooling-example
{"language": "js", "file": "List shows: Post-response", "parts": [{"code": "pm.test('status is 200', () => {\n  pm.response.to.have.status(200);\n});", "note": "A test is a name and a function. If the function throws, the test fails under that name; if it returns, it passes."}, {"code": "pm.test('the body is JSON', () => {\n  pm.response.to.have.header('content-type', 'application/json');\n});", "note": "With a second argument, `have.header` compares the value too. Without it, the header only has to exist."}, {"code": "pm.test('every show has a whole number of seats left', () => {\n  const { shows } = pm.response.json();", "note": "`pm.response.json()` parses the body. A body that is not JSON throws here, which fails this test and no other."}, {"code": "  pm.expect(shows).to.be.an('array').that.is.not.empty;", "note": "`pm.expect` is Chai's `expect`. Some words are only there to be read, such as `to`, `be`, `that` and `is`; `an('array')`, `not` and `empty` are what check."}, {"code": "  shows.forEach((show) => pm.expect(show.seats_left).to.be.a('number').and.satisfy(Number.isInteger));\n});", "note": "One test, many checks: the first show that fails stops the function, and the message says which value it was."}]}
```

Three objects carry it all:

| object | what it is | used for |
|---|---|---|
| `pm.response` | the answer to this request | `.code`, `.headers.get(name)`, `.json()`, `.text()`, `.responseTime` |
| `pm.response.to` | assertions about the answer, Postman's own | `.have.status(201)`, `.have.header(name)`, `.have.header(name, value)` |
| `pm.expect(value)` | Chai's assertions about any value | `.to.equal(x)`, `.to.eql(obj)`, `.to.be.a('string')`, `.to.have.lengthOf(3)`, `.to.include(x)` |

`equal` and `eql` are the pair to keep apart. **`equal` asks whether two things are the same value**,
which works for strings and numbers and fails for two objects that merely look alike. **`eql` asks
whether they have the same contents**, field by field. `pm.expect({a: 1}).to.equal({a: 1})` fails;
the same line with `eql` passes.

## What a failure tells you

A good test name is the claim, written so that a failure reads as a sentence. The run in section 02
failed one test. At the bottom of its output Newman wrote the name, `HEAD answers like GET`, and
under it `expected response to have status code 200 but got 405`.

Together those two lines are a complete defect report: what was claimed,
what was expected, what came back. Compare a test named `test 3` with `pm.expect(pm.response.code ===
200).to.be.true`, which fails with *expected false to be true* and tells nobody anything. **Assert on
the value itself, not on a comparison you made first**, and Chai writes the message for you.

Two more habits, both visible in the collection. Name the test after what a reader would check, not
after the code: *location says where it lives*, not *header test*. And keep the claims of one
request in separate tests, so that one failure does not hide the next. **Create order** checks the
status, the body and `location` in three tests, so when the status is wrong you still learn whether
`location` was there.
