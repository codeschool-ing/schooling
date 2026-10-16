---
title: Heuristics
version: 1
---

The usual picture of a good explorer is somebody with a talent, a nose for defects that the rest of
us lack. Experience does make a difference, but most of what it gives a tester can be written down
and lent to somebody who has not had it yet. **A heuristic is a fallible rule of thumb for coming up
with a test**: it does not promise a defect, and it is not a checklist to finish. It is a way to ask
yourself a question you would not have thought of, at the moment you have run out of ideas.

## SFDPOT: six things a product is

James Bach's model of a product's parts gives six words to walk through, remembered as **San
Francisco Depot**: Structure, Function, Data, Platform, Operations, Time. Each one is a different
way of looking at the same application, and each suggests tests the others do not. For boxoffice:

| | what it asks about | a question for boxoffice |
|---|---|---|
| **S**tructure | what the product is made of | which pages exist that no link leads to? `/health` is one; are there others? |
| **F**unction | what it does | what does each of the four actions do, from each state an order can be in? |
| **D**ata | what it takes in and keeps | what happens to an order number that does not exist, or a quantity of zero? |
| **P**latform | what it depends on | which browser, which screen width, which Python? Lesson 7 asked this one |
| **O**perations | how people actually use it | what does a full Saturday look like, with a queue at the counter and somebody refunding at the door? |
| **T**ime | what changes as time passes | what changes as a show gets close, and once it has started? |

The order of the letters is only a way to remember them. A session usually starts with the one
nearest its charter and turns to another when the first stops producing questions. Ana's charter is
about orders, so Function comes first, and **Time is the letter that is easiest to forget**, because
a tester at a desk tests at one moment of the day.

## Tours

James Whittaker's *Exploratory Software Testing* describes exploration as tourism: a tour is a way
of moving through an application with a theme, the way a visitor might choose a museum tour or a
walk through the back streets. Three of his tours, and what each would be on boxoffice:

- **the money tour** visits the features a customer pays for, the ones the product is sold on.
  For a ticket office that is booking a show and paying for it, end to end, the way a customer would;
- **the back alley tour** visits the features hardly anybody uses, because hardly anybody tested
  them either: the outbox, `/health`, an order page opened by typing its number into the address;
- **the landmark tour** picks the main features and visits them in different orders: sign up, then
  book, then pay; book first and sign up after; pay, then cancel, then book again. Defects that
  depend on what happened before show up only when the order changes.

## Smaller ones, for when you are stuck

Some heuristics are a single question, short enough to keep on a card beside the keyboard:

- **Goldilocks**, from the test heuristics cheat sheet Hendrickson wrote with James Lyndsay and
  Dale Emery: for any input, try one too small, one too big and one just right. For tickets, 0, 7 and 6;
- **the same thing twice**: pay an order that is already paid, cancel one that is already
  cancelled, press Book twice quickly;
- **undo it**: whatever the application lets you do, try to take it back, and see whether
  everything it changed comes back with it;
- **another door**: whatever the browser lets you do, send the same request with curl, including
  values the page never offers. The page's buttons are not the only things that can reach the
  server.

None of these finds a defect by itself. They keep the session from being spent repeating the three
tests that occurred to you first. Section 05 of this lesson uses two of them on purpose,
Function and Time from SFDPOT, and one of the small ones, another door.
