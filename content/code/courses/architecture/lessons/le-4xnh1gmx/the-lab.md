---
title: The lab: Quitanda's decision log
version: 1
---

**This lab needs no containers**: a directory, some Markdown files, two small shell scripts and one file
of application code. The records are decisions this course made, written the way the team would have
written them at the time. It lives in `~/lab/adr`:

```sh
mkdir -p ~/lab/adr/docs/adr ~/lab/adr/app && cd ~/lab/adr
```

`docs/adr/0001-record-architecture-decisions.md`:

The first record of every log, after Michael Nygard's own: the decision to keep the log.

```
# 1. Record architecture decisions

Date: 2026-03-02

## Status

Accepted

## Context

Decisions about Quitanda's architecture are made in meetings and chat threads, and six months later
nobody can say why the shop calls the stock service the way it does. New people either accept every
choice without question or reopen every choice without context.

## Decision

We record every architecturally significant decision as a short Markdown file in `docs/adr`, numbered
in order, in the format Michael Nygard described: title, status, context, decision, consequences.
A record is never edited once accepted, except for its status; a decision that changes gets a new
record that supersedes it.

## Consequences

Each significant change comes with a record to write and review. The log can be read in an afternoon,
and answers "why" questions for as long as the repository exists.
```

`docs/adr/0002-ask-the-stock-service-synchronously.md`:

A decision from lesson 5, written down: the shop asks the stock service when it draws a page.

```
# 2. Ask the stock service synchronously

Date: 2026-03-09

## Status

Accepted

## Context

The shop shows how many units of a product are left. The number belongs to the stock service. The shop
serves a few thousand page views a day, and the stock service answers in a few milliseconds.

## Decision

The shop calls the stock service over HTTP for every product page, with a two-second timeout, and shows
"availability unknown" when the call fails.

## Consequences

The number on the page is always current. The shop cannot show stock while the stock service is down,
and the stock service carries the shop's read traffic, which is fine at this size and will not be at
ten times it.
```

`docs/adr/0003-charge-cards-idempotently.md`:

Lesson 7's decision: payments recognise a request they have already handled.

```
# 3. Charge cards idempotently

Date: 2026-04-14

## Status

Accepted

## Context

Payment requests arrive through a queue that delivers at least once. A consumer that crashes after
charging and before acknowledging receives the same request again, and a customer was charged twice in
testing.

## Decision

Every payment request carries an id. The payments service records the id and the charge in one
transaction, and skips a request whose id it has already recorded.

## Consequences

A redelivered request is harmless. Every producer must send a stable id, generated once per order, not
per attempt. The table of handled ids grows forever unless old ids are archived.
```

`docs/adr/0004-no-select-star-in-application-code.md`:

Lesson 16's decision, and the one the lab will defend with a check that runs on every change.

```
# 4. No SELECT * in application code

Date: 2026-07-20

## Status

Accepted

## Context

The catalogue list moved a megabyte per request to show fifty names, because its query selected every
column, including the descriptions. A large column added to any table later would join every such query
without anybody noticing.

## Decision

Application code names the columns it reads. `SELECT *` is allowed in migrations and in hand-written
queries at a database prompt, and nowhere under `app/`.

## Consequences

Queries are a little longer. Adding a column never changes what existing pages fetch. The rule is checked
by `check.sh`, which fails the build when it finds `SELECT *` under `app/`.
```

`adr-index.sh`, which prints the log:

```schooling-example
{"language": "sh", "file": "adr-index.sh", "parts": [{"code": "#!/bin/bash\nfor f in docs/adr/[0-9]*.md; do\n    title=$(head -1 \"$f\" | sed 's/^# //')\n    status=$(awk '/^## Status/ {getline; getline; print; exit}' \"$f\")\n    printf '%-45s %s\\n' \"$title\" \"$status\"\ndone", "note": "Prints the log as a table of contents: each record's number and title, from its first line, and its status, from the line after `## Status`."}]}
```

`check.sh`, which the last section uses:

```schooling-example
{"language": "sh", "file": "check.sh", "parts": [{"code": "#!/bin/bash\nif grep -rn -i 'select \\*' app/; then\n    echo \"ADR 4: name the columns; SELECT * is not allowed under app/\"\n    exit 1\nfi\necho \"ADR 4: ok\"", "note": "A fitness function for ADR 4: it fails, and says which lines broke the rule, if any file under `app/` contains `SELECT *`. In a real repository it runs in CI on every pull request."}]}
```

`app/catalogue.py`:

```schooling-example
{"language": "python", "file": "app/catalogue.py", "parts": [{"code": "def catalogue_list(db):\n    return db.execute(\"SELECT * FROM products ORDER BY id\").fetchall()", "note": "A page from the shop's code, written before ADR 4, the way lesson 16 found it."}]}
```

Print the log:

```
ana@vm:~/lab/adr$ bash adr-index.sh
1. Record architecture decisions              Accepted
2. Ask the stock service synchronously        Accepted
3. Charge cards idempotently                  Accepted
4. No SELECT * in application code            Accepted
```

Four decisions, each with its status, and each one a file anybody can open and read in two minutes.
Tools such as `adr-tools` and `log4brains` do this and more, creating numbered files from a template and
publishing the log as a website; the format is plain enough that a script of five lines does the part
that matters.
