# The design sheets

One file per course, written **before** its material and kept afterwards. A sheet says how much
of everything a course carries, what it may assume from the courses before it, and what it needs
that does not exist yet.

[`../CONTENT.md`](../CONTENT.md) says what a course *is*. These say what each particular one
*will be*.

---

## Why they exist at all

A course designed alone comes out with the shape of the day it was designed. Twelve of them do
not: `aws-foundations`, `azure-foundations` and `gcp-foundations` have the same lesson count,
the same prerequisites and lesson titles that match word for word — they are one design applied
three times, and designing them a year apart would produce three.

The other half of the argument is that some questions only have an answer at catalogue scale.
Which courses cannot be finished until a sandbox runs a student's program. How many diagrams
somebody has to draw. Whether the declared hours are anywhere near the material. **None of those
is visible from inside one course**, and all of them change what gets built first.

---

## What the sweep has found

### `infra` — the sandbox stops being a runtime

Everything before this category asked the same question of the sandbox: *which language*.
`foundations` wanted a shell and nothing else. **`infra` asks a different question, and the answer
is not a list of languages** — it is a list of environments, and some of them cannot be built at
any price.

| what a course needs | courses |
|---|---|
| nothing | `cloud` |
| a **shell** | `linux-terminal`, `networks`, half of `iac` |
| a shell and a **container daemon** | `docker` |
| a **cluster** | `kubernetes`, `gitops` |
| a **network topology** | `networks-addressing`, `-availability`, `-security`, `-automation` |
| a language **and** a topology | `networks-automation` |
| a **paid account with a third party** | the nine `aws-`, `azure-` and `gcp-` courses |
| a **hypervisor the student drives** | `virtualization` |
| **three desktop operating systems** | `operating-systems` |

Three things follow that no single sheet says on its own.

**Nine of twenty-three are blocked by money rather than by engineering.** A vendor course needs a
real account with a real bill, which is not a sandbox problem and will not be solved by building
one.

**Two have no path at all.** `virtualization` is about building a lab on the student's own
machine, and `operating-systems` covers two desktops nobody can hand out from a browser. For
`virtualization` that may be the answer rather than the problem: the environment is the student's,
and the material should be written to assume that instead of working around it.

**And a topology is the cheapest environment on the list** — several containers that can see each
other is not a cluster — and it serves four courses. If anything beyond a shell is built, that is
the one with the best ratio.

### The reach that was not obvious

`linux-terminal` is **free**, in **ten tracks**, with four dependents — and two of those,
`docker` and `networks`, reach fifteen tracks between them. Only `git` (13) and
`web-fundamentals` (12) appear in more, and neither is free *and* a prerequisite of this much.
It is a stronger argument for shell-first than `git` was, and a different one: conversion rather
than retention.

### Ageing is concentrated, not spread

**Eleven of twenty-three teach somebody else's interface** — the nine vendor courses,
`operating-systems` and `virtualization`. In the rest, the subject outlives its tools. That is
the split that decides which courses can be re-rendered from a file and which have to be
re-recorded by a person.

### `management`, `architecture`, `career` — the bottleneck moves, it does not go away

Fourteen courses, 780 hours, swept together because a guess had been made about them: that they
need no runtime, no browser and no database, and are therefore the cheapest hours in the
catalogue to build. **The guess was right about the sandbox and wrong about the conclusion.**

Thirteen of the fourteen need nothing to run. The exception is `design-patterns` — 80 hours of
SOLID, GoF, TDD and the actor model, where a quarter of the natural exercises are code. Every
other course in the three categories could be published tomorrow as far as an environment is
concerned.

What stops them is the other end. `internal/grade` carries **eight graders and every one of them
checks a closed form** — a choice, an ordering, a number, a label on a picture. None of them reads
a paragraph, and a paragraph is what one-to-ones, feedback, technical proposals, mediation and
saying no are made of. `people-leadership` is the extreme: 24 lessons, ~600 exercises, and no
grader that fits its subject.

**The rescue is the scenario with four replies**, and it is a cost rather than a solution. *Here is
what the engineer said; which of these four answers is feedback and which three are judgement
dressed as feedback* is a `quiz`, and it grades today. It is also several times more expensive to
write than a quiz about a fact, because each wrong answer has to be wrong for a reason a reader can
find. That is the authoring bill for a large part of 780 hours, and it was invisible while the
sandbox was the thing being counted.

