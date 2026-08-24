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
translations by position; both detach silently on an edit, and one of them shipped. (C-09)

**An id is written down, never worked out.** There is no derivation anywhere — not in the
loader, not in the validator, not as a fallback for a file that left one out. A topic with no
id is refused, and the message says what to write. A fallback that slugs the title is the
defect wearing a helpful face: it works, and it ties the identity back to the words.

**Everything has an opaque id. What is addressed has a readable slug as well.**

| | id | slug |
| --- | --- | --- |
| track | `tr-p00q6jw0` | `frontend` |
| course | `co-cbwm5kwa` | `statistics` |
| lesson (= topic) | `le-5he7q8tg` | — |
| section | `se-gy02rmmz` | `vps` |
| exercise | `ex-6yyzbgfd` | — |

Eight characters of Crockford's base32 (no `i`, `l`, `o` or `u`) behind a two-letter prefix.
The prefix is **for people, not for code**: it is there so an id in a log says what it is, and
nothing may branch on it — a `HasPrefix(id, "co-")` deciding behaviour is type information
smuggled inside a string.

A lesson and an exercise get no slug because neither is ever addressed: a lesson is reached by
its position in a course and an exercise is never reached at all. A field nobody reads is cost
without benefit.

**Inside `content/`, everything refers to everything else by slug** — `requires`, a track's
`courses`, its `links`, `continues`, the school's order. That is what keeps a pull request
readable: `"requires": ["python"]` can be reviewed and `["co-8k2p91xz"]` cannot. **`cmd/load` is
the one place that translates**, and past it nothing speaks slugs: the mirror, the API and every
record of what a student did carry ids. Names go in, symbols come out.

The consequence is the point: **a slug is free to change.** Renaming a course used to mean
moving somebody's work, because the one string was the address, the reference and the identity
at once. Now only the address moves.

**What this does not buy is a link that survives a rename.** The address carries the slug, so
changing one still breaks a bookmark exactly as before. What changes is that the student's WORK
no longer moves with it — and that is the half that cannot be repaired afterwards, because a
broken link is a 404 somebody reports and a detached progress row is a screen that looks fine
and is wrong.

Opaque is not decoration. A slug frozen from a title becomes false the moment the title is
edited — it then asserts something untrue, and the next person believes it. A code cannot lie,
cannot collide, cannot be re-derived by somebody tidying up, and is the same in every language.
It makes the rule above a guarantee rather than a habit, which is the same trade this codebase
makes with the append-only triggers and with `event.Dimensions`.

**The material is written by a machine and will be rewritten by one.** For the `code` school
the tracks, courses and topics are settled; the lesson prose and the exercises are scaffolding
and will be deleted and generated again to a higher standard. That plan is exactly why none of
them may be keyed by their words — rewriting a title is the intention here, not a hazard. The
other schools have no structure yet, which is why the format changed now rather than later.

**Order is declared, never inferred from the filesystem.** No numeric prefixes on directories.
`course.json` names its lessons in order; `lesson.json` names its sections. (C-10)

**A topic declares its id, and a lesson is a topic somebody wrote.** `topics` carries
`{ id, title }`: the id is the lesson id, what a progress row records, and the same string in
every language. The title is only what a person reads, and it is the half that gets rewritten.
A bare string is read — so the validator can say "this topic has no id, write one" instead of
the decoder saying the file is malformed — and refused.

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
  dimension as an argument. A dimension added later breaks every call site, which is the point —
  and `population` is the proof it works: adding it broke seven call sites, and each one had to
  decide what it actually knew rather than inherit a default.
- **`population` says whether the person is real or seeded**, and it is a dimension rather than
  a join for two reasons that each stand alone. Half the funnel is visitors with no account, so
  there would be nothing to join to; and erasing a person deletes the account row on purpose,
  which would turn every event they left behind from "a real student" into "unknown"
  retroactively. **A report that changes when somebody asks to be forgotten is not a report.**
  It is a word (`event.Real`, `event.Synthetic`) rather than a boolean, because
  `ForSchool(id, slug, plan, country, locale, false)` is a call site nobody can read.
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

An exercise names its `section` by **slug**, as everything inside `content/` names everything
else. It does not name a title, and it never did so safely: joining by title text is how the
predecessor lost exercises whenever a lesson was renamed. Its own id is opaque like the rest —
`ex-` and eight characters — because a student's answer records it, and a history has to survive
every rewrite the question's wording ever gets.

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

## One grader, and why there is not a second

**Marking happens on the server. Always.** A-09 used to promise two implementations — the client
grading for immediate feedback, the server grading exams, and a conformance test holding them to
each other. That is retired, and the reason is a rule that came to matter more:

**a question is PRESENTED rather than sent.** The key is removed and, where the order is the
answer, shuffled. A client that could mark an answer is a client holding the key — so the second
implementation could only have existed by undoing the thing that keeps an exam an exam.

