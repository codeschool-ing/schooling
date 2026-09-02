# Releases of a course

A course is published as a **set**, not as a pile of files that happen to have been edited on the
same afternoon. Prose, exercises and videos are frozen together, verified together, approved
together, and go into effect together.

Nothing here is built. Most of it is decided; two rows are proposals, and the state column says
which is which — a proposal recorded as a decision is how a document starts lying.

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

The first three carry a number because **they move without moving the release**: two exercises and
a video can rise in one *minor*, and in a *fix* only the prose. The release number does not say
which of them moved.

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

Every level is "some version rose", and the release's level is the highest class that moved.

| Level | What rose | How it is detected |
|---|---|---|
| **major** | the structure: a section or lesson added, removed, reordered, or its `kind` changed | compare the trees of ids and order |
| **minor** | an exercise or a video — something the student interacts with | compare the declared versions |
| **fix** | only the prose | everything else is identical |

This corrects a case the intuitive definition gets wrong. **Repairing a wrong answer key is a
"correction"** and would land in *fix* — but a wrong key is the most consequential change this
system has, the only one it quarantines on its own (`C-15`). By the ruler it is a *minor*, because
the exercise's version rises.

**The tool computes a floor. Whoever publishes may raise it with a reason, and nobody lowers it.**

That is what preserves the distinction the ruler alone cannot draw. A corrected accent and a
rewritten section raise the prose version equally — no diff separates them, because the difference
is intent. So the machine guarantees the floor (only the prose moved: *fix* at least) and a person
declares *minor* when it was a real rewrite.

The number becomes incapable of understating, which is the dangerous error, and judgement enters
only where the machine is blind — including content redistributed among the same sections, which
no diff sees and which whoever publishes raises to *major* by hand. The valve is not an exception
to the rule: it is what stops the rule lying through a technical limitation.

| Decision | Why | State |
|---|---|---|
| major is structure, minor is exercise or video, fix is prose | The three levels are the three classes of artefact by what records them. Mechanically derivable, which a rule about "how big was the change" is not. | Decided |
| The tool computes a floor; a person may raise it, never lower it | A number that cannot understate, with judgement only where a diff is blind. `A-04` already derives rather than asks. | Decided |
| Semantic version, not a monotonic counter | With the floor and the valve the three positions carry meaning that holds. A running number would carry none. | Decided |

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
| The certificate captures the version it was earned on | It already captures the title, the name and the school for exactly this reason. A version left out is a document that cannot say which course it means once the lines diverge. | Proposed |

---

## Still open

**Whether the video decisions and these become numbered entries in `PLAN.md`.** `VIDEO.md` settled
`P-11`, `P-12`, `C-18` to `C-20`, `K-23` and `K-24`; this document settles more, and which of them
are rules other work can violate — rather than reasoning that belongs here — is a judgement nobody
has made yet.

**What a fix looks like on a line that has retired.** A wrong key found in a course whose line is
gone: the quarantine is automatic and applies to the live catalogue, and there is nothing to
quarantine on a line that no longer exists. Whether the certificates earned on it need anything is
the question `C-15` does not currently reach.
