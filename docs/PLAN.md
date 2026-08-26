# The plan

The reasoning behind every rule in [`../CLAUDE.md`](../CLAUDE.md), the questions still open, and
the order of work. This file argues; `CLAUDE.md` commands. Each decision here becomes a file in
`adr/` as it is implemented.

## What we are building, and what changed

One platform, several schools — one per subject — **all of them ours**. That single premise
deletes half a financial system before it exists: no school-to-platform billing, no onboarding of
third parties, no split, no commission, and none of the hard case a previous version of this plan
named by its name — a school in arrears with students who are paid up.

It also removes most of the justification for row-level security, which exists to defend one
party from another. There are no adversarial parties. **The privacy boundary that survives is
between students**, and that one is `account_id`, already enforced.

The material is written and checked by machine, with no human intervention at any step. That is
the founding constraint, and its most important consequence is not about staffing:

> Without a human reviewer, the only thing between a wrong answer key and a student is automatic
> verification. So **the order of the schools follows verifiability, not how easy the subject is
> to write.**

| school | who checks the answer | viability |
|---|---|---|
| programming | interpreter against test cases | strong — already exists |
| mathematics | computer algebra system | strong |
| physics | numeric with units and tolerance | strong |
| chemistry | balancing, stoichiometry, molar mass | strong |
| music theory | deterministic rules | strong |
| languages | vocabulary and conjugation yes; free production no | partial |
| history, geography | recall yes; essays have no verifier | weak |

This contradicts the intuition of starting with whatever is easiest to write. History is easy to
generate and impossible to check — which, in an operation with no reviewer, is the worst possible
profile. Mathematics is the opposite.

## What may never be skipped

Five things that cost almost nothing now and are **impossible** later — not expensive,
impossible, because history cannot be reconstructed and an action already taken cannot grow a
column retroactively. Everything else in this document can wait.

| | why it cannot wait |
|---|---|
| **Rich events** | Statistics come from the event stream, never from current state, which has been overwritten. And every event carries its dimensions **denormalised** — plan, school, country, locale copied at the moment it happens. Storing only `account_id` makes "which plan were they on when they finished this" unanswerable, because the plan has since changed. |
| **The review log** | Append-only, from before there is a practice screen. SM-2 does not need it; a better scheduler later does, and it needs history to fit its parameters. |
| **Audit with an actor** | Two people operate this. The first administrative action already has to record who took it. |
| **Export and erase personal data** | A legal obligation. Today the schema is small enough that you know where personal data lives; at twice the size that becomes archaeology, and the statutory clock runs while you look. |
| **Visitor identity, before the account** | The first step of the funnel happens before a student exists. Linking a visitor to an account after signup requires the visitor to have had an identity at the time of the visit. Without it, "how many of those who arrived became students" is permanently unanswerable for every earlier period. |

---

## Decisions

### Platform

| # | decision | why |
|---|---|---|
| P-01 | School resolved by the full `Host` | Resolving by the whole host, not the first label, leaves a custom domain ready for later. |
| P-02 | Monorepo | The boundary between repositories matches no boundary in the system. In the predecessor, one stylesheet existed in three copies with only one checked, and every contract change cost two pull requests. |
| P-03 | Same origin: the Go binary serves the API and the embedded frontend | Removes CORS, makes the `HttpOnly` cookie real, and drops the static host — with it, the duplicated stylesheets and the edge cache that already caused a defect. |
| P-04 | No global load balancer; one domain mapping per school | A wildcard is only needed when third parties sign schools up themselves. Few schools, all ours, means host-by-host mapping is free and sufficient. |
| P-05 | `tenant_id` everywhere; row-level security deferred | RLS defends one party from another, and there are no adversarial parties. The privacy boundary that survives is between **students**, and that is `account_id`, already enforced. Revisit if a third-party school ever exists. |
| P-06 | Terraform in the monorepo, credentials isolated per environment | The thousand-line prose runbook it replaces has already failed expensively. Isolation comes from the workflow and a required approval, not from a repository boundary. |
| P-07 | Terraform owns what exists; the deploy pipeline owns which version runs | If Terraform manages the service image, every deploy fights it. It owns the database, IAM, secret *containers* (never values), alerts and domain mappings. |
| P-08 | Migration as a job before traffic is released | Migrating at start-up with several instances coming up together is a race. If it fails, the deploy stops and the previous revision keeps serving. |
| P-09 | Semantic versioning, tags and releases from the start; the tag is the only place a version is written | See [`../CLAUDE.md`](../CLAUDE.md). The predecessor's file existed because Pages had no build to stamp during; here a second copy would only be a second thing to disagree. |
| P-10 | API versioned at `/api/v1/` | See [`../CLAUDE.md`](../CLAUDE.md). |

