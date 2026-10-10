---
title: The winner's curse
version: 1
---

**A significant result from a test overstates its effect, on average**, and the smaller the test, the
more it does. This is called the winner's curse, and it follows from how significance works rather
than from any mistake.

Imagine a change with a true lift of 0.3 points, tested with Panela's sample, which was sized for
0.6. Every run of that test produces a different estimate: some near 0.3, some near 0, some near
0.6, by chance. Only the runs whose estimate happens to land far from zero cross the significance
line. **So the significant runs are, by selection, the ones that overestimated**, and the team only
ever hears about those. A test sized for 0.6 that comes out significant will usually report a lift
nearer 0.6 than 0.3, whatever the truth.

Three habits keep it in check.

- **Size the test properly.** A test with high power for the effect it finds reports that effect with
  little exaggeration. The curse is worst in underpowered tests, which is lesson 8's warning made
  concrete.
- **Expect less after launch.** If a test barely crossed the line, plan for a smaller effect than it
  reported. Panela's after-launch tracking is how the real effect is learnt.
- **Report the interval, not the point.** The lower end of the interval is a sober estimate; the
  point estimate of a just-significant test is an optimistic one.

The curse also explains a common complaint: "every test we run wins, and the business does not move".
Many small wins, each overstated, each partly novelty, add up to much less than their sum promised.
Lesson 11 adds the other half of that story: tests that win by being looked at too often.
