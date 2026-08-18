# Roadmap

What each phase is made of. [`PLAN.md`](PLAN.md) carries the shape and the reasoning; this file
carries the list.

**Every item here is a capability, not a task.** "A student can pay with Pix", never "add a Pix
button". Capabilities change rarely and can be verified — you tick one when it actually exists.
Tasks change daily and belong in issues, where going stale costs nothing. A checklist of tasks in
a versioned file is out of date by the second week and nobody notices.

The system is finished **before** any new content is written. **Done means:** the pipeline
produces a course end to end, and a student can pay for it.

---

## 0 — Skeleton, and the five that cannot wait

*Done when: two schools answer over TLS, and the first administrative action shows up in the
audit with a name against it.*

### The five

- [x] Events carry their dimensions denormalised — plan, school, country, locale, copied at emission
- [x] `practice_review` exists and is append-only, before any practice screen does
- [x] Every administrative write records the actor — the audit path refuses an entry without one, and it is the only path there is
- [x] Every table holding personal data is reachable by the export and the erase path, with a test that fails on a table nobody classified
- [x] A visitor has an identity before the account exists, and signup links the two

### Shape

- [ ] Monorepo, with CI filtered by path
- [x] School resolved by the full `Host`; an unknown host is a 404 and never falls into a default school
- [x] Reserved subdomains refused at creation — `www`, `api`, `admin`, `app`, `auth`, `cdn`, `mail`, `static`, `status`, `docs` — by a database constraint as well as by the application, with a test that proves the two agree
- [ ] One Go binary serving the API and the embedded frontend on one origin
- [ ] A domain mapping per school
- [x] `tenant_id` on every school-scoped table, with an index leading with it, and every index that crosses schools declared with its reason
- [x] The module dependency graph enforced by a test

### Identity and access

- [x] One account for the whole platform; session cookie on the parent domain, `HttpOnly`, storing the token's hash and never the token
- [x] Staff roles — owner, operator, read-only, as a row on an account rather than a second account. *Invitations wait on e-mail, which waits on the domain.*
- [x] Mandatory MFA for staff, enforced on the session rather than on the account, and revoking a role ends every session that held it
- [ ] Personal-data export and erasure, reachable from the console

### Operations

- [x] Migration as a job with an advisory lock, run before traffic reaches the new revision
- [ ] Terraform owns the project services, registry, service accounts, IAM, Cloud SQL, secret *containers*, the identity federation and the alert policies
- [ ] The deploy pipeline owns which revision runs; Terraform never manages the image
- [x] Semantic version in one place — the tag — with the release workflow refusing a tag that is malformed, does not increase, or is not on main
- [x] `/api/v1/` from the very first route
- [ ] Uptime check and alert policy reaching a phone
- [ ] A backup **restored** — to a cloned instance, verified, then destroyed. Never over the live one. No staging environment

---

## 1 — The study platform

*Done when: a student walks a whole track of `code` on the new platform.*

### The catalogue

- [x] `content/` holds prose in Markdown and structure and exercises in JSON
- [x] The validator runs in CI — broken prerequisites, cycles, track order, `requires` that no track containing the course satisfies, checked **per branch** of every fork
- [x] The load job writes the mirror from the files and prunes what the files no longer carry, in one transaction, and writes nothing at all if the catalogue does not pass
- [x] Nothing else writes catalogue rows; the console reads and never writes — enforced by a test that scans the source
- [x] Draft and published state per course
- [x] Ids are slugs that never derive from a title; order declared, never inferred from filenames
- [x] The content check runs the **answer keys**, not only the schema, for every type that has a grader — `code` executed and `expression-answer` through the CAS still to come, and reported rather than skipped until then
- [x] An orphaned `.md` that no `lesson.json` references fails the build

### What the student sees

- [ ] `track → course → lesson → section`, with `requires` and `links` distinct
- [ ] The track graph, with edge routing that avoids the cards
- [ ] The graph test — every track, six viewport sizes, four landscape and two portrait, zero crossings
- [ ] Sidebar, search, dashboard, catalogue, track map
- [x] Section progress, resume pointer, notes — completion set-true and never toggled, and refused in a course the student cannot open
- [ ] The modal test — every course, one height, neither column scrolling
- [ ] Portuguese and English, with the interface-string checker
- [ ] WCAG 2.2 AA on every screen, with an automated check in the browser suites
- [ ] Every question type operable by keyboard and legible to a screen reader — `matching`, `ordering` and `labelling` are the hard ones
- [ ] The offline bundle, built **and opened** in CI

### Assessment

