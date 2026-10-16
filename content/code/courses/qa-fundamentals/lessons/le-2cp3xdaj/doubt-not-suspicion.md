---
title: Doubt, not suspicion
version: 1
---

**The tester's mindset is often described as being negative: the person who assumes the software is
broken and the developer careless.** Teams that hire somebody like that learn quickly that it does not
work. Developers stop showing their work early, reports turn into arguments, and the tester spends their
days being right about things nobody wanted to hear.

What the good ones have is different, and it has a better name: **systematic doubt**. Doubt about
claims, not about people.

## Every "it works" is a claim

When Rafael says the price rule works, he is making a claim, and almost always an honest one. What he
means, precisely, is: *it worked for the inputs I tried, in the conditions I tried them.* That is a
narrower statement than "it works", and the gap between the two is where defects live. Lesson 1 found one
there in two commands: Rafael had tried sixty-one, and nobody had tried sixty.

Doubting the claim is not doubting Rafael. The question a tester asks is never "did you make a mistake?";
it is "**what has this been checked against, and what has not?**" The first question asks a person to
defend themselves. The second asks what is known, which is a question everybody can help answer.

## Why the people who built it see less

There is a good reason a second person finds defects the builder missed, and it is not skill.
Psychologists call it **confirmation bias**: once we believe something, we look for evidence that agrees
and read ambiguous evidence as agreeing. A developer who has just written `age > 60` believes it means
"over sixty, as the rule says", and the four test inputs they choose to try it with are ones they expect
to pass, because that is what they are checking.

A tester is useful partly because they did not write it, and so do not yet believe it. **The value is in
the distance, not in a superior eye**, and the same tester reviewing their own test plan has exactly the
same blind spot. That is also why the doubt has to be systematic: a habit applied to every claim,
including your own, rather than a feeling that some code looks wrong.

## The scientific shape of it

Testing well looks a great deal like an experiment, and the vocabulary carries over usefully:

| | in science | in testing |
|---|---|---|
| **hypothesis** | a statement that could turn out false | "the sixty-year-old is charged full price" |
| **experiment** | something you do whose result could refute it | run the price for 59, 60 and 61 |
| **evidence** | what the experiment produced, recorded | the three prices, exactly as printed |
| **reproduction** | somebody else gets the same result the same way | the two commands that show it, on any machine |

A hypothesis has to be capable of being wrong. "The shop has a problem with ages" cannot be refuted by
any run, so it is not one. "Sixty is treated as under sixty" can be refuted by a single command, and so
it can be tested. **The more precise the hypothesis, the cheaper the experiment that settles it.**

## What this lesson does

The rest of this lesson takes a vague report from the box office, *a family was overcharged on Sunday
morning*, and follows it all the way to two commands that anybody can run and see the defect. That
journey, from a complaint to a reproduction, is the core skill of the job. Everything in later lessons,
from the box approaches to root cause analysis, is a refinement of it.
