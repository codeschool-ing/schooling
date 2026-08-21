# The console — a proposal

**Nothing here is decided.** This is written to be disagreed with while it is still cheap:
paragraphs cost less to argue about than screens, and everything below is one merge away from
being a fact nobody revisits.

It exists because phase 0 has one item left — *personal-data export and erasure, reachable from
the console* — and it cannot be done without answering questions much bigger than the item. The
export and the erasure already work and are held by four tests. What is missing is a door, and a
door needs a building.

**Nothing in [`ROADMAP.md`](ROADMAP.md) is pruned by this document.** An earlier draft of it said
phase 4's screens were "explicitly not this", meaning *not in the first slice*, and it read as
*not ever*. That was the draft's fault. The console this proposes is the complete one; what is
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
- The reported-content queue, fed by the student
- The closed list of system parameters, each change audited with actor, old value and new value
- Prices effective-dated, so a subscriber keeps the price they bought at
- Synthetic students flagged and excluded from every aggregate by default, with a visible switch
  and a banner when they are included
- Granting access to one student — a legitimate audited action, where a global paywall switch is
  not (`K-15`)

### Understand

- The funnel, all eight steps from *arrived* to *subscribed*, counted per **person** *(already
  built; the screen is what is missing)*
- Cohorts, by signup and by subscription start
- Item analysis: which questions discriminate, which are broken, what is quarantined — with
  **every threshold displayed beside the number it produced** (`K-16`), and *insufficient data*
  rather than a red that means nothing beneath the minimum sample (`C-17`)
- The catalogue as it stands — draft and published per course. Read, never written: `C-07`, held
  by a test that scans the source

### Watch

- Presence, from `last_seen_at`, written at most once a minute
- A world map with per-country statistics, from an in-process GeoIP database — the country stored
  on the event, the address never stored (`K-05`)
- The failed job queue, with retry
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

`ui/` is the student interface and is, deliberately, mostly a copy of `portal-frontend`. The
console is not a copy of anything, so it is a sibling — its own embedded tree, its own routes, no
shared build step, and none of the assumptions that make sense for a school.

It shares one thing on purpose: the stylesheet. Two visual systems for one product is how a
console starts looking like a different company's software, and the shared file is small.

---

## What this proposal still does not answer

1. **Is a person found by e-mail only?** It is the only identifier a support request carries. It
   is also enough to enumerate accounts if the search answers "no such account" differently from
   "found" to somebody who is only read-only. Probably fine among two people; worth deciding
   rather than inheriting.

2. **Does view-as-student cross into a school the staff member is not a student of?** It has to,
   to be useful, and `K-02`'s three restraints are written for exactly that. What is undecided is
   whether the banner names the school as well as the student.

3. **How far back does the audit screen read before it needs the seam `K-07` describes?** Not a
   question for the first version, and the wrong time to answer it is the first slow query.

---

## If this is accepted

`PLAN.md` gets the decisions and this file stops being a proposal. It is left alone until then on
purpose: `PLAN.md` is where reasoning that has been agreed lives, and writing into it first would
be the same failure as ticking a roadmap box ahead of the thing it claims.