The last place it might have lived was immediate feedback on a drill, and that is now server-side
too: the practice screen sends the answer and is told. The client never had a grader; what this
section used to describe was a plan, and it read as a fact.

Question types: `quiz`, `multiple-choice`, `ordering`, `matching`, `code`, `expected-output`,
`expression-answer`, `numeric`, `cloze`, `labelling`. Every type has a machine grader — that is
the entry requirement, not a nice-to-have. Free-text essays are out.

**`testdata/conformance` stays, and is now the contract between the grader and the questions.**
It is worth as much as it ever was, for a different reason: each file is a question with the
answers that should pass and the answers that should fail, so a change to a grader that alters a
verdict has to change a file somebody wrote deliberately. A gradable type with no fixture fails
the build — "I will add the fixture afterwards" is the door a silent behaviour change walks
through.

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

### `expression-answer` samples, it does not rearrange

The computer algebra system the plan asked for is `expr.go` and `expression.go`, and it is
neither large nor a dependency. Two expressions over the reals are equal if they agree
everywhere, and everywhere can be sampled: parse both, evaluate them at two dozen chosen points,
compare. Two different polynomials of degree n agree at most at n points, so a wrong answer would
have to agree with the right one at every sample to be accepted.

Four things about it are decisions rather than details:

- **It refuses what it does not understand.** A parser that skipped an unknown character would
  mark `x + y` and `x @ y` the same. `wibble(x)` and `sin x` are errors with their own sentences,
  the second because implicit multiplication would otherwise read it as `sin * x` and complain
  about the wrong thing.
- **A typo is `ErrBadAnswer`, not a wrong answer.** An unparseable answer is a slip the student
  can see on their own screen; recording it as a failure would put it in their history and, in a
  drill, move a schedule.
- **A disagreement needs one point; an agreement needs many.** One sample where the two differ
  settles it. Agreement is only trusted after `usablePoints` of them — otherwise a question whose
  range is undefined nearly everywhere would accept anything, having compared almost nothing.
- **The sampling is fixed, never random.** A student told they were right on Tuesday and wrong on
  Thursday cannot find out which was the mistake. Two variables get different offsets, or every
  question about two letters would be a question about one.

What it cannot see is **a difference at a single point** — `x` and `x + 0*(1/x)` differ only at
zero, and no finite set of samples lands there. That is written down in the package and pinned by
a test, so it is a trade somebody chose rather than a surprise somebody finds.

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

**A course's pictures live in its `images/`, and belong to the COURSE rather than the lesson.**
That is not where a file naturally wants to sit — a diagram belongs beside the words it
illustrates — and the reason is who renders a question: today, only the exam paper. A lesson's
exercises are in the model and in the mirror and on no screen at all, so a picture scoped to a
lesson would have been a picture no student could ever reach, and `labelling` would have shipped
unreachable. An exam question belongs to a course and to no lesson; scoping the picture to the
course covers both, and lets two lessons share a diagram.

The bytes go into `catalog_images` and out again as a response body, because the deployed image
is a `scratch` container with no content directory beside it — and because the offline bundle has
no network, where a picture that fails to load is a question nobody can answer. A **track** final
still cannot carry one: a track is a single JSON file with no directory, and the checker says so
by name rather than letting the question reach a screen.

The orphan rule runs in both directions here as it does for prose: a question naming a picture
that is not there fails, and a picture no question labels fails (C-13).

---

## Drilling is not progress, and the two must never meet in one number

`section_progress` answers **what have I done** — set-true, never toggled, and what a progress
bar reads. `practice_state` answers **how well do I still know this**, and it DECAYS: a card
strong in March is due again in June, because that is what remembering does.

A bar built from both falls for a student who did nothing wrong, which is the most demoralising
thing a study platform can do (A-05). The module graph stops the packages importing each other;
a **source scan** stops either reaching the other's table, because the coupling that would do
the damage is a SQL string and no import graph can see one. The same scan keeps practice out of
`certificate` and `exam`: a certificate says an exam was passed on a day, and drilling is not an
exam.

**The quality score is derived, never asked** (A-04). SM-2 wants a 0..5 self-rating; a person
rating their own recall rates their mood, so this uses what the platform observes — whether the
answer was right, and how long it took. Only four of the six values are reachable, and that is
honest rather than incomplete: the 0..2 band separates "no idea" from "recognised it once
shown", which only the student can tell you.

**The ten and forty-five second thresholds are a first guess.** They are roughly right for a
quiz and roughly wrong for a `labelling` question. This is exactly why `practice_review` has
been written since Fase 0 carrying the values from BEFORE each answer: a better scheduler is
fitted by replaying what was known at each point, and that needs history that only exists if it
was being recorded all along. Changing them changes `scheduler` in that log too.

