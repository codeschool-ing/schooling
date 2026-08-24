# Roadmap

What each phase is made of. [`PLAN.md`](PLAN.md) carries the shape and the reasoning; this file
carries the list.

**Every item here is a capability, not a task.** "A student can pay with Pix", never "add a Pix
button". Capabilities change rarely and can be verified — you tick one when it actually exists.
Tasks change daily and belong in issues, where going stale costs nothing. A checklist of tasks in
a versioned file is out of date by the second week and nobody notices.

The system is finished **before** any new content is written. **Done means:** the pipeline
produces a course end to end, and a student can pay for it.

## How a box gets ticked

**A tick is a claim, and it is worth what the evidence behind it is worth.** Every `[x]` here has
to be checkable without taking this file's word for it: a test that names it, a tool that exits
non-zero without it, or a screen somebody can open. **A tick is never written ahead of the thing
it claims.**

That rule is written down because it was broken. "Drilling on a screen" was ticked while the
screen counted the queue and said the questions were not here yet; the routes behind it were real,
so the item read as finished for weeks and the gap was found by accident. A checked box nobody can
disprove is worse than an unchecked one: it stops anyone looking.

**This file is changed on its own, and after the fact.** Ticks are not written into the branch
that earns them: two branches editing one line is one correction arriving in two halves, and it
collides — which is how the very correction above was delivered. So the work merges first, and a
pull request that touches only this file follows it, where every claim it makes can be checked
against `main` rather than against a promise.

The cost is a window in which something is done and this file does not say so yet. That is the
right side to be wrong on. The audit found one item of each kind — one ticked and absent, one
present and unticked — and only the first had ever cost anything, because an unticked capability
gets rediscovered while a false tick stops the search.

*Audited against the code on 2026-08-20. Every `[x]` in phases 0 to 3 was checked against a named
test, a tool run or a screen opened. One tick was false, one item was done and unticked, and three
descriptions had gone stale — an id format, a screen count and a list of types, each of which had
been true when it was written. Phase 0's remaining items were infrastructure that could not be
verified from inside this repository.*

*The infrastructure ones are done, and each was ticked only after the thing had happened in
`aleogr-schooling` rather than after the configuration was written to make it happen — which
turned out to be the difference between a claim and a fact twice over. The alert policy applied
cleanly and was inverted; the restore drill passed its own tests and then failed a good backup on
six rows of ordinary traffic. Neither would have been found by reading the file that declared it.
The one that was left was a screen — the export and the erasure existed, held by four tests, with
no console page an operator could open.*

***Every box in phase 0 is now ticked, and the phase is not finished.** The screen was the last
one, and it went the same way as the infrastructure items: the tick came after an operator had
found a person, exported them and erased them against a real database, and after the two audit
entries had been read back and checked for what they must not contain. Its last two defects were
found by looking at a screenshot and by nothing else — a stylesheet asking for a typeface the page
never linked, and a table that said "18 table".*

*Its other half is met since: the `Done when` also asks that the first administrative action show
up in the audit with a name against it. The first one a released deployment wrote — the platform's
own first role, granted through `cmd/staff`, which is the only door that exists before there is an
operator to open the console with — has been read back on the History screen against the live
database. The condition asked for an action, a name and somewhere to see it, and all three are
there.*

*What is left is the phase's own `Done when`, which asks for **two** schools answering over TLS
and has one. That is not an oversight in the list: a single school with a `Host` check is
indistinguishable from an application that is not multi-tenant at all, and the second school is
what tells the two apart. It needs no code — a tenant row, a `tenant_domains` row, a Cloud Run
mapping and a DNS record, all of them already written down as a runbook in
[`infra/README.md`](../infra/README.md). **The list being finished is not the phase being
finished**, and the gap is left visible here rather than closed by redefining the condition.*

---

## 0 — Skeleton, and the five that cannot wait

*Done when: two schools answer over TLS, and the first administrative action shows up in the
audit with a name against it.*

### The five

- [x] Events carry their dimensions denormalised — plan, school, country, locale, copied at emission
- [x] `practice_review` exists and is append-only, before any practice screen does
- [x] Every administrative write records the actor — the audit path refuses an entry without one, and it is the only path there is. **And the read side is a screen now**, which is what the phase's `Done when` asks to see: `Govern → History`, newest first, with one entry opened on its own address. It answers exactly three questions — everything, one actor's entries, everything done to one subject — and **refuses the fourth by name**: a free-text search, a date range and an action filter come back saying there is no index behind them rather than reading the whole table (K-21). Paging is a keyset with an `(occurred_at, id)` tiebreaker and never `OFFSET`, because two entries written in the same microsecond are the ordinary case on an append-only table read newest first, and an offset silently drops or repeats one at every page boundary. Both were proved by breaking them: the tiebreaker removed, and a filter allowed through
- [x] Every table holding personal data is reachable by the export and the erase path, with a test that fails on a table nobody classified
- [x] A visitor has an identity before the account exists, and signup links the two

