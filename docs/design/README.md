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

### `C-28` is wrong in every case where a track continues another — three for three

Three courses are free, and **nobody arrives at any of them free**:

| course | free because | the track it opens |
|---|---|---|
| `process-management` (60 h) | position 1 of `tech-lead` | its own goal says it "does not start a career, it continues one" |
| `architecture-role` (40 h) | position 1 of `software-architecture` | declares `continues: backend` — fifteen paid courses first |
| `bigdata` (70 h) | position 1 of `data-platform` | declares `continues: data` |

`C-28` makes the first course of a track the free sample, and it was sized on `web-fundamentals`,
which really is what a visitor meets before paying anything. Applied to a track that continues
another it gives away **170 hours to students who have already converted**.

Found in `management`/`architecture` first, where two instances made it "a rule problem rather than
two accidents"; `data` supplied the third and closed it. **That is all three continuation tracks in
the catalogue** — the rule is not misfiring occasionally, it is wrong every time it meets one, and
`continues` is already in the data.

The sheets do not decide it. It is a pricing decision, and it belongs beside the free-tier question
`computing-essentials` raises from the other direction.

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

### `data` — the environment question splits into six, and one of them is metered

Twenty-three courses, **1,550 hours** — the largest category in the catalogue and the largest
batch in the sweep. `infra` asked *which environment*; `data` asks it again and gets six different
answers, one of which is unlike anything found so far.

| what a course needs | courses |
|---|---|
| **nothing** | `statistics`, `data-fundamentals` |
| a **query surface** | `sql-databases`, `warehouse-modeling`, `data-governance` |
| a **server the student can misconfigure** | `db-administration`, `db-performance` |
| **two servers and permission to destroy one** | `db-reliability` |
| **three servers, none of them relational** | `nosql-operations` |
| a **notebook and the scientific stack** | `python-data`, `machine-learning`, `data-cleaning`, `bi-techniques` |
| a **cluster** | `bigdata`, `streaming`, `pipelines-etl` |
| a **GPU** | `deep-learning` |
| a **licensed desktop product** | `excel-analytics`, `analytics-bi` |
| a **paid vendor account** | `aws-data`, `azure-data`, `gcp-data` |
| a **plotting library** | `visualization` |

**A GPU is the first environment in the catalogue whose cost scales with enrolment.** Every
environment the sweep has found until now is provisioned once and shared — a shell, a container
daemon, a cluster, a database, a topology. `deep-learning` needs metered compute per student per
hour, and a free-tier student running a training loop is a bill rather than a load problem.
Nothing in `PLAN.md` or `ROADMAP.md` prices it.

**Two more axes appeared that are not machines at all.** `pipelines-etl` needs *time to pass* —
scheduling, sensors, backfill, "the pipeline that failed at 3am" — and `streaming` needs a process
that *never exits* and is observed while data arrives. Every blocked course before these needed
something to run; these need something to keep running, and to have been running yesterday.

### The cheapest environment in the catalogue serves the most dependents in it

`sql-databases` and `python` are tied at **nine dependents each**, the two hubs of the whole
catalogue. `sql-databases` is in seven tracks, is beginner, and about 60% of its natural exercises
are blocked because SQL is learnt by running it.

And unlike every environment `infra` asked for, **this one has a version with no server**: SQLite
or Postgres compiled to WebAssembly, seeded from a fixture, discarded on reload. A query's result
is a table and comparing two tables is not a sandbox. That is the `infra` sweep's *"a topology is
the cheapest environment and it serves four courses"* argument an order of magnitude larger — and
if one environment in the whole sweep gets built first, this is where the evidence points.

The database question then **splits**, which is the finding that only appears with all four
database courses on the table: a surface you can query is not a server you can misconfigure, and
`db-administration`, `db-performance` and `db-reliability` need the second. **210 hours sit behind
`db-administration` alone** — the highest concentration of blocked hours behind a single unbuilt
thing anywhere in the sweep.

### The two courses that could be built today

Of 1,550 hours in this category, **130 need nothing**: `statistics` (80 h) and `data-fundamentals`
(50 h).

