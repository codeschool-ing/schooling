# The console

**This was a proposal and is now the design.** It was written to be disagreed with while that was
still cheap — paragraphs cost less to argue about than screens — and it was, twice: once for
reading as though phase 4 were being pruned, and once for asking the naming question without
having read the answer already sitting in a migration. Both are recorded below rather than
tidied away.

The decisions are in [`PLAN.md`](PLAN.md) as K-17 to K-22. This file is the working detail; that
table is the register.

It exists because phase 0 has one item left — *personal-data export and erasure, reachable from
the console* — and it cannot be done without answering questions much bigger than the item. The
export and the erasure already work and are held by four tests. What is missing is a door, and a
door needs a building.

**Nothing in [`ROADMAP.md`](ROADMAP.md) is pruned by this document.** An earlier draft of it said
phase 4's screens were "explicitly not this", meaning *not in the first slice*, and it read as
*not ever*. That was the draft's fault. The console described here is the complete one; what is
staged is the order it arrives in, which is a different sentence and is now written as one.

---

## What the console is, whole

`PLAN.md` splits it into four jobs that must not mix — **operate** (current tables, now),
**understand** (aggregates, yesterday will do), **watch** (presence and alerts, seconds) and
**audit** (immutable history) — because *serving all four from the same queries against production
is how every console rots.* That division is the spine of everything below.

### Operate

- Find a person, show what is held about them, **export** it, **erase** them *(the phase-0 item)*
- The student record — plan, subscription, progress, exams, certificates, sessions
- **View-as-student**, audited, time-limited, with a visible banner. `K-02`: without all three it
  does not ship
- The reported-content queue, fed by the student — a **section** or a **question**, and never
  from inside a timed exam. It shows the report and **not who made it**:
  a person is found here by an exact address and never listed (`K-22`), and a queue naming who
  complained is a list of people to browse — which is the read an audit cannot tell from working
- The closed list of system parameters, each change audited with actor, old value and new value.
  A **list**, not a registry: a table of names and values with a screen that edits any of them is
  the configuration surface `K-13` exists to refuse. It lives in `internal/console/writes.go`,
  where a test reads this package's own source and fails on a write nobody declared — so what is
  closed is the set of things the console can do, and adding to it costs an argument
- Prices effective-dated, so a subscriber keeps the price they bought at. A price is **appended**
  where a colour is **replaced**, and the two sit on one screen: nothing has to be explained about
  last month's colour, and a March invoice has to stay explicable in November
- Synthetic students flagged and excluded from every aggregate by default, with a visible switch
  and a banner when they are included
- Granting access to one student — a legitimate audited action, where a global paywall switch is
  not (`K-15`)

### Understand

- The funnel, all eight steps from *arrived* to *subscribed*, counted per **person**
- Cohorts, by signup and by subscription start
- Item analysis: which questions discriminate, which are broken, what is quarantined — with
  **every threshold displayed beside the number it produced** (`K-16`), and *insufficient data*
  rather than a red that means nothing beneath the minimum sample (`C-17`)
- The catalogue as it stands — draft and published per course. Read, never written: `C-07`, held
  by a test that scans the source

### Watch

- Presence, from `last_seen_at`, written at most once a minute — **people and not sessions**, so a
  laptop and a phone are one person, and **a count and not a roll**: `K-22` holds here too, and
  "who is online" is where it is easiest to break by being helpful. It is the one number in the
  console that is current state rather than the event stream, which is `K-06` and not a hole in
  `K-03`: nobody asks who was online last March, and the stream could not answer if they did —
  that needs an event for LEAVING, and no browser reliably sends one
- A world map with per-country statistics, from an in-process GeoIP database — the country stored
  on the event, the address never stored (`K-05`). It counts **people** through the same
  `personOf` the funnel uses, so the two screens cannot disagree; somebody seen in two countries
  is in both, which makes the rows add up to more than the people, so the honest total travels
  beside them rather than being their sum. `unknown` is a row like any other — it is where
  everything behind a VPN comes from, and hiding it would make the percentages lies
- The failed job queue, with retry. Every attempt is a row, written before the work and closed
  after it — so a job that was killed leaves the one trace it will ever leave, and after an hour
  the reader calls it **adrift** rather than busy. The retry is the part that is not built: it
  would mean this console holding the right to start a job
