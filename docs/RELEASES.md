# Releases of a course

A course is published as a **set**, not as a pile of files that happen to have been edited on the
same afternoon. Prose, exercises and videos are frozen together, verified together, approved
together, and go into effect together.

Nothing here is built, and everything in it is decided. The state column is kept anyway, because
rows will be added and a proposal recorded as a decision is how a document starts lying.

---

## What it buys

**It stops video v2 being on the air with prose v1.**

Version the pieces separately and nothing closes that: the script is corrected, the render comes
back, and the text beside it still says the old thing. In the window between the two publications
the lesson contradicts itself — and nobody notices, because each piece is internally consistent.

The second gain is answering **for good what the student saw**. If progress, an answer and a
watched milestone all name a release, "why did they get this wrong in March" has an answer in
March, which is the same argument as `K-03`.

---

## The parts, and which carry a version

```
web-fundamentals  v3.4.1
  prose        v12       the reading event records the version read
  exercises    v4.8.9    an answer records the version it answered (C-16)
  videos       v2        an event records the version watched, and the object key carries it (C-18)
  structure    = major   no number of its own, because it already has one
```

The first three carry a number because **they move without moving the release**: two exercises and a
video can rise together in one publication, and the release's own number does not say which of them
did. That is what makes the parts' versions the thing every machine answer is read from (`C-25`).

Structure cannot do that. It does not move without producing a *major*, and a *major* does not
happen without it — so the `3` in `v3.4.1` **is** the structure, in its third shape. A separate
`structure: v3` would be the same integer written twice, and two copies of one truth is what ends
up disagreeing.

| Decision | Why | State |
|---|---|---|
| A course is released as one set | The only thing that closes the window where one piece is newer than another. | Decided |
| Prose, exercises and videos carry versions; structure does not | The first three move independently of the release number and something records which one a student met. The structure is the release's own shape. | Decided |
| Prose is versioned per section — one `.md` file | "Nothing points at it" described the system as it was, and is circular as an argument about what to build: if we want to compare, we make the pointer. | Decided |
| A translation declares the version it translated | Falls out for free, and catches a defect class nothing sees today: `ls` shows that a `.pt.md` exists, never that it has gone stale. | Decided |

---

## The ruler

**major is the shape. minor is new material. fix is a correction.** In any of the three media —
prose, exercises and video are read the same way, because a student reads one, watches another and
answers the third, and none of that tells you what a change did.

| Level | What it means | What is computed |
|---|---|---|
| **major** | the shape moved: a section or lesson added, removed, reordered, or its `kind` changed | compare the trees of ids and order |
| **minor** | material that is **new** — an exercise or a video with an id that did not exist | compare the sets of ids |
| **fix** | something changed **in place** | everything else is identical |

Two of the three are settled by a diff. The third is not, and saying so is the point: **a corrected
accent and a rewritten section raise the prose version identically**, because the difference is
intent and no diff carries intent.

**So the tool computes a floor, whoever publishes may raise it with a reason, and nobody lowers it.**
A change in place floors at *fix* and is declared *minor* when it was evolution rather than repair.
Content redistributed among the same sections floors at *fix* too, and is raised to *major* by hand,
because no diff sees it. The number is left incapable of understating — the dangerous direction —
and judgement enters only where the machine is blind.

**A course's first release is `v1.0.0`, declared rather than derived.** The ruler describes
transitions, and the first publication has no predecessor to diff against — no level can be
computed, because the floor has no input. Being a declaration, it should say what is true:
`v0.1.0` would announce that this is not yet the course, which contradicts `C-26`, and climbing
from `0.x` to `1.0.0` would need the shape to move, which is the wrong reason to reach a
major. A course exists, complete, or it is a draft and is not published at all.

**Why a new id can be trusted where a changed one cannot:** an exercise or a video that did not
exist before cannot be a correction, since there was nothing to correct. That is the one case where
"new" is a fact rather than a claim, and it is also what *minor* means in ordinary semantic
versioning. (A new prose file is a new section, so it is `major` and never reaches this line.)

### What this ruler used to say, and why it does not