**A practice answer is marked by the server, like an exam.** It was the client's word for one
commit and that was wrong twice over: a client cannot know — the question it is given has no key
in it — so `correct` over the wire could only ever be an assertion nothing checked, and it put
the one piece of grading in this system outside `internal/grade`.

Which means the SHUFFLE HAS TO SURVIVE THE ROUND TRIP. A question is presented rather than sent,
and for `ordering` the permutation IS the answer; an answer marked without mapping it back tells
a student who put four steps in perfect order that they are wrong. An exam keeps the permutation
on the attempt. Practice has no attempt, so `practice_drawn` holds it — one row per card, replaced
on every draw, read once and never again. Deriving it from a seed instead does not work: anything
the server can derive from the account, the exercise and the day, the client can derive too, and
making it safe needs a per-deployment secret to avoid one table.

**A malformed answer is not a wrong answer.** Recording one as wrong moves a schedule on the
strength of a client's bug: a card the student never failed comes back tomorrow, and the review
log carries a failure that never happened.

**THE KEY COMES BACK WITH THE VERDICT, AND NEVER BEFORE IT.** A card is drawn without its answer,
so the drill screen could not mark it if it wanted to; `grade.Expected` produces the key only
inside the same call that marks the answer, in the frame the student was SHOWN — walking the same
permutation the draw wrote down. Send the written frame instead and the tick lands on choice 2 of
a list that is in a different order on their screen: a student who was right is shown their own
answer marked wrong, and it looks like the grader rather than the arrangement.

Four types need it — `quiz`, `multiple-choice`, `ordering`, `matching`. The rest are revealed by
their own renderer out of what it already has, because nothing about them was shuffled, and
`Expected` answers an empty reveal rather than an error: "nothing to add" is a real answer.
`present_test.go` turns every reveal back into an answer and grades it, so a reveal that points at
the wrong thing fails the build.

**One answer per card.** No "try again" in a drill, unlike a lesson: the schedule moves the moment
the answer lands, so a second attempt would be a second answer to a card already counted, and the
interval it earned would be whichever try the student happened to stop on.

**The queue does not cross schools yet.** A request arrives on a school's host and is scoped to
it by the middleware before any module sees it, so a cross-school queue needs the platform's own
address — which needs the domain. Writing it as a query that ignored the tenant would be
building the thing the tenancy test exists to make impossible.

---

## The interface

`ui/` is plain HTML, CSS and JavaScript with no build step, embedded with
`//go:embed` and served by the same binary as the API (P-03). One origin removes
CORS, keeps the session cookie `HttpOnly`, and removes the static host — and with
it the edge cache that handed the predecessor one module from before a deploy and
another from after.

**The routes are fragments**, `#/course/web-fundamentals`. Not a preference: the
offline bundle is one file opened from `file://`, where there is no server to fall
back to and the History API does not work. The one real path is `/verify/<code>`,
because that address is printed on a certificate and typed by somebody checking a
claim.

**The bundle collected on that bet.** `go run ./tools/bundle -host <school host>`
asks a running server for the interface, the stylesheets, the fonts and the whole
catalogue and writes one HTML file. Opened from `file://` it reads everything and
asks nobody for anything; served from the school's own address it is the
application again, signed in, because then it IS on that origin. **One client, not
a reader and an application that drift apart** — that is what the fragments bought.

Three things it does not do, and does not pretend to: signing in, progress and
exams. They are the school's record of a student and a copy of a file has neither;
`api.js` answers `no-server`, and `offline` is exported so a screen refuses BEFORE
it shows a form rather than after somebody has typed a password into it.

`tools/bundle-test` opens it. Built is not the claim — every way the bundler can
fail produces a file that exits zero and opens to a blank screen — and it counts
the requests, because "asks nobody for anything" is invisible in the markup and
visible in the network log.

**Nothing in the shell comes from another origin**, and the type is why that rule
exists. Three families used to be fetched from a font CDN on every page load —
which told a third party which school a student was reading before anything had
rendered, left the offline bundle with no way to look like the site, and made two
machines measure different cards: the graph test failed on the build machine at
two window sizes and on none in the sandbox, because one could reach the CDN and
the other could not. `go run ./tools/fonts` brings the faces in; it is run by
hand and it is the only thing here that touches the network. A test over the
shell fails on any absolute or scheme-relative address, because the way this gets
undone is one convenient `<link>` in a hurry.

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

**Three stylesheets, and which one a rule goes in is not a matter of taste.**
`base.css` and `portal.css` are `portal-frontend`'s **byte for byte** — a diff of
either being empty is what made the duplicated-stylesheet bug findable at all, so
nothing is added to them here, not even a fix. `app.css` may only **override**, and
every override in it is a WCAG failure in the copied file, argued in place and small
enough to re-apply after the next copy. Anything that is neither — the styles for a
question type the portal does not have — gets a file of its own, which is what
`exercises.css` is.