- E-mail deliverability: bounces and complaints

**Operational alerts stay out**, and that is `K-08` rather than an omission: uptime checks and
alert policies have to reach a phone *when the console is down*, which is exactly when you need
to know. That machinery exists and is in `infra/monitoring.tf`.

### Audit

- The immutable history, searchable: who did what, to whom, when, and what the value was before
- It is not a screen bolted on at the end. Every administrative write already records the actor
  (`K-01`) and `cmd/staff` writes to it too, precisely so that "every path" is true rather than
  "every path except one"

### And what feeds it that is not a screen

- A seeder that generates **history** — months of backdated events, with abandonment, returns,
  duplicate signups and refunds. Without it every screen above is developed against three rows
  and looks finished

---

## The order it arrives in

Delivery order, not scope. Each of these is a body of work and each is on the roadmap already.

1. **The door, and the phase-0 item.** The host, the two gates, the audit entry, and one screen:
   find a person, show, export, erase. This unblocks the last box in phase 0.
2. **Audit and the student record.** The two reads that make the first screen safe to use —
   knowing what was done, and seeing the person you are about to act on.
3. **Understand.** The funnel is built and unrendered; item analysis runs in `cmd/analyse` and
   nobody can see it. Both are screens over machinery that already exists.
4. **Watch, and the rest of operate.** Presence, the map, the queues, the parameters,
   view-as-student.

The seeder belongs before step 3, because a funnel with four events in it cannot be reviewed.

Steps 1 to 3 are done and step 4 is in the middle: presence, view-as-student, the
reported-content queue and the map are built, and the parameters have two entries and no list. `ROADMAP.md` is where that is tracked — this document is what the console
IS, and a status line here would be the same fact in two places, drifting.

**Why this order and not the reverse.** Phase 0 is a wall the rest of the project is meant to
wait behind, and one item is holding it. Everything else in the console improves a system that
is already running; the export and the erasure are an obligation to a person who asks.

---

## Where it lives

### One binary, one repository

`P-02` says monorepo, and the reason it gives is precise: *the boundary between repositories
matched no boundary in the system.* The console reads the catalogue, the accounts, the audit and
the privacy registry — four modules that live here. A second repository would mean a second
deployment, a second pipeline, a second Terraform surface and a contract to keep in step, in
exchange for a directory.

The predecessor did split, and `CLAUDE.md` in `codeschool-ing.github.io` records the bill: one
stylesheet in three copies, one of them checked.

So: the same binary that already serves the API and the embedded interface.

### One console, for every school, at `console.<platform domain>`

`console.schooling.lab.aleogr.dev` today, and the domain is provisional in the way the README
already says.

**One and not one per school**, and that is settled by the schema rather than by preference.
`migrations/0004_accounts_and_sessions.sql` opens with

> ONE ACCOUNT FOR THE WHOLE PLATFORM (N-01). There is no tenant_id on any table

A person therefore exists across schools, and exporting or erasing that person is by nature an
operation that crosses all of them. A per-school console could not perform the phase-0 item at
all.

**Not a path under a school.** A school is resolved by `Host` and everything under it is that
school's. Putting the console there would mean either a console that sees only the school whose
address you typed, or a school address that reaches another school's data.

**The resolver learns a third case.** Today an unknown host is a 404 and never falls into a
default school — `tenant.Resolve`, deliberate, and one of the ticked items. The console's host is
a host no school claims, so it would 404 like any other. It is recognised *before* school
resolution, by name, from configuration, never by a guess about subdomains:

> **A host is a school's, or the console's, or a 404.** Three cases, no fourth, and a test.

### The name is `console`, and it goes on the reserved list

`migrations/0003_reserved_labels.sql` refuses ten slugs at school creation, by a database
constraint and by the application, with a test proving the two agree. Its first entry is:

```sql
'admin',   -- the console, wherever it ends up living
```

So a name had already been reserved for this, and it was not the one every other document uses.
`console` is the name; the migration adds it. **`admin` stays reserved** — taking a name off that
list is strictly worse than leaving one on it, and the comment simply stops being a promise.

