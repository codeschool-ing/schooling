# schooling

One platform, several schools — one per subject, all of them ours. The material is written and
checked by machine; no person reviews it before a student reads it.

`docs/PLAN.md` argues the decisions and carries the roadmap. This file states the rules and
cites the decision by id. If the two ever disagree, this file is what the code has to obey and
`PLAN.md` is what needs correcting.

---

## The rules

**English is the source language** — code, comments, documentation, ids, the catalogue. The `en`
dictionaries do not exist: a missing entry falls back to the key, and the key is already the
string to show. (N-06)

**Silent failure is forbidden.** If a path can fail without a symptom, either it says so, or a
test exercises the failure and demands that it says so. A swallowed error needs a comment saying
why the silence is right, and "not fatal" is not a reason on its own. (X-03)

**No module reads another module's tables.** Ask through an interface. `internal/architecture_test.go`
enforces the graph — if it fails, the fix is the dependency, not the test. (X-02)

**A module owns tables and routes; a library owns neither.** `internal/grade` is rules over JSON
values, so any module may import it — it is named in `libraries` in that same test, and a package
declared one that touches a database, serves HTTP or reaches into a module fails. The exception
is checked rather than trusted, because a list of names is how a rule gets weakened one import at
a time.

**Coverage is not a target.** Do not add tests to raise a percentage. Add the test that would
have caught the failure you just found, and the one for the failure mode you can name. (X-04)

**Nothing joins to anything by prose or by position — only by a stable id.** Not by a title,
not by an array index. The predecessor joined exercises to lessons by the title text and keyed
translations by position; both detach silently on an edit, and one of them shipped. Ids are
slugs and never derive from a title, so renaming a title breaks nothing. (C-09)

**Order is declared, never inferred from the filesystem.** No numeric prefixes on directories.
`course.json` names its lessons in order; `lesson.json` names its sections. (C-10)

**Every catalogue write goes through the load job.** The file in `content/` is the source of
truth; the database is a derived mirror. Nothing else writes catalogue rows — the console reads
them and never writes. (C-01, C-07)

**Money is integer cents.** Never a float. And a price is **effective-dated, never overwritten** —
whoever subscribed keeps the price they bought at, so history stays explicable. (K-14)

**The paywall is not configurable.** No parameter, flag or console switch may widen who gets
access. Granting one named student access is an audited action; a global switch is not. (K-15)

**Only something without a right answer becomes a parameter.** If there is a correct value, it
lives in code where a test holds it. Every knob multiplies the state two people have to
test. (K-13)

**Every screen is operable by keyboard and legible to a screen reader**, at WCAG 2.2 AA. The
hard part is not contrast — it is the question types: `matching` and `ordering` by drag and drop,
and `labelling` by clicking a point on an image, are unusable without a keyboard path designed
in. Building one later is rewriting every one of them. (X-05, X-06)

---

## Anything that touches these five is Fase 0 work, wherever it appears

They cost almost nothing now and are **impossible** later, because history cannot be
reconstructed and an action already taken cannot grow a column retroactively.

1. **Events carry their dimensions denormalised** — plan, school, country, locale copied at the
   moment the event happens, never joined later. A new event type without them is a hole in
   every future report. (K-04)
2. **The review log is append-only** and written from the first practice answer, even though
   SM-2 does not read it. A better scheduler needs history to fit its parameters. (A-03)
3. **Every administrative write records the actor.** Two people operate this. (K-01)
4. **Every table holding personal data is reachable by the export and erase paths.** Adding one
   without wiring it there is a legal defect, not a backlog item. (Fase 0)
5. **The visitor has an identity before the account exists**, and signup links the two. Without
   it the first step of the funnel is unanswerable for every earlier period. (K-10)

All five are in the schema and in code — `internal/event`, `internal/audit`, `internal/visitor`,
`internal/privacy` and `migrations/0002` — and three of them are guarantees rather than habits:

- **A dimension cannot be omitted, because the type will not let it.** `event.Dimensions` has no
  exported fields; the only way to build one is `ForSchool` or `ForPlatform`, which take every
  dimension as an argument. A dimension added later breaks every call site, which is the point.
- **`events`, `practice_review` and `audit_log` refuse UPDATE and DELETE by trigger.** Append-only
  as an arrangement is a comment; as a trigger it is a guarantee, and the difference shows up on
  the day somebody corrects data by hand.
