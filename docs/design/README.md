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
format: 3
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

## Format 4

| block | what it holds |
|---|---|
| **Reach** | the tracks it appears in and where; whether it is free (`C-28`); what depends on it; whether a track reaches it through a *choice*, in which case nothing after that choice may assume it |
| **Assumes / leaves ready** | what `requires` lets the prose take for granted, and what this course owes the ones below it. This is the field that stops 122 courses re-teaching HTTP |
| **Shape** | sections and their kinds, exercises, video minutes, estimated hours against declared |
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