An accessibility fix to a copied element went into `portal.css` once. It worked and it
was still wrong: it ended the invariant that makes the next such bug visible.

**"Override" means a colour, not a `display`.** `app.css` is loaded last, so a layout
property written there against a class name the copied stylesheet already uses wins on
every element of the copied markup carrying it — on screens the change was never about,
invisibly in a diff. An enrolment list styled as `.steps` laid out every lesson's row of
section tabs as a column, and `.steps` in `portal.css` is that row. `tools/check-css`
now fails on exactly that: a layout property, on a class of theirs, with nothing of ours
in the selector to hold it to our screen — which is why `.view-account .on` is allowed
and a bare `.steps` is not. A new screen's own element gets a name of its own.

**Anything that differs between schools comes from the school, not from a file that
ships with the application.** Its name, its accent, the address of its own site, what
a subscription costs there. Each of those was a constant in a copied file first, and
each looked correct on the school it was copied from — which is why they survived: an
account menu linking every student to codeschool.ing and an invitation quoting `R$ 490`
to a school that charges euros are not screens anybody reports as broken.

**A colour somebody else chose still has to be readable** (X-05), and no colour is
readable in both themes — that is arithmetic, not caution. The two page backgrounds are
far enough apart that the best any colour manages against both is 4.17:1, where AA asks
4.5. So a school's colour is its **hue**: `ui/app/accent.js` uses the accent where it
reads and moves it along its own lightness where it does not, measured per theme
against **every surface it lands on** — the page and the panel, because a card is
lighter than the page behind it and half this text is on a card. It says in the console
what it moved and why. The fixture the browser suites seed carries an accent that is
not the palette's, so axe measures the applied colour rather than the one it replaced.

**The key is the English string**, so there is no `en` dictionary — it would be an
identity map. `tools/check-interface` fails on a string with no translation **and on
a translation nothing says any more**, because a stale entry reads as current. A
string that is the same in both languages gets an entry mapping to itself: that
says somebody decided, where an absence says nobody looked.

**A dictionary translates the INTERFACE and never the catalogue.** The dictionaries
carry the words this application says — buttons, headings, the sentence above a form.
A course's name, summary, syllabus and topics belong to a school, and they come from
that school's own files: `courses/<id>/course.<locale>.json` beside `course.json`, and
`tracks/<id>.<locale>.json` beside the track. The server answers them per request,
which is why every catalogue route takes `?lang=`.

It was a dictionary once, keyed by codeschool.ing's course ids — and for that school
it looked right. For any other one, every course came out in English on a Portuguese
page and **nothing looked broken**, because a missing key falls back to itself and the
key is the English text. A school's content cannot live in a file that ships with the
application.

**A translation carries what somebody translated and no more** (C-11). Every field is
optional and falls back on its own: a course translated in its name and not its
summary keeps the English summary rather than losing it. Absent is not empty — in the
JSON, and in the `COALESCE`/`NULLIF` that reads it back.

**A fork's translation is keyed by POSITION, because a fork has no id.** It is the one
join in the catalogue a reordering can break in silence: insert a step and every fork
after it moves while the translations stay put, describing a different choice in
perfect Portuguese. `validate-content` fails on the symptoms — a translated position
that is not a fork, and a list of option names a different length from the fork's.

**A QUESTION IS TRANSLATED AND ITS ANSWER KEY IS NOT.** `exercises.<locale>.json`
sits beside `exercises.json`, keyed by the question's id, and carries only what a
student reads: `prompt`, `hint`, `trap`, the option texts and the reasons they are
wrong, the items of an ordering, the two halves of a pair. `correct`, `accept`,
`value`, `tolerance` and a label's coordinates are not nameable in it — a file that
mentions one is refused, because a translation that could reach the key would mark
the same answer differently in two languages and **nobody would find it**: both
screens read perfectly well on their own.

`cmd/load` merges each translation over the English and writes a COMPLETE payload
per locale, so the grader, the presenter and the offline bundle each take one
payload and never ask which language it is in. Merging in every reader instead
would mean one of them forgetting, and a screen half translated.

**Inside an exercise the lists join by POSITION**, which is forbidden almost
everywhere here and right in this one place: the answer key is `choices[2]` and a
student's answer records the index they chose, so position is already the identity
and an exercise is immutable within its `version`. A translated list of a different
length is the symptom of an insert, and `validate-content` fails on it.

**Server messages go through `txt()` too.** They arrive in English, English is the
key, so they can be translated by adding an entry. The checker cannot see them —
they are written in Go — and that is the known edge of what a static check reaches.

## The track graph

**Ported from the predecessor rather than reinvented.** The hard parts were paid for
once: the ordering that minimises crossings, and the router that takes a line around a
card instead of through it. What changed is the data and the comments.

