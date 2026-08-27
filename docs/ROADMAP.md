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

***Phase 0 is finished**, and it finished last — every box in it was ticked for weeks while the
phase was not, because its `Done when` asked for something no box contained.*

*The screen was the last box, and it went the same way as the infrastructure items: the tick came
after an operator had found a person, exported them and erased them against a real database, and
after the two audit entries had been read back and checked for what they must not contain. Its
last two defects were found by looking at a screenshot and by nothing else — a stylesheet asking
for a typeface the page never linked, and a table that said "18 table".*

*The `Done when` asks two things. The first is that the first administrative action show up in the
audit with a name against it, and it was met earlier: the first one a released deployment wrote —
the platform's own first role, granted through `cmd/staff`, which is the only door that exists
before there is an operator to open the console with — has been read back on the History screen
against the live database. The condition asked for an action, a name and somewhere to see it, and
all three are there.*

*The second is met now: **two schools answer over TLS.** `math.<platform domain>` — Mathematics,
violet, and deliberately empty — was created beside `code` and both were asked the same
school-scoped route at the same moment. One binary, one revision, two different answers, chosen by
nothing but the `Host`:*

```
math: {"slug":"math","name":"Mathematics","accent":"#8b5cf6","passMark":70}
code: {"slug":"code","name":"Programming","accent":"#2f6bff","passMark":70}
```

*That condition was not decoration, and it proved it on the way in. A single school with a `Host`
check is indistinguishable from an application that is not multi-tenant at all — and **the second
school found two defects the first could not.** `tenant_domains` turned out to hold the service's
own `run.app` URL against `code`, an address where the catalogue reads and signing in silently
cannot: the session cookie is set on the parent domain, so a browser at a `run.app` host rejects
it and the form appears to work. And `HostOf`, which builds the link an operator follows to view as
a student, sorted a school's addresses ALPHABETICALLY while the paragraph beside it had always said
the oldest — a difference that only exists once a school has two, and that would have handed an
operator a raw Cloud Run URL for any school sorting after `schooling-…`.*

*Neither was findable with one school. **The list being finished was not the phase being finished**,
and the gap was left visible here rather than closed by redefining the condition — which is what
gave the condition the chance to earn its keep.*

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

***Phase 2 is finished.** Both halves of the `Done when` are held by tests against a real
Postgres rather than by this paragraph: `(x+1)^2` is accepted against an expanded key by the
sampling grader, and `TestAnAnsweredCardLeavesTheQueueAndComesBackWhenItIsDue` is the second
sentence with a name. The last box was the queue that crosses schools, and it closed the way
the phase-0 condition did — by being left visible until it was true rather than redefined.*