- **A new table that nobody classified fails CI.** Every table carries a
  `COMMENT ON TABLE … 'personal-data: …'`, and a test compares the live schema against
  `privacy.Registry`. Adding one without deciding what it holds is not possible rather than
  discouraged.

**How erasure works, because everything else rests on it.** None of these tables holds a name —
they hold uuids. Erasing a person deletes the rows that give those uuids a meaning (`visitors`
and `account_visitors`), which leaves the event and review rows pointing at nothing and joinable
to nobody. The statistics survive; the person is not in them. That is also *why* the append-only
triggers can be absolute: the erase path never needs to update or delete one of those rows. It
is also why `events.visitor_id` is **not** a foreign key — `ON DELETE SET NULL` would try to
update an append-only row, and the legal obligation and the immutability guarantee could not
both hold.

---

## Identity

**One account for the whole platform** (N-01). Nothing in `internal/identity` mentions a school
and no table it owns carries `tenant_id`: what is school-scoped is what somebody DID, not who
they are.

**The sign-in method is a row, not a column.** `account_credentials` has a `kind`, so adding a
second way in — an identity provider, a passkey — is a new kind of row rather than a migration
of `accounts` with a nullable password column left behind. E-mail and password is what shipped
because it is the only method that can be built and tested with no cloud project and no domain:
the other two candidates need exactly the infrastructure that is still undecided.

Four rules that are cheap now and are incidents later:

1. **The session token is stored as its SHA-256, never as itself.** A backup that leaks then
   costs a rotation rather than every live session.
2. **Sign-in answers identically for a wrong password and an address nobody has** — and costs the
   same, by verifying against a decoy hash. Otherwise the form is a way to ask whether a
   particular person studies here, and on an education platform that is a question about
   somebody's private life.
3. **Changing a password revokes every other session.** Without that, the person who changed it
   believes they locked somebody out and did not.
4. **Argon2id parameters are stored beside each hash**, in the standard PHC string. A constant in
   the code means raising the cost invalidates every password ever stored, which means nobody
   raises it.

**Staff is a role on an account, not a second account.** Both people who run this are also
students of it; one account with a role beside it makes "am I looking at this as staff or as
myself" one question rather than a habit of remembering which browser you are in. Three roles,
totally ordered — `owner` > `operator` > `read-only` — because a permission matrix is a screen
nobody can hold in their head.

**Mandatory MFA is enforced on the SESSION, not on the account.** `sessions.mfa_at` is null until
a code is presented, and `RequireStaff` checks it every time. A role without the factor is
exactly the state "mandatory" is supposed to make impossible, and it is reachable the moment
somebody signs in with a password — so the refusal lives at the door rather than in a rule about
how accounts are set up. **Revoking a role ends every session that held it**, because otherwise
removing access is only scheduling it.

TOTP is written out rather than imported, and that is defensible for one reason: RFC 6238
publishes test vectors, so the implementation is **proved against the specification**. Do not
replace that test.

`Authenticate` never refuses; `Require` does. Half the API is legitimately anonymous, so a
middleware that refused would need a list of exceptions — and a list of exceptions is where the
one nobody added lives.

---

## The vocabulary, which is a contract

**`track → course → lesson → section`.** Do not rename these, and do not introduce `topic` as a
fifth word: in the predecessor *topic* already meant lesson, and reviving it with a new meaning
guarantees a misunderstanding. In Portuguese the interface says *etapa* — the model still says
`section`, and that is a translation choice rather than a model change.

An exercise names its `section` by **id**. It does not name a title, and it never did so safely:
joining by title text is how the predecessor lost exercises whenever a lesson was renamed.

**`requires` is knowledge; `links` is sequence.** `requires` names only what the student has to
know first. If the reason is "in this track it comes after that one", it belongs to the track's
`links`, which draws the same arrow in that track and nowhere else. Conflating the two cost 18
false edges once. `tools/validate-catalog` fails on the symptom that catches it — a prerequisite
absent from a track that shows the course.

**A section is `drillable` or it is not.** The same question serves as an exam item and a drill
card; the difference is in the state, not the content. (A-01)

**The paywall is checked on the way IN, not only on the way out.** A student may not record
progress, move a resume pointer or write a note in a course they cannot open — otherwise the
paywall is a decoration on the reading path, a client that never asks for the lesson marks it
done anyway, and a certificate rests on sections nobody was entitled to. Same 402, same reason.