### Product

| # | decision | why |
|---|---|---|
| N-01 | One login for the whole platform | With a single owner, one identity is better product, and it is already the mechanism: the cookie is issued for the parent domain. |
| N-02 | One subscription, all schools | The marginal cost of another school is zero. The scarce resource is students, not content — and splitting the offer charges more from the person doing the thing that differentiates the platform. |
| N-03 | The subscription's scope is modelled anyway | `subscription(account_id, scope)`, where scope is a school or `all`. A column today; a billing migration later. |
| N-04 | Free tier per school: the first course of every track | It is the shop window, and it must be open at every door. |
| N-05 | One visual identity, one accent token per school | Inherited from the predecessor. The student needs to know where they are without the brand fragmenting. |
| N-06 | English is the source language; Portuguese and English first | See [`../CLAUDE.md`](../CLAUDE.md). |
| N-07 | The same study interface in every school | Sidebar, search, graph, exams, certificates. The colour and the content change; what the student learned to operate does not. |
| N-08 | Brazil: annual and biennial, paid in card instalments | No monthly. Twelve instalments feel monthly to the buyer, lock in a year of revenue and remove monthly churn. Pix in one payment, at a discount, joins the annual plan: near-zero fee and no chargeback. |
| N-09 | Elsewhere: monthly, annual and biennial, recurring | Real recurrence, where it is the market default. |
| N-10 | No free trial period | The free tier is the trial: the first course of every track, in every school, with no card and no deadline. A timed trial on top of that would only add fraud. |

**Card instalments in Brazil are not recurring billing.** They are a single authorisation split by
the issuer. Three consequences belong in the design from the start: renewal at the end of the
period is a **new sale** and needs its own flow with notice before expiry; two billing models
will coexist — recurring abroad, one-off instalments here — and they are different subscription
states; and exposure per transaction is larger than monthly.

### How the code is written

| # | decision | why |
|---|---|---|
| X-01 | Idiomatic Go, not a catalogue of patterns | Small interfaces defined by the consumer, dependencies passed to the constructor, no injection container. Abstract factories and singletons belong to another language and produce bad Go. |
| X-02 | The module dependency graph is enforced by a test | `platform` imports nobody; `identity` and `catalog` cannot see each other. It is what turns "extract this into its own service" into a day's work. |
| X-03 | Every failure path has a test that exercises the failure | Silent failure is forbidden — see [`../CLAUDE.md`](../CLAUDE.md). |
| X-05 | WCAG 2.2 AA from the first screen, checked automatically | Cheap now and a rewrite of every screen later — the same pattern as the five in phase 0, with the aggravation that this is an education product, where excluding a screen reader excludes a student. |
| X-06 | Every question type operable by keyboard and screen reader | The hard part is not contrast. `matching` and `ordering` by drag and drop, and `labelling` by clicking a point on an image, are unusable without a keyboard path designed in. |
| X-04 | Coverage is not a target; an untested failure mode is | See [`../CLAUDE.md`](../CLAUDE.md). |

### Learning

The hierarchy stays: **track → course → lesson → section**. Every school has "a programme, a
subject, a topic, a step".

**`requires` is knowledge; `links` is sequence.** `requires` names only what the student must
know first. If the reason is "in this track it comes after that one", it belongs to the track's
`links`. Mathematics is almost all `requires`; history is almost all `links` — and the system
holds both extremes, the graph becoming a path instead of a lattice and staying correct.
Conflating the two once cost **18 false edges**, which is why a validator runs in CI before
anything reaches the database. It is also what stops an automatic generator from inventing a
prerequisite that does not exist.