It read *minor* as **an exercise or a video** and *fix* as **the prose**, sorted by what records
each: an answer names an exercise version and an event names a video version, while prose was only
read. The argument was that a change to an exercise reaches a judgement about a student — a mark, a
pass, a certificate — so a corrected answer key must not be filed as a *fix*.

**The premise was true and it did not matter.** Nothing reads a release's level to decide how to
treat an answer. `C-16` carries that on the exercise's own version, and `C-15` quarantines on it.
The level was being asked to protect something already protected elsewhere, and paying for it with
the only meaning a reader actually wants from a version number.

It also failed on its own terms, which is how it was caught: the rule was written as *"something the
student interacts with"*, and that separates nothing. A student interacts with prose by reading it
and with a video by watching it. The wording was a description of two of the three, standing in for
a criterion that was not there — the same fault, one layer along, as the first draft's *"content
changed"* against *"a correction"*.

| Decision | Why | State |
|---|---|---|
| major is the shape, minor is new material, fix is a correction | It is what a person reads a version number for, and the level has no other job — see below. Two of the three levels are still derived. | Decided |
| The tool computes a floor; a person may raise it, never lower it | A number that cannot understate, with judgement only where a diff is blind. `A-04` already derives rather than asks. | Decided |
| **Nothing computes from the declared level** | For a change in place, *minor* against *fix* is a claim about intent that no diff can check — safe exactly as long as nothing reads it but a person. Every machine answer comes from the versions of the parts: "did anything but the prose move between these two" is asked of prose, exercises and videos directly. The day something folds the level into a query, one person's judgement becomes load-bearing, and the day it is wrong nobody will know why. `C-25`. | Decided |
| Semantic version, not a monotonic counter | With the floor and the valve the three positions carry meaning that holds. A running number would carry none. | Decided |
| A course's first release is `v1.0.0` | The first publication has no predecessor, so no level can be derived and the number is a declaration. `v0.1.0` would announce a course that is not the course yet, which `C-26` refuses. | Decided |

---

## Putting one on the air

**The console does not choose a version — it asks `load` to load a named release.**

The job stays the single writer `C-07` requires. What the console gains is not the pen, it is the
**trigger**: git owns *which* releases exist, and the console owns *when*.

No second source of truth and no pointer table. And because the load is already one transaction
that validates before it writes, rollback inherits that guarantee for free: it comes back whole or
it does not come back. The cost is that it is not instant — it is a job, tens of seconds — which
for "that video says something wrong, take it down" is acceptable, and far cheaper than the
alternative.

`cmd/load` already carries the hard half. It validates the whole tree, writes in one transaction,
and stores nothing if anything is wrong; its own comment says a half-written load would leave "a
catalogue that is neither the old one nor the new one". **What is missing is the label**: the
commit is read from `build.Current()` and goes to a log line and nowhere else, so asking "which
release is live" today means reading logs.

| Decision | Why | State |
|---|---|---|
| The console triggers `load` at a named release; `load` stays the only writer | Keeps `C-01` and `C-07` intact. The console owns when, not what. | Decided |
| Rollback is loading the previous release | One audited action, every piece coherent with every other, and the transaction makes it whole or nothing. | Decided |
| An `operator` approves and publishes a release | Three roles and no more (`K-01`), and the migration that created them refuses a fourth in writing: "a role nobody can name the purpose of is a permission nobody can reason about". `owner` does everything including granting roles, `operator` changes a plan and quarantines a question, `read-only` writes nothing. Publishing has the same shape as quarantining — an audited write that changes what students see — so it needs no fourth role, and owner-only would make the one person who grants roles the only one who can ship. | Decided |
| The gate is "the checks passed", not "I read it" | The founding constraint is that material is written and verified by machine with no human step. A person deciding to ship something already verified is `C-14`; a person reading it through is the reviewer this system says it does not have. The release carries the checks' verdict and its verification level — which is `C-05`. | Decided |

---

## Major lines coexist. Nothing else does

A course that reorganises under someone mid-way through does not only harm them: **it looks like an
unfinished product**, and that costs once per person who sees it happen. A notice does not fix
that; a notice documents it.

But coexisting everything is the same mistake from the other side. **Pinning somebody to a *fix*
means deliberately serving them a typo you have already corrected.**