**A section id from a client is checked against the catalogue**, never trusted. Otherwise a
three-section course is finished by sending thirty ids, and the progress bar, the certificate and
the cohort are all built on rows naming nothing.

**Completing twice emits ONE event.** Statistics come from the event stream (K-03), so a handler
that emitted on every call would inflate "sections completed this month" by every double tap and
every retry — quietly, and in the direction that flatters. `Complete` answers whether it was the
first time and the caller emits only then. This was found by running the thing by hand and
looking at the rows, not by a test.

**`section_progress` is completion; `practice_state` is mastery.** Completion is set-true and
never toggled. Mastery decays. **Decayed strength never feeds a progress bar** — a bar that moves
backwards for someone who did nothing wrong is the worst thing this product can do. (A-05)

---

## Content

`content/` is the source of truth; `docs/CONTENT.md` is its specification. The material is
written by a person working with an agent, on demand — **the system automates the checking, not
the writing** (C-14). What CI verifies is therefore not a formality: it runs the answer keys
through the same machinery that grades a student, because a schema check alone would pass a
question whose key is wrong, and that is the one failure this system cannot absorb (C-12).

An exercise carries a `version`, and a student's answer records the version it answered. A
question the statistics flag is **quarantined by threshold, never by decision** — and nothing
fires below a minimum sample, because three wrong out of three is chance. (C-15, C-16, C-17)

## The catalogue is a mirror, and only one thing writes it

`content/` is the truth; the `catalog_*` tables are derived (C-01). **A test scans the source for
anybody but `cmd/load` writing to one**, because the first console screen that fixes a typo
directly is the moment the files stop being the truth — and the next load undoes that fix,
silently.

`cmd/load` **validates first and writes nothing if anything is wrong.** The gap between "CI was
green on that commit" and "this is what is being loaded now" is exactly where a half-written
catalogue reaches students. It is one transaction including the prune: a load that failed halfway
would leave a catalogue that is neither the old one nor the new one.

Pruning is deletion, and it is safe because nothing a student did points at those rows —
`practice_review.exercise_id` is text and deliberately unkeyed. A question that leaves the
catalogue leaves the history intact and orphaned, which is the same decision, for the same
reason, as erasure.

A directory in `content/` **does not create a school**. A school is also an address and a domain
mapping, so a typo in a directory name would otherwise become a school answering at no address
and appearing in every count.

**Access is computed, never stored, and it fails closed.** Something recognised opens a course;
**anything else closes it** — an unknown plan, an empty plan, a plan somebody misspells in a
migration two years from now. A paywall that opens on an unrecognised input is a paywall with a
list of ways around it that nobody has finished writing. The free tier is the first course of
every track, computed from the track's order rather than flagged on a course, because a flag is a
second place to say what position 0 already says.

Three refusals that look like details and are not:

- **A draft is absent, not locked.** Even to a subscriber. Asking for one directly answers exactly
  as a course that does not exist, because anything else tells a stranger what is being written.
- **A locked course shows its shape and not one word** — the lesson route refuses with **402**
  rather than serving an empty body, which would be a paywall that looks like a bug.
- **An unreadable catalogue refuses; it never answers empty.** A 200 with no courses cannot be
  told from a school that has none, so a database that is down would look like a catalogue that
  was deleted, on every screen.

---

## Two implementations of one rule

The client grades for immediate feedback and the server grades exams. They **must** agree, or the
same answer scores differently in a course exam and a track exam. Adding a question type means
adding it to both and to the conformance fixtures. (A-09)

Question types: `quiz`, `multiple-choice`, `ordering`, `matching`, `code`, `expected-output`,
`expression-answer`, `numeric`, `cloze`, `labelling`. Every type has a machine grader — that is
the entry requirement, not a nice-to-have. Free-text essays are out.

**`internal/grade` is the server's half, and `testdata/conformance` is the contract.** Both
graders run every fixture; a gradable type with no fixture fails the build, because "I will add
the fixture afterwards" is the door the disagreement walks through.

Three rules inside it:

- **`Key` exists so the content check can feed a question its own answer.** A quiz with two
  correct choices, an ordering of one item, a cloze whose accepted set is empty once normalised —
  each passes a shape check and cannot be answered by anybody. This caught a stub in this
  repository's own fixture on its first run.