**Nothing is pinned per track.** The order inside each column is measured — the drawing
that comes out is scored — so a track added tomorrow lays out as well as one added
today. Sugiyama's method in three pieces, and the third is the one people leave out:
barycentre, then transposition **accepting the tied swaps** (that is what unlocks the
arrangements which only improve by moving two columns at once), then several starting
orders because the first two are greedy. The shuffle is seeded, so a track does not
change shape between visits.

**The cost is three numbers compared in order, never summed** — crossings, then upward
bias, then the curriculum's order. Summing would let a lesser criterion buy an extra
crossing.

**A fork is one node.** It is a decision, and drawing three boxes where the student
takes one would say the track is three times as wide as it is.

**The router runs in one axis and serves both.** Everything in it thinks the graph goes
left to right; flowing downwards, the boxes go in with x and y swapped and every point
comes back swapped. So "the lane above the cards" is the margin to their left, and not
one line of the routing is written twice. Under 900px the track flows down, because
seven levels laid out sideways on a phone is a drawing you read by dragging.

**Whether a line is blocked is geometry, not a count of skipped levels.** Counting
missed the case where a column splits and a neighbouring card sits in the corridor —
with the edge joining *adjacent* columns, so no count would have flagged it.

**The edges are measured off the boxes the browser produced**, not from positions this
code guessed — which is why the drawing survives a different font, a longer name and a
narrower window. It also means nothing in the graph may be positioned with a transform:
a transform moves what is drawn without moving what `getBoundingClientRect` reports.

**`tools/graph-test` checks the drawing, not the code that made it**: every track, six
window sizes, each line walked point by point through the SVG the router produced. It
does **not** check whether two lines cross each other — the ordering minimises those and
a graph can be non-planar, so demanding zero would be demanding the impossible. A line
through a *card* is always avoidable, which is why that is the one it fails on.

## Every screen goes through axe

**WCAG 2.2 AA, checked by a machine on every run** (X-05). Cheap now and a rewrite of
every screen later — and here the aggravation is particular: this is an education
product, so a screen a reader cannot operate is not a degraded experience, it is a
student who cannot study.

**In both themes.** Contrast is the most common failure and the light theme is a
different set of colours entirely; a palette that passes in the dark and fails in the
light is one `data-theme` away from shipping. It found exactly that on its first run:
`opacity` on a locked card took its own text to **4.09:1** dark and **3.32:1** light,
where AA asks for 4.5. Fading something to say "you cannot have this" makes it harder
to read for everybody and hardest for the people already struggling — locked is a word
and a dashed border now, never a fade.

**What it cannot check is still somebody's job.** axe finds what is decidable from the
document: contrast, a missing label, a heading that skips, an absent landmark. It does
not find whether the focus order makes sense, whether an error is announced when it
appears, whether a name describes what a control does. Saying so is the difference
between a check and a claim of compliance — which is why the interface also carries
what axe cannot see: the skip link, focus moved on navigation and not on first render,
Escape closing a picker, `ordering` on buttons rather than a drag.

**There is no modal test, because there is no modal.** The predecessor showed a course
in one, on a marketing page; here a course is a screen. An inherited suite applies
where its subject exists, and inventing a modal to have something to test would be the
tail wagging the dog.

**Editing anything in `ui/` needs the server restarted.** `//go:embed` bakes the files
into the binary at build time, so a running process serves the interface it was built
with. It cost twenty minutes once: a fix was in the file, the browser had the old one,
and everything else looked right.

**Sitting an exam: the paper is the server's.** The screen draws what it was given,
records each answer as it is made, and hands in. It keeps no copy of the questions,
computes no mark, and cannot know which answer is right — that is the whole point of a
question being *presented* rather than sent.

**Every answer is sent as it is made**, not collected and posted at the end. A closed
tab, a lost connection or a flat battery costs the questions that were not answered,
not the ones that were — and it is what makes resuming real. Reopening a paper puts the
answers back into the controls, because a paper that came back blank would tell somebody
their work was gone when it was not, and they would do it again on a clock.

**Ordering is buttons and matching is a select, and that is the accessible choice rather
than the cheap one.** Dragging is what everybody builds and it is operable by exactly one
kind of person. Two buttons per row and a native select are operable by everyone, are
already announced correctly, and are less code. A button fires no `change` event, so
`ordering` dispatches one — without it the arrangement saved nothing as it went.

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

## The funnel counts people, not identities

The top of the funnel is browsers and the bottom is accounts. **Counting each step by whichever
identity its event happened to carry would make somebody who arrived on Monday and subscribed on
Friday two people**, and the conversion rate a ratio between two different populations — falling
as the product gets better.