### Shape

- [x] Monorepo, with CI filtered by path — a `Changes` job diffs the pull request and answers which suites it can reach, and each suite carries an `if`. **`if` on the job and not `paths:` on the workflow**, because a skipped job reports as skipped and a required check accepts that, while a workflow filtered by `paths:` never reports at all and a required check that never reports blocks the merge forever. **And it fails open**: a push, a release, a diff that cannot be computed and an empty one all run everything. `docs.yml` is deliberately unfiltered, because its input is the whole tree — the file that breaks a relative link is usually not the `.md` holding it
- [x] School resolved by the full `Host`; an unknown host is a 404 and never falls into a default school
- [x] Reserved subdomains refused at creation — `www`, `api`, `admin`, `app`, `auth`, `cdn`, `mail`, `static`, `status`, `docs` — by a database constraint as well as by the application, with a test that proves the two agree
- [x] One Go binary serving the API and the embedded frontend on one origin
- [x] A domain mapping per school — `tenant_domains`, one row per host, read on every request to decide which school is answering; a host nobody mapped is a 404 and never falls into a default. **Found unticked while it was done**, which is the same failure as a false tick read the other way round: what is missing is a bought domain and its DNS, not a mapping
- [x] `tenant_id` on every school-scoped table, with an index leading with it, and every index that crosses schools declared with its reason
- [x] The module dependency graph enforced by a test

### Identity and access

- [x] One account for the whole platform; session cookie on the parent domain, `HttpOnly`, storing the token's hash and never the token
- [x] Staff roles — owner, operator, read-only, as a row on an account rather than a second account. *Invitations wait on e-mail, which waits on the domain.*
- [x] Mandatory MFA for staff, enforced on the session rather than on the account, and revoking a role ends every session that held it — **and it can now be enrolled from a screen, with recovery codes, which is the difference between a factor and a lockout.** Every part of it had a test against a real Postgres and every one of them passed while the interface refused with "this school does not have multi-factor sign-in yet": the first factor on this platform was enrolled by hand from a browser console, which is the shape of a claim that was never round-tripped. `#/account` now offers it, shows the secret to type in, takes the code back and hands over ten single-use codes once — and `tools/mfa-test` signs up, enrols, signs out through the screen's own button and signs in twice, once with the app and once with a code, then checks the code was spent. Enrolment also **refuses to replace a factor that already exists** unless the session presented one, because an attacker holding a stolen cookie could otherwise enrol their own and lock the owner out; that one was found by reading the code rather than by a test failing, and the test came after
- [x] Personal-data export and erasure, **reachable from the console** — the export and the erase were already held by four tests (every table that reaches a student is covered, a password hash and an answer key are never carried, and erasure severs the person while leaving the statistics); what was missing was the screen, and it is at `console.<platform domain>` under `Govern`. A person is found by a **whole address and never listed** (K-22), what is held comes back as **counts and never rows** — because reading the rows *is* the export, and the export is audited — and the erasure asks for `operator`, the person's own address typed back, and refuses if the audit entry cannot be written first. **The audit entry carries counts and does not name the person**, so an append-only table cannot become the last surviving copy of somebody who asked to be forgotten. Three of the ten tests were checked by breaking what they hold: the role check disabled, the record moved after the erasure, and raw rows passed to the audit instead of counts

### Operations

- [x] Migration as a job with an advisory lock, run before traffic reaches the new revision
- [x] Terraform owns the project services, registry, service accounts, IAM, Cloud SQL, secret *containers*, the identity federation and the alert policies — `infra/`, applied against `aleogr-schooling`, and `terraform plan` says `No changes`
- [x] The deploy pipeline owns which revision runs; Terraform never manages the image — a tag builds three images, runs the migration to completion, loads the catalogue, replaces the revision, and then **asks the running service which release it is**. `lifecycle { ignore_changes }` on the image is what stops the two from arguing
- [x] Semantic version in one place — the tag — with the release workflow refusing a tag that is malformed, does not increase, or is not on main
- [x] `/api/v1/` from the very first route
- [x] Uptime check and alert policy reaching a phone — `/readyz` probed every five minutes against a school's own host, alerting after more than one failed probe sustained for ten minutes. **Delivery is proven rather than assumed**, because the policy went off by accident: `COMPARISON_LT` against a reducer that counts *failures* reads "fewer than one failure", so it fired fourteen minutes after creation on a service answering 200. The mail arrived. Whether the address reaches a phone is the address's job and not this repository's; the channel is e-mail
- [x] A backup **restored** — to a cloned instance, verified, then destroyed. Never over the live one. No staging environment. `tools/restore-drill/restore-drill.sh`, run against `aleogr-schooling`: 663 lines identical across 42 tables, 6648 rows, 24 migrations, the school and both its hosts, and the clone deleted at the end. Live is read first in one `REPEATABLE READ` snapshot and the clone is restored to that same instant, which is what keeps *identical* the verdict now that visitors arrive between one reading and the next

