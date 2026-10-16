---
title: There is never time to test everything
version: 1
---

**Testing everything is impossible: Joana's five sentences already allow more combinations of age, day, time and
order size than anybody would run, and a real system has thousands of sentences. So every test plan is a choice of
what to leave out.**
Prioritisation is making that choice on purpose, with reasons somebody else can read, rather than by whatever got
tested first before the time ran out.

At Cine Aurora, the release on Friday carries six areas of change, and Lia has two days, sixteen hours, to test them:

| area | what changed |
|---|---|
| **price rule** | the age line and Wednesday, lesson 17's fix |
| **orders** | the order program now rejects a refused order without writing it |
| **coupons** | PIPOCA and ESTREIA, lessons 15 and 16 |
| **seat map** | the website now shows which seats are taken |
| **refunds** | a refund button at the box office |
| **nightly report** | a discount column, lesson 18's action |

Sixteen hours do not cover all of it in depth. Splitting them evenly, under three hours each, treats the nightly
report like the price rule, and nobody believes they matter equally. The question is how to say *how much* each one
matters, in a way the team can agree with or argue about.

## Four questions

Four questions do most of the work, and each has a section of its own in this lesson:

1. **How likely is it to be broken?** New code, complex code, code changed in a hurry, code nobody understands.
2. **How bad would it be if it were?** Money, trust, law, safety, how many people are hurt.
3. **How often is it used?** A defect in something every customer touches does more damage than one in a corner.
4. **Where have defects been before?** Defects cluster; the part that failed last month is a good bet for this one.

The first two are the classic definition of **risk**: likelihood times impact. The other two refine it. Usage
frequency sharpens the impact; defect history sharpens the likelihood.

## Prioritising is a team decision

Lia does not decide alone what matters most. The likelihood is often best judged by Rafael and Tomás, who know which
code was hard to write. The impact is Joana's to judge, because she knows what a wrong price costs the business. The
usage comes from data, and the history from the defect records. Lia's part is to ask all four questions, put the
answers in one place, and turn them into an order everybody can see.

The output is not just an order of testing. It is also a statement of **what will be tested lightly or not at all**,
said out loud before Friday, which is lesson 21's subject: a release decision made with the gaps visible is a
decision; one made without them is a surprise waiting to happen.