- [x] `expression-answer` graded by a computer algebra system — **by sampling rather than by rearranging symbols.** Two expressions over the reals are the same if they agree everywhere, and everywhere can be sampled: a parser for school algebra (implicit multiplication included, because that is how people write it), then both sides evaluated at two dozen chosen points. It cannot simplify or factor and does not need to — the question is always "are these equal", never "what is this" — and what it cannot see is a difference at a single point, written down in the package and pinned by a test
- [x] `numeric` — a number with a unit and a tolerance
- [x] `cloze` — a blank with accepted answers and normalisation
- [x] `labelling` — a label on a point of an image, in fractions of it rather than pixels
- [x] All four in the conformance fixtures — `numeric`, `cloze`, `labelling` and now `expression-answer`, whose fixture carries the two verdicts that matter either way: `(x+1)^2` accepted against an expanded key, and a typo returned as a bad answer rather than a wrong one
- [x] `drillable` on exercises — checked rather than trusted, so an exam-only question cannot be drilled into telling a student what is on the paper
- [x] `practice_state` — strength, due date, lapses; overwritten in place beside the append-only log it can be recomputed from
- [x] SM-2, with the quality score derived from correctness and time rather than asked — the thresholds are a first guess, and `practice_review` carries the before-values so they can be fitted rather than argued about
- [x] A review queue that crosses schools, scoped by what the subscription covers — **`my.<platform domain>`, and it was a second entry point over the same rows exactly as this line predicted.** No second scheduler, no second table: the schedule, the SM-2 state and the answering are what they were, and this reads across them.

  THE BLOCKER TURNED OUT TO BE ONE HOSTNAME AND ONE ROUTE. A request arrives at a school's host and is scoped to that school before any module sees it, which is what makes every query in this platform safe to write — so crossing schools had to be a second ADDRESS rather than a flag on a route, and adding "…or all of them" to the existing queue would have put two meanings behind one door. And it needed no new sign-in: the session cookie has been on the parent domain since it existed, precisely so one login covers every school (N-01), so `my.` is a sibling of `code.` and a student signed in at their school is signed in here.

  **The gates are the same gates.** Naming a school at that address grants nothing — the paywall is asked per course with that school on the context, exactly as at the school's own host, and the quarantine is asked per school because a withdrawn question is a fact about one school's catalogue. The door cache is keyed on school AND course, and that is the one real hazard here: two schools may hold a course with one id, and a shared key would let the first school's paywall answer for the second's. It is the test a single-school suite cannot write.

  WHAT IS IN IT IS WHAT IS DUE AND NOT WHAT IS NEW. A school's own queue offers both, so it is never empty for somebody who finished today's; four schools' worth of never-answered questions interleaved by nothing is a catalogue with a timer on it. That also settles which schools are in scope with no rule about it — a card is there because the student has a schedule for it, so the schools that appear are the ones they are actually in rather than every school offering its free first course.

  **The screen is its own interface** (`ui/my/`), and the alternative was traced rather than assumed: serving the study interface's shell there does not crash, because its three school-scoped fetches each carry a `.catch`. It renders, the brand paint is guarded and never runs, and the markup's default stands — `codeschool.ing`, the predecessor's name, over an empty school, looking deliberate. A second mode would have put "and with no school?" into every screen written from then on, with exactly that silent failure. It shares `assets/base.css` byte for byte and has its own dictionary, checked by a second invocation of a tool that already took a directory. The cards are counted there and answered at their school, where the catalogue that explains them lives
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

- [x] The country stored on the event; the address never stored — **one package reads the caller's address and a test holds the rest of the repository to never doing it.** `platform/geo` is that package; `internal/address_test.go` parses every Go file in the tree and fails on a second reader of `X-Forwarded-For` or `RemoteAddr`. It caught its own author's sign-up test on the first run, and the fix was to EXPORT `geo.HeaderForwardedFor` so the test could name the header without the rule having an exception in it — a rule with one exception is a rule nobody can cite.

  **Which end of the trail is the whole security question.** `X-Forwarded-For` accumulates left to right and the caller writes the left end, so reading the first entry is reading a string the visitor chose. It takes `trail[len(trail)-Hops]` instead, counted from the right, with `Hops` configured to the number of proxies actually in front of this service — and a forged header is in the tests, proving the invented country never lands. `Hops <= 0` reads `RemoteAddr` and raises no alarm, because that is a laptop with nothing in front of it and not a misconfiguration.

  **And the alarm never carries the address.** It says the reason, how many hops were configured and how many entries it saw — enough to fix a proxy count, and nothing that survives in a log for the retention period. The point of not storing an address is lost the first time it is written into a warning instead of a column.

  It resolves in process from a DB-IP Lite database compiled into the binary (`//go:embed`, CC BY 4.0, attributed in `dbip/LICENCE.md`), so there is no request to anybody's API on the request path, no key, no subscription and no third party learning who visits. A test fails when the file is more than a year old, because the silent failure mode of an embedded database is not being wrong — it is being quietly out of date while looking exactly like this
