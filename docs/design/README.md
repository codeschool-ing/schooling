# The design sheets

One file per course, written **before** its material and kept afterwards. A sheet says how much
of everything a course carries, what it may assume from the courses before it, and what it needs
that does not exist yet.

[`../CONTENT.md`](../CONTENT.md) says what a course *is*. These say what each particular one
*will be*.

**And `tools/check-design` now compares them to `content/`**, which nothing did for as long as
they existed. A sheet is prose: it renders perfectly whatever it says, `validate-content` reads
the catalogue and has never heard of one, and so a sheet naming a course that does not exist, an
id belonging to another course, or thirteen lessons for a course whose structure declares
sixteen would have passed every check in this repository. Same failure shape as the privacy
policy against the registry, one layer along.

The tool **refuses a disagreement of fact** — an id, a slug, a lesson count, the sheet format —
and **only reports a budget**. A course being written has fewer sections than it will have; a
check that failed on that would be red from the day a course is started until the day it is
finished, which is a check nobody can keep green and therefore one whose output everybody learns
to skip. The counts are printed on every run instead, because the count is the evidence and *it
is coming along* is an assertion.

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

**And the rule works where it was meant to, twice.** `security-fundamentals` is free as position 1
of `security` and `python` as position 1 of `data-science` — both tracks continue nothing, so a
visitor really can arrive at either having paid for nothing.

`python` is the striking one: **ninety hours, nine dependents, nine tracks — the largest hub in the
catalogue, given away correctly.** A visitor who finishes it can enter eight other tracks, which
makes it a far stronger conversion instrument than `web-fundamentals`, the course `C-28` was
actually sized on. It is also bigger than that course, which is the cost side of the same fact.

Having the two working cases in the register beside the three broken ones is what shows the rule is
sound and its blindness to `continues` is the whole of the defect.

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

### `security` and `quality` — thirteen courses want the same fixture

Fifteen courses, 940 hours, swept together because both categories are about **checking somebody
else's system**, and the guess was that they would want the same thing. They do.

**Ten of the fifteen need an application with known flaws that resets**, and so do `ai-security`
and `rag` from the previous batch. That is not an environment — it is *authored material*, and it
lives in `content/`:

| the fixture | courses it serves |
|---|---|
| a **web application with known flaws** | `attacks-threats`, `secure-code`, `ai-security`, `manual-testing`, `web-automation`, `non-functional-testing`, `api-mobile-automation` |
| a **vulnerable network** | `pentest`, `defense-hardening`, `soc-response` |
| **logs and captures containing a real attack** | `soc-response` |
| a **corpus where retrieval can fail** | `rag` |
| **tables with deliberate defects** | `data-cleaning` |

The first row is the finding. **One deliberately-broken web application is the most reused piece of
authored material in the catalogue** — seven courses across three categories — and it is cheaper
than any environment on the `infra` or `data` lists. Nothing in the sweep has a better ratio.

The `soc-response` fixture is the expensive one and worth separating out: realistic logs containing
an attack, **with the answer known**, is harder to write than a vulnerable application, because the
evidence has to be findable in retrospect and the noise has to be convincing. It also pays back
most, because a capture is a fixed artefact — "which of these five events is the compromise" is a
`quiz`, "order these into the kill chain" is an `ordering`, "mark the indicator" is `labelling`.
**The authored data unlocks graders that already exist.**

And `pentest` supplies its own answer, which no other blocked course in the sweep does: its lesson
20 names HackTheBox, TryHackMe, VulnHub, picoCTF and pwn.college. **The vulnerable network already
exists publicly and is somebody else's to run.**

### The platform is the worked example, four times over

A pattern that started as a note on one sheet is now a list, and it is short enough to act on:

| course | its lessons | what already exists here |
|---|---|---|
| `web-automation` | Playwright, Page Object, traces, parallel execution, flaky tests | `tools/a11y-test`, `tools/graph-test`, `tools/landing-test`, `tools/bundle-test` — four Playwright suites driving a real application |
| `db-reliability` | backup, restore drills, measuring how long a restore took | `tools/restore-drill`, restoring a real database in CI |
| `data-governance` | personal and sensitive data, lineage, retention, audit | `internal/privacy`, a registry of every table with a test against the live schema |
| `secure-pipeline` | quality gates, secret scanning, runner permissions, policy as code | `.github/workflows/`, and `tools/check-origin` is policy-as-code by another name |

