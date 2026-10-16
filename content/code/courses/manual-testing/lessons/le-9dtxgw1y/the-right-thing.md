---
title: When the requirement is the problem
version: 1
---

The first three sections of this lesson produced three kinds of finding, and only one of them is a
defect in boxoffice. **Each kind goes to a different place and is decided by a different person**,
and sending one to the wrong place is how a good finding disappears.

## Four findings, four destinations

| what you found | what it is | where it goes | who decides |
|---|---|---|---|
| boxoffice does something R1 to R9 say it must not | a defect | a defect report citing the requirement, lesson 15 | the team, at triage, lesson 16 |
| a requirement can be read two ways | an ambiguity | a question to the requirement's owner, before the cases are written | the owner |
| boxoffice meets the requirement and the requirement misses the need | a validation finding | the same owner, with the journey that shows it | the owner |
| boxoffice departs from the requirement and the departure looks better | a defect, for now | a defect report that says so, and a proposed change to the requirement | the owner |

The owner here is the theatre's manager, who wrote R1 to R9. In a larger organisation it is
whoever holds that role: a product owner, a business analyst, the client's representative.

## Two ways to lose a finding

**Reporting a validation finding as a defect.** Ana files "boxoffice refuses a school group" in
the defect tracker. Rui reads R4, sees that boxoffice does exactly what it says, and closes the
report as working as specified. He is right, and the question about school groups is now closed
with it, in a tool the manager never reads. Lesson 16 is about rejections like that one, and most
of them are correct about the product and silent about the requirement.

**Testing against what you think the theatre wants.** The opposite mistake is quieter. Ana decides
that half price obviously means per ticket, writes her cases to expect R$ 152,00 for the family of
section 03, and reports a defect when boxoffice charges R$ 120,00. Now the expected result in her
case is her own opinion, and Rui has a report saying his code is wrong against a rule nobody wrote.
Lesson 1 said a tester tests against something written down; when the written thing is unclear,
the fix is to get it rewritten, not to fill the gap privately.

The path between them is to test the requirement as written, and to raise the question about it
separately, to its owner, in words the owner can answer.

## The departure that looks better

The fourth row of the table is the one people argue with. Suppose Rui, finding R6 awkward, had made
boxoffice let a customer cancel a paid order as well as a reserved one, and the manager liked it.
It still goes in as a defect, with a sentence saying it looks like an improvement, because **a
requirement that no longer describes the product makes every later test wrong**. The next tester,
or Ana herself in lesson 10 running the regression suite, would report the same departure again,
and the cases that cite R6 would expect something the product no longer does. Either the product
goes back to R6, or R6 changes to match the product. The owner picks, and the report is how the
choice reaches them.

## What happens once the answer arrives

Say the manager answers the R5 questions: half price is per ticket, and a student shows a card at
the door. The change travels in a fixed order:

1. the requirement is rewritten first, so that it carries the answer: "Each student ticket costs
   half the show's price, and the student shows a student card at the door";
2. the cases that cite R5 change next, which lesson 2's traceability makes a search rather than a
   guess;
3. the product changes last, and the changed cases are what checks it.

Doing it in any other order leaves one of the three out of step with the others for a while, and
"for a while" in a project is often until release day. A change to a requirement in the middle of
a release can also move the plan, because new work arrived; section 07 of lesson 1 is where the
schedule says what waits for what.

None of this is a tester rewriting requirements. Ana may propose the wording, and often should,
because she has just been reading every sentence for its second meaning. The decision stays with
the person who owns the need, and **the tester's part is that no question goes unasked and no
answer stays outside the written requirements**.
