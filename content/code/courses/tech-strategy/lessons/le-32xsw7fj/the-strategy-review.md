---
title: The strategy review
version: 1
---

The review is where a strategy stops being Davi's document and becomes the company's decision. It
lasts an hour, it has two people in it who can say no, and **almost all of it is questions**, each
of which this course has already answered somewhere. This section follows the meeting through,
and it doubles as a map of the course: every answer Davi gives was produced in a lesson you have
done.

It is a Thursday in February, two weeks before the Reservations team is due to start. In the room
are Helena Prates, the CTO, who asked for the strategy; Otávio Lins, the CFO, who has to agree to
what it costs; and Davi Moreira, who wrote it.

## The first five minutes

Davi puts up the slide from the previous section and reads the title aloud: fix the seat holds
before the on-sale season, R$ 48,000 once, against R$ 364,800 a year of expected loss. Then he
stops talking.

That pause is deliberate. **The slide is built so that the questions start immediately**, and the
questions are the meeting. A presenter who fills the hour with a walk through the appendix is
protecting the strategy from the only test that matters: whether the two people who can stop it
still want it after they have pushed on it.

## The questions, and where each answer came from

Otávio asks most of them. Helena asks two, and hers are harder.

| the question | Davi's answer | where it came from |
|---|---|---|
| "What exactly is broken?" | Big on-sales fail in the seat-hold code of the reservation module, about twelve a year are at risk, and every team edits that code while none owns it. | the diagnosis, lesson 1 |
| "You said R$ 48,000. What do we pay if we wait?" | The debt charges 31 hours of interest a sprint, R$ 4,650; 806 hours a year, R$ 120,900, before counting a single failed on-sale. | interest per sprint, lesson 5 |
| "Search is on your plan too. Why buy it instead of building?" | Over three years buying costs R$ 433,080 against R$ 450,000 to build, R$ 16,920 less, and in the first year it is R$ 157,200 against R$ 246,000. | the three-year comparison, lesson 8 |
| "The hosted observability licence is the dearer one. Why that?" | The licence alone favours self-hosting by R$ 124,200, but operating it is 76% of its cost of ownership; in total the hosted service is R$ 174,150 cheaper. | total cost of ownership, lesson 9 |
| "Aren't we locking ourselves in to the payment gateway?" | We pay R$ 24,000 for portability there, because the expected cost of the lock-in is R$ 47,250. For the document database we accept it: R$ 21,000 expected, against R$ 63,000 to avoid it. | lock-in priced, lesson 10 |
| "If I asked you to cut 10%?" | That is R$ 1,738,400 of a R$ 17,384,000 budget — 6.6 engineers, or 68% of the whole cloud bill. 79.0% of the budget is people, so a cut that size is mostly people. | the budget, lesson 11 |
| "The cloud bill goes up again next year." | By 11.3%, while tickets grow faster: the cost per ticket falls from R$ 0.517 to R$ 0.454. And the idle staging environments are R$ 117,600 a year we stop paying. | unit cost and showback, lesson 12 |
| "Why the seat-hold fix before Pix in instalments, which sales want?" | Ordered by cost of delay divided by duration, the fix goes first, and that order costs R$ 1,632,000 in delay against R$ 1,794,000 for putting the item with the highest cost of delay, Pix, first. | cost of delay, lesson 13 |
| "In a year, how will anybody know why we chose this?" | Each of these decisions is an architecture decision record, numbered, beside the code; the search and observability ones are already written. | ADRs, lesson 17 |

Read the right-hand column as a list and it is most of this course. **None of the answers is an
opinion**, and none of them was prepared for the meeting: each one existed already, as a sheet or a
page, because the strategy was built out of them.

## Helena's two questions

Helena's first question is about the people: "Which two team leads lose their projects this year,
and have they heard it from you?" It is the question about the not-list from lesson 3 — the
microservices migration and the front-end framework — asked as a question about people instead of
projects. Davi told both, in person, before the review. A strategy whose losers learn their fate
from a slide has a second problem waiting behind the first.

Her second question is the one that tests the whole thing: "What would make you change this?" Davi
answers with conditions, the kind lesson 19 asks for. If the load test shows the hold path
surviving an on-sale before the lock removal is finished, the deploy freeze can be relaxed. If two
big on-sales fail anyway this season, the diagnosis was wrong, and the strategy comes back to this
room. **A strategy that names what would change it can be trusted to be changed for a reason**,
rather than by whoever asks loudest next quarter.

## The decision, and where it is written

Otávio approves the team and the fix, and asks for one thing in return: the same slide, with real
numbers in place of expected ones, at the review after the on-sale season. Helena agrees that the
migration and the framework wait a year, and says so to the team leads herself.

Davi writes it down the same afternoon. The strategy page records the decision and the date. An
architecture decision record, in the format from lesson 17, records why the Reservations team was
created and what was decided against. And the not-yet table from lesson 19 gets its first entry the
moment the review ends, because somebody always asks for something on the way out. **The record is
what lets next year's review start from what was decided instead of from what people remember.**

## What the course added up to

This is the last lesson of the course and of the track. The track's earlier courses gave you the
team's process, its people, its metrics and its communication. This one gave you the part where a
lead decides where the engineering money goes and defends it.

Each tool in it answered one kind of question. Rumelt's kernel decided what the strategy is about.
Interest per sprint priced the debt. The three-year sheet, the total cost of ownership and the
expected cost of lock-in priced what to build, buy or adopt. The budget and unit cost put the
spending in the business's terms, and cost of delay ordered the work. The ADRs kept the reasons.
Saying no with a cost and a date kept the strategy intact between reviews, and the review is where
all of it is tested by people who can say no.

Coreto is invented. Your own company is not, and it has its own on-sale somewhere: the moment where
it earns its reputation and where, very probably, nobody owns the code that fails. Find it, write
the diagnosis in three sentences, and price it. The rest of this course is what you do next.