- **An unknown type is an error, never a pass.** "Give them the mark" is the direction a lenient
  default always goes, and it turns a typo in a content file into a question everybody gets right.
- **Grading is binary.** Partial credit is a decision about assessment that has to be made once,
  for every type; a grader that invented its own would make two exams incomparable, quietly.

Normalisation is **declared per question**, never chosen by the grader: whether case matters is a
property of what is being asked, and in a question about naming conventions it is the entire
point.

---

## Sitting an exam

Without a human reviewer, the exam is the only moment the system asserts that a student knows
something — everything else it measures is effort. A certificate rests on it (A-08), so it is
built to be defensible rather than convenient.

**The answer must not leave the server.** A `quiz` payload carries `correct: true`; an `ordering`
carries the correct order as the array itself. So a question is **presented** rather than sent —
the answer removed and, where the order IS the answer, shuffled — and the permutation stays here.
`grade.Present` and `grade.Restore` are that, and the answer fields are **absent rather than
blanked**, because a field that is always `false` in a presented question is a field somebody
will one day forget to blank.

The test is a property rather than a list of field names, so it covers a type somebody adds
later: *what can be derived from what the student was sent must not pass*. It is deliberately not
"asking for the key must fail" — for `ordering` and `numeric` the derivation succeeds and
produces something wrong, which is just as safe, and stating it the other way failed on two
fixtures that were fine.

**The paper is sealed when it is drawn.** Every question is copied into the attempt: what was
shown, the permutation, and the question as written with its key. Nothing is read back out of the
catalogue afterwards — the load job rewrites the whole mirror on every content deploy, and
without the copy a student who started ten minutes earlier is marked against questions they never
saw. `exam_answers.sealed` is read by exactly one query, the one that marks the paper.

**One open attempt at a time**, enforced by a partial unique index rather than by a handler. If a
second start drew a second paper, the way to pass would be to start, read, abandon and start
again until the questions were ones you liked — and every draw is an ordinary-looking row that no
report would flag. Starting again resumes.

**Nothing knows the result until the paper is handed in.** Answers may be replaced until then and
`correct` stays null throughout; marking happens once, at submission. So there is no endpoint
that could leak the result of a question the student is still looking at, and the reply to an
answer is `recorded` and nothing else.

**An unanswered question is wrong**, never excluded — a paper marked out of the questions
somebody chose to attempt would let a student answer the one they were sure of and score a
hundred percent.

**The pass mark is in code with a test on it** (K-13), and every attempt records the mark it was
judged by, so moving the constant changes what a new attempt must reach and nothing about an old
one. The comparison is `score * 100 >= PassMark * of` — integers, because a student sitting
exactly on the mark must not pass or fail depending on how a ratio rounded.

**A pass is never undone.** Sitting it again and failing does not unmake the day somebody knew
the material, for the same reason a finished section never un-finishes (A-05).

**Item analysis comes from the event stream, not from the attempts.** One `exam.item.answered`
per question at submission, because events survive an erasure orphaned — so a student asking to
be forgotten does not take the evidence about a bad question with them, while their attempts go
with them, as their own data should.

**A course exam is the course's door; a track final is every door in the track** — except at a
fork, where any one option being open is enough, since a student takes one branch and not the
others.

**A track's final lives beside the track**, in `tracks/<id>-exam.json`, because a track has no
lesson to put it in. The price of the convention is that `tracks/<x>-exam.json` with no track
`<x>` is a file nothing will ever read, so the loader refuses it (C-13).

---

## The interface

`ui/` is plain HTML, CSS and JavaScript with no build step, embedded with
`//go:embed` and served by the same binary as the API (P-03). One origin removes
CORS, keeps the session cookie `HttpOnly`, and removes the static host — and with
it the edge cache that handed the predecessor one module from before a deploy and
another from after.

**The routes are fragments**, `#/course/web-fundamentals`. Not a preference: the
offline bundle is one file opened from `file://`, where there is no server to fall
back to and the History API does not work. Choosing fragments now makes the bundle
a packaging job rather than a second router. The one real path is `/verify/<code>`,
because that address is printed on a certificate and typed by somebody checking a
claim.

