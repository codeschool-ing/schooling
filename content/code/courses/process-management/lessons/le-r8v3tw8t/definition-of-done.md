---
title: The Definition of Done
version: 1
---

The Definition of Done is **a formal description of the state the Increment is in when it meets the quality measures required for the product**. When a backlog item meets it, an Increment is born. When an item does not, it is not shown at the review and it goes back to the Product Backlog for future consideration. There is no "nearly done" in the guide's vocabulary.

## What one looks like

A Definition of Done is a short list that applies to every item, written by the team or inherited from the organisation. For the Agenda team at Ponte Saúde — the invented team this course follows, building an appointment app for physiotherapy clinics — it reads:

- the code is reviewed by somebody who did not write it;
- automated tests cover the new behaviour and the whole suite passes;
- the change is deployed to the staging environment and checked there;
- the accessibility checks pass on every screen the change touches;
- the user-facing text exists in Portuguese and in English;
- anything an operator needs to know is in the runbook.

**Every line is something somebody can check with a yes or a no.** "Good quality" is not a line; "the whole suite passes" is.

## Done is not acceptance criteria

Two lists are often confused. **Acceptance criteria belong to one item** and say what that item must do: *a patient can cancel up to 24 hours before the appointment*. **The Definition of Done belongs to every item** and says how finished it must be: reviewed, tested, deployed to staging. An item needs both to count, and a team that writes its quality rules into every story's acceptance criteria ends up with a different Definition of Done per story.

## Why it matters to an architect

The Definition of Done is where non-functional requirements get teeth. An organisation that needs every change to keep the p95 response time under a limit, to log in a structured format or to pass a security scan can write that into the Definition of Done, and from then on it is part of what *done* means rather than a separate task somebody schedules when there is time. If the organisation has a standard Definition of Done, every Scrum Team must follow it as a minimum, and teams may add to it.

The cost is also visible here. A Definition of Done that requires a manual regression test of the whole app makes every item slower to finish, and the honest response is to automate the test or to accept the slower pace — not to drop the line quietly in the last days of a Sprint.
