---
title: loanbook's retrospective
version: 1
---

Here it is, as it would be committed beside the README. It is one page, and every claim in it can be
traced to something in this course.

```localised
# loanbook: a retrospective

Five weeks, 1 June to 6 July 2026, four milestones, all reached on their dates.

## What went well
- The refusal went into the second milestone, right after the skeleton. Whatever happened
  later, the one thing the project had to prove was done by 15 June.
- The test for it was checked by removing the index and watching it fail.
- The deploy survived being killed: systemd restarted it and the data was in the volume.

## What did not
- The rules milestone took five working days against an estimate of three and a half. The
  estimate covered the two rules and not the error handling and empty state they needed.
- An unexpected error still closes the connection instead of answering 500.
- There is no loading state; on a slow phone the table is empty for a moment.
- The borrower's name was drawn as HTML until the accessibility commit. A self-review found
  it late, in code written two weeks earlier.

## What I would do differently
- Estimate each milestone, including its should items, not only the musts.
- Build every row with textContent from the first commit that shows user input.
- Add the 500 and the loading state before calling it v1.0.0.

## What I learned
- A database constraint is a better place for a rule than a check in code, when two
  requests can arrive together.
- A tool like axe passes things a keyboard walk does not.
```

Notice its tone. **Facts, then conclusions**: *five days against three and a half* before *estimate each
milestone*. **No blame and no apology**, including towards yourself: *the self-review found it late* says
what happened and what changes, which is all a reader needs. And **the what-did-not section is the longest
one**, which is honest, and is also what makes the what-went-well section believable.
