---
title: The context, written as forces
version: 1
---

**The context section describes the situation that made a decision necessary, as a set of forces:
facts, constraints and pressures, some of them pulling in opposite directions.** It is the part a
future reader needs most, because it is the part that tells them whether the decision still holds:
if the forces have changed, the decision may have to.

## Forces, not a story

A weak context tells the story of the meeting. A strong one lists what was true:

> **Weak.** We had a lot of problems with double bookings around São João, and after discussing it
> the team felt the current approach was not working, so we looked at some alternatives.

> **Strong.**
> - Seats are held as rows in the booking database while a passenger pays.
> - At peak, 1,800 holds are created per minute; 70% expire without payment.
> - Creating and expiring holds is 40% of the database's write load at peak, and the database is at
>   85% CPU in the week before São João.
> - A hold must be exclusive: two passengers must never hold the same seat.
> - A lost hold is acceptable: the passenger chooses again. A lost booking is not.
> - The Platform team already runs Redis for sessions.

Every line in the strong version is a fact somebody could check, and together they explain why a
change was needed and what any option had to respect. Two of them, *a hold must be exclusive* and
*a lost hold is acceptable*, are the forces the eventual decision balances.

## The solution in disguise

The commonest fault in a context is that it argues for the answer. *We need a fast in-memory store
for holds* is not a force; it is the decision, written early. Readers notice, and a context that
only supports one option makes the options section look like theatre. **Write the context so that a
reader could, from it alone, imagine choosing differently.** If the forces only allow one answer,
there may not have been a decision to record.

## Numbers and dates

Forces age, and the numbers are how a reader knows by how much. *The database is busy* means
nothing in two years. *85% CPU at peak in June 2025* can be compared with whatever the dashboard
says the day somebody reopens the question. That is also why a record carries the date it was
accepted, near its status.

## Links, not copies

The context should be readable on its own, in a page. It links to the evidence rather than pasting
it: the dashboard, the incident report from the Friday before São João, the design document. A
reader who trusts the summary does not need to follow them; a reader who does not can.
