---
title: Testing from the outside
version: 1
---

**Black-box testing examines a system only through what it does: the inputs it accepts and the outputs
it gives back.** The tester does not read the code, and does not need to. What they read instead is the
specification, the requirement, the user's expectation, anything that says what the system **should**
do. The test is the comparison between that and what it **does**.

The name comes from engineering, where a black box is a device you can only study by feeding it signals
and watching what comes out. Its opposite, a white box, is one you can open; lesson 7 opens it, and
lesson 8 is about the middle ground.

## What you can see from outside

From the outside, `tickets.py` is a command that takes four words and prints a price. That is all a
black-box tester knows, and it is a lot:

- **the inputs**: an age, a yes or no for student, a day, a time;
- **the outputs**: a price, in the format `R$ 36,00`, or something else when it fails;
- **the rule** it is meant to follow: Joana's four sentences from lesson 1.

Everything in this lesson is done with those three things and nothing else. Lesson 4 already worked this
way until its very last step, when the evidence told Lia which line to look at.

## Why test without the code

It sounds like a handicap. It is the opposite, for three reasons.

**It tests what the customer experiences.** Customers never see the code. A defect matters because of
what the system does to somebody, and black-box testing looks at exactly that.

**It is independent of the implementation.** A tester who reads `if age > 60` before testing tends to
test that line, and confirms what it does. A tester who reads only *over-60s* asks what the rule means,
and tests that. The sixty-year-old's defect was found from the rule, not from the code.

**It survives a rewrite.** If Rafael rewrites `tickets.py` from scratch next year, every black-box test
of it still applies unchanged, because the rule did not change. A test written against the code's
structure may have to be rewritten with it.

## What you cannot see from outside

Black-box testing has one structural limit, and it is worth naming exactly. **You only test the
behaviours you thought of.** The rule says what should happen for students, older people, children,
evenings, matinées and Wednesdays. It says nothing about a student on a Wednesday, a time written as
`9:30`, or an age typed as a word. If the code does something special for one particular input that no
rule mentions, no amount of testing from the rule will find it, because nothing points the tester there.

That limit is why black box is not the only approach, and why the next two lessons exist. Within the
limit, it is the approach that finds the defects customers would find, and most of the defects in this
course so far.

## The techniques, by name only

There are systematic ways to choose black-box inputs, and you will hear their names in every testing job:
**equivalence partitioning**, which groups inputs that should behave the same so you test one of each
group; **boundary value analysis**, which tests at the edges of those groups, where the sixty-year-old
lived; **decision tables**, for rules that combine conditions; and **state transition** testing, for
systems whose answer depends on what happened before.

They are the subject of `manual-testing` lessons 4 and 5, which teach them properly. This lesson does
something earlier and rougher on purpose: it reads Joana's rule one sentence at a time, turns each
sentence into cases, and then asks what the rule leaves out. Those habits are what the techniques make
systematic.
