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
| [`docs/PLAN.md`](docs/PLAN.md) | why each rule exists: 74 decisions with their reasoning, the open questions, the shape of the phases |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | what each phase is made of, as capabilities to tick off |
| [`docs/CONTENT.md`](docs/CONTENT.md) | the shape of `content/`, what CI checks, and what happens when a question turns out to be bad |
| [`docs/CONSOLE.md`](docs/CONSOLE.md) | what the console is, whole, and the order it arrives in — the decisions it settled are K-17 to K-22 |
| `docs/adr/` | one decision per file, dated, as each is implemented |
| `docs/DEPLOY.md` | the runbook — arrives with phase 0 |

`CLAUDE.md` is normative and `PLAN.md` is historical. If they disagree, the code follows
`CLAUDE.md` and `PLAN.md` is what needs fixing.

---

## Layout

```
cmd/          api (server + embedded frontend), migrate (job), pipeline (content generator)
internal/     platform, tenant, identity, catalog, progress, assessment,
              certificates, execution
web/          app (the student portal), admin (the console), assets
tools/        the suites — graph, modal, session, smoke, bundle, i18n, catalogue validation
content/      the catalogue: prose in Markdown, structure and exercises in JSON
migrations/
deploy/
infra/        terraform
docs/
```

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

Phase 4 of seven. Phases 0 to 3 are done — the skeleton and the five things that cost nothing
now and are impossible later, the study platform, learning complete, and billing up to the point
where it waits on a payment gateway nobody has chosen. The roadmap and what each phase is done
by are in [`docs/PLAN.md`](docs/PLAN.md).
