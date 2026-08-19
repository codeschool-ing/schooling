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
- [x] One Go binary serving the API and the embedded frontend on one origin
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

- [x] `content/` holds prose in Markdown, structure and exercises in JSON, and a course's pictures in its `images/` — a picture no question labels fails the build, exactly as an orphaned `.md` does
- [x] The validator runs in CI — broken prerequisites, cycles, track order, `requires` that no track containing the course satisfies, checked **per branch** of every fork
- [x] The load job writes the mirror from the files and prunes what the files no longer carry, in one transaction, and writes nothing at all if the catalogue does not pass
- [x] Nothing else writes catalogue rows; the console reads and never writes — enforced by a test that scans the source
- [x] Draft and published state per course
- [x] Ids are slugs that never derive from a title; order declared, never inferred from filenames
- [x] The content check runs the **answer keys**, not only the schema, for every type that has a grader — `expression-answer` now goes through its grader too, so a question whose own accepted expression does not parse fails on a pull request rather than on a screen; `code` executed is still to come, and reported rather than skipped until then
- [x] An orphaned `.md` that no `lesson.json` references fails the build

### What the student sees

- [x] The interface served from the same binary and the same origin, with no build step — fragment routes, so the offline bundle is a packaging job and not a second router
- [x] Nothing loaded from another origin, the type included — a student's browser tells no third party which school they are reading, and the two machines that render this interface finally measure the same cards
- [x] `track → course → lesson → section`, with `requires` and `links` distinct
- [x] The track graph, with edge routing that avoids the cards — Sugiyama's ordering, and a router that takes a line around a card when it can see one in the way
- [x] The graph test — every track, six viewport sizes, four landscape and two portrait, no line through a card
- [x] Sidebar, search, dashboard, catalogue, track map
- [x] Section progress, resume pointer, notes — completion set-true and never toggled, and refused in a course the student cannot open
- [x] Sitting an exam on a screen — the paper, an answer saved as it is made and put back on a reload, and a hand-in that says what it came to
- [x] Drilling on a screen — one card at a time, marked by the server, with the day it comes back said out loud
- [x] ~~The modal test — every course, one height, neither column scrolling~~ — **there is no modal here.** The predecessor showed a course in one, on a marketing page; a course is a screen of its own in this interface, so the test has no subject. Its actual concern — a layout that holds for every course — is covered by the accessibility pass, which opens the course and lesson screens, and by the graph test, which measures a real drawing rather than trusting one
- [x] Portuguese and English, with the interface-string checker — which fails on a missing translation **and** on one nothing says any more
- [x] WCAG 2.2 AA on every screen, with an automated check in the browser suites — axe over twenty-four screens, both themes, signed out and signed in, the exam paper included
- [x] Every question type operable by keyboard and legible to a screen reader — `ordering` on buttons, `matching` on a select, and `labelling` by choosing a label and then placing it with a click **or the arrow keys**, its position said in words ("63% across, 41% down") so somebody who cannot see the diagram can still be told where they put a thing and move it
- [x] The offline bundle, built **and opened** in CI — one file, one school; opened from `file://` it reads the whole catalogue and asks nobody for anything, served from the school's origin it is the application again; signing in, progress and exams are refused with a sentence rather than a form that does nothing

### Assessment

- [ ] The seven types: `quiz`, `multiple-choice`, `ordering`, `matching`, `labelling`, `expression-answer` **done**; `code` and `expected-output` need a sandbox
- [x] Conformance fixtures, per type — no longer between two graders (A-09 is retired: a client that could mark an answer would be a client holding the key) but between the grader and the questions, so a change that alters a verdict has to change a file somebody wrote. A gradable type with no fixture fails the build
- [x] A question is **presented** rather than sent — the answer removed, the order shuffled where the order is the answer, and the permutation kept here
- [x] Course exams and track exams — a sealed paper per attempt, one open attempt at a time, marked once on hand-in against the questions as they were actually asked
- [x] Certificates, with a public verification page — issued at the moment an exam is passed, saying what it said on the day, and verifiable by a stranger with no account
- [x] Free tier: the first course of every track, in every school — computed from the track's order rather than flagged on a course
- [x] Access computed fail-closed — an unrecognised plan is a guest, an unreadable catalogue refuses

