# schooling

One e-learning platform running several independent schools — one per subject, all of them ours —
with the material written and checked by machine rather than by a person.

| school | address | state |
|---|---|---|
| programming | `code.example.tld` | migrating from `codeschool.ing` |
| mathematics | `math.example.tld` | second |
| physics, chemistry, music theory, languages | — | ordered by how well a machine can check an answer |

The platform domain is provisional — see *The name* in [`docs/PLAN.md`](docs/PLAN.md).

---

## The documents

| | what it is for |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | the rules the code has to obey, in the imperative. Read this before writing a line. |
| [`docs/PLAN.md`](docs/PLAN.md) | why each rule exists: 100 decisions with their reasoning, the open questions, the shape of the phases |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | what each phase is made of, as capabilities to tick off |
| [`docs/CONTENT.md`](docs/CONTENT.md) | the shape of `content/`, what CI checks, what happens when a question turns out to be bad, and how much material a course has to carry — the decisions it settled are C-26 to C-28 |
| [`docs/EXERCISES.md`](docs/EXERCISES.md) | what makes a question worth asking rather than merely well formed: the ten ways a question leaks its answer, why difficulty belongs to the thinking and never to the options, and why discrimination is the axis that matters |
| [`docs/TEACHING.md`](docs/TEACHING.md) | how the material itself is written — when a second explanation is not repetition, when a diagram earns its place, and what goes in a spoken script |
| [`docs/CONSOLE.md`](docs/CONSOLE.md) | what the console is, whole, and the order it arrives in — the decisions it settled are K-17 to K-22 |
| [`docs/VIDEO.md`](docs/VIDEO.md) | how video is **made**, hosted, delivered, protected and measured, what it costs, and what was deferred or refused — the decisions it settled are P-11, P-12, C-18 to C-20, C-29 to C-36, K-23 and K-24 |
| [`docs/RELEASES.md`](docs/RELEASES.md) | how a course is published as one versioned set, what major/minor/fix mean, and what happens to a student mid-course when the structure changes — the decisions it settled are C-21 to C-25, N-11, K-25 and K-26 |
| [`docs/design/`](docs/design/) | one sheet per course, written before its material: how much of everything it carries, what it may assume from the courses before it, and what it needs that does not exist yet. **All 122 of them**, one with its sections designed — and what the finished sweep found, which is four kinds of blocker of which only one is a sandbox |
| [`infra/README.md`](infra/README.md) | the project this runs in, and the runbook for it: the bootstrap, the database, a school, an address, monitoring |

`CLAUDE.md` is normative and `PLAN.md` is historical. If they disagree, the code follows
`CLAUDE.md` and `PLAN.md` is what needs fixing.

**Two rows used to sit here promising documents that were never written** — `docs/adr/`, one
decision per file, and `docs/DEPLOY.md`, "the runbook — arrives with phase 0". Neither exists, and
neither was a link, which is why the check that walks every relative link never said so.

What they promised is not missing, though, which is the argument for saying this rather than
writing them late: the decisions are `PLAN.md`'s numbered list, and the runbook is
`infra/README.md` for everything provisioned by hand and `.github/workflows/release.yml` for a
release, which is a tag and nothing else. If either turns out to want a document of its own, it
gets one when there is something to put in it.

---

## Layout

```
cmd/          api (server + embedded interface + console), migrate (job),
              load (catalogue mirror), analyse (item analysis), staff (roles)
internal/     platform, tenant, identity, catalog, progress, practice, exam, grade,
              certificate, billing, event, analysis, audit, privacy, legal,
              visitor, console
ui/           the student interface, embedded in the binary — no build step
tools/        the checks and the jobs — a11y-test, graph-test, landing-test,
              console-test, mfa-test, check-interface, check-css, check-origin,
              validate-content, check-exercises, bundle, bundle-test,
              restore-drill, release, fonts, world
content/      the catalogue: prose in Markdown, structure and exercises in JSON
migrations/
deploy/       the Dockerfile, and the compose file that brings the system up locally
infra/        terraform
docs/
```

**The console's interface is in `internal/console/ui/`, not beside the student's.** The same
binary serves it on its own host, and it borrows exactly one file from `ui/` — `assets/base.css`,
the same bytes out of the same embed rather than a copy, with a test comparing them.

One repository maps to a deployable unit, never to a school. With three schools or thirty, the
number of repositories, services and migrations is the same — a school is a row, not a fork.

---

## Running it

The whole system on a laptop, with no cloud account and no domain:

```sh
docker compose -f deploy/local/docker-compose.yml up --build
open http://code.localhost:8080
```

That brings up Postgres, migrates it, creates two schools and seeds one of them with the fixture
the browser suites read — so the address opens a catalogue, a track graph, a lesson and an exam
paper rather than an empty school. `math.localhost:8080` is the same platform with nothing in it,
on purpose: two schools side by side are what make a lookup answering with the wrong one visible.

`.localhost` resolves to the loopback in modern browsers and in curl, so there is no `/etc/hosts`
to edit first.

There is also a single-file copy of one school, for a laptop with no connection. It asks a
running server for everything, including the interface itself, so the stack above has to be up:

```sh
go run ./tools/bundle -from http://localhost:8080 -host code.localhost -out bundle.html
```

Then open `bundle.html` from `file://`. It carries the catalogue, the graph and the lessons;
signing in, progress and exams are the school's record of a student and a copy of a file has
neither, so the interface says so where it would otherwise have shown a control.

---

## Where things stand

Phase 4 of seven — the console. Phases 0 to 3 carry the skeleton and the five things that cost
nothing now and are impossible later, the study platform, learning complete, and billing that
sells in Brazil and nowhere else yet.

**Every box in phase 0 is ticked and the phase is not finished**, which is a distinction this
project draws rather than rounds off: its `Done when` asks for two schools answering over TLS and
there is one, and a single school behind a `Host` check is indistinguishable from an application
that is not multi-tenant at all. Phases 1 to 3 each keep an item open for the same kind of reason
— a sandbox that runs a student's program, the platform's own address, and a way to be paid from
outside Brazil.

**That last one used to read "a payment gateway", and it had been wrong for a while.** The
domestic gateway is chosen and integrated — Asaas, with Pix, boleto and card instalments, a
webhook that has settled real purchases — and what is open is the international provider, which
waits on the legal entity rather than on a comparison of products. A sentence describing a
decision as unmade after it was made is the kind of thing this repository would rather name than
quietly correct.

Phase 4's boxes are all ticked now and it is not finished either, for a reason of its own: its
`Done when` asks for a funnel that shows a drop at a step nobody suspected, and a population this
repository invented drops where the model was told to make it drop. The machinery is what is
finished. The finding waits on real students.

[`docs/ROADMAP.md`](docs/ROADMAP.md) is the list and says which and why;
[`docs/PLAN.md`](docs/PLAN.md) is the shape and the reasoning.