`statistics` is the stronger of the two, and it may be the strongest build-first candidate the
sweep has produced. It is **the best-graded course in the catalogue** — `numeric` and
`expression-answer` are two of the eight graders that exist, and this is the one course whose
natural answers *are* numbers with tolerances and expressions that must agree everywhere. It needs
no runtime, no browser, no database, no account and no GPU. It has three dependents and three
tracks behind it. `web-fundamentals` is the shop window; **this is the course that would prove the
machine-graded premise on material nobody could fake.**

### The blocked proportions are much worse here, and they are worth ranking

| course | blocked | by what |
|---|---|---|
| `deep-learning` | ~80% | a GPU |
| `db-reliability` | ~75% | two servers and permission to destroy one |
| `excel-analytics` | ~75% | a Microsoft licence |
| `python-data`, `machine-learning`, `bigdata`, `streaming`, `db-administration`, `db-performance` | ~70% | a runtime or a cluster |
| `sql-databases` | ~60% | a database |

For comparison, the highest figure in the two previous batches was `design-patterns` at 25%. **The
category that carries the most hours is also the one least able to publish them**, and the two
facts compound: 1,550 hours where the median course cannot ship most of its practice.

### `ai` — the first category that can go wrong faster than it can be written

Eleven courses, 630 hours. The environment answer is short and the same for ten of the eleven: **an
API key with a bill attached** — a metered third party, not a machine. It is cheap per call,
impossible to avoid (prompt engineering needs something to prompt) and non-deterministic, so
`expected-output` would not grade it even if that grader existed. `ml-mlops` is the exception and
needs no key at all.

The finding is elsewhere, and it is about time rather than money.

**This category names more third-party products than any other, and unlike a console they get
discontinued.** `ai-models` names fifteen in twenty-one lessons — Claude, Gemini, the GPT and o
families, Cohere, Mistral, Llama, DeepSeek, Qwen, Gemma, Hugging Face, Transformers.js, Ollama, LM
Studio, OpenRouter. `embeddings-vectors` names seven vector databases. `llm-observability` names
six SaaS products. `agents-mcp` spends six lessons on a protocol barely two years old and three
more on vendors' agent SDKs.

The `infra` sweep's ageing finding was *"eleven of twenty-three teach somebody else's interface"* —
a console gets redrawn while continuing to exist. **Here the product goes away.** And that meets
`C-30`, which makes the screen the frame: a course of this shape has a re-recording cost that
recurs on somebody else's schedule and never stops. `agents-mcp` is 80 hours — the largest course
in the category — on the fastest-moving subject in the catalogue, and every other large course the
sweep has met is large *because* its subject is settled (`design-patterns` at 80 h on thirty-year-old
patterns; `machine-learning` at 90 h).

**So the design instruction for this category is a split rather than a schedule:** separate the
durable spine from the product directory, and give the directory the opposite treatment to
everything else — text-first, short, cheap to re-render. In `ai-models` the spine is lessons 1–5
and 21 and the directory is 6–20. In `agents-mcp` the spine is lesson 7, *"Implementing an agent by
hand, from scratch"*, which is what makes the three SDK lessons readable rather than magic.

Two courses escape it. **`ai-security` ages slowest** — attacks and defences outlive the models
they are aimed at — and it is also the only course here with real reach (three tracks). It is the
best-value course in the category on both axes at once. **`prompt-reliability`** names almost no
products and teaches discipline.

### `ai-dev` is placed correctly eleven times and wrongly once

Twelve tracks — the widest reach after `portfolio-project`, `first-job` (16) and `git` (13), tied
with `web-fundamentals`. In eleven of them it is the only AI course there is, arriving late in a
track about something else, which is exactly right.

In the twelfth it is a summary of the four courses immediately before it. `ai` reaches it at
position 10, after `ai-models`(6), `embeddings-vectors`(7), `rag`(8) and `agents-mcp`(9), and its
eleven lessons are tokens, RAG, agents and MCP, function calling, providers and risks — **a
50-hour compression of the 270 hours just finished.**

That is the same defect `data` produced (`bi-techniques`'s four-lesson machine-learning overview
reaching `data-science` at position 9, one after `machine-learning` itself at 8) and it is larger
here. **Two categories, found independently, both invisible from inside either course** — which is
what a sweep is for.

