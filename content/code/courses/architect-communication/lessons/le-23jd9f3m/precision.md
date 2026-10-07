---
title: Precision: the word that can be checked
version: 1
---

**A precise sentence is one the reader could check, and a vague one is a sentence they have to
trust.** Engineers are precise in code because the compiler insists. In prose nothing insists, so
the same people write "soon", "slow" and "a few customers" and leave the reader to guess which
number was meant.

The guess is rarely the number you had in mind. "The migration is nearly done" means two days to
the person who wrote it and two weeks to the one who has heard it before. Both leave the
conversation believing they agreed.

## Replace the adjective with the measurement

| vague | precise |
|---|---|
| soon | by Thursday 19 March |
| slow | the order page takes 2.4 s at the 95th percentile, against a target of 800 ms |
| a few customers | about 180 failed checkouts every Friday evening |
| significant cost | R$ 4,000 a month in database fees, plus six engineer-weeks once |
| high risk | if it happens on a Friday evening, checkout stops for everybody until somebody intervenes |
| we are working on it | Bruna is testing the fix in staging; the next update is at 16:00 |

The right-hand column is longer, and that is fine. **Precision spends words where they carry
information and saves them where they did not**, which the next section is about.

Not every sentence needs a number. "The fix is simple" is acceptable when the next sentence shows
the fix. What matters is that a claim a reader might doubt arrives with the thing that would settle
the doubt.

## Precise about what you do not know

Uncertainty is a fact like any other and it can be stated precisely. "It might take a while" hides
it. "Between two and four weeks; the range narrows once we have tried the migration on a copy of
production, which we will do on Monday" states it, says why it exists and says when it will
shrink. Lesson 4 builds a whole method on this.

The opposite failure is **false precision**: "the migration will take 13.5 days" when the honest
answer is a range. A number with more digits than the estimate deserves is read as confidence you
do not have, and the reader plans around it.

## One name for one thing

Engineering prose has a habit that school essays teach on purpose: avoiding repetition by changing
the word. The orders database becomes "the main DB", then "Postgres", then "the primary", then
"the core store". A reader who does not know the system now believes there are four of them.

**Pick one name, define it the first time, and use it every time.** If two names are genuinely
needed, say so: "the orders database (the PostgreSQL primary that checkout writes to)". This is
the prose version of a rule this codebase applies to its own data: a thing is called by one stable
name, and a second name is a second thing.

## Words that sound precise and are not

Some words look like measurements and carry nothing:

- **"Best practice"**, which names no practice and no source. Say which practice and why it fits here.
- **"Scalable", "robust", "modern"**, which are directions, not properties. Scalable to what load,
  robust against which failure, modern compared with what?
- **"Just"** and **"simply"**, as in "we just need to add a cache", which tell the reader that the
  hard part is not worth mentioning. It usually is.
- **"Obviously"**, which is either true, and therefore unnecessary, or false, and therefore insulting
  to the reader who did not find it obvious.
