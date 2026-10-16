---
title: Kinds of oracle
version: 1
---

**Oracles come in a few kinds, and each is strong in one place and blind in another.** A tester who knows the kinds
can usually find one, even where nobody wrote an expected result.

| kind | what it compares against | Cine Aurora | blind to |
|---|---|---|---|
| **specified** | a written expected result: a rule, an example, a criterion | the five sentences, the agreed outline | whatever the specification left out, or got wrong |
| **reference** | another implementation of the same thing | the price list printed at the counter; last month's version of the program | defects the reference shares |
| **implicit** | things that are wrong in any program | a crash with a traceback on `sixty` in lesson 6 | everything that runs without complaint |
| **consistency** | the product against itself and its world | an earlier session that costs more than a later one | a defect that is consistent everywhere |
| **human** | a person who knows the domain | Célia, who knows what a family pays at 9:30 on a Sunday | what that person has never seen |

## Implicit oracles are free

Some results are wrong whatever the specification says: a crash, a traceback, an error page, a negative price, a
total that does not add up its lines, a screen that never finishes loading. These need no expected result, which is
why every exploratory session watches for them. Lesson 6's `sixty` crash was found by an implicit oracle: nobody had
written what should happen when the age is a word, but nobody had to.

## Consistency heuristics

When no specification answers the question, a tester can still ask whether the product is consistent with things it
ought to agree with. Michael Bolton, building on James Bach's work, collected these as a list of heuristics usually
remembered as **FEW HICCUPPS**. A selection, with the Cine Aurora question each one raises:

| the product should be consistent with | the question |
|---|---|
| **its history** | did a ticket cost R$ 28,00 at this matinée last week? |
| **comparable products** | what does the cinema across the road charge a student on a Wednesday? |
| **claims** | does the poster at the door, *Wednesdays half price*, match what the program charges? |
| **user expectations** | would a family expect a morning session to cost more than an afternoon one? |
| **itself** | does the same ticket cost the same on the website and at the counter? |
| **its purpose** | does the price rule actually make cinema cheaper for students, as Joana meant it to? |
| **statutes** | does an older customer get the half price the law grants? |

None of these produces an expected price. Each produces a *reason to suspect* a price, which is what an oracle has to
do. The question a heuristic raises becomes a question to a person, often Joana, and the answer becomes a written
example, a specified oracle, for next time.

## Human oracles

The most flexible oracle is a person who knows the domain. Célia knew the Sunday price was wrong in seconds, because
she sells tickets every day. Human oracles are slow, inconsistent, and unavailable at three in the morning, so they do
not scale. They are also the only oracle for questions no document answers yet, which is why lesson 14's System Demo
and lesson 12's review put the product in front of people.