Three courses escape it on their own material, and it is worth knowing which: `delivery-metrics`
(Little's law, DORA, error budgets, Monte Carlo — `numeric` fits better than anywhere outside
mathematics), `tech-strategy` (total cost of ownership, cost of delay, debt priced as interest) and
`tech-support` (reproduce, isolate, test, confirm — a method in four steps is an `ordering` item,
and every lesson after the first can reuse the shape).

### `C-28` is keyed on position and does not know about `continues`

Two courses in this batch are free, and **nobody arrives at either of them free**:

| course | free because | reached by |
|---|---|---|
| `process-management` | position 1 of `tech-lead` | a track whose own goal says it "does not start a career, it continues one" |
| `architecture-role` | position 1 of `software-architecture` | a track that `continues: backend` — fifteen paid courses first |

`C-28` makes the first course of a track the free sample, and it was sized on `web-fundamentals`,
which really is what a visitor meets before paying anything. Applied to the two continuation
tracks it gives away **100 hours to students who have already converted**. The same defect found
independently in both is what makes it a rule problem rather than two accidents — and the rule
already has the field it needs to tell the cases apart, because `continues` is in the data and the
free-sample rule does not read it.

The sheets do not decide it. It is a pricing decision, and it belongs beside the free-tier question
`computing-essentials` already raises from the other direction.

### The two courses everybody finishes through, and nothing points at

`portfolio-project` and `first-job` are the last two courses of **all sixteen tracks that start a
career** — always in that order, always at the end, absent from the three tracks that continue one.
Sixteen tracks each is **the widest reach in the catalogue**, wider than `git` (13) and
`web-fundamentals` (12).

Neither has a single dependent. By the dependency graph they are leaves and rank last; by the
student's experience they are the final impression the school leaves and rank first. **Those two
readings disagree maximally, and this is the only place in the sweep where they do.** A
graph-shaped argument about what to build first cannot see these two courses at all, which is a
reasonable summary of why the sweep is worth its time.

### Two courses want the same mechanism, and it does not exist

Nothing in `content/` lets a course, a lesson or a section differ by the track that reached it or
by the option a student took at a fork. Two sheets in this batch need exactly that:

- **`design-patterns`** sits behind `backend`'s choice of JavaScript, Python, Java or Go, and every
  pattern it teaches is code in one of them. Pick one language (wrong for three quarters of
  readers), write four snippets (four times the writing and the maintenance), or use pseudocode
  (grades nothing).
- **`portfolio-project`** has sixteen audiences and knows it — lesson 3 is *"Choosing by track: what
  somebody hiring in your field actually opens"*. Generic is the one thing a portfolio course must
  not be.

One course wanting a mechanism is a request. Two, arrived at from different categories for
different reasons, is a decision with something behind it.

### Nobody has been named to draw ~1,750 pictures

Summed across the 40 sheets written so far, the diagram estimates come to **1,747** — for a third
of the catalogue. The heaviest are `architecture-modeling` (~130), `data-storytelling` (~90) and
`computing-essentials` (~85), and in two of those three **the images are the assessment rather than
the illustration**: "mark the three things wrong with this chart" is a `labelling` item, which is
the one grader that fits soft material well, and it does not exist without the picture.

This began as a note on one sheet. At three courses and ~305 images between them it is a
catalogue-level fact, and it has no owner.

---

## What a sheet is not

**It is not the material, and it is not a promise about the material.** Every number in a
`Shape` block is an estimate that the section design replaces — the same relationship `C-27`
already sets between a course's declared hours and what it turns out to hold. A sheet projects;
the release measures.

**It is not a schedule.** No sheet says when.

---

## The format, and the one thing that is checked

Each sheet declares `format` in its front matter:

```markdown
---
format: 5
course: web-fundamentals
---
```

**The current format is whatever the newest sheet declares, and every other sheet has to match
it.** There is no constant anywhere saying which format is current — a constant would be a second
place to disagree, and it would disagree the first time somebody bumped one file and not the rest.

So raising the format on one sheet is what makes the check fail on the others, by name. That is
the intended behaviour rather than a side effect: **a half-migrated register is the thing being
prevented**, because a sheet written against an older format looks finished and is missing fields
nobody remembers.

