---
title: What operational means
version: 1
---

A company decides at three speeds, and each speed needs a different screen. **Operational BI
serves the decisions taken today, in minutes or hours, by the people doing the work.** Tactical BI
serves this month's decisions, made by managers who move budget, people and stock; strategic BI
serves this year's, made by the owners and the board. This lesson is the first of the three, and
lessons 15 and 16 take the other two.

| level | horizon | who decides at Varanda | the question | what the screen shows | how fresh |
|---|---|---|---|---|---|
| operational | minutes to hours | Marcos at the warehouse, the store managers, customer service | what needs my attention now? | the exceptions, one row each | minutes |
| tactical | weeks and months | Renata, Caio, Otávio | are we on plan, and where do we move resources? | the month against target and last year | the closed month |
| strategic | years | Helena and the board | are we going the right way? | a few numbers over five years | the closed year |

## The wrong picture: the monthly dashboard, refreshed more often

The common mistake is to treat the three levels as one dashboard at three refresh rates: take the
charts the directors look at, make them update every ten minutes, and put them on a screen in the
warehouse. **The levels differ in the question, not in the clock**, and a chart of the month answers
a director's question however often it is redrawn.

Marcos is Varanda's delivery coordinator at the warehouse in Contagem. On a Wednesday at 11:00 he has
fourteen trucks out and one question: which of them needs him now? A line chart of this month's
on-time rate cannot tell him. Neither can a pie of deliveries by region. Both are true and both are
about something else.

## Decisions in minutes, by people on the floor

Operational decisions share a shape. **They are many, small and reversible, and the people who take
them are not analysts.** Marcos moves six stops from a late truck to one that is ahead. A store
manager sees that the garden hoses are gone from the shelf at three in the afternoon and calls the
warehouse. Someone in customer service sees that a customer's delivery window has closed and phones
them before they phone the shop.

Each of those people reads the screen in a few seconds, often on a phone or on a television on the
wall, while doing something else. None of them wants to analyse anything. They want the screen to
have done the looking for them and to point at the row that is wrong.

## Exceptions, not averages

That is why an operational screen leads with exceptions. On that Wednesday at 11:00, the fourteen
routes were on average **19.3 minutes** behind their plan, with a median of 13.5. Read as a single
number, that says "a little late everywhere" and suggests nothing to do. The routes themselves say
something else: six were within ten minutes of the plan, and one, route 11 to Ribeirão das Neves,
was **74 minutes behind**, with three customers whose window had already closed.

An average is the right tool for comparing this January with last January, which is a tactical
question. For the person on the floor it hides the one row that needs them inside thirteen that do
not. **An operational screen is a list of what is wrong, sorted by how wrong**, with everything that
is fine reduced to a line saying so.

## An answer that arrives late is not an answer

The other property is freshness. Where the trucks were at 08:00 is history by 11:00, and a decision
taken on it moves stops onto a truck that is no longer ahead. Operational data has to be minutes old,
and the screen has to say how many minutes. The last section of this lesson is about what happens when
it is not.

## What operational BI is not

It does not explain. The board shows that route 11 is 74 minutes behind; it does not know that the
truck had a flat tyre at 09:40. Marcos finds that out by calling the driver, and why deliveries run
late across a whole month is the diagnostic question of lesson 7, asked at the monthly review of
lesson 15.

It does not decide either, at least not here. Lesson 9 handed a reorder rule to the system because the
decision was frequent, cheap to get wrong and easy to undo. Moving a delivery is frequent too, but it
depends on things the data does not hold — whether the customer can take it later, whether the second
driver knows the area — so a person decides and the screen suggests.

**Lívia's part is everything around the screen.** She does not watch it; Marcos does. She defines what
"behind" and "late" mean, agrees the alert threshold with him, builds the board and makes sure it
fails loudly. Lesson 13 said that Marcos needs his numbers by order, and now; this lesson is what that
sentence costs to deliver.