`web-automation` is the strongest of the four — four suites rather than one artefact, and its
lesson 14 is *"Flaky tests: causes, diagnosis and quarantine"*, which this repository has lived
rather than read about.

### `quality` is the only self-contained category in the catalogue

Five courses, **one track**, a single linear chain: `qa-fundamentals` → `manual-testing` →
{`web-automation`, `api-mobile-automation`} → `non-functional-testing`. Nothing outside `qa`
reaches any of them, and nothing outside the category depends on any of them. No other category is
closed like this.

Two things follow. It can be designed as one 310-hour object rather than as five courses — and it
is **the easiest category in the catalogue to defer entirely**, because deferring it strands
nothing else.

It is also uniform in a way worth checking rather than trusting: **22, 22, 22, 22 and 24 lessons;
60, 60, 60, 60 and 70 hours.** The register's opening paragraph names exactly this shape as the
reason the sheets exist, about `aws-`, `azure-` and `gcp-foundations`. Here it may be right — a
chain of equal-weight courses is a reasonable thing — but *"they came out the same"* and *"they
were designed the same"* are different claims, and only the lesson lists tell them apart.
`api-mobile-automation` is the one that already fails it: **it is two courses in one file**, API
testing to lesson 13 and mobile from 14, sharing a track position and nothing else.

### The deepest chain in the catalogue is in `security`, and it is six long

`security-fundamentals` → `cryptography` → `attacks-threats` → `secure-code` → `threat-modeling` →
`secure-pipeline`, with `testing-cicd` arriving from another category at the end. **360 hours have
to be right before the last course means anything**, and nothing else in the catalogue sits behind
six prerequisites.

`attacks-threats` is the hub of it — four dependents, two tracks — and its first nine lessons are
about people rather than machines, which makes roughly a third of a 70-hour course publishable with
no environment at all.

### `security` ages slowest, which is the opposite of what the subject suggests

nmap, Wireshark, netcat, Metasploit, `dd` and Autopsy are decades old and current. Phishing,
spoofing, injection and privilege escalation still work. STRIDE is from the 1990s. Set against
`ai`, where one course names fifteen products and the central protocol is two years old, **this is
the most durable technical category the sweep has found**.

