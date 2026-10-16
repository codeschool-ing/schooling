---
title: From cause to action, and checking it worked
version: 1
---

**An analysis is finished when an action is chosen, owned and checked, not when the diagram is drawn.** A wall of
causes with no action under it is a record of a bad week, and the next week repeats it.

## Good actions and weak ones

The causes from the Wednesday fishbone produced a list of possible actions. They are not equally good.

| action | strength | why |
|---|---|---|
| "be more careful with discounts" | weak | it asks people to try harder at the thing they were already trying to do |
| "Lia reviews every price change" | weak | it adds a gate in front of one person, lesson 5's bottleneck |
| combination cases at every planning, from lesson 6's habit | medium | it changes the process, and depends on somebody remembering |
| an outline of discount combinations that runs on every change, from lesson 17 | strong | it is automatic, and the next stacking defect fails it the day it is written |
| a discount column in the nightly report | strong | it makes the next one visible even if every other step misses it |

The pattern is the one safety engineers use: actions that change the system beat actions that ask people to behave
differently, and an action that makes a failure *visible* is worth having even when the failure is supposed to be
prevented elsewhere.

## Every action has an owner and a date

Cine Aurora writes each chosen action on the board with a name and a date: *discount combinations outline, Rafael,
by Friday*; *discount column in the report, Tomás, next sprint*. An action without a name belongs to everybody, which
is to say nobody, and it is the first thing to fall out of the next sprint.

## Checking that it worked

An action is a hypothesis: *if we do this, defects like that one stop*. Like any hypothesis it can be tested, and the
retrospective a month later is where. Lia asks two questions:

- **was it done?** The outline exists and runs on every change; the report has its column.
- **did it work?** Since then, has a defect of the same kind reached a customer, or been caught later than it should?

The second question needs the defect records of lesson 4 to say what kind each defect was. That is one reason a defect
report has fields and not just a description: a month later, *how many discount defects reached the box office since
the outline?* is a question somebody can answer.

## There is rarely one root cause

The name *root cause analysis* suggests that every defect has one root, waiting to be dug up. The fishbone shows why
that is misleading: the Wednesday defect needed a silent requirement, a missing planning habit, a late review, no
automated checks and a report that hid discounts, all at once. Removing any of them would have stopped it.

Some writers prefer the term **contributing causes** for exactly that reason, and it is the healthier way to think.
A team hunting for *the* root cause stops at the first plausible one and feels finished. A team looking for
contributing causes keeps asking what else had to be true, and ends up with more places to act, most of them cheap.

That is the tester's case for root cause analysis, in one sentence: **testing finds the defect; analysis finds the
reasons the next one is coming, and it is the cheapest testing a team will ever do.**
