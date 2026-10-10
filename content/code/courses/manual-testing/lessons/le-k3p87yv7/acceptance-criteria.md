---
title: Acceptance criteria in Given, When, Then
version: 1
---

**Acceptance criteria are the conditions a feature has to meet for the client to accept it**, agreed
before it is built. They are often confused with the requirement they belong to, and the difference
is the point. R5 says "students pay half". An acceptance criterion says how anybody, the manager
included, will check that on the day: which order, which button, which number on the screen.

Agile teams write them on every story, and the format most of them use comes from
behaviour-driven development: **Given** a starting situation, **When** somebody does one thing,
**Then** something you can see happens. It reads like a sentence, which is why a client can write
it, and it has the three parts of a test case from lesson 2, which is why a tester can run it.

## Criteria for boxoffice

Here are four, for the part of boxoffice the theatre cares most about. The words `Feature`,
`Scenario`, `Given`, `When`, `Then` and `And` are the format's keywords; everything else is the
manager's language.

```localised
Feature: the price of an order

  Scenario: a student pays half
    Given a confirmed member is booking 2 tickets for Hamlet, at R$ 80,00 each
    And she ticks "Student (half price)"
    When she books
    Then the order shows 50% off
    And the total is R$ 80,00

  Scenario: discounts do not add up
    Given a confirmed member is booking 5 tickets for Hamlet
    When she books
    Then the order shows 15% off
    And the total is R$ 340,00

  Scenario: six tickets is the most in one order
    Given a member is booking 7 tickets for Hamlet
    When she books
    Then no order is made
    And the page says "You can book 1 to 6 tickets."

Feature: booking closes before the show

  Scenario: an hour before curtain, booking closes
    Given it is 19:01 on the day of The Seagull, which starts at 20:00
    When a member tries to book 2 tickets for it
    Then no order is made
    And the page says "Booking for this show has closed."
```

Three things make these useful rather than decorative.

**Each Then can be seen.** "The total is R$ 80,00" is on the order page or it is not. Compare a
criterion a client writes on a first try, "students get a fair price": nobody can fail it, so
nobody can pass it either, and the argument it postpones arrives on the day of sign-off instead.

**Each scenario checks one thing.** The first scenario is about the student rule, so everything
else is held still: the same show and quantity, a member. If it fails, nobody has to wonder which
of three changes caused it.

**The numbers are worked out in advance.** R$ 340,00 is five tickets at R$ 80,00 with 15% off, the
larger of the member's 10% and the group's 15%. A criterion that says "the right discount" leaves
the arithmetic to the person running it, and puts it where mistakes hide. Lesson 5 built the full
decision table for R5; a criterion picks the rows the client cares about and writes them in the
client's words.

## Where they come from, and where they go

**The client writes them, with help.** The tester's part is to ask questions until every Then can be
seen: "what does the customer see if they ask for seven?", "is the hour counted from the time on
the ticket?". This is the cheapest testing there is, because it finds mistakes in the requirement
before anybody writes code. A team that writes criteria together often calls it the **three
amigos**: a person for the business, one for the code and one for testing, around one story.

**They become the UAT cases.** Each scenario is already a case: Given is the precondition, When is
the step, Then is the expected result. Ana copies them into the session plan in the same words, so
the manager tests her own sentences and not a translation of them.

**They can also be run by a machine.** Tools such as Cucumber and behave read files written in this
format and run them against the application, with code behind each line. That is automation and
belongs to `web-automation`; here it is enough to recognise a `.feature` file when you see one, and
to know that the format was designed for people first.

## What a criterion is not

It is not the whole of testing. These four say nothing about the outbox, the phone layout or the
refund of a used order, and lesson 5's state-transition tests and lesson 7's screens still matter.
Acceptance criteria are the client's minimum, written in the client's words: **passing them means
the client agreed it does the job, and says nothing about what nobody thought to write down.** The
next section is about how a session with the client finds some of that.
