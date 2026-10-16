---
title: Flow efficiency, and what the board cannot see
version: 1
---

The last section found the waiting **between** columns. The waiting **inside** a column is harder to see, and it is usually larger. An item that spends 3.6 days in *Development* was not being developed for 3.6 days. Some of that was work; some was its developer in a meeting, reviewing a colleague's change, answering a support question or waiting for a test environment.

**Flow efficiency** is the name for the share that was work:

```localised
flow efficiency = time actively worked ÷ total elapsed time
```

An item worked on for one day out of a five-day cycle time has a flow efficiency of 20%. The number matters because it says where improvement can come from. If an item is worked on 20% of the time, making people work faster can shave a little off that 20%; **removing waiting can take time out of the other 80%**.

## Why the board cannot compute it

A board records when an item **entered** a column. It does not record when somebody was actually working on it, because nobody moves a card back to *Waiting* every time they go to lunch. So flow efficiency is the one number in this lesson the Billing team's files cannot give you. `billing.py` knows how many days of work each item needed, and deliberately does not write it down, because no real board would have it.

What the files **can** give is a bound. Every day in the review column was waiting except the last, because reviewing takes hours and the item merged the day it was reviewed. In July that alone was 7.1 days of pure waiting out of a 42.5-day lead time, before counting a single idle hour inside development. Bounds like that are often enough to settle an argument.

## Making the waiting visible

The standard remedy is to give the waiting its own columns, so the board records it as it happens:

- **Split each active column into *doing* and *done*.** *Development: done* is an item finished by its developer and waiting for review. Time there is waiting, by definition, and the board now counts it.
- **Make review a queue column.** *Ready for review* and *In review* tell apart the item nobody has picked up from the one being read.
- **Mark blocked items, and keep them on the board.** A blocked item moved to a separate list stops counting as work in progress and stops ageing where anybody looks. `BIL-189` was blocked in exactly that way, and lesson 3 is about what that hides.

Each split costs a little discipline and buys a measurement. Do not split everything at once: start with the column whose queue the last section found largest, which for the Billing team in July was review.

## A warning about the number

When teams do measure flow efficiency, the result tends to be low enough to cause alarm, and the alarm tends to produce the wrong response: pressure on people to be "busier". **Flow efficiency is a property of the system, not of the people.** A developer at 100% utilisation is exactly the person in front of whom work queues up; lesson 12 shows the arithmetic. The fix for low flow efficiency is fewer items open and faster hand-offs, which is lesson 4.