So a person is defined once, in `personOf`: **an account where the identity is linked to one, and
the visitor otherwise.** That is what `account_visitors` is for, and it is why the visitor has an
identity before the account exists at all (K-10). One person on two browsers is one person; forty
lessons opened is one lesson step.

**A step with no event is not a step with nobody.** Two of the eight cannot be emitted —
verifying an address has no feature, subscribing has no gateway — and `Measured` is a field of
its own rather than `People == 0`, so a screen cannot show a missing feature as a total
drop-off. It is the same rule as `insufficient` in item analysis, and for the same reason.

The order of the steps is written down rather than derived from what the stream contains: a
funnel that hid its empty steps would hide exactly the drop somebody is looking for.

Three modules meet in `cmd/analyse` to produce it — `event` reports who reached what, `visitor`
says which browsers belong to which account, `analysis` decides who is who. None of them reaches
into another's tables.

---

## Item analysis, and what a number is not allowed to say

There is no human reviewer. Two things stand between a wrong answer key and a student: the
content check, which runs every key back through the grader before publication, and
`internal/analysis`, which reads how people actually answered.

**The discrimination index is the one that earns its place.** Difficulty tells you a question is
hard; it cannot tell you whether it is hard or wrong. The index asks whether the students who did
well on the paper got THIS question right more often than the students who did badly — and a
question the strong students fail is not difficult, it is a wrong key or an ambiguous prompt.
That is the only failure this system can find without a person.

Four rules, each a test:

- **Nothing is decided below the minimum sample**, and `insufficient` is a member of the verdict
  list rather than the absence of one — a screen cannot show an unmeasured question as though it
  had passed. The index is not even computed below the sample: a number on a screen is read as a
  finding whatever the label beside it says.
- **An index of zero is not always a measurement.** When the paper separated nobody there are no
  two groups to compare, so the answer is `insufficient` rather than `weak`. Reading it as weak
  blames the question for the paper — and getting this wrong was the first mistake here, caught
  by working the edges by hand after every test passed.
- **A tie at the group boundary takes everybody on it.** The boundary is a score, not a position,
  so the same answers give the same verdict whatever order they arrive in. A question quarantined
  by a `sort` is not a finding.
- **Two versions of a question are two questions.** Folding them would average a wrong key with
  the fix that corrected it, hiding the fix behind the answers given before it.

**The threshold travels with the number it produced** (K-16) — stored on the row, not looked up
when it is read, or a verdict computed under a minimum of thirty would explain itself with
whatever the constant says today.

**A flagged question goes out of circulation on its own**, and that is the strongest thing this
system does without a person: it removes a question from a course while nobody is looking.
Waiting for somebody to read a list is the same as not acting — the list is read on the days
somebody remembers — so the safety is in the threshold rather than in a person:

- **Only `inverted` triggers it.** Never difficulty, never a verdict below the sample.
  `Quarantine` refuses anything else, so the one caller that could widen it cannot.
- **It leaves the exam draw and the drill queue, and comes out of the denominator** of a paper
  already in progress. Still marked, because the paper is a record of what was asked; not
  counted, because nobody should fail on a question we have admitted is broken. Two students
  with the same paper can be scored out of different totals when a quarantine lands between
  their submissions — that is right, and the alternative is marking the second one on a question
  we had already withdrawn.
- **An exam whose whole pool is withdrawn refuses to start.** A paper of nothing would be passed
  — the score is out of what was asked — and a certificate would follow.
- **The quarantine is keyed by version**, so a new version is not under the old one. Fixing the
  question is the ordinary way out and nobody has to remember to release anything. Releasing is
  the override, needs a reason, and a later sweep puts it back out if the numbers still say so.
- **It lives in its own table, never on `catalog_exercises`.** That is a mirror the load job
  owns (C-01); a flag there would be overwritten by the next load, and it would put a fact about
  our observation inside a copy of what somebody wrote.

Every transition is audited with the numbers that decided it, actor `system: item analysis`. **A
quarantine whose audit entry fails to write is an error, not a silence** — the row is already
there by then, and swallowing it would leave a question gone from a course with nothing saying
why.

**The stream is the truth and the rollup is a cache.** `cmd/analyse` recomputes from `events`
rather than resuming, because a resumable job merges new answers into stored counts and a merge
is where a double-counted event lands — the one failure that would condemn a question nobody
complained about.

`internal/event` reads the rows and `internal/analysis` decides what they mean; the two meet in
`cmd/analyse` and neither touches the other's tables. The same split as the catalogue's: it
answers which door a plan opens and does not decide which plan somebody has.

**And the schedule is `infra/scheduler.tf`, at 03:10 São Paulo time.** That is worth a line
because the paragraph above it was true of the design and false of the deployment for as long as
this command existed: the comment said it ran on a schedule, and there was no job and no
scheduler. It had never run in production once — so the rollup the console reads had never been
written, and the sweep that withdraws a broken question had never withdrawn one.