- [x] World map with per-country statistics, from an in-process GeoIP database — **it counts people the way the funnel counts them, through the same `personOf`.** A map counting identities beside a funnel counting people would put two different totals on two screens of one console, both correct by their own definition and neither reconcilable, which is worse than one of them being wrong because there is nothing to fix.

  **A person seen in two countries is in both, and the total says so.** Somebody who studies at home and again on a trip appears twice, so the countries add up to MORE than the number of people. That is what the number means rather than a rounding error to hide, so the honest figure travels beside the rows instead of being computed from them — the same rule as a threshold travelling with the number it produced (`K-16`). `unknown` is a country on the list for the same reason: it is where everything behind a VPN keeps coming from, and dropping it would make the map look complete and every percentage on it a lie.

  The map itself is vector and ours: `tools/world` turns Natural Earth's 110m boundaries into 174 SVG paths, equirectangular rather than Mercator so nobody plans around a Greenland the size of Africa, with Antarctica dropped because no student is there. No CDN, no map library, no tiles fetched from somebody who would then know who is looking.

  **The defect it shipped with was invisible by construction.** The seeder wrote `BR` and `platform/geo` writes `br`, so one country was two rows — one drawn on the map with a flag and a name, one a bare code in the list beside it — and nothing failed anywhere, because both spellings are valid. It is folded in the reader rather than repaired in a migration: a migration cleans what exists once, and the column will have another writer
- [x] Presence via `last_seen_at`, written at most once a minute per session — **the column existed and answered a different question.** It had been advanced at most once an HOUR since phase 0, which is right for "is this session still in use", asked of a person's own list of sittings, and cannot answer "is somebody here now": a timestamp allowed to be fifty-nine minutes stale reports an empty platform at its busiest, confidently. It is a minute now, and it is still not a write per request — the rate limit is a clause of the query that authenticates, so it holds across every instance rather than once per instance and costs no round trip.

  A session also records WHICH SCHOOL it was last used on, because a platform-wide count is a number about nobody. The column is not called `tenant_id` on purpose: `sessions` is platform-wide (K-18) and an account has no school at all (N-01), so that name would put the table in the school-scoped set `tenant/schema_test.go` reads out of the catalogue. A host that is no school's passes nothing and nothing erases nothing — somebody who reads the landing page between two lessons must not vanish from the school they are studying in, and a console left open all day must not put its own operators into one.

  It counts PEOPLE and it does not LIST them. Distinct over accounts, so a laptop and a phone are one person, and the platform figure is distinct again rather than the sum — those two legitimately disagree and the screen says so. There is no field on the answer that can carry a name: K-22 is that a person is found by an exact address and never listed, and "who is online" is the most natural place for that to break by somebody being helpful. Three exclusions each of which would otherwise be a plausible number: a signed-out session keeps its timestamp and is excluded explicitly, an operator viewing a student is not the student being here, and a seeded student is excluded with no switch beside it — the seeder never signs anybody in, and a control whose two settings draw the same picture teaches people not to trust the others
