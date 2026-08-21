# The console — a proposal

**Nothing here is decided.** This is written to be disagreed with while it is still cheap:
paragraphs cost less to argue about than screens, and everything below is one merge away from
being a fact nobody revisits.

It exists because phase 0 has one item left — *personal-data export and erasure, reachable from
the console* — and it cannot be done without answering questions that are much bigger than the
item. The export and the erasure already work and are held by four tests. What is missing is a
door, and a door needs a building.

---

## What the first version is

**Find a person. Show what is held about them. Export it. Erase them.** Four things, on one
screen, and nothing else.

That is the phase-0 item and its whole scope. Everything in [`ROADMAP.md`](ROADMAP.md)'s phase 4 —
cohorts, the funnel, the world map, view-as-student, the parameter list, the reported-content
queue — is explicitly **not** this. Phase 4 is a body of work; this is the door it will later be
built around.

The temptation is to build a dashboard because a console feels like it should have one. A
dashboard with no students is a screen that teaches nobody anything, and the roadmap already says
where those belong.

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

### Its own host, and that is not cosmetic

`console.<platform domain>` — `console.schooling.lab.aleogr.dev` today, subject to the naming
question at the end of this document, which turns out to have been half-answered already.

**Not a path under a school.** A school is resolved by `Host` and everything under it is that
school's; the console operates *across* schools, so putting it under one would mean either a
console that can only see the school whose address you typed, or a school address that can reach
other schools' data. Neither is a thing to build.

**The resolver has to learn about it.** Today an unknown host is a 404 and never falls into a
default school — that is `tenant.Resolve`, it is deliberate, and it is one of the ticked items. A
console host is a host no school claims, so it would 404 like any other. It therefore needs to be
recognised *before* school resolution, by name, from configuration — not by a guess about
subdomains.

That check is worth writing down as a rule: **a host is a school's, or the console's, or a 404.**
Three cases, no fourth, and a test that says so.

### And a mapping, which is a runbook line

`infra/README.md` already describes creating a school as two rows and a domain mapping. The
console is one more `gcloud beta run domain-mappings create`, and the certificate takes the same
forty minutes.

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

**Read-only reads. Operator erases.** An export is a read of everything about a person and an
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

## What this proposal does not answer

Left open on purpose, because they are decisions and not details:

1. **Does the console show one school at a time, or all of them at once?** Everything phase 4 wants
   — funnels, cohorts, item statistics — is per school. A school picker is a decision that reaches
   every screen ever built, and it is cheaper to make it now than to retrofit it. The first
   version does not need one, which is exactly why it will be made carelessly if nobody asks.

2. **Is a person found by e-mail only?** It is the only identifier a support request carries. It
   is also enough to enumerate accounts if the search answers "no such account" differently from
   "found" to somebody who is only read-only. Probably fine among two people; worth deciding
   rather than inheriting.

3. **`console.` or `admin.`?** The reserved-label list already has an opinion, and it is not the
   one this document assumed. `migrations/0003_reserved_labels.sql` refuses ten slugs at school
   creation, by a database constraint and by the application, with a test that proves the two
   agree — and the first entry reads:

   ```sql
   'admin',   -- the console, wherever it ends up living
   ```

   So somebody already reserved a name for this and it was not `console`. Two ways out, and they
   are not equal:

   - **`admin.<platform domain>`** — already reserved, no migration, and the comment stops being a
     promise. Against it: `admin` says who may enter and `console` says what the thing is, and the
     product calls it a console everywhere else including the phase in the roadmap.
   - **`console.<platform domain>`** — the name the rest of the documents use, and a migration
     adding it to the list.

   What must NOT happen is the console answering at a name a school could also be created at. The
   file's own header says what that costs: the fix becomes renaming a school students have
   bookmarked, *"the one kind of change this project has already decided it will not make
   quietly."* Whichever name wins, it is on the list before the console answers anywhere.

---

## If this is accepted

`PLAN.md` gets the decisions and this file stops being a proposal. It is left alone until then on
purpose: `PLAN.md` is where reasoning that has been agreed lives, and writing into it first would
be the same failure as ticking a roadmap box ahead of the thing it claims.