Doing this before the console answers anywhere is the whole point. The migration's own header
says what the alternative costs: renaming a school that students have bookmarked, *"the one kind
of change this project has already decided it will not make quietly."*

### And a mapping, which is a runbook line

`infra/README.md` already describes creating a school as two rows and a domain mapping. The
console is one more `gcloud beta run domain-mappings create`, and the certificate takes the same
forty minutes.

---

## What a number is scoped to, and why the screen says so

With one school this changes nothing. With three it decides every screen ever built, which is why
it is decided now rather than discovered later.

The schema already sorts the console's subjects into three kinds:

| kind | tables | what a total means |
|---|---|---|
| **per school** | `catalog_*`, `item_statistics`, `question_quarantine`, `certificates` | a sum across schools describes no school |
| **platform-wide** | `accounts`, `sessions`, `subscriptions`, `ledger_entries`, `audit_log`, `staff` | a school breakdown is not available, because the row has no school |
| **either** | `events` — `tenant_id` is nullable, with a `CHECK` that it is NULL exactly when `school_slug` is empty | both questions are real and they are different questions |

Item analysis is the clearest case: "does this question discriminate" is asked of a question in a
school's catalogue, and averaging its difficulty with another school's produces a number that
describes neither.

**So the scope is declared and never assumed.** A control in the chrome — *this school*, or *the
platform* — and every screen states which one it is showing. A screen whose subject has no school
says so instead of offering a filter that would do nothing; a screen whose subject cannot be
summed across schools says *that* rather than summing anyway.

This is the same rule as `K-16`, one level up: a threshold travels with the number it produced,
and so does a scope. A dashboard whose numbers are right and whose scope is a guess is a
dashboard that gets quoted in a meeting.

---

## Who gets in

Nothing new is needed, and that is worth saying because it is unusual.

- **An account with a staff role.** `identity.Role` — owner, operator, read-only — already exists,
  ranked, with `Covers`. `cmd/staff` grants the first one, because the console cannot grant the
  role that reaches the console.
- **A second factor on the session.** Mandatory for staff, enforced on the session rather than on
  the account, and revoking a role already ends every session that held it.
- **The session cookie is already on the parent domain**, so a staff member who signed in at a
  school is signed in at the console. That follows from `K-01` — *staff is a role on an account,
  not a second account* — and it is the same person either way.

**Two gates, independently.** The host must be the console's *and* the session must carry the
role. Either one alone is a single mistake away from a hole, and they fail differently: a
misconfigured host is a deployment error, a missing role check is a code error, and a system that
needs both to be wrong is a system that survives one of them.

**Read-only reads. Operator acts.** An export is a read of everything about a person and an
erasure cannot be undone; the ranks already exist to say which is which.

---

## Both actions are audited, including the export

`K-01` says *every administrative write records the actor*, and an erasure is plainly that. An
export is not a write, and it is audited anyway.

The reason is that an export is the one read that removes the protection every other read has:
after it, a person's whole record is a file on somebody's laptop, outside every access control
this system has. "Who took a copy of whose data, and when" is a question that gets asked exactly
once, in the worst week of the project, and the answer has to already exist.

---

## The seam, and the architecture problem it runs into

`K-07` says *every console read goes through its own layer* — today it queries production, and
the seam is what lets it point at a replica or a rollup later without touching a screen.

That collides with the rule this repository enforces with a test: **a module may not import
another module.** A console module reading accounts, audit and privacy would import three.

It is not a new problem and it already has an answer here. `visitor.SchoolOf` and
`visitor.Arrived` are function types the *consumer* declares and `cmd/api` wires together — the
module says what shape it needs and never says who provides it. The console does the same, with
more of them.

Whether that stays comfortable at twenty functions instead of two is the first thing this design
will find out, and it is worth saying now so that nobody is surprised into a shortcut later.

---

## What the interface is

`ui/` is the student interface and is, deliberately, mostly a copy of `portal-frontend`. **The
console is the same kind of copy, of `console-frontend`** — the staff console the finished
project already shipped. It is a full-screen layout and not a page: the fixed 64px bar across the
top, a left rail whose entries are grouped by job, and a stage that fills the rest. A screen is
`async (section) => ({ title, el })` and the router is a hash router, because that is the contract
those screens are already written against.