- [x] Failed job queue, with retry — **every attempt is a row, and an operator can start one by hand.**

  The prerequisite was the discovery: `cmd/analyse` has opened by saying it runs on a schedule since it was written, and there was no Cloud Run job for it and no scheduler anywhere in `infra/`. It had never run in production once, so the rollup the console reads had never been written and the sweep that WITHDRAWS a question the strong students fail had never withdrawn one — every such question stayed in front of students, and every student who met it was marked on our mistake.

  The console's item analysis is the reason this was findable. It draws "no rollup has been made" as its own screen rather than an empty table, and an empty table would have read as a platform whose questions are all fine. It is now a job, a scheduler at 03:10 São Paulo time, and a third service account that may start that one job and read nothing.

  **And every attempt is a row now**, written BEFORE the work and closed after it. That order is the whole design: recording only on the way out captures every outcome except the one with no other trace — a job killed, out of memory, or with its instance withdrawn writes nothing at the end, and the table would say the last run was the night before, which is exactly the lie `computed_at` already tells. A run that vanished leaves a row still saying `running`, and after an hour the reader calls it ADRIFT rather than busy. Nothing sweeps it: a janitor would need something to run it, and a row rewritten by one stops being what the job itself last said.

  `computed_at` SAYS WHEN THE WORK LAST SUCCEEDED and this says when it was last ATTEMPTED. Three situations look identical through the first — failed at 03:10, disabled in March, ran perfectly and found nothing to change — and the third is why a stale timestamp cannot be an alarm.

  **The retry was the last half, and the reason it stayed open was true rather than an excuse**: starting a job means the console holding the right to run one, which is an identity and a network path it did not have. It has both now — `roles/run.invoker` ON THE JOB rather than on the project, and a token the instance mints for itself from the metadata server, so there is no key and nothing configured. A process on Cloud Run already knows its project and its region, and the copy in an environment variable is the one that goes stale when a service moves.

  WHAT MAY BE STARTED IS A CLOSED LIST OF ONE. The migration and the catalogue load are in the same project behind the same permission, one path parameter away, and passed through this route would be a general-purpose Cloud Run trigger wearing a console's clothes. The list is checked before Google is asked anything and the IAM grant is the second fence rather than the first.

  Four refusals, and the interesting one is which is NOT a refusal. Rank, then the list, then whether this deployment can start a job at all — every laptop and CI cannot, and the screen draws no button rather than one that always fails — then whether one is already running, because two analyses are two sweeps and a sweep withdraws a question. **An ADRIFT run does not block a start**: adrift is what a killed job leaves behind, nothing rewrites it, and treating it as busy would make a job unstartable until somebody edited the database, which is the opposite of what the button is for.

  A run started by hand is **indistinguishable in `job_runs`**, deliberately: the scheduler makes the identical call and the job cannot know who asked. Who started one lives in the audit, which is the only place it can, and the entry carries the state the job was in when somebody reacted to it. Alerts stay out of the console either way (K-08): they have to reach a phone when the console is down, which is when they are needed
- [ ] Email deliverability — bounces and complaints

### Operating

- [x] View-as-student: audited, time-limited, with a visible banner — **the three restraints shipped together or not at all (K-02), and a fourth was added on the way.** A viewing CANNOT WRITE: `identity.RefuseWrites` refuses it anything but a GET, because an operator who can answer an exam question as a student can forge a pass and an audit trail explains that afterwards rather than preventing it. That is not in K-02 and it should be.

  It is a SESSION ROW and not a table of its own, because it IS a session: every property a viewing needs — an expiry, a revocation, a last-seen — is already on `sessions` and already respected by the one place that verifies a token. A parallel table would be a second thing to expire and a second thing to forget to revoke. It travels in a second cookie, host-only on the school being looked at, and `viewing_tenant` says the same thing where a copied cookie cannot argue with it.

  Two things were found building it. A viewing is NEVER asked for a second factor — the operator does not have the student's phone, and a viewing that stopped at a code prompt would be a feature that never works for exactly the accounts most worth looking at. And the handoff link was hard-coded to `https`, which is right in production and nowhere else; it reads `X-Forwarded-Proto` first, because Cloud Run terminates TLS and `r.TLS` is nil on every production request there is
