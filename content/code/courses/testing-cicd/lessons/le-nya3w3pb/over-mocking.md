---
title: When doubles test the wrong thing
version: 1
---

Doubles make tests fast and focused. Used everywhere, they make tests that check nothing a user
would care about. Three failures recur, and each has a symptom you can spot in review.

## The test mirrors the implementation

Imagine a test of `place` written with mocks for everything, asserting every call in order: `add`
called with the email and cents, then `send` called with the subject and body. Now somebody changes
`place` to store and send inside a transaction helper, `with orders.saving(...)`, with the same
result for the customer. The test fails, because the calls changed, although nothing a customer
sees did.

**Symptom: the test breaks on a refactoring that kept the behaviour.** A test should fail when the
behaviour is wrong and pass when it is right, and a test that restates the code line by line fails
on both kinds of change. `shipquote`'s `test_orders.py` asserts one call, the e-mail, because the
e-mail *is* behaviour. It does not assert how the order was stored; the fake's state answers that.

## The double drifts from the real thing

Section 06 showed a plain mock passing after `send` became `deliver`, and section 10 showed a stub
passing after `cents` became `price_cents`. **Symptom: the double was written by hand, from memory,
and nothing ties it to the real collaborator.** The cures are the two shown: build mocks from the
real class with `create_autospec`, and check stubs against the real service with contract tests.

## Everything is a double, so nothing is tested

A test that replaces the database, the carrier, the mailer *and* the pricing function, then
asserts that the handler called them, tests the order of four function calls. If every collaborator
of a piece of code is a double, the test is about the wiring of mocks, not about the program.
**Symptom: you cannot say what bug this test would catch.** Lesson 1's rule helps here too: test
each rule at the lowest layer that observes it, and use real objects wherever they are cheap. `brl`
and `freight` are never mocked in `shipquote`: they are fast and deterministic, so the tests call
them for real.

## A short checklist

Before adding a double, ask:

1. **Is the real thing slow, costly, non-deterministic or unavailable?** If not, use it.
2. **Is this call the behaviour, or a step towards it?** Assert on calls only in the first case.
3. **What keeps this double honest?** A spec from the real class, a contract test, or a shared
   test run against fake and real. If the answer is "nothing", the double is a guess.

Lesson 4 adds a fourth question with numbers behind it: coverage reports lines a test executed,
and a line executed under a double that does nothing is a line the report counts and nobody
checked.