| # | decision | why |
|---|---|---|
| A-01 | One content entity; `exercises` gains `drillable` | The same question serves as an exam item and a drill card. The difference is in the state, not the content. |
| A-02 | SM-2 to begin with | No training data needed, documented for decades, and the state fits in four columns. |
| A-03 | Append-only review log from day one | See **What may never be skipped**, above. |
| A-04 | The quality score is derived, not asked | Correctness and time give the score. "How well did you know this?" is subjective — and a human judgement in a system that has none. |
| A-05 | Decayed strength never feeds the progress bar | A bar that moves backwards for someone who did nothing wrong is the most demoralising thing a study platform can do. A bar for the course, a queue for review. |
| A-06 | The review queue crosses schools | "Review today" mixing derivatives and syntax is a differentiator that falls out of the single login and single subscription for free. |
| A-07 | Practice does not count towards the certificate | A certificate that depended on decaying strength could be revoked by forgetting. Finishing is history; remembering is present tense. |
| A-08 | Exams per course and per track, kept | Without a human reviewer, the exam is the only moment the system asserts that the student knows. The course issues a certificate; the track is the final. |
| A-09 | ~~A conformance test between the two graders~~ → **one grader, on the server** | Retired. It assumed the client would grade for immediate feedback, which cannot be done without giving the client the key — and a question is *presented* rather than sent. The last candidate, feedback on a drill, is marked server-side. The conformance fixtures stay, as the contract between the grader and the questions rather than between two graders. |

**Question types.** Seven exist and all stay: `quiz`, `multiple-choice`, `ordering`, `matching`,
`code`, `expected-output`, `expression-answer`. Three join, each with a machine grader:

- `numeric` — a number with a unit and a tolerance. Physics and chemistry do not exist without it.
- `cloze` — a blank with accepted answers and normalisation. The workhorse of drilling.
- `labelling` — a label on a point of an image. It is `matching` with coordinates.

Audio waits for the music school. **Free-text essays never enter**: no verifier, and it
contradicts the founding constraint.

### Content

| # | decision | why |
|---|---|---|
| C-01 | The catalogue is a file in git, not a row in the database | With nobody reviewing before publication, the diff is the last trace that exists — and the load is destructive, pruning whatever the file no longer carries. |
| C-02 | The cross-repository bridge dies; the file survives | The snapshot step existed only to cross the boundary the monorepo removes. A load job remains. |
| C-03 | Prose in Markdown; structure and exercises in JSON | What a person might want to read, in Markdown — a diff per paragraph. What only the machine reads, in JSON, which wants strict validation. |
| C-04 | Publication state: draft and published | Generate, verify, look at the diff, publish. Without a draft state, generating is publishing. |
| C-05 | Provenance: which run produced what, at which verification level | When a wrong answer key surfaces, the question is not who wrote it — it is what else came out of the same run. |
| C-06 | Item analysis is the reviewer | Attempts, percentage correct, mean time and a discrimination index. A question everyone gets wrong is either excellent or broken; one that everyone gets right measures nothing; one the strong students fail and the weak ones pass is **inverted**, which happens with automatic generation. |
| C-07 | The database is a derived mirror, and only the load job writes it | The server does not read files per request — it joins sections with progress, computes the free set, counts denominators. If they disagree, the file wins. The console reads the catalogue and never writes it. |
| C-09 | Nothing joins by prose or position — only by a stable id | The predecessor joined exercises to lessons by the title text and keyed translations by array position. Both detach silently on an edit, and one of them shipped. With a machine rewriting titles they stop being hazards and become certainties. |
| C-10 | Order is declared, never inferred from the filesystem | No numeric prefixes on directories. Reordering is one changed line instead of a cascade of renames that git shows as deletions. |
| C-11 | One Markdown file per section, its translation beside it and optional | A diff per paragraph is the whole reason the catalogue is a file. Exercises live with their lesson; exams live with the course and with the track, because they belong to neither lesson. |
| C-12 | The content check runs the answer keys, not only the schema | A schema check would pass a question whose key is wrong, which is the one failure this system cannot absorb. `code` is executed, `expression-answer` goes through the CAS, `numeric` units are parsed. |
| C-13 | An orphaned prose file is an error | Content generated and then forgotten appears nowhere else. It only happens with a machine writing. |
| C-14 | Generation is a person with an agent; the system automates the checking | There is no pipeline service. Git is the state, so "how does it know what it wrote" and "how does it resume" stop being questions. What cannot be a conversation is the verification, because it is what stands in for the reviewer. |
| C-15 | A flagged question is quarantined automatically, by threshold | A broken key harms students now, and the cheapest correct action is to stop serving it. A human decision is exactly what this system does not have. |
| C-16 | Exercises are versioned; an answer records the version it answered | Without it there is no way to know whether a replacement helped, and the history lies — December's apple against March's orange. |
| C-17 | Nothing fires below a minimum sample | Three wrong out of three is chance. Beneath the threshold the console says *insufficient data* rather than a red that means nothing. With few students almost everything sits there for months, and that is correct. |
| C-08 | Structure first, video last | Tracks, courses, lessons and sections are designed before anything is generated. Video is the final layer of the material, after the whole system including billing. |