- [x] Student record — plan, subscription, progress, exams, certificates, sessions — **one request, and a section per school, because an account crosses every school and almost nothing else does** (K-18). Two schools' progress added together is a number about nobody, so the answer is a person and then a section per school they have anything in; a school they have never touched is left out, because four empty tables bury the answer in the part that says nothing. It is `billing`, `progress`, `exam` and `certificate` at once and imports none of them — ONE function type, joined where those modules already meet, rather than four the caller would only ever wire together. A sitting says how many and since when and **never carries anything that would let an operator become the person**, held by a test that reads the response for the words. It is not an export either: counts, states, dates and titles, never a note somebody wrote or an answer they gave — reading *that* is the export, and the export is audited. What it costs is said out loud in the file: one query set per school, which grows with schools rather than with students, and the honest moment to reshape it is when a fiftieth school exists
- [x] Reported-content queue, fed by the student — **a section or a question, and the exam is the one place it does not appear.** That last part is the decision the first half deferred: the exercise card is drawn by one renderer shared by the assessment, the drill and the exam, and a control there would open a form in the middle of a timed paper. A student loses minutes they are being measured on, and the thing they are most likely to want to report during an exam — "the answer I gave was right" — is a verdict they have not been shown yet. The same question is reportable from the drill and from the assessment it belongs to, with nothing at stake.

  **A question sends one field and the server finds the rest.** A drilled card comes out of a queue that spans courses and carries no path, so asking the browser where the exercise lives would be asking it to tell us something we hold — and a stale tab would file against a section the question has since left. The version comes from the catalogue for the same reason: a key fixed last week and a report from last month are about different questions with one id.

  Two things the schema had to learn. The unique index now includes the exercise — keyed on the section alone, the SECOND bad question a student found in one assessment would have read as a duplicate of the first, silently, with a message thanking them for something they had already said. And `lesson_id` and `section_id` stopped being non-empty: `catalog_exercises` places almost every exercise and not every one, and refusing the rest would close this channel for exactly the questions a student meets most often. A blank is honest — the queue shows the question and a hyphen where the path would be.

  Two closed lists rather than free text on either side — five reasons and three verdicts, in Go where a test holds them, travelling to their screens on the answer. A queue whose categories are prose is one where a wrong answer key and a broken video arrive looking alike; a report closed with no word for what was found is what teaches people that closing one means nothing. **One open report per person per section**, as a partial unique index: not a rate limit but what makes the control idempotent, and the second call reads the first row back WITHOUT overwriting the note, because what somebody wrote when they first noticed is the report.

  The queue names nobody (K-22) and the row goes when the person does — `note` is a sentence in their own words, so the table cascades on erasure. That makes the record-before-you-act rule STRONGER here than elsewhere rather than the same: the audit entry is the only lasting record that a section was ever complained about
- [x] The closed list of system parameters, each change audited with actor, old and new value — **and the list is in Go with a test on it, because the obvious build was the wrong one.** A school's accent is set from `Operate → Schools`, recorded with the actor, the colour that was there and the colour that replaced it, and refused for a role below operator. The audit seam grew to make that possible: it carried one value and a bare account id, so every entry the console wrote said "account" and put whatever it had in `before`; it now names the SUBJECT'S KIND and both sides of the change.

  The screen shows what the colour BECOMES rather than what was typed, in both themes, using the study interface's own correction module — which moved to `assets/` so that it is served to the console as well and does not exist twice. A colour that had to move says so, and so does a hue where a finished course and an available one come out the same. `school.json` carried an `accent` that nothing read; it is gone, because the catalogue is rewritten by every load and a colour there would be undone by the next publish.

  **The second is the price**, on the same screen, and it behaves differently on purpose — a colour is replaced and a price is appended (K-14, above). Two settings on one school that do not behave alike is exactly the thing an operator will assume wrongly, so the screen says which is which rather than leaving it to be discovered.

  WHAT DID NOT HAPPEN IS A PARAMETER REGISTRY. A `system_parameters` table — a name, a value, a screen that edits any row — is the shape that suggests itself and precisely the configuration surface K-13 exists to refuse: it grows to fill the space it is given, and the next value somebody wants to make settable costs one INSERT and no argument.

  So `internal/console/writes.go` is the list, and what it closes is not the set of values a table may hold but **the set of things this console can do at all**. Every write route in the package is declared there with its kind and its reason, and a test reads the source in both directions: an undeclared route fails, and so does an entry for a route that is no longer registered — a stale exception reads as current, which is the same rule the tenancy exceptions and the dictionaries follow.

  TWO KINDS, BECAUSE THEY ARE NOT THE SAME QUESTION. A PARAMETER persists — set it and the platform behaves differently until somebody sets it back — and is what K-13 is about; an ACTION happens once and leaves no dial at a new position. Erasing a person, starting a viewing and settling a report are actions, and they are on the list anyway: a list of what a console can change that omitted them would answer "what can this console do" wrongly, which is the question a person actually asks of it.

  **The cost of adding one is the whole mechanism.** A new write fails the test until somebody writes its sentence, and writing that sentence for a parameter means arguing that the value has no right answer — because if it has one it belongs in code where a test holds it. The count of parameters is itself asserted, so a third is a deliberate line in a diff rather than a drift.

  What is NOT on the list, deliberately: `cmd/staff` granting a role. It is a change to the system, audited, and it is not something the console does — a role is granted from a terminal precisely because the first one could not be granted through a console that needs a role to open
