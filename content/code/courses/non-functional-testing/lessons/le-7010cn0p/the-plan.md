---
title: The test plan, one category at a time
version: 1
---

A test plan built from the Top 10 is a table with one block per category. Each row is a test case
small enough to fail: a request, the answer it must get, and **what holds it**. That last column is
the one that makes the plan honest, because it has only four possible values, and only one of
them is a test that already runs:

| what holds the row | meaning |
|---|---|
| **a test** | written, in the suite, and it runs on every change |
| **to write** | a test could hold it and nobody has written it yet |
| **a scanner** | a tool from lesson 16's five kinds checks it, on a schedule or on every change |
| **a review** | only a person reading the design, the code or the deployment can judge it |

The plan below covers the two services of this course: the box office of lesson 1, on port 8000,
and the account service of lesson 16, on 8001. The test names are the ones in `test_account.py`
(lesson 16), `test_sessions.py` (lesson 17), `test_vectors.py` (lesson 20) and `test_owasp.py`,
which this lesson adds.

## The plan

| | test case | held by |
|---|---|---|
| **A01** | a customer's token cannot read another customer's booking | a test, lesson 16 |
| | a customer's token cannot open the staff list; a member of staff can | a test, lesson 17 |
| | a token in the address is ignored | a test, lesson 17 |
| | one customer's form token does not work for another | a test, lesson 20 |
| | the box office believes any `customer` name a booking carries | **a review**: by design, it has no identities |
| | no route fetches an address a user supplied (server-side request forgery) | a review: true today, to re-check when one does |
| **A02** | every answer carries `nosniff`, and `Server` names no software or version | a test, this lesson |
| | the page cannot be framed by another site | a test, this lesson |
| | the page of somebody's bookings tells caches to keep no copy | **open finding F19-1**, a test marks it |
| | the box office's `Server` header names its software and version | a review, a finding for the box office |
| | HTTPS only, with `Strict-Transport-Security`, on the deployment | a review, and a DAST scan of staging |
| **A03** | `account.py` uses Python's standard library and nothing else | a review |
| | no tool in the virtual environment has a published advisory | a scanner, lesson 21 |
| | every download in the setup is pinned to a version, from its publisher | a review |
| **A04** | a password is stored as a salted scrypt hash, never as itself | a test, lesson 17 |
| | the database holds no live session token | a test, lesson 17 |
| | the session cookie carries `Secure` once the service is behind HTTPS | a review of the deployment |
| **A05** | a single quote in the search is only text | a test, lesson 16 |
| | markup in a booking comes back escaped | tests, lessons 16 and 20 |
| | no SQL is built by joining strings | a scanner (SAST), and a review |
| **A06** | five failed sign-ins lock the name, so anybody can lock anybody out | **a review**: a design decision, lesson 17 |
| | the abuse cases of every new feature are written beside its use cases | a review |
| **A07** | sign-in stops after five failures | a test, lesson 17 |
| | an unknown name is answered exactly like a wrong password | a test, lesson 17 |
| | a session ends at logout and at expiry | tests, lessons 16 and 17 |
| | registration refuses a password shorter than 12 characters | **to write** |
| **A08** | an upload is checked by its content, stored under a random name and never served | tests, lessons 16 and 20 |
| | no request body is read with anything but `json.loads` | a review |
| | no commit adds a secret | a scanner, lesson 18's hook and pipeline |
| **A09** | a failed sign-in is logged with the name and without the password | a test, this lesson |
| | a refusal is logged with the account that asked and what it asked for | a test, this lesson |
| | a name cannot write a log line of its own | a test, this lesson |
| | a successful sign-in is logged | **open finding F19-3**: it is not |
| | a burst of refusals or lockouts alerts somebody | a review today, lesson 24 |
| **A10** | a malformed body is a `400` | a test, this lesson |
| | an unexpected error answers one plain sentence and no trace | tests, lesson 16 and this lesson |
| | a `Content-Length` that is not a number is answered `400` | **open finding F19-2**, a test marks it |
| | an error inside the session check refuses rather than lets through | a review: `guarded` answers `500`, never the route |

## Reading it

**Count the column, not the rows.** Of the thirty-eight rows above, nineteen are held by a test that
runs on every change, and most of those were written in lessons 16, 17 and 20 before this plan
existed: the list confirms them rather than inventing them. That is normal, and it is also the
point of building the plan, because it shows where the rest is.

- **The reviews are not failures of the plan.** A06 has no test because a test checks that code
  does what was decided, and Insecure Design is about what was decided. A person reads the
  decision and says whether it holds up; lesson 17's drill was one such reading, and the box
  office trusting any name it is sent is another.
- **The scanners cover the rows that look the same in every application**: a library with an
  advisory, a secret in a commit, SQL built by joining strings. Lessons 18 and 21 run two of them.
- **The rows marked *to write* are a debt with a name.** The password length is checked by
  `register` today and nothing would notice if it stopped being checked.
- **The open findings are defects the plan found**, and the next section shows each one. A test
  plan that turns up nothing new was written to describe the system rather than to test it.

The plan is reviewed again whenever the system grows a feature, which is when its rows go stale:
the day `account.py` fetches an address, A01 needs its server-side request forgery row tested
rather than reviewed.