**There is no catch-all.** An unknown path is a 404. A shell that rendered itself
at any address leaves somebody looking at an empty screen wondering what they
typed. `ui/ui_test.go` also holds the line that matters: the shell never answers
for `/api/v1/` — the two are one registration order away from swapping, and a
client asking for JSON and getting a page debugs the wrong thing all afternoon.

**Caching is the build, and an unstamped build offers nothing.** With no build step
there are no hashed filenames, so every file revalidates and every file's validator
is the release — one deploy invalidates all of them together. A build that cannot
say which build it is has no honest validator, so it sends `no-store`. Without that
rule every unstamped build shares the string `dev`, and a browser keeps the first
stylesheet it ever saw; that is not hypothetical, it is what happened on the first
run and it made an edit invisible.

**The palette is shared; the layout is not.** The custom properties at the top of
`app.css` are byte-for-byte the showcase's, because a student who learns one school
should recognise the next (N-07). The rest is this application's own — copying a
marketing page's thousand lines so that one file could be called shared would give
us a shared file nobody dares edit.

**The key is the English string**, so there is no `en` dictionary — it would be an
identity map. `tools/check-interface` fails on a string with no translation **and on
a translation nothing says any more**, because a stale entry reads as current. A
string that is the same in both languages gets an entry mapping to itself: that
says somebody decided, where an absence says nobody looked.

**Server messages go through `txt()` too.** They arrive in English, English is the
key, so they can be translated by adding an entry. The checker cannot see them —
they are written in Go — and that is the known edge of what a static check reaches.

**Focus is moved on navigation and not on the first render.** After a navigation,
moving focus into the content is what tells a keyboard user the page changed. On
the first render there has been no navigation, and moving focus puts the skip link
and the whole chrome *behind* the user — the skip link then cannot be reached going
forwards at all, which is the exact thing it exists to fix. Found by pressing Tab.

## The certificate, and the page anybody can check it on

**The pass is the fact; the certificate is the document.** Passing is on the attempt and nothing
in `internal/certificate` can change it. What that package writes down is what the pass entitles
somebody to say about themselves.

**Everything it says is captured at issue** — the name, the title, the school. Nothing is read
live, because the catalogue moves: a course is renamed, and the load job prunes whatever the
files no longer carry. A certificate that read its title live would one day name something else,
or nothing. Same decision as `audit_log.actor_label`, for the same reason.

**A certificate with no name asserts nothing**, so there is no such thing. An account with no
name has still passed — that is on the attempt — and collects the document from the claim route
the moment it has one. `ErrNoName` is deliberately a distinct error and not a refusal.

**The code is the whole handle, so it is eighty bits from `crypto/rand`.** Verification takes no
account and no session: the code is the only thing between a stranger and the fact that a named
person studied a named subject, and enumeration is the attack. The alphabet is Crockford's
base32 — no `I`, `L`, `O` or `U` — because the code is read off a document and typed by a person,
and `I` against `1` is a support conversation with somebody who has concluded a candidate's
certificate is fake.

**Verification returns no score.** The page asserts that the person passed; the mark they passed
by is between them and the school, and a verification page that published it would be a page that
ranks people.

**It goes when the person goes.** A certificate carries a name and is readable by anybody holding
its code, so keeping one after an erasure request would mean publishing the name of somebody who
asked to be forgotten. It cascades with the account, and **an erased certificate verifies exactly
like a code that never existed** — answering differently would say one had been there, which is
the fact being erased.

**A certificate is never edited**, by trigger. Something that needs to change is a new
certificate, or none.

---

## Multi-tenancy, in practice

The school comes from the `Host` and is resolved once, in middleware. Business code does not
mention it. (P-01)

Every school-scoped table carries `tenant_id`, and every index on one leads with it. Row-level
security is deliberately **not** in place — the privacy boundary that matters is between
students, and that is `account_id`. Do not rely on the database to scope a query for you. (P-05)

Identity is global: one account for the whole platform, one subscription covering every school.
`subscription(account_id, scope)` exists so the scope can narrow later without a billing
migration. (N-01, N-02, N-03)

---

## Versioning

Semantic versioning, and **the tag is the one place a version is written**. Not a file, not a
constant — the git tag, stamped into the binary at link time by the release workflow. A wrong
version is worse than none, because it answers with confidence. (P-09)