---

## 2 — Learning, complete

Everything the other subjects will demand, built before a subject demands it.

*Done when: an algebraic answer written differently is accepted, and yesterday's review comes
back today.*

- [x] `expression-answer` graded by a computer algebra system — **by sampling rather than by rearranging symbols.** Two expressions over the reals are the same if they agree everywhere, and everywhere can be sampled: a parser for school algebra (implicit multiplication included, because that is how people write it), then both sides evaluated at two dozen chosen points. It cannot simplify or factor and does not need to — the question is always "are these equal", never "what is this" — and what it cannot see is a difference at a single point, written down in the package and pinned by a test
- [x] `numeric` — a number with a unit and a tolerance
- [x] `cloze` — a blank with accepted answers and normalisation
- [x] `labelling` — a label on a point of an image, in fractions of it rather than pixels
- [x] All four in the conformance fixtures — `numeric`, `cloze`, `labelling` and now `expression-answer`, whose fixture carries the two verdicts that matter either way: `(x+1)^2` accepted against an expanded key, and a typo returned as a bad answer rather than a wrong one
- [x] `drillable` on exercises — checked rather than trusted, so an exam-only question cannot be drilled into telling a student what is on the paper
- [x] `practice_state` — strength, due date, lapses; overwritten in place beside the append-only log it can be recomputed from
- [x] SM-2, with the quality score derived from correctness and time rather than asked — the thresholds are a first guess, and `practice_review` carries the before-values so they can be fitted rather than argued about
- [ ] A review queue that crosses schools, scoped by what the subscription covers — **the queue exists, within one school.** Crossing them needs the platform's own address, because a request arrives on a school's host and is scoped to it before any module sees it; that waits on the domain. The change will be a second entry point over the same rows, not a second scheduler
- [x] A test proving decayed strength never reaches a progress bar — a source scan, because the coupling that would do the damage is a SQL string and no import graph can see one
- [x] Practice excluded from certificate eligibility — held the same way, over `certificate` and `exam`

---

## 3 — Billing

*Done when: a student pays under both models, delinquency suspends on its own, and recovery
restores access with progress intact.*

- [ ] Brazil: annual and biennial in card instalments
- [ ] Brazil: Pix in one payment, at a discount, on the annual plan
- [ ] Elsewhere: monthly, annual and biennial, recurring
- [x] Two subscription state machines, because instalments are not recurrence — and the difference is enforced rather than documented: an instalment plan **refuses** `payment-failed` and `retries-exhausted`, because a card instalment is one authorisation split by the issuer and there is no monthly charge for us to see fail. Written as one machine with a flag, the instalment plan would inherit a grace period and a suspension path its payments cannot reach — dead states waiting for somebody to wire an event into them
- [x] Renewal as a **new sale** for the instalment model, with notice before expiry — an expired term is revived by a payment on the same row, so recovery keeps the person's history rather than starting a second subscription beside it. The notice window is one function, asked by whatever screen or job needs it, because two implementations of "is it nearly over" would disagree in the one week that matters
- [x] Grace with retries before suspension — grace still opens the door. Cutting somebody off at the first declined card would lock out every student whose bank flagged a routine transaction, and the retry schedule exists because most of those recover. A recurring subscription is also never expired by time alone: one that lapsed because a webhook was late would be a paying student cut off for our own outage
- [x] Cancellation at the end of the paid period; refund and chargeback cutting immediately. The two are separate events even though both cut access at once, because they mean opposite things about the person — one is an agreement and the other is a dispute, and an operator needs to know which conversation to have
- [ ] Webhooks idempotent by event id — **the guarantee is in place; the endpoint waits on the gateway.** It is a unique index on the ledger row itself rather than a table somebody checks first: read as check-then-insert it is a race, and a retry arriving while the first delivery is still running is the normal case rather than the exception. Both are pinned by a test, one of them concurrent
- [x] An append-only ledger — no update, no delete; a reversal is a new entry. Not double entry, and the reason is written in the migration: the second side would be a constant, because splits, payouts and school-to-platform billing were all removed from this system before it was built. A refund points at the payment it refunds, and cannot take off more than is left — checked in the transaction that writes it, with the row locked, because it is an aggregate over siblings rather than a property of one row
- [x] Every amount an integer number of cents — a `Money` whose fields are unexported, so there is no float arithmetic on an amount to write anywhere in this repository, and whose zero value is deliberately invalid, so an uninitialised total cannot add cleanly to a bill in any currency. Instalments are split so the parts sum back to the whole, with the odd cent on the early ones; a percentage rounds half away from zero, which is what a person checking the invoice by hand does
- [x] Access always computed from the subscription, never from an enrolment record — `planOf` in `cmd/api` is the only place `catalog` and `billing` meet, which is why neither ever had to know about the other. It fails closed on an unreadable database too: an outage that quietly made every paid course free is the one failure a paywall cannot have. Reading a subscription **settles it in memory**, so a period that ran out closes the door with no job having run; the job that writes the row back exists so a report is not counting cancellations that ended weeks ago
- [x] Terms of use and privacy policy published, covering the visitor identity — **and the policy is checked against the privacy registry.** A `covers:` line in each document names the tables it accounts for, and a test fails when a table holding personal data is not among them. That is the same failure shape as an unclassified table, one layer up and worse: an unclassified table fails CI, while a table nobody wrote into the policy fails nothing — the document keeps rendering, keeps looking finished, and nobody rereads a privacy policy against a schema. Four things in the two documents are still somebody else's decision (the company, the jurisdiction, the refund window, the notice before a price change) and are marked in every language, with a test that they stay marked

