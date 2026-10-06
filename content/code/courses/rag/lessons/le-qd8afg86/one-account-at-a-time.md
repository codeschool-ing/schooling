---
title: One account at a time
version: 1
---

A memory table holds every customer's words in one place, and the only thing that keeps Rafael's
assistant from reading Beatriz's turns is a `WHERE account = %s` in each query. Here is the state
function written once without it, the way it might be written in a hurry, or by a test that worked
because the database only held one customer:

```
ana@lab:~/rag$ python careless.py "Rafael Lima"
You are Rafael Lima. Your order number is MG-31770254 and MG-20481937.
```

**Rafael is told that his order number is MG-31770254 and MG-20481937**, and the second one is
Beatriz's. Nothing failed. The query returned rows, the sentence is well formed, a reply would quote
it and cite it, and lesson 7's check would pass it, because the state says exactly that. The only
symptom is a customer reading a stranger's order number, and on a platform where that number opens a
page with an address on it, that is a personal data breach.

With the account in the query, Rafael's own recall finds only his own turns:

```
ana@lab:~/rag$ python recalled.py chat-b A-1002 4
turn 4: Could you remind me of my order number?
   0.495  turn 1: Hello, this is Rafael Lima. My order MG-31770254 has not arrived.
   0.290  turn 3: I would prefer a refund rather than waiting for a new parcel.
```

## Making the filter impossible to forget

A condition every query must remember is a condition one query will forget. Three habits move it from
memory to structure:

- **The account is a parameter of every function that reads memory**, never optional and never
  defaulted, as in `recall(account, …)` and `state(account, …)`. A caller cannot ask for memories
  without saying whose.
- **A test with two customers.** The leak above is invisible with one customer in the database and
  obvious with two, so the test that matters loads both and asserts that neither ever sees the
  other's order number. It is the same test lesson 14 writes for documents.
- **The database enforces it.** Postgres can attach a policy to the table so that a query sees only
  the rows of the account the connection was opened for, whatever its `WHERE` says. Lesson 14 builds
  that for documents, and the same mechanism covers this table.

An assistant that remembers is an assistant that can remember the wrong person. That is why memory is
built per account from the first row, and never filtered afterwards.