*The predecessor kept the number in `index.html` and had the release workflow check the tag
against it. That was right there and is wrong here: Pages served the branch as it was, so there
was no build to stamp anything during, and the file was the only thing that could carry a
number. There is a build here. Keeping the file anyway would leave two places naming one
version — which is the shape of the mistake that failed this repository's first CI run, where
three places named a Go version and two agreed.*

So there is nothing to keep in sync. What `tools/release` checks is the tag against three
things that are not copies of it:

- **the shape** — `vMAJOR.MINOR.PATCH`, with no pre-release form, because `dev` is already
  every build that is not a release and `v1.2.0-rc.1` would be a third state meaning one of the
  two that exist;
- **the last release** — a tag that does not increase sorts wrongly for as long as the
  repository exists, and `v1.10.0` typed as `v1.1.0` is the way that happens;
- **main** — a release nobody merged cannot be reproduced from main, and the checks that gate
  main never ran on it.

`dev` is every build that is not a release, and it still reports its commit: during an incident
the question is which code is running, and a tag only answers it on the days there is one.

### Cutting one

```sh
git tag v1.2.0 && git push origin v1.2.0
```

That is all of it — there is no file to edit first, and editing one would be editing nothing.
The workflow refuses the tag, runs the same checks main is gated by (it *calls* `ci.yml`,
rather than repeating its steps), stamps the binaries, **asks the binary what version it is**
and compares that with the tag, and only then creates the release.

The API is versioned at `/api/v1/`. This is not ceremony: the **offline bundle** is a client that
may be months old and that nobody can update. (P-10)

---

## Before pushing

```sh
export GOTOOLCHAIN=local     # never let go download a compiler nobody chose
gofmt -l .                   # silence is the pass
go build ./...
golangci-lint run            # before the tests: it is what build and vet do not do
go run ./tools/validate-content   # the answer keys, not only the schema
go run ./tools/check-interface    # every string the interface says, in every language it claims
go test -race ./...          # needs SCHOOLING_TEST_DATABASE_URL and a real Postgres
```

And for anything in `ui/`, open it. `go run ./cmd/api` with a seeded school, then look at it in
a browser at more than one width, in both themes and both languages — three of the defects in
that directory were invisible to every check above and obvious in a screenshot.

**`GOTOOLCHAIN=local`, and it is the first line for a reason.** Left at its default, Go silently
downloads whatever version `go.mod` asks for, so a `go mod tidy` on a newer machine can raise the
directive and every local command keeps passing on a compiler that CI does not have. That
happened on the first pull request: the directive moved to 1.25, CI installed the 1.24 written
in the workflow, and the failure arrived as a linter complaining about a config file. The
version now comes from `go.mod` in every place that needs one — the workflow, the Dockerfile —
and `local` is what makes a mismatch say so on the first build instead of the last step.

`golangci-lint` refuses to run when the Go it was built with is older than the directive, so its
version is not free to lag behind either. Raising `go.mod` means raising it on the same commit.

The suites inherited from the predecessor still apply where their subject exists. Each one is
here because it caught something a diff did not show:

- the catalogue validator — broken prerequisites, cycles, track order
- the dictionaries against the catalogue
- the graph, rendered at six viewport sizes, checked for an edge crossing a card
- the modal, opened for every course
- the session suite, which answers the API itself and is the only place the client and the
  server can be seen to disagree
- the single-file bundle, **opened** and not merely built

And read the output. A suite that reports success through a pipe may be reporting the exit code
of the pipe. `gofmt -l` is the same trap in a different shape: it prints the files it would
change and **exits 0**, so the check is `[ -n "$(gofmt -l .)" ] && exit 1`, never `gofmt -l .`
on its own.

## A test does not own the database

`go test` runs packages **in parallel** against one database. So:

- **Never `TRUNCATE` a shared table.** It is not tidying up, it is deleting another package's
  rows halfway through its run.
- **Never seed a fixed unique value.** Two packages inserting the school `code` collide on the
  unique index, and which one loses is a matter of timing.
- **Scope every assertion to the rows the test wrote** — `WHERE tenant_id = $1`, not
  `count(*)`.

This reached CI as a duplicate key raised in two packages at once, after passing locally on
timing alone — which is worse than failing, because it means the suite was green by luck. The
third rule is the one that pays for itself anyway: a test asserting about its own rows is
saying something, and one asserting about the whole table is guessing.