The exceptions are named rather than general: `cloud-security` (three providers' consoles),
`api-mobile-automation` and `web-automation` (fifteen and eight tools by name), and the
certification lists that appear as a single lesson in several courses.

### Two courses are blocked on the same missing answer type, and it is not a sandbox

`architecture-modeling` and `threat-modeling` both ask the student to **draw**, and there is no
answer type for a diagram — no upload, no canvas, no comparison. Both have the same rescue:
`labelling` on a finished diagram, which grades today and teaches, but never asks the student to
produce one.

`threat-modeling` is the cleaner case, and an unusually clean test of whether the illustration bill
gets paid: fifty hours, no runtime, no target, no account, **and ~90 diagrams**. The pictures are
its entire cost.

### `pentest` raises something the sheets cannot settle

Its lessons 1, 2 and 22 are rules of engagement, *"Written authorisation: the document that
separates a profession from a crime"*, and the tester's liability in Brazil. `ai-security`'s lesson
11 is the same boundary.

**Teaching exploitation to anonymous paying students at scale is not the exposure a university
course with an enrolled cohort has.** That is not a design question and no sheet can answer it — it
is the one place in the sweep where the material raises something for the platform to decide, and
it wants deciding before the course is sold rather than after.

### `programming`, `backend`, `frontend`, `mobile` — the fork is where the catalogue lies

Thirty-three courses, 2,360 hours, and the category the sandbox was originally imagined for: a
language runtime and a file. The environment answer is the least interesting part of this batch.
**The forks are the finding.**

Four tracks reach a choice, and the options are meant to be comparable. Three of them are:

| fork | options | spread |
|---|---|---|
| `frontend` — the framework | 90, 90, 80, 70 h | 1.29× |
| `mobile` — which platform | 170, 170, 170 h | **exactly equal** |
| `devops` / `devsecops` — the automation language | 90, 80, 80 h | 1.13× |
| **`backend` — the server language** | **140, 150, 220, 290 h** | **2.07×** |

**A student choosing Go in `backend` signs up for 150 hours more than one choosing JavaScript**,
and the fork's note says *"Master one properly before jumping to another. The rest of the track is
the same on any path."* That note is true and it is about what comes *after*. Nothing tells the
student that the paths themselves are not comparable.

JavaScript is `javascript` + `node`. Go is `go` + `go-concurrency` + `go-back` + `go-production` —
four courses, because Go's concurrency and its production tooling were each given a course. Both
decisions are defensible on their own; **together they make one option of a four-way choice more
than twice the size of another, presented as an equal.** No sheet could see this and no course
contains it.

And `mobile`'s equal hours hide the opposite problem: **one of its three options cannot be
practised at all.** `ios-apps` needs Xcode, which is macOS-only by Apple's licence, plus a paid
developer account. Android needs a heavy emulator that nonetheless runs on Linux in a container;
React Native is JavaScript. **The hours are equal and the buildability is not.**

The useful half of that: `swift` runs on Linux — its own lesson 20 says so — so the wall falls
*between* the two courses of the iOS path rather than across both. The first 80 hours are
teachable and the second 90 are not.

### The one place the catalogue already solved the problem it keeps asking for

Three sheets in earlier batches asked for a mechanism that does not exist: content varying by the
path a student took. **`frontend` solves it in the material instead**, and does it four times.

`react-ts` closes with *"A look at Angular, Vue and Svelte, from where React stands"*. `vue`,
`angular` and `svelte` each close the same way, from their own position. `react-ts` and `angular`
also **open** by naming the contrast — *"Why React is a library where Angular is a framework"*.
`node` does it too, opening with *"Why master one language before jumping to another"* and closing
with a look at the others. `react-native` closes on Flutter and Kotlin Multiplatform.
`mobile-fundamentals` goes further and teaches the whole fork **one position before the student
reaches it**.

That is the fork's own note — *"the fourth course you meet in your career will cost you a week"* —
written into every option rather than left in the track file. **It costs one lesson per course and
needs no mechanism at all**, and it is the answer `design-patterns`, `portfolio-project` and
`ai-dev` do not have. Whether it generalises to them is a real question; that it works here is
demonstrated four times over.

The discipline extends past the fork: `apis`, `architecture`, `scale`, `servers-cache` and
`testing-cicd` in `backend`, and all four `front-*` courses in `frontend`, are written for a
student holding any option and **name none**. `front-performance` discharges the obligation in a
single lesson that covers Next, Nuxt, SvelteKit and Angular SSR — one per fork option.

### A third missing answer type, and this one has a mechanical answer

`html-css`'s exercises produce a **picture**. "Does this layout centre" is not a string, an
ordering or a number, and `expected-output` would not help even if it existed, because the output
is rendered rather than printed.

That is the third answer type the catalogue wants and does not have:

| missing type | courses | rescue |
|---|---|---|
| **prose** | `people-leadership`, `architect-communication`, most of `management` | the scenario with four replies, expensive |
| **a diagram the student draws** | `architecture-modeling`, `threat-modeling` | `labelling` on a finished diagram |
| **a rendered page** | `html-css` | **a screenshot diffed against a reference** |

The third has something the other two do not: **this repository already does it.**
`tools/graph-test` and `tools/landing-test` drive a real browser and compare what came out. The
mechanism exists, in this codebase, for the platform's own checks.

---

## What the finished sweep says

122 of 122. **7,880 hours, 2,402 lessons, 19 tracks, 13 categories** — every course with a sheet,
all at format 5.

**Seventeen courses, 940 hours, need no runtime at all.** That is 12% of the catalogue's hours, and
it is where anything gets built first. But needing no runtime is not the same as being unblocked:
`people-leadership` and `architect-communication` are stopped by the grader, and
`architecture-modeling`, `threat-modeling`, `computing-essentials` and `data-storytelling` by the
illustration bill. **The courses clear on every axis are a much shorter list** — `statistics`,
`data-fundamentals`, `security-fundamentals`, `qa-fundamentals` and `web-fundamentals` — and
`statistics` is the strongest of them: 80 hours whose natural answers are numbers with tolerances,
which two of the eight existing graders already check.

**Forty-two courses are 70% blocked or worse**, peaking at `deep-learning` and `ios-apps` at 80%.
The blocked hours are not spread evenly: they concentrate in `data`, in the language chains, and in
mobile.

**Four things block material, and only one of them is a sandbox:**

| what blocks it | scale |
|---|---|
| **an environment** — a runtime, a browser, a database, a cluster, a topology, a GPU | most of the catalogue, and the thing everybody means by "the sandbox" |
| **somebody else's bill** — twelve vendor cloud courses, `cloud-security`, both mobile stores, Excel, Power BI | ~15 courses, 750 h in the cloud family alone |
| **an answer type that does not exist** — prose, a drawn diagram, a rendered page | `management` almost entirely, plus five named courses |
| **material nobody has written** — ~6,600 diagrams, a vulnerable web application, attack logs, a broken-data corpus | catalogue-wide, and with no owner |

The last row is the one the sweep changed most. It began as a note on `computing-essentials`'s ~85
diagrams and ended as **~6,600 across 122 sheets**, plus a category of authored adversarial
material — a deliberately broken web application serving seven courses, logs containing a real
attack, tables with the right defects — that reads as an environment problem and is not one.

**And four courses have no path at any price**: `operating-systems`, `virtualization`, `ios-apps`
and the iOS lessons of `api-mobile-automation`. Three of the four are somebody's licence rather
than an engineering limit. The first two have since been written on the student's own machine,
`C-38` in `PLAN.md`, so "no path" turned out to mean no path for the platform, which is a different
thing.

### What the sweep found that no single sheet could

- **`C-28` is wrong in every case where a track continues another** — three for three, 170 free
  hours to students who have already bought a track, and `continues` already in the data.
- **`backend`'s fork is 2.07×**, presented as a choice of equals.
- **`portfolio-project` and `first-job` are the last two courses of all sixteen career tracks** —
  the widest reach in the catalogue, and invisible to every graph-shaped argument because neither
  has a dependent.
- **`sql-databases` and `python` tie at nine dependents**, and `python` is free while
  `sql-databases` is the cheapest large environment nobody has built.
- **Eight compressed overviews**, of which one is wrong (`ai-dev` at position 10 of `ai`), one is
  arguable (`bi-techniques` after `machine-learning` in `data-science`) and six are correctly
  placed because no student meets both sides.
- **The platform is the worked example five times over** — `web-automation`, `db-reliability`,
  `data-governance`, `secure-pipeline`, `testing-cicd`.
- **`pentest` raises a question no sheet can answer**, about teaching exploitation at scale to
  anonymous students.

None of those is visible from inside one course, which was the argument for doing this at all.

### Nobody has been named to draw ~6,600 pictures

Summed across all 122 sheets, the diagram estimates come to **6,662**. The heaviest are `architecture-modeling` (~130), `visualization` (~110),
`data-storytelling` (~90), `computing-essentials` (~85) and `statistics` (~80), and in most of
those **the images are the assessment rather than the illustration**: "mark the three things wrong
with this chart" is a `labelling` item, which is the one grader that fits soft material well, and
it does not exist without the picture.

`visualization` and `data-storytelling` sharpen it further: ~200 images across two courses on the
same subject, adjacent in the same two tracks, **which must not contradict each other**. That is
the first shared illustration budget the sweep has found, and it is an argument for drawing them
together or not at all.

This began as a note on one sheet. Across the finished catalogue it is the largest single unowned
cost the sweep surfaced, and it is still nobody's.

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

It does **not** ask that every course has a sheet. Coverage is reported rather than enforced,
because the sweep was deliberately partial for a long time and a check failing on the 119 missing
ones would have been a red build describing a plan working as intended.

**That reason has expired.** Coverage is 122 of 122, so the check now reports a number that cannot
go down by accident and can only go down when somebody adds a course without a sheet — which is
exactly the thing the sheets exist to prevent. **Enforcing coverage is now free**, and the argument
against it was entirely about the transition.

The sheet does not make the change, because turning a reported number into a failing one is a
decision about what CI is for rather than a fact about the catalogue. It is recorded here as the
one thing completing the sweep unlocked.

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