**"Section", not "topic".** `topic` is taken: a lesson carries `topic_key`, which is how
exercises join to the pipeline — *topic already means lesson*. The ambiguity that prompts the
question is Portuguese, where *seção* and *sessão* sound alike; the source term is `section` and
is unambiguous. It is a translation choice, not a model change.

### Console

Four jobs that do not mix: **operate** (current tables, now), **understand** (aggregates,
yesterday will do), **watch** (presence and alerts, seconds), **audit** (immutable history).
Serving all four from the same queries against production is how every console rots.

| # | decision | why |
|---|---|---|
| K-01 | Roles, mandatory MFA, audit with an actor | Two people from day one. An account that can change a student's plan carries a second factor. |
| K-02 | "View as student", with three restraints | The most useful support tool and the most classic breach vector. Always audited, time-limited, and with a visible banner. Without all three, it does not ship. |
| K-03 | Statistics come from the event stream | Current state cannot answer "how many were active in March". |
| K-04 | Events carry their dimensions denormalised | See **What may never be skipped**, above. |
| K-05 | Geolocation in-process; store the country, never the IP | Cloud Run does not provide a geo header — the load balancer does. An embedded GeoIP database resolves it with no new infrastructure, and an aggregated country carries far lighter obligations than an address. |
| K-06 | Presence via `last_seen_at`, written at most once a minute | "Online now" is presence, not an event. Writing on every request is amplification. |
| K-07 | Every console read goes through its own layer | Today it queries production directly, and that is fine. The seam is what lets it point at a replica or a rollup later without touching a single screen. |
| K-08 | Operational alerts do not live in the console | Uptime checks and alert policies reach a phone when the console is down — which is exactly when you need to know. |
| K-09 | Cohorts and funnels from the start | Even with no population to make them legible. Same rule as finishing the system before the content: a screen waiting for data beats data waiting for a screen. |
| K-10 | Visitor identity, before the account | See **What may never be skipped**, above. |
| K-11 | Synthetic students flagged, excluded by default, with a visible switch | `accounts.synthetic`. Every aggregate excludes them; the screen offers to include them, with a banner. Otherwise the first real cohort is born polluted with no way to separate it. |
| K-13 | System parameters are a **closed list**, and every change is audited | Actor, old value, new value, time. A price that changed silently makes every invoice unexplainable. And only something without a right answer becomes a parameter: if there is a correct value it lives in code, where a test holds it. A configuration surface grows to fill the space it is given, and every knob multiplies the state two people have to test. |
| K-14 | Money parameters are effective-dated, never overwritten | Change the annual price and whoever already subscribed keeps the price they bought at. A price is therefore a row with a validity period, not a mutable field — overwriting destroys the ability to explain history, and a March invoice has to stay explicable in November. |
| K-15 | The paywall is not configurable | Access is an active subscription, a published course and the same school. Granting access to **one** student is a legitimate audited action; a global switch is not. The day correctness depends on a mutable row instead of code with a test, it stops being possible to assert that the paywall works. |
| K-16 | A threshold is shown beside the number it produced | *"Flagged, minimum sample 30"*. Lowering the minimum sample so the dashboard finally shows something breaks the guarantee rather than configures the system — so the rule travels with the statistic it made. |
| K-12 | "Active" is defined in one place | Active = completed at least one section or one review in the period. A login is a weak signal: opening the tab is not studying. |
| K-17 | One console for every school, on its own host — and a host is a school's, the console's, a student's own, the platform's front door, or a 404 | Settled by the schema rather than by taste: there is no `tenant_id` on any account table (N-01), so a person exists across schools and exporting or erasing one crosses all of them. A per-school console could not perform the phase-0 item at all. The last case is written as a rule because cases with an implied remainder is how a console ends up answering at an address nobody meant — and the list has grown twice since, which is the argument working rather than failing: `my.` was added and this sentence was not, so for a while the rule named three cases and the server answered four. The front door is the fourth, at the bare domain, and it is the one address on the platform that asks to be indexed. |
| K-18 | A scope is declared on every screen, never assumed | The schema sorts the console's subjects into three kinds — per school (`catalog_*`, `item_statistics`, `question_quarantine`, `certificates`), platform-wide (`accounts`, `sessions`, `subscriptions`, `ledger_entries`, `audit_log`) and either (`events`, whose `tenant_id` is null exactly when `school_slug` is empty). This is K-16 one level up: a threshold travels with the number it produced, and so does a scope. A screen whose subject cannot be summed across schools says so rather than summing anyway. |
| K-19 | Two independent gates on the console: the host, and the staff role | They fail differently — a misconfigured host is a deployment error, a missing role check is a code error — and a system that needs both to be wrong survives one of them. |
| K-20 | The export is audited, not only the erasure | K-01 already covers the erasure, which is a write. An export is a read, and it is the one read that removes the protection every other read has: afterwards a person's whole record is a file on somebody's laptop, outside every access control this system has. "Who took a copy of whose data, and when" is asked once, in the worst week, and the answer has to already exist. |
| K-21 | A console screen asks only what an index sustains | `audit_log` already carries four — by time, by actor, by subject, by school, each ordered by time descending — so recent-first paging costs the same at ten million rows as at ten. The question was never how far back a screen reads; it is which query it makes. One that does not fit becomes an index or a rollup, decided then, rather than a screen nobody notices getting slower. |
| K-22 | A person is found by an exact address, and never listed | The console's job is to answer a request from somebody who wrote in, not to browse people — and browsing personal data is precisely what an audit cannot tell from working. Exact match also gives away nothing: "not found" tells the asker only what they already typed. |

