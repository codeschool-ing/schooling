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
| [`docs/PLAN.md`](docs/PLAN.md) | why each rule exists: 70 decisions with their reasoning, the open questions, the shape of the phases |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | what each phase is made of, as capabilities to tick off |
| [`docs/CONTENT.md`](docs/CONTENT.md) | the shape of `content/`, what CI checks, and what happens when a question turns out to be bad |
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

Not yet. The repository is at phase 0 and nothing here starts. This section is written from what
actually runs, once something does — an instruction that does not work is worse than no
instruction.

---

## Where things stand

Phase 0 of seven: the skeleton, plus the five things that cost nothing now and are impossible
later — rich events, the review log, audit with an actor, personal-data export, and the visitor
identity that precedes the account. The roadmap and what each phase is done by are in
[`docs/PLAN.md`](docs/PLAN.md).