| | |
|---|---|
| **fix, minor** | everyone moves at once — these are improvements, and there is nothing to protect |
| **major** | whoever is mid-course stays on the line they entered, and keeps receiving the fixes and minors *of that line* |

Someone on line 3 goes on getting 3.5.0 and 3.5.1; they only do not jump to 4.0.0. It is how
software keeps a previous version alive, and it is cheap because *major* is rare by construction.
Lines alive at once: one, nearly always; two just after a major. Not N.

**Enter on the newest. Leave the line by finishing or by choosing. The line dies when it empties.**

A new student, and a student who has not started, always enter the newest line — which is what
makes the drain terminate, because an old line's population only falls. The line is stamped on the
**first completed section**, not at purchase: somebody who bought and has not begun has no progress
to preserve, and pinning them to the version of their purchase date would protect them from
nothing. The hook exists — `progress.Complete` already answers whether that was the first time.

**On completion the line is released**, or whoever finished holds it open forever. What they
completed stays a fact: the certificate and the events name the line it happened on, and that does
not change. Coming back to review shows them the current line, with new material appearing undone —
which is honest, and does not touch the certificate, which certifies what they studied and not what
the course became.

Retirement is a **drain, not a schedule**: the old line closes when its last student finishes, and
the console shows how far it has to go — *"line 3, 4 students left"*.

**One cost is recorded as a cost.** Whoever is pinned to the old line *does not get the structural
improvement* — if the major exists because the course is better organised now, that person is
deliberately on the worse version. It is the exact mirror of the harm being avoided, and it is why
the voluntary migration exists.

The bulk of the work is a line dimension on the catalogue tables from the course down —
`catalog_courses`, `lessons`, `sections`, `prose`, `exercises` and their `_text` companions, about
eight; the track tables stay out, because a track sits above a course. `load` goes from "load and
prune what disappeared" to "load this release **into its line**", pruning only within it. Video
duplicates nothing, because its objects are already addressed by version; prose and exercises
duplicate, and they are text.

---

## When a line will not empty on its own

**Automatic: the pin drops when access lapses.** Access is an active subscription (`K-15`), so
somebody not paying cannot open the course at all — and cannot be harmed by their line going away,
because they already see nothing. Keeping a line alive for them is paying for a promise nobody can
call in. On return they enter the current line like anyone starting now, and progress crosses over
by intersection of ids exactly as in a voluntary migration: they lose no work, they simply get the
notice instead of the question.

That alone drains nearly all of the tail, because whoever disappears disappears from the
subscription too.

**Human: an operator closes a residual line, with a dated notice, looking at the numbers.** What is
left is somebody who *pays and does not study*, and there I would not put an automatic threshold.
`C-15` quarantines a question on its own because **a wrong key harms students now**. A stranded line
harms nobody: it costs a little storage and a little query complexity. With no urgency, moving a
paying customer deserves a person looking.

| Decision | Why | State |
|---|---|---|
| Only major lines coexist | The one change where progress may not transfer. Everything else is an improvement. | Decided |
| Enter newest, leave on finishing or choosing, die on emptying | An old line's population only falls, which is what makes retirement terminate rather than being hoped for. | Decided |
| The line is stamped on the first completed section | No progress, nothing to preserve — and pinning at purchase would hold somebody on an old version for no reason. | Decided |
| The pin drops when access lapses | Somebody who cannot open the course cannot be harmed by its line retiring. | Decided |
| A residual line is retired by a person, not a threshold | The automatic quarantine exists because a wrong key harms students now. A stranded line harms nobody, so the argument does not transfer. | Decided |

---

## What migrating does to progress

**Nothing special — and that is the design, not an omission.** Progress is a **set of completed
section ids**; the new line is a set of ids that exist; what is done is the intersection. There is
no mapping to maintain and no calculation to get wrong, and it works because `C-09` already paid
for it: nothing joins by prose or by position, only by a stable id.

| | | |
|---|---|---|
| **same id** | stays complete, even with the prose rewritten | it is the same section, better — nobody is un-ticked by an improvement |
| **reordered** | nothing happens | order is declared (`C-10`) and completion is by id |
| **removed** | the progress row is orphaned | it leaves the numerator and the denominator together: neither for nor against |
| **new** | appears undone | the course grew and there is more to do, which is honest |

