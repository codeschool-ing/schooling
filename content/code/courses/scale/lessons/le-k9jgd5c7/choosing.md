---
title: Choosing, one operation at a time
version: 1
---

The lesson has been arguing one thing from several directions: **consistency and availability are
chosen per operation, not per system**. The box office already makes different choices for its two
requests, and a real ticketing system has a dozen more. For each, the useful question is the one
section 04 left: what goes wrong if this answer is stale, or if this write lands on both sides of
a partition?

| operation | if stale, or written on both sides | choice | how, in this course |
|---|---|---|---|
| sell a seat | a seat sold twice | **consistent**: refuse during a partition | one primary, the sale in one transaction (lesson 1), synchronous replica if no sale may be lost |
| show a show's page | a count a few seconds old | **available** | asynchronous replica (lesson 2) |
| a buyer's own ticket | "your ticket does not exist" | read-your-writes | primary for that user, or wait for the LSN (lesson 2) |
| add to a cart | an item lost | **available, merged** | a set merged by union (section 09) |
| count views of a page | a count a little low | **available** | a G-counter, or simply an approximate number |
| a buyer's display name | the older of two edits kept | **available, last write wins** | LWW, knowingly |

Three habits make the table usable on a system of your own:

- **Start from what a stale answer costs a person**, not from what the database offers. A cost of
  "a support call" and a cost of "money taken for a seat that does not exist" are different rows.
- **Look for invariants.** "At most capacity seats", "a balance never below zero", "one account per
  e-mail". Every invariant needs coordination at the moment of the write, and is where consistency
  is not negotiable.
- **Expect to mix.** The box office's sale is consistent and its page is available, on the same
  data, in the same program. That is normal, and it is the shape most real systems end up with.

Lessons 4 and 5 meet databases built around these choices: some consistent by default, some
available by default, several letting each query decide. The vocabulary of this lesson is how to
read their documentation, which describes the same trade in its own words.