---

## 4 — The console, complete

*Done when: a question with a broken answer key is found by the statistics, and the funnel shows
a drop at a step nobody suspected.*

### Understanding

- [ ] Cohorts, by signup and by subscription start
- [ ] The funnel, all eight steps from *arrived* to *subscribed*
- [ ] "Active" defined in one place — completed a section or a review
- [x] Item analysis: attempts, percentage correct, discrimination index — **mean time is not among them, and that is a decision rather than an omission.** The exam does not measure how long a question took: answers are saved as they are made, so the only timestamps available would measure how long a tab was left open. Practice does measure it, and practice is the same person answering the same card repeatedly, which answers a different question. Measuring it properly means the exam screen reporting elapsed time per question, and that is its own piece of work
- [x] Nothing fires below a minimum sample; the screen says *insufficient data* rather than a false red — `insufficient` is a member of the verdict list rather than the absence of one, so a screen cannot show an unmeasured question as though it had passed. The discrimination index is not even computed below the sample: a number on a screen is read as a finding whatever the label beside it says. It is also the answer when the paper separated nobody — an index of zero because there were no two groups to compare is not a weak question, and calling it one blames the question for the paper
- [x] A flagged question is quarantined automatically, by threshold — it leaves the exam draw and the drill queue, and **comes out of the denominator of a paper already in progress**: nobody should fail on a question we have admitted is broken, and dropping it from the score is the only remedy that does not require guessing what they would have answered. Only `inverted` triggers it, never difficulty and never a verdict below the sample; `Quarantine` refuses anything else, so the one caller that could widen it cannot. A new version is not under the old quarantine, which makes fixing the question the ordinary way out; releasing is the override and needs a reason. The terms of use say all of this again, in the words a student reads
- [x] Exercises are versioned, and a student's answer records the version it answered — and item analysis keeps them apart. Folding two versions together would average a wrong key with the fix that corrected it, so the fix would be hidden by the answers given before it, which is the exact failure this is for
- [x] Quarantine and reinstatement are audited events, with the numbers that decided them — the actor is `system: item analysis`, which is a real actor rather than a blank. A quarantine whose audit entry fails to write is an error and not a silence: the row is already there by then, so swallowing it would leave a question out of circulation with nothing explaining why. **Replacement is not a third action:** a new version of a question is a different question that the old quarantine does not match, so replacing one is content work that shows up in the load job's history rather than an administrative act on this table
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
