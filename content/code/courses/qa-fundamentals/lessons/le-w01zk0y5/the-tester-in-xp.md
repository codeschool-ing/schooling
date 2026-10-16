---
title: The tester on an XP team
version: 1
---

**The first XP books had no tester in them.** Programmers wrote the unit tests, the customer wrote the
acceptance tests, and that was meant to be all. Teams that tried it found the gap quickly: customers are not
trained to think of the cases nobody mentioned, and programmers testing their own code share its blind spots.
Lisa Crispin and Tip House wrote *Testing Extreme Programming* in 2002 about exactly that gap, and the role
they described is close to the one this course has been building.

## What moves away from the tester

On an XP team, two things a tester used to do are done by somebody else, and done earlier.

- **Checking that the code does what the programmer meant.** The programmers' own automated tests, written
  before the code, cover it. A tester who spends the day re-running what the unit checks already prove is
  wasting the day.
- **Running the regression suite by hand.** Continuous integration runs every check several times a day. The
  old weeks of manual regression testing from lesson 10 do not exist.

## What moves towards the tester

What takes its place is the work that needs a tester's habits most.

**Helping the customer write acceptance tests.** Joana knows what a ticket should cost; she does not naturally
think of 59, 60 and 61, or of a student on a Wednesday. Lia sits with her and turns the rule into examples,
which is the work of lesson 12's acceptance criteria and, in lesson 17, of ATDD. In XP these examples become
automated customer tests that run in every build.

**Exploring.** Automated checks only confirm what somebody thought to write down. The questions nobody wrote
down are the tester's: the age typed as a word, the session time with one digit, the order of seven tickets.
On an XP team, exploration is most of what is left for a person to do, and it matters more, not less, because
everything else is automated.

**Pairing.** A tester can pair with a programmer as well. When Lia pairs with Rafael, she does not type the code;
she asks the questions while it is being written. Ten minutes of that, she says, saves an afternoon of
reporting.

## Continuous integration from a tester's side

Continuous integration changes what a failing check means. Before it, a failing check found in week three
pointed at three weeks of changes. Now it points at the last hour.

| | before CI | with CI |
|---|---|---|
| when the regression checks run | at the end of a cycle | on every merge, several times a day |
| how much changed since they last passed | weeks of work | one change |
| who notices a failure | the tester, later | whoever just merged, at once |
| what a red build means | "somebody broke something" | "my change broke something" |

The rule that makes it work is the one teams find hardest: **a red build is fixed before anything else**. A team
that lets the build stay red for days has lost what CI was for, because every new failure hides behind the
old one. That is lesson 13's stopping the line, applied to a build.

## The cost of believing the checks

One risk grows on an XP team rather than shrinking. With hundreds of automated checks passing every hour, the
team starts to read green as "it works". It means the code does what the checks say. Whether the checks say the
right thing, whether they are missing a case, whether the feature should exist at all: none of that turns
green. Keeping the team honest about the difference is part of a tester's job on any team, and an XP team needs
it most.