Two things to take from that, neither of which is about Terraform. **A comment describing
machinery is a claim**, and a claim in this repository is held by something or it is decoration.
And the console's item analysis is the only reason it was findable: it draws *"no rollup has been
made"* as its own screen rather than an empty table, and an empty table would have read as a
platform whose questions are all fine. A screen that says what it does not know finds things a
screen showing zeroes never will.

---

## The privacy policy is checked against the registry

`internal/privacy` already guarantees that no table exists without somebody having decided what
it holds. **`internal/legal` is the layer above: no table holding personal data exists without
the published policy accounting for it.**

Each document carries a `covers:` line in its front matter naming its tables, and
`TestThePrivacyPolicyAccountsForEveryTableThatHoldsPersonalData` compares that against
`privacy.Registry`. Every language must cover exactly the same set — compared against English
rather than against the union, because a union lets one language carry a table the other omits
and still pass.

It is the same failure shape as an unclassified table, one layer up and worse. A table nobody
classified fails CI. A table nobody wrote into the policy fails **nothing**: the document keeps
rendering, keeps looking finished, and is quietly wrong from the day the migration lands. Nobody
rereads a privacy policy against a schema.

The list is in the front matter and not in the prose, because a person reading a privacy policy
does not want a table name. The check is exact; the reading is human. The `covers:` field is
`json:"-"` and there is a test that it never reaches a browser.

**The test lives in `internal/architecture_test.go`**, because `legal` and `privacy` are both
modules and modules do not import each other — including in tests, since the graph check reads
`TestImports` too. That file is not in a module and is the one place both can be seen at once.

Two more rules about the documents:

- **They are readable with no session and no school.** A privacy policy only a signed-in student
  can read is one nobody can read at the moment they are deciding whether to hand over an e-mail
  address. They are baked into the offline bundle for the same reason, and the bundle test
  asserts they do *not* say "this needs the school" — the one deliberate exception to everything
  else in that file.
- **What is not filled in is a `{{token}}`, not a sentence saying it is missing.** One thing is
  left: the company itself — `{{company.name}}`, `{{company.registration}}`, `{{company.address}}`
  and `{{company.contact}}`, in all four files. Filling it in is a search and replace, and the
  test checks the token **set matches across languages** — because the way search and replace
  actually fails is that it is done in English, the tests pass, and Portuguese still carries the
  token. A second test asserts a placeholder still exists at all; when the company is real, that
  one is deleted on purpose. The moment nobody asserts a `{{…}}` exists is the moment nobody
  notices one does.

  It is a token in the file rather than a setting because the company's name is a fact with a
  right answer that simply is not known yet, and **only something without a right answer becomes
  a parameter** (K-13). A setting here would be a knob whose one correct position is a value that
  a wrong environment variable publishes a policy against the wrong company with.

**The decided half is Brazilian.** The terms are governed by the Consumer Protection Code and a
dispute is heard where the student lives; the refund window is the statutory seven days and
nothing beyond it, said out loud rather than left to be discovered; a price change carries 30
days' notice and happens at most once in twelve months. The privacy policy names the LGPD and
the ANPD. None of that is a placeholder — it is the answer, and changing it means changing a
policy rather than filling in a blank.

---

## Money

**Every amount is an integer number of cents, and `billing.Money` is the only way to hold one.**
Its fields are unexported, so there is no `amount.Cents * 1.1` to write anywhere here; its zero
value is invalid, so an uninitialised total cannot add cleanly to a bill in any currency. Parsing
a price never goes through a float — `strconv.ParseFloat("1199.90")` × 100 truncates to a cent
below what the page says.

Two operations can lose a cent, and both have their rule written down where they are:

- **`Split`** distributes the remainder instead of dropping it, so twelve instalments add back up
  to the year. The odd cent goes on the EARLY instalments, which is what a card issuer does and
  keeps the final one from being the number a customer compares against their quote.
- **`Percent`** takes basis points, not a float, and rounds half away from zero — the rule a
  person checking the invoice by hand uses.

**The ledger records money that MOVED, and never what somebody owes.** Access is computed from
the subscription; a ledger that also answered "may they study" would be a second place the
paywall could be read from, and one of the two would be wrong first. It is not double entry,
because the second side would be a constant: splits, payouts and school-to-platform billing were
all cut from this system before it was built.

Three things hold it together, and each is a test:

- The table refuses UPDATE and DELETE by trigger. **A correction is a new row**, pointing at what
  it reverses, in the opposite sign and the same currency, never for more than is left
  un-reversed — checked inside the writing transaction with the original row locked, because two
  refunds arriving together would otherwise each see the payment as untouched.
- **Idempotency is a unique index on the row the money is on**, not a table checked first. A
  gateway retries a webhook whenever it does not hear back in time, so a duplicate delivery is
  the normal case; check-then-insert is a race, and a constraint is not.