### The closed list of parameters

Editable in the console, each change audited: prices per plan, region and currency, with an
effective date; the Pix discount on the annual plan; the grace period and its retry schedule; the
minimum sample and the quarantine thresholds for item analysis; the daily cap on the review
queue; the maintenance banner and whether it shows; whether signup is open.

Not editable, by decision: anything that decides who has access; the free tier, which is computed
from the tracks rather than typed; secrets, allowed origins and the database; the content
verification levels; and a school's own metadata, which lives in `school.json` because the file
is the source of truth.

Infrastructure configuration stays in environment variables, validated at start-up with every
problem reported together rather than one per restart. Product parameters live in the database.
The screen shows the effective value, where it came from, and who put it there.

Two are still open rather than decided: a cap on exam attempts, and whether a certificate ever
expires. Neither exists today, and a certificate that expires is a product decision too large to
arrive as a configuration field.

**The funnel.** Seven of these are events already emitted; the first is what makes K-10
necessary: *arrived* → created an account → verified the address → chose a track → opened the
first lesson → finished the first section → finished the free course → **subscribed**.

**Seeding fifty accounts does not test a cohort.** A cohort needs events spread over months with
plausible backdated timestamps; a funnel needs drop-off at each step. The seeder generates
*history*, and generates **messy behaviour on purpose** — someone who disappears for three
months and returns, someone who signs up twice, someone who refunds. If every fake student
progresses in a straight line, the funnel looks perfect and the wrong query never surfaces.

A support ticket system stays out: months of work to solve what an email address solves, and if
it ever becomes necessary, it is bought rather than built.

---

## Open questions

**The name.** `example.tld` in these documents is a placeholder, not a choice — every address
here is written that way so that nothing has to be rewritten when the real one arrives.

An offer of US$300 is out on **`schooling.app`**. It recovers the word that made `school.ing`
attractive in the first place, without needing the premium TLD: it is a dictionary word rather
than a compound, it covers mathematics and music as well as programming, and the subdomains read
as a phrase — `code.schooling.app`, `math.schooling.app`. Two things to confirm before paying:
that it **renews at the ordinary rate** rather than carrying a recurring premium, and that its
**history is clean** — it has had an owner, transactional mail will be sent from it, and a domain
burned by previous spam starts with a deficit in exactly the deliverability this plan already
tracks as a console concern.

