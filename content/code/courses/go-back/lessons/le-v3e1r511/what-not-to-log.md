---
title: What stays out of the log
version: 1
---

A log is read by more people than any other output of a service: operators, developers, support, the
log platform's vendor, whoever restores a backup next year. **It is kept longer than the data it
describes**, and it is copied to places the database never goes. So the rule for what it may hold is
stricter than the rule for the database, not looser.

## Never

- **Secrets.** Passwords, tokens, API keys, session cookies, the `Authorization` header. boxoffice's access
  line has logged the path and never a header since lesson 2, which is why the staff tokens of lesson 2
  appear in no log of this course.
- **Payment data.** Card numbers and their security codes, which the card schemes' rules forbid keeping
  anywhere outside a certified system.
- **Whole request or response bodies.** A body holds whatever the client sent, including everything in the
  two items above, and logging it "for debugging" logs all of it.

## Only when needed, and reduced

**Personal data**, an e-mail address, a name, a street address, is regulated: Brazil's LGPD and Europe's
GDPR both give people rights over it, including having it deleted, and a log full of e-mail addresses is a
copy of personal data that nobody will find when the deletion request arrives. Log an identifier instead,
the ticket id or an account id, which leads to the data where it is managed. When an address really helps,
**reduce it at the type**, as section 03's `email` did with `LogValue`: every call that logs that type gets
the reduced form, and nobody has to remember.

## What a good line holds

The request id, the method and path, the status, the size, the duration: lesson 2's choice, now as fields.
Ids of the things involved, the event and the ticket. **The error, in full, on the server's side**, which
lesson 3 kept out of the client's answer and put in the log. And the level, set honestly: a client's 404
is `INFO`, not `ERROR`; a log where everything is an error is a log where nothing is.

## Checking it

A rule kept by memory fails. Three habits make it hold: **types that redact themselves**, as above; a review
question, "what can this field contain?", for every new log call that takes a value from a request; and an
occasional search of the real logs for an `@`, a `Bearer` or sixteen digits in a row. Lesson 15's tests can
assert that a handler's log output does not contain the token it was given.