---

## 1 — The study platform

*Done when: a student walks a whole track of `code` on the new platform.*

### The catalogue

- [x] `content/` holds prose in Markdown, structure and exercises in JSON, and a course's pictures in its `images/` — a picture no question labels fails the build, exactly as an orphaned `.md` does
- [x] The validator runs in CI — broken prerequisites, cycles, track order, `requires` that no track containing the course satisfies, checked **per branch** of every fork
- [x] The load job writes the mirror from the files and prunes what the files no longer carry, in one transaction, and writes nothing at all if the catalogue does not pass
- [x] Nothing else writes catalogue rows; the console reads and never writes — enforced by a test that scans the source
- [x] Draft and published state per course
- [x] **An opaque id that never derives from a title, and a readable slug beside it where a thing is addressed** — `co-cbwm5kwa` is what a progress row, a note and an exam answer point at; `statistics` is what the URL carries and a reviewer reads, and it is free to be rewritten. `content/` refers to everything by slug and `cmd/load` is the one translator. Order declared, never inferred from filenames
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
- [x] Drilling on a screen — one card at a time, drawn without its answer, marked by the server, the key revealed over what the student gave once it is in, and the day it comes back said out loud. **This is the item the preamble is about**: ticked weeks before the screen could draw a card, and unticked until it could
- [x] ~~The modal test — every course, one height, neither column scrolling~~ — **there is no modal here.** The predecessor showed a course in one, on a marketing page; a course is a screen of its own in this interface, so the test has no subject. Its actual concern — a layout that holds for every course — is covered by the accessibility pass, which opens the course and lesson screens, and by the graph test, which measures a real drawing rather than trusting one
- [x] Portuguese and English, with the interface-string checker — which fails on a missing translation **and** on one nothing says any more
- [x] WCAG 2.2 AA on every screen, with an automated check in the browser suites — axe over seventy-four screens, both themes, signed out and signed in, the exam paper walked question by question, and the console on its own host with an operator the suite makes for itself. **A state it can only reach by luck is a failure and not a skip**: the drill's two verdicts used to be whichever the shuffle produced, so a contrast defect on one of them was reported about one run in three and passed the rest of the time. Both are now asked for by name, arranged through the interface's own controls, and confirmed against the verdict the server returned
- [x] Every question type operable by keyboard and legible to a screen reader — `ordering` on buttons, `matching` on a select, and `labelling` by choosing a label and then placing it with a click **or the arrow keys**, its position said in words ("63% across, 41% down") so somebody who cannot see the diagram can still be told where they put a thing and move it
- [x] The offline bundle, built **and opened** in CI — one file, one school; opened from `file://` it reads the whole catalogue and asks nobody for anything, served from the school's origin it is the application again; signing in, progress and exams are refused with a sentence rather than a form that does nothing

### Assessment

- [ ] The ten types: `quiz`, `multiple-choice`, `ordering`, `matching`, `cloze`, `numeric`, `labelling`, `expression-answer` **done — eight graders, each with a conformance fixture**; `code` and `expected-output` need a sandbox that runs a student's program, which is why they are absent from `graders` rather than stubbed
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

*The first half is demonstrable now, and getting there found the machinery unable to do it. The
discrimination index ranked attempts by their WHOLE paper mark, which ranks them partly by the
question being measured — a bias that is positive for every question, harmless on a good one and
fatal on an inverted one, because the item's own contribution cancels its correlation with the
rest. On a six-question paper a deliberately backwards key scored +0.03 and was reported `weak`;
it only reached `inverted` at twenty-four questions. Every exam this platform sets is in the range
where the number was wrong. The groups are ranked by the REST of the paper now — the classical
correction, which exists for exactly this reason — and the same population gives between −0.25 and
−0.35 at every length, with the good questions between +0.39 and +0.55.*