- [ ] The seven types: `quiz`, `multiple-choice`, `ordering`, `matching` **done**; `code`, `expected-output` need a sandbox, `expression-answer` needs the CAS
- [x] Conformance fixtures proving the client grader and the server grader agree, per type — the server's half runs them, and a gradable type with no fixture fails the build
- [ ] Course exams and track exams
- [ ] Certificates, with a public verification page
- [x] Free tier: the first course of every track, in every school — computed from the track's order rather than flagged on a course
- [x] Access computed fail-closed — an unrecognised plan is a guest, an unreadable catalogue refuses

---

## 2 — Learning, complete

Everything the other subjects will demand, built before a subject demands it.

*Done when: an algebraic answer written differently is accepted, and yesterday's review comes
back today.*

- [ ] `expression-answer` graded by a computer algebra system
- [x] `numeric` — a number with a unit and a tolerance
- [x] `cloze` — a blank with accepted answers and normalisation
- [x] `labelling` — a label on a point of an image, in fractions of it rather than pixels
- [ ] All four in the conformance fixtures
- [ ] `drillable` on exercises
- [ ] `practice_state` — strength, due date, lapses
- [ ] SM-2, with the quality score derived from correctness and time rather than asked
- [ ] A review queue that crosses schools, scoped by what the subscription covers
- [ ] A test proving decayed strength never reaches a progress bar
- [ ] Practice excluded from certificate eligibility

---

## 3 — Billing

*Done when: a student pays under both models, delinquency suspends on its own, and recovery
restores access with progress intact.*

- [ ] Brazil: annual and biennial in card instalments
- [ ] Brazil: Pix in one payment, at a discount, on the annual plan
- [ ] Elsewhere: monthly, annual and biennial, recurring
- [ ] Two subscription state machines, because instalments are not recurrence
- [ ] Renewal as a **new sale** for the instalment model, with notice before expiry
- [ ] Grace with retries before suspension
- [ ] Cancellation at the end of the paid period; refund and chargeback cutting immediately
- [ ] Webhooks idempotent by event id
- [ ] An append-only ledger — no update, no delete; a reversal is a new entry
- [ ] Every amount an integer number of cents
- [ ] Access always computed from the subscription, never from an enrolment record
- [ ] Terms of use and privacy policy published, covering the visitor identity

---

## 4 — The console, complete

*Done when: a question with a broken answer key is found by the statistics, and the funnel shows
a drop at a step nobody suspected.*

### Understanding

- [ ] Cohorts, by signup and by subscription start
- [ ] The funnel, all eight steps from *arrived* to *subscribed*
- [ ] "Active" defined in one place — completed a section or a review
- [ ] Item analysis: attempts, percentage correct, mean time, discrimination index
- [ ] Nothing fires below a minimum sample; the screen says *insufficient data* rather than a false red
- [ ] A flagged question is quarantined automatically, by threshold — it leaves the draw and stops counting
- [ ] Exercises are versioned, and a student's answer records the version it answered
- [ ] Quarantine, replacement and reinstatement are audited events
- [ ] Generation provenance: which run produced what, at which verification level
- [ ] The nightly rollup, per school, country and event type
- [ ] Every console read through its own layer, so it can point elsewhere later

### Watching

- [ ] World map with per-country statistics, from an in-process GeoIP database
- [ ] The country stored on the event; the address never stored
- [ ] Presence via `last_seen_at`, written at most once a minute per session
- [ ] Failed job queue, with retry
- [ ] Email deliverability — bounces and complaints

### Operating

- [ ] View-as-student: audited, time-limited, with a visible banner
- [ ] Student record — plan, subscription, progress, exams, certificates, sessions
- [ ] Reported-content queue, fed by the student
- [ ] The closed list of system parameters, each change audited with actor, old and new value
- [ ] Prices effective-dated — a subscriber keeps the price they bought at
- [ ] Every threshold displayed beside the number it produced
- [ ] Synthetic students flagged, excluded from every aggregate by default, with a visible switch and a banner when included
- [ ] A seeder that generates **history** — months of backdated events, with abandonment, returns, duplicate signups and refunds

---

## 5 — The pipeline and the content

The last component of the system, and the first batch of what it produces.

*Done when: a course is born end to end without anyone writing a sentence, and item analysis
reports no inverted key.*

- [ ] The generator writes prose, exercises and exams into `content/`
- [ ] Three verification levels recorded per item — structure, execution, critiqued
- [ ] Provenance recorded on everything it produces
- [ ] It is resumable: it knows what it has already written and does not start over
- [ ] The regeneration loop — item analysis flags a question, the pipeline rewrites it, and the new version is compared against the old
- [ ] `code`: the seven entry courses that currently open onto an empty room
- [ ] `code`: the remaining courses
- [ ] `math`: the whole school

---

## 6 — Video and scale

*Done when: opening a new school is running the pipeline, and nothing else.*

- [ ] Video as the final layer of the material
- [ ] Signed URLs, short-lived, validated against the subscription at every issue
- [ ] Physics and chemistry
- [ ] The remaining languages
- [ ] A custom domain per school, if it turns out to be worth it