If the offer is refused, the criterion stands: a whole word if the TLD is unusual, otherwise a
short `.com` or `.com.br`. A compound plus a rare TLD is the worst of both. **Deadline: before a
student bookmarks the address and before billing goes out from that sender.**

Nothing is blocked while this is open. The repository is named for the product rather than the
domain, the GCP project id is neutral and never public, and the platform domain is an environment
variable — so the decision reduces to DNS and a variable rather than a change to the code.

**Payment gateway.** It has to cover three things at once: international recurrence, Brazilian
card instalments, and Pix. Without splits and third-party onboarding the problem is far smaller
than it was — fees, interest-free instalments and the cost of two coexisting billing models
remain. Decide before the billing phase, not during it.

**Video provider.** Managed service or own transcoding, behind an interface. Deferred by
construction: video is the last layer of the material, so the decision happens when there are
real hours watched to weigh.

**The definition of a practice "item".** Whether it is the same across domains or each school
declares its own. Decide alongside the practice subsystem.

---

## Roadmap

The shape and the reason for the order. The list of what each phase is made of lives in
[`ROADMAP.md`](ROADMAP.md), as capabilities rather than tasks.

The system is finished **before** any new content is written. That inverts the obvious order,
and the inversion has a reason: with a working pipeline, content stops being slow work and
becomes a batch run. "Write first because writing takes months" does not apply to somebody who
does not write by hand.

**Done means:** the pipeline produces a course end to end, and a student can pay for it.
Anything not needed for those two sentences is phase 6.

### 0 — Skeleton, and the five that cannot wait

Monorepo, school by host, Go serving API and embedded frontend, domain mapping, single identity,
roles and MFA, minimal Terraform, tags and releases. Plus rich events, the review log, audit with
an actor, personal-data export, and the visitor identity that precedes the account.

*Done when: two schools answer over TLS, and the first administrative action shows up in the
audit with a name against it.*

### 1 — The study platform

Migration of what already works: the catalogue in files with its load job, the graph with its
edge-crossing test at six viewport sizes, sidebar, search, course and track exams, certificates,
the seven question types. No new content.

*Done when: a student walks a whole track of `code` on the new platform.*

### 2 — Learning, complete

Everything the other subjects will demand, built before a subject demands it: `expression-answer`
through a computer algebra system, the `numeric`, `cloze` and `labelling` types, and the practice
subsystem — SM-2, a review queue crossing schools, a score derived from correctness and time.

*Done when: an algebraic answer written differently is accepted, and yesterday's review comes
back today.*

### 3 — Billing

Two models coexisting: recurring abroad, instalments in Brazil, Pix on the annual plan. Grace
with retries, cancellation, refunds, idempotent webhooks, an append-only ledger, integer cents.
The longest phase by a wide margin.

*Done when: a student pays under both models, delinquency suspends on its own, and recovery
restores access with progress intact.*

### 4 — The console, complete

What the phase-0 events made possible: the world map with per-country statistics, presence, item
analysis, generation provenance, the reported-content queue, email deliverability, the nightly
rollup — and full cohorts and funnels, verified against synthetic history generated on purpose
with abandonment, returns and refunds.

*Done when: a question with a broken answer key is found by the statistics, and the funnel shows
a drop at a step nobody suspected.*

### 5 — The pipeline and the content

The last component of the system, and the first batch of what it produces: the generator writing
material, exercises and exams, at three verification levels with provenance recorded. `code`
first — starting with the seven entry courses that currently open onto an empty room — then
`math`.

*Done when: a course is born end to end without anyone writing a sentence, and item analysis
reports no inverted key.*

### 6 — Video and scale

Video as the final layer, with signed URLs validated against the subscription on every issue. A
third and fourth school — physics and chemistry, by the same verifiability yardstick. The
remaining languages.

*Done when: opening a new school is running the pipeline, and nothing else.*

---

## Not on the roadmap, deliberately

**Kubernetes.** Cloud Run is already managed container orchestration: it scales to zero and
costs nothing idle. A cluster would add a fixed bill and an operational surface — node upgrades,
ingress, certificates, secrets — to solve a problem this system does not have, with one stateless
service, one database and one job. The image is ordinary OCI and runs on GKE unchanged the day
there is a reason; the coupling is in the deploy tooling, not in what was built.

The honest case for a cluster is the executor sandbox at volume, and even that starts as jobs and
moves when the volume justifies it.
