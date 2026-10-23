---
title: Functional requirements that can be checked
version: 1
---

**A functional requirement says what the system does, for whom, and how anybody would know it was
done.** The last part is the one most often missing, and it is what turns a wish into a requirement.
Two forms dominate practice, and they suit different moments.

## Use case text

Lesson 2 drew the use case diagram and said the real use case is text. Here is the text for one of
Carcará's, in the shape Alistair Cockburn popularised:

```localised
Use case: Cancel a paid ticket
Primary actor: Passenger
Precondition: the passenger is signed in and owns a Paid ticket
Main success scenario:
  1. Passenger asks to cancel the ticket.
  2. System shows the refund amount and the policy that applies.
  3. Passenger confirms.
  4. System releases the seat and requests the refund.
  5. System confirms the cancellation by e-mail and in the app.
Extensions:
  2a. Departure is less than three hours away:
      System offers a change to another trip for a fee; no refund.
  2b. The trip has already left:
      System refuses, saying why.
  4a. The refund request fails:
      System keeps the ticket Cancelled, retries the refund,
      and alerts Payments after three failures.
Success guarantee: seat released; refund requested exactly once.
```

The value is in the **extensions**. The main scenario is what everybody already imagined; the
extensions are the questions somebody has to answer, and each answer is a requirement. 2b is the
third guard lesson 4's activity diagram found; 4a is a quality requirement hiding inside a
functional one.

## User stories with acceptance criteria

Agile teams write a requirement as a **user story**, *as a passenger, I want to cancel a paid ticket,
so that I get my money back when my plans change*, and make it checkable with **acceptance
criteria**. A common shape for the criteria is *Given / When / Then*, from behaviour-driven
development:

```localised
Given a Paid ticket for a trip departing in 5 hours
When the passenger cancels it
Then the seat is released
And a full refund is requested once
And the passenger receives a confirmation e-mail

Given a Paid ticket for a trip departing in 2 hours
When the passenger cancels it
Then no refund is requested
And the passenger is offered a change for a fee
```

Each scenario names a starting state, an event and observable results: the state table from lesson
4, written for one row at a time. Many teams run criteria in this form as automated tests.

## Which to use

- **Use case text** when the behaviour has many branches and several actors, and the analysis is done
  before the work is split up. It keeps the whole goal in one place.
- **Stories with criteria** when the work is planned in small increments. A story is a slice of a use
  case; several stories together usually cover one.

Either way, **a functional requirement without a way to check it is a topic, not a requirement**.
*Passengers can manage their tickets* is a topic. The use case above is a requirement.