- **`ledger_entries` has no foreign key to `accounts`**, like `events` and `practice_review`.
  It is the only arrangement that meets both obligations: the record that money changed hands is
  a tax obligation and cannot go on request, and the identity that makes it somebody's can. After
  an erasure the row is still there and joins to nobody. CASCADE would destroy accounting
  records; RESTRICT would make erasure impossible for everybody who ever paid.

The payment gateway is still an open decision (it has to cover international recurrence,
Brazilian instalments and Pix at once). Nothing above depends on the answer, which is why it
could be built first — and building it first is the only way it gets built properly, rather than
as a refactor of every call site performed under the pressure of a number that came out wrong.

---

## Two subscription state machines, and why not one with a flag

**A card instalment plan is one authorisation, split by the issuer.** We are paid once. What the
customer sees as twelve monthly lines is an arrangement between them and their bank, and we never
learn whether any individual line was collected. So there is no monthly payment to fail, nothing
to retry, and **nothing to suspend** — and `Advance` REFUSES `payment-failed` and
`retries-exhausted` on an instalment plan rather than ignoring them.

That refusal is the whole design. Written as one machine with a flag, the instalment plan
inherits a grace period and a suspension path its payments cannot trigger: dead states on one
model, waiting for somebody to wire an event into them.

Real recurrence is the opposite — a charge is attempted every period, it can fail, it is retried,
and access is eventually cut. **Grace and suspension exist only there.**

Four rules that are each a test:

- **Grace still opens the door.** Most declines are a bank flagging a routine transaction, and
  the retry schedule exists because most recover. Access is cut when the retries run out.
- **A recurring subscription never expires by time alone.** One that lapsed because a webhook was
  late would be a paying student cut off for our own outage.
- **Cancelling honours the paid period.** Cutting on the day is taking money for a period and not
  delivering it. A refund or a chargeback does cut immediately, and those two are separate events
  even though the access outcome is identical: one is an agreement, one is a dispute.
- **`Opens` never reads a clock.** A cancelled subscription past its period opens nothing because
  `Settle` moved it, not because `Opens` compared a date. Two places that both decide access from
  the calendar are two places that can disagree.

**Reading settles in memory; the job settles the row.** That split is deliberate: the paywall
must be right at the instant it is asked, with no window every night in which somebody keeps
access they stopped paying for — and the row still has to match eventually, or a report counts
cancellations that ended weeks ago.

`planOf` in `cmd/api/main.go` is **the only place `catalog` and `billing` meet**, which is the
module rule (X-02) and also why neither ever had to know about the other: the catalogue decides
which door a plan opens, billing decides which plan somebody has. It fails closed on an
unreadable database — an outage that quietly makes every paid course free is the one failure a
paywall cannot have, and unlike an unreadable catalogue it shows the student something that
works.

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
go run ./tools/check-css          # our stylesheet overrides theirs and never lays it out
go test -race ./...          # needs SCHOOLING_TEST_DATABASE_URL and a real Postgres
```

And for anything under `infra/`, the same two commands CI now runs. `validate` and not `plan`:
a plan needs credentials and a state file and asks Google what exists today, which is a
different question from whether the configuration is coherent.

```sh
cd infra
terraform fmt -check -recursive
terraform init -backend=false && terraform validate
```

The three browser suites need a server and a school to look at, which is what
`tools/graph-test/fixture.sql` is for until `content/` has one:

```sh
npm ci && npx playwright install chromium
go run ./cmd/migrate
psql "$SCHOOLING_DATABASE_URL" -v slug=graphtest -v host=code.example.tld \
  -f tools/graph-test/fixture.sql        # it takes its school as a parameter
go run ./cmd/api &
node tools/graph-test/graph-test.mjs    # no line through a card, six window sizes
node tools/a11y-test/a11y-test.mjs      # axe over every screen, both themes —
                                        # the console too, on its own host. It
                                        # grants itself an operator through
                                        # `cmd/staff`, so this one needs the
                                        # database as well as the server.

node tools/mfa-test/mfa-test.mjs        # enrol a second factor, sign in with it,
                                        # then again with a recovery code

go run ./tools/bundle -host code.example.tld -out bundle.html
node tools/bundle-test/bundle-test.mjs bundle.html   # opened, not merely built
```

And for anything in `ui/`, open it. The shortest way is the local stack, which migrates, creates
two schools and seeds the same fixture into `code`:

```sh
docker compose -f deploy/local/docker-compose.yml up --build   # http://code.localhost:8080
```

`math.localhost:8080` is left empty on purpose — it is the control that makes a lookup answering
with the wrong school visible. Then look at more than one width, in both themes and both
languages: three of the defects in `ui/` were invisible to every check above and obvious in a
screenshot.

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