The cheap fix is a position in a track file rather than a mechanism: `ai` could reach `ai-dev`
before the deep courses instead of after.

### Three courses now want content that varies by the path taken

Nothing in `content/` lets a course, a lesson or a section differ by the track that reached it or
by the option a student took at a fork. **Three courses from three categories need exactly that,
for three unrelated reasons:**

- **`design-patterns`** sits behind `backend`'s choice of JavaScript, Python, Java or Go, and every
  pattern it teaches is code in one of them. Pick one language (wrong for three quarters of
  readers), write four snippets (four times the writing and the maintenance), or use pseudocode
  (grades nothing).
- **`portfolio-project`** has sixteen audiences and knows it — lesson 3 is *"Choosing by track: what
  somebody hiring in your field actually opens"*. Generic is the one thing a portfolio course must
  not be.
- **`ai-dev`** is the only AI course in eleven tracks and the fifth in one, and the right material
  differs by which.

One course wanting a mechanism is a request. Three, arrived at independently, is a decision with
something behind it — and `ai-dev`'s case has a cheap partial answer the others do not: moving it
earlier in one track file.

### A category of work that is not an environment: authored adversarial material

Three courses in two batches need **data with deliberate defects in it**, which is fixture content
living in `content/` rather than a machine to be provisioned:

| course | what it needs |
|---|---|
| `data-cleaning` | tables with the right defects — a column where missing means zero, a duplicate that is not exact, an outlier that is a real event |
| `rag` | a corpus long enough to chunk, ambiguous enough that retrieval can fail, structured enough that a citation means something |
| `ai-security` | a deliberately vulnerable application, with known weaknesses, that resets |

These read as blocked on the sandbox and are not. **They are blocked on somebody writing the
broken thing**, which is closer to the illustration bill than to the environment list — and, like
it, has no owner.

### The subjects that most need a real bill are the ones a sandbox can least provide

Named after the third instance rather than the first: the vendor data family (*"the two decisions
that define the bill"*), `bigdata` (*"what an hour of cluster costs"*), `deep-learning` (*"training
time against the gain"*) and `multimodal` (*"cost, file size and upload limits"*) all teach cost as
subject matter to students who cannot incur any.

`multimodal` is the sharpest case, and it is a shape the sweep had not met: **every other blocked
exercise costs a machine that is already running; these cost money per attempt.** Generating an
image or transcribing audio is a metered call, and *retrying is the pedagogy* — lesson 3 is prompt,
style and limits, learnt by varying one thing and looking again. A per-attempt cost that rises with
how much a student practises is worse than `deep-learning`'s GPU, because for most of it there is
no cheaper local substitute.

### `continues` read correctly, for once

`ml-mlops`'s first four lessons duplicate `machine-learning`'s first four — supervised and
unsupervised, the common tasks, splits and leakage, the accuracy trap. **No student ever meets
both**: `ml-mlops` is reached only through `data-platform`, which `continues: data`, and `data` does
not contain `machine-learning` (`data-science` does).

Worth recording as the positive case beside the three places where `C-28` reads the same field
wrongly. The mechanism works; the free-sample rule just does not consult it.

### Nobody has been named to draw ~3,800 pictures

Summed across the 74 sheets written so far, the diagram estimates come to **3,797** — for three
fifths of the catalogue. The heaviest are `architecture-modeling` (~130), `visualization` (~110),
`data-storytelling` (~90), `computing-essentials` (~85) and `statistics` (~80), and in most of
those **the images are the assessment rather than the illustration**: "mark the three things wrong
with this chart" is a `labelling` item, which is the one grader that fits soft material well, and
it does not exist without the picture.

`visualization` and `data-storytelling` sharpen it further: ~200 images across two courses on the
same subject, adjacent in the same two tracks, **which must not contradict each other**. That is
the first shared illustration budget the sweep has found, and it is an argument for drawing them
together or not at all.

This began as a note on one sheet. At half the catalogue it is the largest single unowned cost the
sweep has surfaced, and it is still nobody's.

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