**The one case that does not resolve itself is splitting or merging sections.** The temptation is a
map — "this one replaces that one" — and I would refuse it. It is written by hand, it is one more
place to be wrong, and the error is asymmetric: a wrong map **credits somebody for work they did
not do**, and that can feed a certificate. Losing credit for a restructured section is annoying;
gaining credit that was not earned is false. Without a map, **keeping the id becomes the author's
lever** — explicit in the diff, visible in review, and exactly what `C-09` asks for.

**The denominator is always the line the student is on now**, never history, so the percentage only
falls when the course actually grew and never because something was removed. `resume_pointer` is
recomputed to the first incomplete section of the new line, which is consistent with what it means:
the code says the pointer follows "the most recent thing they did".

**Before confirming, the student sees the arithmetic** — set arithmetic over ids, exact and cheap:

> 12 sections you completed still count. 3 are new. 1 is no longer part of the course.

Without that the option should not exist, because it would be asking for faith. The migration is
**one-way**: the data would allow going back — nothing is deleted — but back and forth creates a
matrix of states nobody wants to debug. That is said on the confirmation screen, not hidden.

**And the same arithmetic decides whether the migration is offered.** "Offer or hide" looked binary
and is not, because the sum answers *before* the question: if everything they completed still
counts and only new material appeared, offering is a gift — *"this course gained 3 sections, update?"*
If they would lose credit, it is not offered; they finish in peace and find the option if they look.
One line on the course page, dismissible, not returning for that release.

That is what actually drains: most majors will be purely additive for most people, so the
conditional offer empties lines on its own, and the tail rule is left with the cases where migrating
would cost something — which is where it should work slowly and with somebody looking. **Automatic
migration, under no circumstances.**

---

## Measuring the prose

"Does the current text explain it better?" has three answers of very different quality.

**The good one: the exercise that follows.** If the text improved, first-attempt success should
rise. That is not a proxy for attention — it is a learning outcome, and the machinery exists: item
analysis is the reviewer (`C-06`) and an answer already records the exercise's version. It is
*better* than what video has, where the curve measures attention.

**The middle one: coming back after getting it wrong.** Whoever fails and returns to the section is
saying the text did not land. It needs an event of its own — this repository refuses to record a
visit as progress, *"opening a section is not finishing it"* — so it waits.

**The weak one: reading depth.** Worth far less here than in video, because scrolling to the bottom
costs two seconds; the argument that nobody games a system by waiting does not apply to text. And an
honest limit: a section whose lesson has no exercises is left with the two weak signals only.

**The version read goes as a dimension on `section.completed`, which already exists.** `K-04` has
events carry their dimensions denormalised, and this is one more, recorded at the moment it is true.
Hanging it on the answer would be worse: it would mean *inferring* from a timestamp which version
the person read, and they may have read it three days ago under another. Inferring at write time
what the stream already knows is the opposite of `K-03` — so the strong measurement is a **join
between two events**, each recording the truth that is its own.

The event fires only on the **first** completion, and that helps rather than hinders: the right
comparison is between **cohorts of first-time readers**, whoever read v11 against whoever read v12,
and never the same person twice, which would be a before-and-after contaminated by their already
knowing the subject.

**Comparing two versions of prose is not an experiment — except when nothing else moved.** The
cohorts are from different periods, and alongside the prose the exercises, the videos and who
arrived that month may all have changed.

The temptation is to read that off the declared level — "it is a *fix*, so only the prose moved".
That does not hold: with the manual raise, a release marked *minor* may have been prose only.
**The comparison's validity is computed from the diff of the parts**, which is always available
because they all carry versions. Put another way: **the declared number is for people, and the diff
of the parts is for the statistics.** Neither has to lie for the other to work.

---

## Item analysis sums across lines, and never across versions

The intuition is to split by line, and it has the wrong dimension. Item analysis exists to find a
**broken question** — an inverted key, a question everybody gets wrong — which is what `C-06` means
by the item analysis being the reviewer. And that does not depend on the line: an inverted key is
inverted on line 3 and on line 4.

