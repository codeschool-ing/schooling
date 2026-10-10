---
title: Reusing data, and getting back to the start
version: 1
---

Data that worked once is supposed to work again, and that is where most test data goes wrong. **A
case can be repeated only if the data it starts from is the same every time, and that takes two
things: data that comes out the same whenever it is made, and a way back to the state before it
was made.** Boxoffice has both, which is why this course's transcripts can say "order 1001" and be
right on your machine.

## Running the same thing twice

Section 03 of this lesson signed up five accounts. Run the same program again, without touching
boxoffice:

```
ana@laptop:~/boxoffice$ python3 make_accounts.py 5
test001@example.org  There is already an account with that e-mail.
test002@example.org  There is already an account with that e-mail.
test003@example.org  There is already an account with that e-mail.
test004@example.org  There is already an account with that e-mail.
test005@example.org  There is already an account with that e-mail.
```

Nothing is wrong with boxoffice. The five accounts already exist from the first run, and R2 says
an address no other account uses, so all five are refused, correctly. But a case written as "run
make_accounts.py, expect five accounts created" passed a minute ago and fails now, and nothing
about the product changed in between. **The data from the last run is part of the state the next
run starts in**, and a case that does not control it is testing its own history.

## Boxoffice resets by restarting

Boxoffice keeps everything in memory, as lesson 1 said, so stopping it with Ctrl-C in its terminal
and starting it again with `python3 boxoffice.py` throws away every account, order and message
that was added. Do that, and run the program once more:

```
ana@laptop:~/boxoffice$ python3 make_accounts.py 5
test001@example.org  Account created. We sent a link to test001@example.org.
test002@example.org  Account created. We sent a link to test002@example.org.
test003@example.org  Account created. We sent a link to test003@example.org.
test004@example.org  Account created. We sent a link to test004@example.org.
test005@example.org  Account created. We sent a link to test005@example.org.
```

Created again, the same five, because the seed in `make_accounts.py` makes the same five every
time and the restart put boxoffice back where it started. Those two together are the whole of
repeatable test data, and every technique below is a way of getting them where they do not come
free.

## The values that have to be the same every run

Random is useful for variety and harmful for repetition. A case that signs up a random name today
and a different one tomorrow cannot be compared with itself, and a failure that happened with one
name is lost when the next run picks another. **Seeding** keeps the variety and removes the
surprise: `random.Random(1)` produces a different-looking list from `random.Random(2)`, and the same
list every time it is asked.

Boxoffice applies the same idea to itself in two places, both set from the environment and both
met in earlier lessons. `BOXOFFICE_SEED` makes the confirmation links come out the same on every
run, and `BOXOFFICE_NOW` fixes the clock, which lesson 13 called a fake clock. The transcripts in this
course were recorded with both set, which is why their dates and links are the same on every
recording. Yours differ in exactly those two things, because you start boxoffice without them.

## Real systems do not reset by restarting

Most applications keep their data in a database that survives a restart, so the way back has to be
built. Teams use three approaches, often together:

| approach | how it works | what it costs |
|---|---|---|
| restore before the run | the database is put back to a saved, known state before testing starts | somebody keeps the saved state up to date as the product changes |
| each case makes its own | a case creates the account or order it needs, with a value nobody else uses | more data piles up, and cases depend on the parts that create it |
| clean up after | each case deletes what it created | a case that fails halfway leaves its data behind for the next run |

**Restoring before is the most trustworthy of the three**, because it does not depend on the last
run having finished properly. Cleaning up after is the most fragile for the same reason: the run
that fails is exactly the one that leaves a mess.

## Sharing an environment

The hardest data problem is two people. Ana and Rui test against the same shared environment, both
book with the member account, and Rui's run uses up the last seats Ana's case needed. Neither of
them did anything wrong, and Ana's case fails anyway. The fixes are the ones above, applied per
person: each tester gets accounts of their own, as numbered addresses make easy, and the cases
that need a known starting state run where nobody else is changing it. Lesson 21 is about the
environments themselves, and why a case that passes on one machine fails on another.