*It was found by building the seeder and asking it to plant a broken key, which is the argument for
seeding a population rather than waiting for one: the failure this phase is `Done when` it can
catch was one the code could not catch, and nothing in the system said so.*

### Understanding

- [ ] Cohorts, by signup and by subscription start — **the first is built and the second cannot be, so this box stays open on the half that is missing** rather than being ticked on the half that is done. That is the seeder's rule three items down, applied to the same shape of gap.

  Grouping by subscription start means grouping by a moment nothing records: nothing writes a subscription into the stream, because there is no payment gateway. It is the same absence as the funnel's last step and the screen reports it the same way — a sentence saying so, not an empty table that reads as "nobody ever subscribed".

  **What counts as ACTIVE is the whole report**, so it is a constant with the argument beside it and it travels to the screen with the numbers: `section.completed`. Opening a page is a click and a retention curve built on clicks flatters itself; finishing a course is rare enough that the table would be noise. The interface holds no copy of it, for the reason it holds no copy of a threshold.

  The reader is SEPARATE from the funnel's rather than a wider version of it. `Reached` is `SELECT DISTINCT name, visitor_id, account_id`, and that DISTINCT is what makes a funnel cheap — forty lessons opened collapse before they reach Go. A timestamp on it would collapse nothing, so `Monthly` collapses again at the grain a cohort needs: one row per identity per month, `AT TIME ZONE 'UTC'` explicitly, because `date_trunc` otherwise follows a session setting and a cohort boundary that moves with a connection parameter is somebody landing in a different intake depending on which server asked.

  **Its tests need no database, and that is what found the defect.** `Cohorts` never touches the pool, so the store takes a nil one and the folding is checked on every machine rather than only in CI. Three of the nine failed at once: a row's width came from the newest INTAKE rather than from the calendar, so a school whose last signup was in March would have shown every cohort one month wide — every later month of retention missing, and nothing on the screen to say so. Had those tests wanted Postgres they would have skipped and it would have shipped
- [x] The funnel, all eight steps from *arrived* to *subscribed* — **counted per PERSON, which is the only hard part.** The top is browsers and the bottom is accounts, so counting each step by whichever identity its event happened to carry would make somebody who arrived on Monday and subscribed on Friday two people, and the conversion rate a ratio between different populations. A person is an account where the identity is linked to one and the visitor otherwise, which is what `account_visitors` is for and why the visitor has an identity before the account exists (K-10). One person on two browsers is one person; forty lessons opened is one lesson step.

  Six steps are emitted. The two that are not — verifying an address, subscribing — come back saying **no event exists yet** rather than zero. A zero reads as everybody dropping out there, which is the same mistake as a discrimination index of zero that was never measured. `Measured` is a field of its own so a screen cannot show the two alike

  **And it is on a screen now**, which is the first entry in `Measure` — a rail group that had a name and no sections. It was computed nightly and printed into a log for as long as it existed, with a comment admitting why: there was no console to put it on. The unmeasured steps get no bar at all rather than a bar of length zero, which is the same distinction one layer up
- [x] Item analysis on a screen — the other half of this phase's `Done when`, and **every number that is a judgement carries the threshold it was judged against**. None of those six numbers is written in the interface: they arrive on the answer from the package that applied them, because a copy in a screen keeps saying what a bar used to be the day the constant moves.

  Two things it refuses to infer. Whether a question is **out of circulation** is read rather than derived from the verdict — the sweep runs nightly, so a question found this afternoon is flagged AND in front of students tonight, and one released by hand is in circulation carrying the verdict it was condemned on. And **when the rollup was made**, which is the failure nobody sees: these rows are a cache of a job, and if it has been failing for a week every number looks exactly like this morning's. A job that never ran gets its own screen rather than an empty table, because an empty table says "nothing here is wrong" and nothing checked

### Watching

- [ ] World map with per-country statistics, from an in-process GeoIP database
- [ ] The country stored on the event; the address never stored
- [ ] Presence via `last_seen_at`, written at most once a minute per session
- [ ] Failed job queue, with retry
- [ ] Email deliverability — bounces and complaints

### Operating