What came across is the shell and the vocabulary — `assets/console.css`, `app/routes.js`,
`app/dom.js` — and what did not is every screen, because the screens are about this platform and
that one is about one school. The tree is still the console's own and still embedded; nothing is
shared at build time with a repository this one does not write to.

`assets/base.css` is shared for real, though, and not by copying: the console serves the study
interface's bytes out of its embed, so the tokens, the reset and the bar cannot drift between the
two halves of one binary. Two visual systems for one product is how a console starts looking like
a different company's software.

**That stylesheet already exists three times across the organisation** — here, in
`portal-frontend`, in `console-frontend` — each with a comment asking whoever edits one to copy
it onward. A fourth copy inside this binary would have been indefensible, which is what
`TestTheConsoleServesTheSharedStylesheetAndNotACopy` is standing on.

---

## The three that were open

### A person is found by an exact address, and never listed *(K-22)*

E-mail, because it is the only identifier a support request carries — nobody writes in quoting a
uuid, and a name is not unique.

**The decision was never which field, though. It was exact or partial.** An exact match answers
"this person who wrote to me, are they here?". A partial one — type `@gmail.com`, read the list —
is a different power: it is browsing people. And browsing personal data is exactly what an audit
trail cannot distinguish from working, because both look like a staff member opening records.

Exact match also closes the smaller thing: a search that answers "no such account" differently
from "found" is an oracle for whether any given address has an account here. Among two people
with mandatory MFA that is a small worry, but not building it is free — and with an exact match,
"not found" tells the asker only what they already typed in.

### The banner names the school as well as the student, and so does the audit entry

`K-02` gives view-as-student three restraints that ship together or not at all: audited,
time-limited, visible banner. The open part was what the banner says.

The console is one and crosses schools, while a student's view is served on a school's host. So a
banner naming only the student is ambiguous with two tabs open — and "the address bar says which"
is another way of saying the information lives somewhere nobody looks while concentrating.

Honestly: this is clarity rather than safety. The danger the banner exists for is forgetting you
are impersonating **somebody**; which school is the smaller confusion. It is worth the few words
anyway, and the half that matters more is the other one — **the audit entry carries the school
too**, which costs no migration because `audit_log.tenant_id` already exists and is null for a
platform-wide action. The value shows up in the conversation that begins "why did you open that
person's account": a screenshot and a log line telling the same story is an answer, and two
partial versions is an argument.

### A screen asks only what an index sustains *(K-21)*

This one was asked wrongly, and reading the table answered it. `audit_log` already carries four
indexes:

```sql
audit_log_by_time    (occurred_at DESC)
audit_log_by_actor   (actor_id, occurred_at DESC)
audit_log_by_subject (subject_kind, subject_id, occurred_at DESC)
audit_log_by_school  (tenant_id, occurred_at DESC) WHERE tenant_id IS NOT NULL
```

So the question is not **how many rows**, it is **which query**. Recent-first paging, one actor's
entries, everything that happened to one person — each has an index that already sorts it — cost
the same at ten million rows as at ten. What gets expensive is what has no index: free text
through `before`/`after`, totals, a filter on `action` with no time bound.

So the first version asks only what those cover, and `K-07`'s layer goes in from the first day —
not because anything will be slow, but because it is what stops the day something *is* from
becoming a rewrite of screens. A query that does not fit becomes an index or a rollup, decided
there and then.

---

## What made this document wrong twice

Kept because both are the same shape as failures this project has already written rules about.

**It read as pruning phase 4.** An early draft said the phase-4 screens were "explicitly not
this", meaning *not in the first slice*, and never said the other half anywhere. Scope and order
are different sentences and had been written as one.

**It asked a question a migration had already answered.** The open list included "should
`console` be reserved?" — while `migrations/0003_reserved_labels.sql` had reserved `admin` years
of decisions ago, with the comment *"the console, wherever it ends up living"*. The answer was in
the repository and the question was asked anyway. That is the same failure as a roadmap tick
nobody can disprove, pointed the other way: not a claim without evidence, but a question whose
evidence was never looked for.
