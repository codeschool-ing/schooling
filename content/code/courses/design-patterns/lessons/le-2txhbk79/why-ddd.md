---
title: When Domain-Driven Design pays
version: 1
---

**Domain-Driven Design is a way of building software for a complicated business by putting the
business's own model, in its own words, at the centre of the code.** Eric Evans wrote it down in
2003, in a book subtitled *Tackling Complexity in the Heart of Software*, and the subtitle is the
part to remember. DDD is a set of tools for complexity that lives in the rules, and where the rules
are simple it is ceremony.

The wrong picture of DDD is a folder layout: `entities/`, `value_objects/`, `repositories/`, and a
class called `Aggregate` somewhere. Those are the *tactical* patterns, and lesson 12 is about them.
They are the smaller half. The larger half is *strategic*: agreeing on words with the people who
run the business, deciding which part of the system deserves the most care, and drawing the lines
where one meaning of a word stops and another starts. A team can use every tactical pattern and
none of the strategy, and end up with the same tangle in more files.

## The test: where does the difficulty live?

Ask what makes the software hard. If the answer is "the screens", "the volume" or "the
integrations", DDD has little to offer. If the answer is "the rules, and the arguments about the
rules", it has a great deal.

Take two pieces of the lending library. The first is the page where a member edits her phone number
and address. It reads a row, shows a form, validates a few fields and writes the row back. Every
rule fits in a sentence, and none of them depends on another. A plain create-read-update-delete
module, written quickly, is the right design.

The second is lending. Here is what the librarians said when they were asked how it works:

- a book goes out for 14 days, a film for 7, and a reference book not at all;
- late returns cost 50 cents a day, and a member who owes more than 1000 cents cannot borrow;
- a member may hold at most 5 loans at once;
- a title with holds against it cannot be renewed;
- a returned copy with a hold goes to the hold shelf, not back to the shelves, and waits 7 days.

**Each rule is simple, and the trouble is that they meet.** A renewal touches the loan, the holds
and the fine. A return touches the loan, the fine, the hold shelf and the next member in the queue.
Change one rule, say films going out for 10 days, and the question is which of the others it
disturbs. That is the kind of difficulty DDD was written for, and in a library this is where the
librarians spend their arguments.

## What it costs

DDD is not free, and the bill comes in conversations rather than code. It asks developers to sit
with the people who know the business, often, and to rename things in the code when the business
corrects them. It asks for discipline about boundaries that a single model would let you ignore for
a while. On a small team with a simple domain, that time buys nothing.

| sign | probably worth it | probably not |
|---|---|---|
| where the hard part is | rules that interact | screens, throughput, integrations |
| who can explain the rules | only people outside the team | anyone reading the code |
| how often the rules change | every few months, by argument | rarely, and simply |
| how long the system lives | years | a campaign, a prototype |

The rest of this lesson builds the strategic half on the library: the words first, then the parts
of the business and how much each deserves, then the lines between models, how those models relate,
and how to protect one from another. The last section is a workshop for finding all of that out in
a room.
