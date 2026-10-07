---
title: Why "it is technical debt" loses the argument
version: 1
---

**An engineer who says "this is risky" and a director who hears "this engineer wants to rewrite
something" are having two different conversations, and the engineer usually loses.** Not because
the director is short-sighted, but because nothing in the sentence is in a form a director can
weigh against the other things competing for the same money.

Every week Otávio hears that something is urgent. Sales says a client will leave without a feature.
Marketing says a campaign needs a landing page by Friday. Engineering says the database is fragile.
The first two arrive with a number attached, a client's annual contract or a campaign's expected
orders. The third arrives with an adjective. **A risk described only in adjectives competes against
risks described in reais, and it loses on the comparison, not on the merits.**

## The words that lose

| what the engineer says | what the director hears |
|---|---|
| "the database is fragile" | engineers prefer things to be tidy |
| "we have a lot of technical debt" | engineering wants a quarter without features |
| "it doesn't scale" | it works today |
| "it is a ticking time bomb" | a metaphor, so probably an exaggeration |
| "we need to refactor before it is too late" | a project with no end and no measurable result |

None of these is false. **Each one describes the system, and the director decides about the
business.** Lesson 3's ladder applies exactly: the engineer is on the bottom rung and the decision
lives on the top one.

## A risk that was described correctly, too late

On 1 August 2012, Knight Capital, then one of the largest traders in US shares, deployed new
software to its order-routing servers. A technician copied the new code to seven of the eight
servers. On the eighth, a flag repurposed by the new code switched on an old function that had sat
unused for years, and that server began sending orders nobody had intended. By the account of the
US Securities and Exchange Commission, Knight lost more than 460 million dollars in about 45
minutes. Within months it had agreed to be taken over.

Described at the bottom rung, the risk was "dead code still deployed, and a manual deployment with
no check that every server received the release". Described at the top rung, it was "one
deployment mistake can cost more than the company is worth in under an hour". The first sentence
is the kind that sits in a backlog. The second is the kind that gets a budget.

## What the rest of the lesson does

The remaining sections turn a technical risk into the second kind of sentence, step by step:

1. **likelihood and impact**, the two numbers any risk has to be described with;
2. **putting numbers on them** for Marola's Friday problem, with the arithmetic shown;
3. **options rather than alarms**, so that the decider chooses instead of being frightened;
4. **uncertainty stated honestly**, because a risk estimate is never a measurement.

`process-management` lesson 11 treats risk as a project manager sees it, with registers and
response plans. This lesson is about one step that process leaves to whoever understands the
system: **getting the technical risk into the register in a unit the register can compare.**
