---
title: A one-page report for boxoffice 1.1
version: 1
---

Lesson 1's plan ended its list of deliverables with "a one-page summary at the end". This section
writes it, for boxoffice 1.1, from the 1.1 run in lesson 18's spreadsheet and the defects this
course has found so far. **Read it first the way the theatre's manager would: top to bottom,
stopping as soon as you have enough to decide.** The rest of the section says why each row is
where it is.

## The page

| | boxoffice 1.1, test summary, 10 October 2026 |
|---|---|
| answer | **Not ready to release.** Two of the plan's three exit criteria do not hold, and the third has not been asked for |
| if it is released as it is | Students are charged full price, or 10% off if they are members, instead of half: two tickets for Hamlet cost R$ 160,00 instead of R$ 80,00. A ticket already used at the door can be refunded, and its seat goes back on sale. A refund is accepted after the show has started. A word typed in the tickets field shows an error page with the program's own code in it. A customer using a screen reader is not told what the tickets field is for |
| also open, smaller | The shows table scrolls sideways on a phone, which the triage still put first for the next build. Refusing a move says "cannot be useed" |
| since 1.0 | Fixed: six tickets can be booked, and a member booking five pays 15% off instead of 25%. Broken: the student discount, which 1.0 got right |
| what would change the answer | The student discount, both refund defects, the error page and the label fixed in a new build, and lesson 10's regression suite run on it |
| exit criteria | Every case for risks A to C passes: **no**, three fail, one on price and two on refunds. No open critical or major defect: **no**, the student price and the refund of a used ticket are critical, and the late refund, the error page and the missing label are major. Acceptance signed off: not asked for while the first two fail |
| not tested | Payment, load and the real mail server, left out by the plan. The confirmation link, R3, has no case yet |
| numbers | 17 cases run: 10 passed, 7 failed, 0 blocked. 7 defects open, 2 fixed in 1.1, 1 new in 1.1 |

The defect reports, the spreadsheet and `results-1.1.xml` go with it as links, for whoever wants
to check a line.

## Why it is in that order

**The answer is the first row, and it is a word.** The manager who reads nothing else knows not to
release. "Not ready" is said plainly, without "some concerns" or "mostly passing", because a
softened answer is read as a yes.

**The consequences come before the evidence.** The second row is what happens to the theatre's
customers and money, in the theatre's words: prices in reais, tickets, refunds, the show starting.
There is no case id in it. Each of the five sentences is a defect report from earlier lessons,
translated into what a person at the box office would see.

**The smaller defects are named, and kept apart.** A misspelt message is not a reason to hold a
release, and putting it in the same list as the price would make the price look as small as the
message. Naming it still matters: the manager may decide to release a later build with those two
open, and that should be a decision rather than a surprise.

**"Since 1.0" is there because the last report is what the reader remembers.** 1.1 fixed two
things and broke one. Saying so stops the reader from assuming 1.1 is simply better, and it is the
regression lesson 10 found, stated as news.

**What would change the answer is specific.** Five defects, a new build, one suite run again. The
manager can ask Rui how long the five take and plan a date from that; "more testing is needed"
would give her nothing to ask.

**The exit criteria are the plan's, quoted back.** Nobody can argue that the bar was raised at the
end, because it was written in lesson 1 before any case ran. Severity is the one judgement in the
row, and it is lesson 15's scale, applied in lesson 16's triage.

**What was not tested is on the page.** The confirmation link has no case at all. A manager who
reads this page and releases knows that, which is the difference between a risk taken and a risk
not seen.

**The numbers are last, and every one says what it counts.** Seventeen cases, ten passed, seven
failed, nothing blocked. No pass rate, for the reason section 01 of this lesson gave.

## What was left out

The case-by-case results, which are one link away. The charts, which would say again what the
numbers row says. The effort: how many hours, how many cases written, which nobody deciding a
release needs. And the history of each defect, which lives in the tracker of lesson 17.

**Leaving those out is the hard part, and it is the skill.** A tester who has spent two weeks on a
release knows every one of those details and wants each to be seen. The page is not a record of
that work; the spreadsheet, the XML and the reports are. The page is the one thing the manager has
to read before she decides, and it fits on one page because she has other things to read today.

## Writing yours

Whatever the product, the same rows work:

1. the answer, in one word or a short sentence;
2. what happens if it is released as it is, in the business's words;
3. smaller problems, apart;
4. what changed since the last release;
5. what would change the answer;
6. the exit criteria of the plan, each with yes or no;
7. what was not tested;
8. the numbers, each saying what it counts.

If the page does not fit on one page, the second row is usually trying to describe every defect.
Keep the ones that would change the decision, and link the rest.