- [x] Prices effective-dated — a subscriber keeps the price they bought at. **Both halves now: the offer is a series, and the subscription points at a row of it.** `tenants.plan_price_cents` was a column that could be overwritten, which reads as harmless and is the one shape a money parameter may not have: the moment it changed, "why was this person charged 490 when the site says 590" stopped being answerable. `ledger_entries` has been append-only since it existed, so what somebody PAID was already unforgeable; this was the other half of that sentence and it was the editable half.

  `subscriptions.price_id` is the half that closes it, and it is NOT NULL — which was only possible on the day it was added. Nothing creates a subscription yet: there is no gateway, the seeder writes none, and `billing.Begin` had no caller outside its own tests. A year from now the choice would have been a nullable column half the code checks, or a backfilled guess about what somebody was charged — the one guess this schema exists to prevent. So the migration REFUSES rather than backfills: a `DO` block raises if the table has rows, and says what to decide.

  WHICH ROW, given that one subscription covers every school (N-02) and prices are per school: the one in force **at the school where the purchase happened**. That is not a second decision — it is the only price the platform has and the number the person actually read, and `tenant_id` on the row records which door they came in by without a second column. When scope narrows (N-03) it simply means what it says.

  Paying again keeps the original row. A test raises the school's price between two payments and asserts the renewal is not moved onto the new one, which is the whole sentence in one assertion.

  `school_prices` carries the same append-only trigger as the ledger, the events and the audit. The migration dates the old value to the SCHOOL'S CREATION rather than to now — dating it to today would claim the price began today, which is the one thing the table exists not to say — and drops the columns in the same migration that fills it, because two places holding one value is how the wrong one gets edited. `effective_from` carries both meanings, so a price dated ahead is representable and is not the offer until its day arrives; a test holds that.

  APPENDING IS NOT THE ACCENT'S SHAPE. Saving the same colour twice is somebody clicking and is refused; saving the same price twice is a fact about the offer — "this is still what we ask" — and a series that dropped the repeats could not tell that from a price nobody has touched since January. The test that holds this fails if the accent's short-circuit is copied across.

  What is left is the sentence in the title, and it is two blockers rather than one: nothing would read a link from a subscription to a price row, because there is no gateway and no renewal charges anything; and a subscription is platform-wide (N-02) while a price is a school's, so what a subscriber "bought at" is the offer they were SHOWN rather than a property of what they hold. That is a decision to make with the gateway in hand
- [x] Every threshold displayed beside the number it produced — **both of them do now.** All six of that screen's bars come from `analysis`'s own constants, on the answer, so the screen cannot hold a stale copy of a decision. `item_statistics` stores `minimum_sample` on the row for the same reason one level down: a verdict computed under a minimum of thirty and displayed beside a constant that now says fifty is a row explaining itself with the wrong number.

  The pass mark was the one that did not, and it was found writing this line. The server applied `exam.PassMark`, stored it on the attempt and sent it as `pass_mark`; `ui/app/exams.js` declared `PASS_MARK = 70` of its own and showed THAT, twice. The number travels by two routes now, because the screens need it at two moments: a PAPER carries it — and a handed-in one carries the mark it was JUDGED by, off its own row, so a result is never explained by a rule nobody applied to it — and a SCHOOL carries it, because the course card says "minimum to pass" before any paper exists. What survives in the interface is an unexported offline default for the single-file bundle, which normally gets the real one anyway
