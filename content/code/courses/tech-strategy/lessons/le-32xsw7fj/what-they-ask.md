---
title: What executives ask
version: 1
---

An executive reviewing a technical strategy asks four things: **what can go wrong, what it costs,
when it pays off, and what you want from them today.** Risk, money, time and the decision. A
presentation that answers other questions — how the system works, why the old design was chosen,
what the new one looks like — is answering questions nobody in the room asked. It also uses up the
time in which the four would have been answered.

Two weeks before Coreto's strategy review, Davi showed Helena Prates his draft presentation. It
opened with `coreto-core`'s architecture, walked through the reservation module, and reached the
row locks with a diagram of the queue they form under load. It was accurate, and Davi was proud of
the diagram. Helena let him get through it and then said: "Otávio will stop you on the second slide
and ask what it costs. Start there."

## The four questions

Otávio Lins is Coreto's CFO. He does not need to understand a row lock to approve a team that
removes them, any more than he needs to understand a ticket printer to approve buying one. **What he
needs is enough to compare this decision with the others on his desk**, and every decision on his
desk arrives in the same four questions.

| what Otávio asks | the technical answer | the answer he can use |
|---|---|---|
| What happens if we do nothing? | "the reservation module is fragile under load" | "we expect to lose R$ 364,800 a year in failed on-sales" |
| How much, and compared with what? | "four engineers for two quarters" | "the fix costs R$ 48,000 of engineering time, and nobody new is hired" |
| When do we see it? | "after the refactor" | "before this year's on-sale season, measured by a load test" |
| What do you need from me? | (no answer) | "approve the Reservations team from 1 March, and the two projects that wait a year" |

The middle column is not wrong. It is in the wrong unit for this reader, and it leaves him to do the
translation, which he cannot do without the knowledge he does not have. The right-hand column does
the translation for him, and every number in it comes from work this course has already done:
lesson 5 priced the debt, and the next section prices the risk.

The fourth row is the one presentations most often leave empty. **A review that ends without a
decision has not happened**, whatever was presented in it, because nothing is different the next
morning. Write the decision you want before you write anything else, and if you cannot write it,
you are not ready to ask for the meeting.

## Answer in their unit

Each question has a unit the asker thinks in, and a strategy review is where the translation has to
be finished rather than started.

**Risk is money a year, or a named consequence.** "Fragile" is an adjective; an expected loss is a
number that can be set beside a price. `architect-communication` lesson 4 shows how a technical risk
becomes a business one — likelihood and impact, and the consequences money does not cover — and the
next section applies it to Coreto's largest risk.

Money is reais and a share of something the reader already knows. Lesson 11 put Coreto's
engineering budget at R$ 17,384,000, 79.0% of it people. Measured against that, a fix of R$ 48,000
is small, and saying so is part of the answer.

Time is a date in the business's calendar. "Two quarters" means nothing to a CFO until it is tied
to something he is already counting on — here, the on-sale season, whose revenue he forecasts
every year.

The decision is a verb, an owner and a date: approve, fund, stop, wait. `architect-communication`
lesson 3 covers adapting a message to a board or an executive in general; `people-leadership`
lesson 24 covers the relationship with the person you report to. Both apply here, and neither
needs repeating.

## Doing nothing is an option, and it has a price

Executives choose between options, and a presentation with one proposal offers them a choice
between yes and an argument. **The option they always have is to do nothing**, so price it first.
At Coreto, doing nothing is the R$ 364,800 a year of expected loss, plus the 31 hours of interest
the seat-hold debt charges every sprint (lesson 5). Everything Davi proposes is measured against
that line, and the line is the reason the meeting exists.

## What they test you on

A CFO tests a strategy by what it gives up, because that is where the money that is not being
spent goes. Expect the question "what are you not doing?", and answer it from the page: lesson 3
put the list there. At Coreto it is short — the microservices migration and the new front-end
framework wait a year — and **saying it before he asks is the strongest signal that the strategy
chose something.**

Expect also to be asked how sure you are. Sounding confident does not answer it. Showing how wrong
your estimate could be before the decision changes does, and that is the last part of the next
section.