- [ ] View-as-student: audited, time-limited, with a visible banner
- [x] Student record — plan, subscription, progress, exams, certificates, sessions — **one request, and a section per school, because an account crosses every school and almost nothing else does** (K-18). Two schools' progress added together is a number about nobody, so the answer is a person and then a section per school they have anything in; a school they have never touched is left out, because four empty tables bury the answer in the part that says nothing. It is `billing`, `progress`, `exam` and `certificate` at once and imports none of them — ONE function type, joined where those modules already meet, rather than four the caller would only ever wire together. A sitting says how many and since when and **never carries anything that would let an operator become the person**, held by a test that reads the response for the words. It is not an export either: counts, states, dates and titles, never a note somebody wrote or an answer they gave — reading *that* is the export, and the export is audited. What it costs is said out loud in the file: one query set per school, which grows with schools rather than with students, and the honest moment to reshape it is when a fiftieth school exists
- [ ] Reported-content queue, fed by the student
- [ ] The closed list of system parameters, each change audited with actor, old and new value — **the first parameter exists and the list does not.** A school's accent is set from `Operate → Schools`, recorded with the actor, the colour that was there and the colour that replaced it, and refused for a role below operator. The audit seam grew to make that possible: it carried one value and a bare account id, so every entry the console wrote said "account" and put whatever it had in `before`; it now names the SUBJECT'S KIND and both sides of the change.

  The screen shows what the colour BECOMES rather than what was typed, in both themes, using the study interface's own correction module — which moved to `assets/` so that it is served to the console as well and does not exist twice. A colour that had to move says so, and so does a hue where a finished course and an available one come out the same. `school.json` carried an `accent` that nothing read; it is gone, because the catalogue is rewritten by every load and a colour there would be undone by the next publish
- [ ] Prices effective-dated — a subscriber keeps the price they bought at
- [x] Every threshold displayed beside the number it produced — **both of them do now.** All six of that screen's bars come from `analysis`'s own constants, on the answer, so the screen cannot hold a stale copy of a decision. `item_statistics` stores `minimum_sample` on the row for the same reason one level down: a verdict computed under a minimum of thirty and displayed beside a constant that now says fifty is a row explaining itself with the wrong number.

  The pass mark was the one that did not, and it was found writing this line. The server applied `exam.PassMark`, stored it on the attempt and sent it as `pass_mark`; `ui/app/exams.js` declared `PASS_MARK = 70` of its own and showed THAT, twice. The number travels by two routes now, because the screens need it at two moments: a PAPER carries it — and a handed-in one carries the mark it was JUDGED by, off its own row, so a result is never explained by a rule nobody applied to it — and a SCHOOL carries it, because the course card says "minimum to pass" before any paper exists. What survives in the interface is an unexported offline default for the single-file bundle, which normally gets the real one anyway
- [ ] Synthetic students flagged, excluded from every aggregate by default, with a visible switch and a banner when included — **the flag is now a dimension on the event, which is the half that could not be added later.** `accounts.synthetic` had existed since phase 0 and never reached the stream, so item analysis and the funnel had no way to tell a seeded student from a real one; joining to `accounts` would have failed twice over, because half the funnel is visitors with no account and because erasing a person would retroactively turn their events from real to unknown. Both reads now exclude synthetic by default, **and can be told to look**: `event.Counting` is a word with three values, anything it does not recognise falls back to `real`, and `cmd/analyse` is deliberately fixed on `real` with no flag — that job withdraws a flagged question from circulation, so pointed at seeded answers it would remove real questions from real courses. What may read the seeded population is something that reports and says so.

  **The switch and the banner exist now**, on the funnel, which is the only read in the platform that offers the choice. Two things make it a control rather than a decoration: the word travels to the reader AND comes back on the answer, so a chart of real people cannot be drawn under a heading naming another population; and a word the API does not know is **refused** rather than corrected, because the SQL answers `everbody` with real people — right for SQL, and exactly that failure on a screen. The item analysis has no switch and says why: it shows what the nightly job wrote, and that job withdraws questions from circulation
- [ ] A seeder that generates **history** — months of backdated events, with abandonment, returns, duplicate signups and refunds. **Three of the four exist**: `cmd/seed` writes a past into the event stream, which is the only thing it backdates, because statistics come from the stream and never from current state. A refund is not representable there today — nothing emits a subscription event into the stream, which is also why the funnel's last step comes back saying it is not measured — so this box stays open on the one behaviour that is missing rather than being ticked on the three that are.

  Two things it will not do, written down where the next person will look for them. It touches **no subscription, transition or ledger row**: their timestamps are not settable and must not become settable, because a fabricated row in those three is indistinguishable from one a payment produced. And it cannot be undone — `events` is append-only by trigger, so there is no `--clean` and there cannot be one, which is why it refuses a population too small for item analysis to say anything about BEFORE writing it.

  It also checks itself: one exam question is seeded with an inverted key, and the run fails if `analysis` does not call it inverted. Against the fixture's eight-question exam the planted one comes back at −0.32 and the seven others between +0.05 and +0.24

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
