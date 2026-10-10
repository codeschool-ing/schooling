---
title: Choosing the cells
version: 1
---

Two choices come naturally and both are poor. One is to test on whatever the tester happens to
have, which tests the tester's own habits. The other is to test on as many cells as time allows, in
no particular order, which stops wherever time runs out. **Coverage is chosen from two inputs:
who actually uses the product, and where it is most likely to break.** The first says which cells
matter; the second says how deeply to test each.

## Who uses it

The theatre already has a website, and its statistics say what its visitors used last month:

| browser and platform | share of visits |
|---|---|
| Chrome on Android phones | 46% |
| Safari on iPhones | 24% |
| Chrome on Windows | 13% |
| Edge on Windows | 7% |
| Safari on Macs | 4% |
| Firefox, every platform | 3% |
| everything else | 3% |

Seven visits in ten come from a phone, which turns R8's 360 pixels from a detail into the main
case. And the first two rows alone are seven in ten, so a defect that only shows in Chrome on an
Android phone reaches nearly half of the audience.

**Audience data describes the people the old site worked for.** If the old site had been broken in
Firefox, Firefox users would have stopped coming, and the statistics would show a small Firefox
share as if it were a fact about the audience. Read a low share as a question before reading it as
a reason to skip a cell.

## Where it is likely to break

The second input is risk, the same likelihood and impact that ranked boxoffice's risks in lesson 1.
For compatibility, likelihood comes from what differs between environments:

- layout, because each engine computes widths slightly differently, and fonts that differ by system
  make the same word wider or narrower;
- form controls, because the show menu, the Student checkbox and the text fields are drawn by the
  system, not by the page;
- scripts, because code running in the browser meets each engine's own quirks.

boxoffice sends plain HTML with one short block of style and no script at all, so the third risk is
absent and the first two are small. That is a real finding about the product, and it is why a
modest matrix is defensible here. A booking page built from a large script framework would earn a
wider one.

Impact comes from the audience table: a fault in Chrome on Android costs nearly half the customers,
one in Safari on a Mac costs four in a hundred.

## The choice for boxoffice 1.0

Put together, the two inputs give every cell a depth rather than a yes or no:

| cell | why | depth |
|---|---|---|
| Chrome on an Android phone, 360 | 46% of visits, a phone | full pass |
| Safari on an iPhone, 360 | 24%, the only engine on an iPhone | full pass |
| Chrome on Windows, desktop | 13% | full pass |
| Edge on Windows, desktop | 7%, the same engine as Chrome | short pass |
| Safari on a Mac, desktop | 4%, WebKit at desktop width | short pass |
| Firefox on Windows, desktop | 3%, the only Gecko cell | short pass |
| Chrome, Firefox and Edge on an iPhone | WebKit, already covered by Safari on the iPhone | not tested, and the plan says so |

A **full pass** runs every case. A **short pass** runs lesson 8's smoke list and the cases for the
highest risks, and then looks at each page at that size: does everything show, can every control be
reached and used. Three full passes
and three short ones fit in the time fourteen full passes would not, and every engine and both
sizes are in it.

Two rules are worth keeping beyond this example. **Every engine gets at least one cell**, because
engines are where the differences are, however small an engine's share. And the cases that carry
the highest risks of the plan, the price and the phone layout for boxoffice, run in every cell that
is tested at all; it is the low-risk cases that are spread thin.

## What the lab can reach

Ana's laptop runs Ubuntu. Chrome, Firefox and Edge all have Linux versions, so the engines of the
three Windows cells are on her desk, drawing with Ubuntu's fonts instead of Windows', which is close
and not the same. Safari runs only on Apple's systems, and neither phone is a laptop. So three of
the six chosen cells need something Ana does not have, and section 05 of this lesson is about where
those come from. Whatever the answer, it goes in the environment row of the plan from lesson 1, which
said "Chrome, Firefox, Safari and Edge, current versions; a phone 360 pixels wide" and can now say
which, where, and how deeply.
