---
title: The cost of a late finding, and the number everybody quotes
version: 1
---

Every argument for shifting left ends up at one chart. A bar for each phase of a project, a defect
costing 1 unit to fix at design, 6.5 in implementation, 15 in testing and **100 after
release**, attributed to the "IBM Systems Sciences Institute". It is in vendor slides and in
textbooks, and it is quoted as a measurement.

**Nobody who has gone looking has found the study behind it.** The trail ends at course notes
from an IBM training institute in the early 1980s, cited second hand by later books. No paper with
the projects, the data or the method has turned up. Laurent Bossavit's *The Leprechauns of
Software Engineering* is the best-known account of that search, and it treats the chart as what it
is: a number that has been repeated so often that it reads as a finding.

### What the older data actually said

There is real data in the neighbourhood, and it is narrower than the chart. Barry Boehm's
*Software Engineering Economics* (1981) collected the cost of fixing defects on large projects of
the 1970s. They were built in long sequential phases, so a requirement misunderstood at the start
could be discovered years later, in a system already delivered. In 2001 Boehm and Victor Basili put "often
100 times more expensive" at the top of their list of defect-reduction facts in *IEEE Computer*.
The same item said that for small, non-critical systems the ratio was **closer to 5 to 1**.

So the honest version is this. On large projects with long phases, late defects cost a great deal
more than early ones. The old studies saw ratios in the tens to a hundred. Where the system was
small, the gap was small even then. **Nobody measured security findings in a
pipeline on a service like linkbox**, and a slide that applies 100x to it is decorating an
argument with a number it does not have.

### The argument without the number

Shifting left does not need the chart. It needs four things that are true of linkbox today, and
each one can be checked rather than believed:

| what grows with time | why |
|---|---|
| **the context to rebuild** | the author of a change knows why each line is there for a few hours; a week later they read it like anybody else |
| **the code built on top** | other changes start depending on the flawed one, so the fix touches more than the line that was wrong |
| **the copies** | once the image is pushed it is in the registry, on servers and in caches; a fix has to reach every copy |
| **the time it is exposed** | a flaw in production is open to anybody who finds it, for as long as it stays there |

None of these needs a multiplier to be convincing, and none of them says how big the difference
is. That part is a measurement your own team can make: **how long, in minutes, from pushing a
change to reading its result**, and how long, in days, from a finding being raised to being fixed.
This lesson measures the first one on linkbox, and lesson 20 measures the second.

### Why this matters in a security course

A security programme runs on trust. The developers are asked to accept a slower pipeline and a
build that breaks for reasons they did not choose. They accept it because the people asking are
believed. **A number that falls apart when somebody checks it spends that trust.** The
developer who looks up the 100x and finds course notes nobody can read will wonder what else on the
slide was decoration. Quote what you measured; where you have no measurement, give the reasons and
say that they are reasons.

The same discipline is the one this course keeps for its own transcripts. Every count it quotes,
from Bandit's findings in lesson 3 to the vulnerabilities in an image in lesson 8, was printed by a
tool on a machine like yours, and you can make the tool print it again.
