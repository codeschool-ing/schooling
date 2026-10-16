---
title: Shift left, and what it does not mean
version: 1
---

**"Shift left" is the name the industry gave to the conclusion of this lesson.** Draw the lifecycle from
left to right, requirements first and production last, and testing has traditionally sat near the right
end. Shifting it left means doing quality work earlier: reviewing requirements, testing as code is
written, involving testers from the first conversation about a feature. The phrase was coined by Larry
Smith in 2001, and it is now in nearly every job advert for a tester.

It is a good idea, and it is commonly misunderstood in three ways.

## It does not mean testing less at the end

A team that shifts left still tests the finished product. What changes is that fewer defects reach
that point, so the testing at the end finds less and takes less time. A team that shifts left by
removing its final testing has not shifted anything; it has stopped detecting.

## It does not mean the tester does everything earlier

Shifting left moves quality work earlier for the **whole team**. Rafael writing a test before he writes
the price rule is shift left. So is Joana answering "over 60, or 60 and over?" before the sprint starts.
Lia's part is often to ask the question, not to do the work, and lesson 5 argues that a tester who tries
to do all the quality work alone is the bottleneck the rest of the team waits behind.

## It does not mean every defect can be found early

Some defects only exist when real people use the real system. How many customers buy on the night a
blockbuster opens, what a slow phone on a weak connection does to the seat map, which combination of
reductions somebody actually tries: these are discovered in production or not at all. **Shift right** is
the name for the complementary practice: monitoring, watching real usage, releasing to a few customers
before all of them, and being able to roll a change back quickly. A defect found in production is cheaper
when it is found in the first hour than in the fifth week, which is the same curve again, drawn after
release.

## Early work is not free either

The previous sections make finding defects early sound like pure profit. It is not. A review of every
requirement costs the time of whoever does it; a test written before the code costs time on a feature
that may be cancelled next week. **The question is never "can we find it earlier?", which is almost always
yes, but "is it worth finding earlier?"**, and the four things that grow from the second section are how
you answer it.

A defect with little built on it, that few people would meet, that is easy to fix whenever it is found,
is fine to catch late. A requirement that the next three months of work will be built on deserves an hour
of three people's time before anybody writes a line. Lesson 20 turns that judgement into a method for
deciding what to test first.

## What this lesson leaves you with

The curve is real in shape and unreliable in its numbers; argue from the mechanism. Four things grow
between a mistake and its discovery: what is built on it, who meets it, who still remembers it, and how
many steps a fix goes through. And the cheapest defect is the one stopped in a sentence, which is why
the next lesson is about how a tester reads, thinks and doubts.
