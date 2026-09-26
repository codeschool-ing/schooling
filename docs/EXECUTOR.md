# The executor

What it would take to run a student's program, and what that costs.

Two of the ten answer types — `code` and `expected-output` — have no grader. They are **absent
from `graders` in `internal/grade` rather than stubbed**, so asking for one answers
`ErrUnknownType` instead of guessing, and `CONTENT.md` says why: both need a sandbox that runs a
student's program, which is its own piece of work. This file is that piece of work, written
**before** it exists.

It is written now because the decisions are cheap now. The moment there is an endpoint that runs
somebody else's code, the cost of getting the boundary wrong is not a refactor.

Nothing here is built. The state column says what is decided and what is only proposed, and the
difference is not decoration: a proposal recorded as a decision is how a document starts lying.

---

## Deferred, and what replaces it

**The executor is deferred, and the student's own machine is the lab** (`C-38`). A course whose
practice needs an environment teaches the student to have one: installed on their computer, in a
virtual machine, or in an online service, and a lesson early in the track walks through all three.
The platform grades what it can grade by itself, the closed types and the exams, and runs nothing a
student wrote.

Four reasons, and the first two would each be enough:

- **It costs nothing per student**, where the executor costs something per execution and a ceiling
  to hold it.
- **It has no attack surface here.** Every row under *Isolation* and *Abuse* below exists because a
  stranger's program would run on this platform's account. A program that runs on the student's
  computer is the student's.
- **Setting up the environment is itself worth teaching.** A support technician, a developer and an
  analyst all have to do it on the first day of a job, and a course that hid it behind a sandbox
  would leave it out. `virtualization` is built on this: its last two lessons are the student's own
  lab, and its sheet had already said *"the environment is theirs, not ours"*.
- **Nothing is waiting on it.** 6,692 questions across the catalogue, and none of them is `code` or
  `expected-output`. `operating-systems`, `networks` and `virtualization` were written with every
  command captured on a real machine, and a student repeats them on their own.

What it gives up is a verdict on a program the student wrote. Their practice happens where the
platform cannot see it, and what the platform asserts about them rests on the closed questions and
the exam. That is a real loss for one kind of course, and it is named in the trigger.

**The trigger that reopens it**: a course whose practice IS writing a program reaches the front of
the queue, **and** its exam cannot be written in closed types without losing what it measures.
Both halves, because the first alone describes `python`, whose exam is 100 closed questions that
measure it well enough.

Everything below stays as the design for that day. It was written so that the decisions would be
cheap when they are made, and deferring the build does not make them any less cheap.

---

## The word is doing two jobs

"Sandbox" in `PLAN.md` means **an environment** — *"a runtime, a browser, a database, a cluster, a
topology, a GPU"*. Under that one word sit two systems with opposite requirements, and almost
every argument about cost is really an argument about which one is meant.

| | what it is | how long it lives |
|---|---|---|
| **the executor** | takes a submission, runs it against fixed inputs, returns a verdict | seconds, then nothing |
| **an interactive terminal** | a shell the student types into, with state between commands | as long as the tab is open |

**This document is about the first.** The second is refused below, and what replaces it costs
nothing.

---

## The register

`Decided` was chosen. `Proposed` is a recommendation nobody has ratified. `Deferred` is reopened
by a named trigger, not by a date. `Refused` was considered and dropped, and the reason is kept so
the next person can disagree with it rather than rediscover it.

### Shape

| Decision | Why | State |
|---|---|---|
| It starts as **Cloud Run Jobs**, not a cluster | `PLAN.md` already settled this under *Not on the roadmap, deliberately*: *"the honest case for a cluster is the executor sandbox at volume, and even that starts as jobs and moves when the volume justifies it."* Four jobs already exist here — `migrate`, `load`, `analyse`, `settle` — so this is a fifth of a shape the deploy already knows, not a new kind of infrastructure. | Decided |
| **One execution per submission**, a fresh container each time | The strongest isolation available without buying anything: no state survives, so nothing a submission does can reach the next one. It is also the slowest — see the latency row — and that trade is made knowingly. | Proposed |
| The **verdict is the server's**, always | `A-09` was retired with the sentence that settles it: *a client that could mark an answer would be a client holding the key.* Wherever the student's code runs for THEM, the verdict comes from a run they cannot reach. | Decided |
| The submission is **passed by value**, bounded, and never stored | A table of student-written code is a new subject in the privacy registry and a new thing to erase, and `A-10` keeps nothing about a lesson's answers anyway. Passing it in the execution keeps both true. The bound is what makes it possible — a few tens of kilobytes, refused above that with a sentence rather than truncated. | Proposed |
| The verdict records **which image produced it** | The runtime is part of what graded the answer. Without this, re-running a submission from March against today's image can disagree with the verdict the student was shown, and nothing would say why. Same argument as a question carrying a version (`C-16`). | Proposed |

### Isolation