`.github/workflows/docs.yml` runs it, and that workflow is deliberately not filtered by path —
a check on documents has to run on a change that touches no code.

### What the check asks

| | |
|---|---|
| every sheet declares `format` and `course` | a sheet with no format cannot be told from a current one |
| every sheet declares the same format | the newest is the current one |
| `course` names a course that exists in `content/` | a sheet for a course that was renamed is a sheet nobody will find |
| two sheets never name the same course | |

It does **not** ask that every course has a sheet. Coverage is reported and not enforced: the
sweep is deliberately partial for a long time, and a check that failed on the 119 missing ones
would be a red build describing a plan working as intended.

---

## Format 5

| block | what it holds |
|---|---|
| **Reach** | the tracks it appears in and where; whether it is free (`C-28`); what depends on it; whether a track reaches it through a *choice*, in which case nothing after that choice may assume it |
| **Assumes / leaves ready** | what `requires` lets the prose take for granted, and what this course owes the ones below it. This is the field that stops 122 courses re-teaching HTTP |
| **Shape** | declared hours, lessons, **hours per lesson**, and the **section budget** those hours buy. Not an hours estimate — see below |
| **Execution** | runtime, browser, database, exercises *blocked* without a sandbox against exercises that would merely *improve*, and the diagram count |
| **Ageing** | whether the video depends on a third party's interface — the one kind of material that goes wrong while its script stays right |
| **Sections** | optional, and present only once a course's sections are designed: every section numbered, with its slug, its kind and what it covers |
| **Flags** | what needs a decision, numbered, with the cost attached |

**A sheet with a `Sections` block states the same fact twice** — once as the list and once as the
total in `Shape` — so the check compares them, and compares the numbering against itself. A gap
or a repeat in 1..N is the silent kind of defect, because the list still reads as a list.

### What each format added

**1 → 2.** Execution. The sweep turned out to be the only thing that could size the sandbox —
which languages, whether a browser is needed, how many exercises actually depend on it — and
without those fields it could not.

**2 → 3.** Three fields, each from something a category revealed that the previous one had not:

- **choice**, because 30 courses are reached through a fork rather than in sequence, and a course
  after a fork may not assume any of its options was taken;
- **ageing**, because `C-30` made the screen the frame, and a screen showing somebody else's
  product is the only material that expires on its own;
- **video as an estimate rather than a target**, after `C-36` — two numbers had been invented for
  it before anybody noticed they were being obeyed.

**4 → 5.** The `Shape` block stopped estimating hours and started stating facts, because the
estimate was an artefact of its own proxy.

A rule projecting sections from the *lesson count* — 7.7 a lesson, measured on `web-fundamentals`
— was applied to the 23 courses of `infra` and **fired on 15 of them**, in both directions:
`kubernetes` +116%, `docker` +102%, the nine vendor courses between +32% and +55%, `cloud` and
`networks` at −40%. A rule that fires on two thirds of a category is not finding exceptions.

Anchoring on the hours instead — sections = hours × 60 ÷ 28, floored at the minimum shape of four
a lesson — puts almost every course at its declared figure, and puts `web-fundamentals` at 86
against the **85 that were actually designed**. That course is the only one whose sections were
drawn against the material rather than projected, so its agreement is the evidence, and it says
the declared hours were fine and the proxy was not.

What survives is better than what was lost: **hours per lesson varies 3.6× across the catalogue**,
from 1.67 in `kubernetes` to 6.00 in `cloud` and `networks`. A six-hour lesson needs about
thirteen sections and a 1.7-hour lesson sits on the floor of four. Those are different objects,
and a sheet that says so is more useful than one that reports a divergence its own arithmetic
invented. The 20% rule is retired with it.

**3 → 4.** The `Sections` block, so that a course whose sections are designed keeps that design
where its material will be written rather than in a rendering of it. It arrived with the third
instance of one habit: the section list had every lesson opening with a video and seven of eleven
with the second video in the penultimate slot, and **neither had been decided** — it was one shape
applied eleven times.

Checking it lesson by lesson is what makes the entry worth reading. Most of those positions turned
out to be right for a reason that belongs to the material: a demonstration shows what an
explanation has established, so it falls late on its own. **The suspicion was correct about the
opening and wrong about the demonstration**, which is why a pattern is worth checking rather than
either trusted or condemned.
