---
title: Fixing it, and why a longer timeout is not a fix
version: 1
---

**The fix for a flaky test is almost never a longer timeout.** It is the first thing people try,
because the failing attempt usually ends in a timeout message and raising the number makes the
message go away for a while. A timeout is a limit on how long a check may wait for something that
will happen. It helps only when the thing really does happen, just later than the limit allowed,
and that is the rarest of the six causes.

Look at the failing attempt in the diagnosis section. It took 6.1 s, because `toHaveText` waited
out its five seconds against a list that already said three fruit and was never going to change.
A limit of thirty seconds would have made that attempt take thirty seconds and fail in exactly
the same way. **Waiting longer for a wrong final state only watches it longer.** The same holds for
the shared basket: a count of 2 does not become 1 if you wait.

## The fix belongs to the cause

| cause | the fix | where this course does it |
|---|---|---|
| timing | wait for a state that is false until the page is done, never for a length of time | lesson 3, and lesson 13 |
| shared state | each test gets data nobody else touches | lesson 15 |
| order | each test sets up its own starting point | the reset in lessons 6 and 10, and lesson 15 |
| environment | remove the difference between machines, or make the test say which one it got | the platform's fonts |
| the test itself | no unexplained randomness: fixed or seeded values, and a rate written down where one is accepted | lesson 2's test ids |
| the application | fix the page; the test was right | below |

The platform's cases fit the same table. The course-card race was fixed by waiting for the heading
to name the course that was asked for. The Go packages stopped colliding when no test seeded a fixed
name any more. The font difference went away when the fonts were served from the platform's own
address, and the graph test still prints which ones loaded. The practice screen's shuffle stopped
deciding the accessibility check when the suite began asking for each outcome by name; the
platform's roadmap puts it as *a state it can only reach by luck is a failure and not a skip*.
Two more of its rules are this table's fifth row in practice. The grader that checks an algebraic
answer evaluates it at fixed points, *never random*. The drawing of its track graph uses a seeded
shuffle, so a track does not change shape between visits.

## The search, fixed

The shop's search is the last row. Lesson 3 showed one fix: remember what was asked and drop any
answer to a question the box no longer holds. With that listener in place of the old one in
`app/public/search.js`, the quarantine job:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  20 passed (20.8s)
```

Twenty of twenty. How much that proves depends on the rate it replaced. Before the fix this test
failed 5, 6 and 8 attempts in twenty on three runs, about one in four. At that rate, twenty passes
in a row would happen by luck with a chance of 0.75 raised to the power 20, about 3 in 1,000, which
is strong evidence. **A short green streak proves little about a rare failure**, though. Had the
test failed one attempt in twenty, twenty passes in a row would still happen about 36% of the
time, since 0.95 raised to the power 20 is about 0.36. So measure a fix where the test failed most,
many times, and prefer a fix you can explain from the code, as this one can. Put the original `search.js` back after trying this: the shop's flaws are kept on
purpose for the lessons that use them.

## Leaving the quarantine

When the fix is in the application, the test moves back into `tests/` unchanged, because it was
right all along. When the fix is in the test, the changed test moves back. Either way the
quarantine folder gets one test shorter, and the annotation goes with it. A quarantine that only
grows is the slow deletion from the previous section.

In this project `quarantine/typing.spec.js` stays where it is, because the search defect stays:
lesson 3 left it in on purpose, and so does this lesson. The test is the record that it is there,
and that it shows only at some speeds.