| Decision | Why | State |
|---|---|---|
| **No network at all** | The first-order risk is not escape, it is egress: a submission that can reach the internet is a machine somebody else is renting from you, and it is also the one that can reach this platform's own API. | Proposed |
| Read-only root, a small writable `tmpfs`, non-root user, no added capabilities | The ordinary container hardening, and the part that costs nothing to do on day one and is awkward to retrofit. | Proposed |
| **Hard caps on CPU, memory, wall clock and output** | A loop that never ends and a program that prints forever are the two failures every executor meets in its first week. The wall clock is the one that also protects the student's patience. Output is capped because a verdict comes back through a response. | Proposed |
| The platform's own isolation is **not** the plan, it is the floor | Cloud Run runs each container inside a sandbox of its own, which is worth knowing and not worth relying on alone: the rows above are what this system is responsible for. | Decided |

### Abuse, and what happens when it is refused

| Decision | Why | State |
|---|---|---|
| Signed in, and a **quota per account** | Anybody who can submit code can spend your CPU. The gate is not a firewall, it is arithmetic: a number of executions per hour, per account, with a global ceiling above it. | Proposed |
| A refusal is **`correct: null`**, never an error | The interface already has this state and already says it honestly — *unjudged never becomes failed*, and the client renders "not checked". So the executor being over quota, cold, or down degrades to a question nobody marked rather than to a question marked wrong. **This is the reason the two types were left absent instead of stubbed**: the shape that carries "we did not check" already exists end to end. | Decided |
| The ceiling is a **cost ceiling**, stated in money | A quota in executions is a quota in vCPU-seconds is a quota in reais, and the last of the three is the one worth writing down, because it is the one somebody will be asked about. | Proposed |

### Latency

| Decision | Why | State |
|---|---|---|
| A student waits **seconds**, and is told so | A fresh container per submission costs a cold start. The screen already has a "checking…" state and a verdict that arrives asynchronously, so the cost lands on patience rather than on architecture. | Proposed |
| The trigger to revisit is **volume, not taste** | A long-lived executor service with an in-process jail is faster and weaker: one container serves many submissions, and the isolation becomes something this system maintains rather than something it gets. It is the right trade at a volume this platform does not have. Revisit when submissions per minute make the cold start the complaint. | Proposed |

### What it is not

| Decision | Why | State |
|---|---|---|
| **No interactive terminal on the server** | It is the expensive shape: a container held per concurrent student, and a student who leaves a tab open holds it. It also has no grading value — see the verdict row. | Refused |
| **A shell in the browser instead**, for teaching | It runs on the student's machine, so it costs nothing per student and has no security surface here. `PLAN.md` already uses this argument for a database: *"a database has a version that runs in the browser with no server at all."* It is less real than a machine — but for paths, permissions, processes and text tools it is close enough to teach with. It has **no grading authority** and must never be given any. Since `C-38` it is optional: the student's own terminal is the default, and this is a convenience on top of it. | Proposed |
| No GPUs, no topologies, no persistent student machines | Each is a different product with a different bill. The sweep in `PLAN.md` lists them as separate blockers for separate courses, and none of them is this. | Decided |

---

## Where it plugs in

`internal/grade` owns what a verdict is. It may not import a module that runs containers, and the
executor may not import it — modules meet through an interface the consumer defines, wired in
`cmd/`, which `internal/architecture_test.go` holds.

So `grade` declares what it needs — *run this, with these inputs, and tell me what came out* — and
`cmd/api` hands it something that does that. Which means the whole of this document is replaceable
without `grade` knowing: a local runner in development, a job in production, and a fake in the
tests that returns a fixed result.

The conformance fixtures already exist for the eight types that have graders, and `CONTENT.md`
makes them the entry requirement. `code` and `expected-output` join that rule the day they have
one; a type with a grader and no fixture fails the build.

---

## What it costs

Today: the API service scales to **zero** and the database does not. The fixed part of the bill is
Cloud SQL — `db-f1-micro`, zonal, 10 GB — and the executor does not change that.

What it adds is **per execution**: a container that lives about as long as the program does. At the
volume this platform has, that is small enough that the interesting number is not the unit price —
it is the ceiling, which is why a cost ceiling is a row above rather than a note here.

What it does not add: anything idle. A job with no executions costs nothing, which is the whole
reason the shape was chosen before the volume exists.

**The number to check before building.** Current Cloud Run pricing per vCPU-second and GiB-second,
against an assumed submission profile — a second of CPU, a quarter of a gibibyte, ten thousand
submissions a month. That arithmetic belongs in this file once somebody has done it against the
live price list, and this paragraph is here so that its absence is visible.

---

## What this unblocks, and what it does not

`PLAN.md`'s sweep found **four** things blocking material, and only one of them is an environment:
somebody else's bill, an answer type that does not exist, and material nobody has written are the
other three. Seventeen courses and 940 hours need no runtime at all.

So the executor unblocks **the courses whose practice is writing a program**, and nothing else. It
does not unblock `linux-terminal`, whose sheet says *0 exercises blocked — publishable degraded*:
that course's questions can be built on real command output captured while it is written, and the
browser shell above is what makes them feel like a terminal.

**Which is the order this argues for.** Write the material that needs no runtime — it is most of
the catalogue — and build the executor when a course whose practice IS a program reaches the front
of the queue. It is a week of work that buys nothing until then, and its cost starts the day it
exists. `C-38` sharpens that trigger, at the top of this file: until then, the runtime is the
student's.