Splitting would have a concrete cost: it **halves a sample that is already thin**, and `C-17` then
silences both halves for sitting below the minimum — on a question that had plenty of data added up.
Silencing the alarm to gain purity is the worse side to err on.

What may not be summed is what `C-16` already says: **different versions of the exercise**. That is
another question, with another statement or another key, and adding them is December against March.
If the exercise is the same on both lines, it is the same question. So the line is a **breakdown and
not a partition**: when a number looks odd, the operator opens it and sees it split by line.

---

## What survives a retired line

**The catalogue rows are pruned, like any others.** Keeping them would make the catalogue an
archive, and `C-07` says it is a derived mirror. Nothing is lost: **git is the archive**, the release
is a tag, and anyone who needs to see what line 3 looked like checks it out. That is what `C-01` is
for.

Everything a student did survives orphaned, which is already the design — `cmd/load` prunes today
for exactly this reason, and its comment says so: nothing a student did points at those rows,
because `practice_review.exercise_id` is text and deliberately unkeyed.

**And the certificate was already built for this, before any of it was proposed.** Its migration
says everything on it is captured when it is issued — the student's name, the title, the school —
and that none of it is read live, because "a course can be renamed or removed from the catalogue
entirely… and a certificate that read its title live would silently start naming something else, or
nothing." The line retiring is precisely that case, and it is already handled.

The one gap is that a certificate captures the title and not **which version** it was earned on. With
lines, two people can hold certificates under the same title for materially different courses. The
substance is traceable — the certificate points at the attempt, which is how "which questions was
this earned on" is answered — but the document does not say it. One more captured column, for the
same reason as the three that are already there.

| Decision | Why | State |
|---|---|---|
| A retired line's catalogue rows are pruned | The catalogue is a derived mirror; git holds the release under its tag. Student history is unkeyed and survives orphaned by design. | Decided |
| The certificate captures the version it was earned on, and the verification page shows it | It already captures the title, the name and the school for exactly this reason, and a version left out is a document that cannot say which course it means once the lines diverge. What settles it is the asymmetry rather than the value: a certificate is immutable by trigger, so the version either enters at issue or never exists — hiding a captured field later is easy, capturing retroactively is impossible. Shown, because a captured field nobody displays answers nothing, and because the reason the score is withheld does not apply: a score would rank people, and a version describes the course. | Decided |

---

## A broken key on a line that has retired

Retirement does not touch this, and the reason is that the remedy was never in the catalogue.

The quarantine (`C-15`) stops a question being **served**, which applies to a live line by
definition. The retrospective half — finding who was affected — runs over `exam_attempts` and
`exam_answers`, which are a student's record rather than catalogue rows and survive the prune
intact. The chain is already built and already argued: the certificate stores `attempt_id`, and
its migration says why — "for the question 'which questions was this earned on', which is the one
that matters the day a question is found to be broken." A line retiring cuts no link in it.

The question's text goes with the prune, and is in git under the release's tag, which is the same
answer as everything else here.

**What is left over is not a line problem.** Nothing looks backwards: `C-15` quarantines forward
and no one re-examines past attempts. That is true today, with no releases and no lines, so
recording it here would file it under the wrong subject. If it is ever closed, it is a console
screen — quarantining a question lists the attempts that contained it and the certificates resting
on those attempts, **for a person to look at**. Not automatic: touching a certificate is a decision
about a person, and a certificate leaves only by erasure.

---

## What this settled, and what stayed here

Eight of the decisions above are rules other work can violate, so they carry numbers and live where
every other rule lives: **C-21** a course is published as one set, **C-22** the level is a computed
floor, **C-23** migration is the intersection of ids, **C-24** the console triggers the load and the
load job stays the only writer, **C-25** nothing computes from the declared level, **N-11** only
major lines coexist, **K-25** the prose version rides on the event, **K-26** item analysis sums
across lines and never across exercise versions.

The rest stayed here, and that is not a leftover: the drain, the tail rule, the arithmetic a student
sees before migrating, and what survives a retired line are reasoning and mechanism rather than
rules somebody could break. A register that swallowed them would stop being a list of rules.