- [x] Synthetic students flagged, excluded from every aggregate by default, with a visible switch and a banner when included — **the flag is a dimension on the event, which is the half that could not be added later.** `accounts.synthetic` had existed since phase 0 and never reached the stream, so item analysis and the funnel had no way to tell a seeded student from a real one; joining to `accounts` would have failed twice over, because half the funnel is visitors with no account and because erasing a person would retroactively turn their events from real to unknown. Both reads now exclude synthetic by default, **and can be told to look**: `event.Counting` is a word with three values, anything it does not recognise falls back to `real`, and `cmd/analyse` is deliberately fixed on `real` with no flag — that job withdraws a flagged question from circulation, so pointed at seeded answers it would remove real questions from real courses. What may read the seeded population is something that reports and says so.

  **The switch and the banner exist**, on the funnel AND on the cohorts — both of the reads that offer the choice, which is what closes this box. Two things make it a control rather than a decoration: the word travels to the reader AND comes back on the answer, so a chart of real people cannot be drawn under a heading naming another population; and a word the API does not know is **refused** rather than corrected, because the SQL answers `everbody` with real people — right for SQL, and exactly that failure on a screen. The item analysis has no switch and says why: it shows what the nightly job wrote, and that job withdraws questions from circulation.

  **This box was done and unticked, which is the failure the preamble names in its other direction.** The line above said the funnel was the only read offering the choice; that had been true when it was written and stopped being true when the cohorts screen got the same selector and the same banner. Presence excludes the seeded population with no switch beside it and says why — a control whose two settings draw the same picture teaches people not to trust the others — and `cmd/analyse` is fixed on `real` with no flag, because a job that WITHDRAWS a question must never act on students who were invented (K-11). An unticked capability costs a rediscovery; this is what that cost looks like
- [ ] A seeder that generates **history** — months of backdated events, with abandonment, returns, duplicate signups and refunds. **Three of the four exist**: `cmd/seed` writes a past into the event stream, which is the only thing it backdates, because statistics come from the stream and never from current state. A refund is not representable there today — nothing emits a subscription event into the stream, which is also why the funnel's last step comes back saying it is not measured — so this box stays open on the one behaviour that is missing rather than being ticked on the three that are.

  Two things it will not do, written down where the next person will look for them. It touches **no subscription, transition or ledger row**: their timestamps are not settable and must not become settable, because a fabricated row in those three is indistinguishable from one a payment produced. And it cannot be undone — `events` is append-only by trigger, so there is no `--clean` and there cannot be one, which is why it refuses a population too small for item analysis to say anything about BEFORE writing it.

  It also checks itself: one exam question is seeded with an inverted key, and the run fails if `analysis` does not call it inverted. Against the fixture's eight-question exam the planted one comes back at −0.32 and the seven others between +0.05 and +0.24.

  **Against production it has never run, and the first real run is what said so.** A school with no exam questions has nothing to plant a key on, which is every school this platform has until the content pipeline writes one — so the command seeded a thousand people, reported it, and said in its last line that item analysis had nothing to find. That is the right behaviour and the sentence above overstated it: the self-check has a precondition, and the only school that exists does not meet it.

  The same run showed the precondition missing one layer down. The refusal of too small a population is *about* item analysis, and it fired for a school where item analysis cannot run at all — fifty seeded people for the funnel, refused with a minimum sample computed for an exam that does not exist. Arithmetic that was right, for a reason that could not apply, stated with the confidence of a real constant

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
