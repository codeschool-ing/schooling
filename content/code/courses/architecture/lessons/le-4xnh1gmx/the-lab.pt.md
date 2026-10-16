---
title: O laboratório: o log de decisões da Quitanda
version: 1
---

**Este laboratório não precisa de contêineres**: um diretório, alguns arquivos Markdown, dois scripts de shell
pequenos e um arquivo de código da aplicação. Os registros são decisões que este curso tomou, escritas como
a equipe as teria escrito na época. Ele fica em `~/lab/adr`:

```sh
mkdir -p ~/lab/adr/docs/adr ~/lab/adr/app && cd ~/lab/adr
```

`docs/adr/0001-record-architecture-decisions.md`:

O primeiro registro de todo log, como o do próprio Michael Nygard: a decisão de manter o log.

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

Uma decisão da aula 5, posta por escrito: a loja pergunta ao serviço de estoque quando desenha uma página.

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

A decisão da aula 7: os pagamentos reconhecem um pedido que já trataram.

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

A decisão da aula 16, e a que o laboratório vai defender com uma conferência que roda a cada mudança.

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

`adr-index.sh`, que imprime o log:

```schooling-example
{"language": "sh", "file": "adr-index.sh", "parts": [{"code": "#!/bin/bash\nfor f in docs/adr/[0-9]*.md; do\n    title=$(head -1 \"$f\" | sed 's/^# //')\n    status=$(awk '/^## Status/ {getline; getline; print; exit}' \"$f\")\n    printf '%-45s %s\\n' \"$title\" \"$status\"\ndone", "note": "Imprime o log como um sumário: o número e o título de cada registro, da primeira linha, e o status, da linha depois de `## Status`."}]}
```

`check.sh`, que a última seção usa:

```schooling-example
{"language": "sh", "file": "check.sh", "parts": [{"code": "#!/bin/bash\nif grep -rn -i 'select \\*' app/; then\n    echo \"ADR 4: name the columns; SELECT * is not allowed under app/\"\n    exit 1\nfi\necho \"ADR 4: ok\"", "note": "Uma função de aptidão para o ADR 4: ela falha, e diz que linhas quebraram a regra, se algum arquivo em `app/` contiver `SELECT *`. Num repositório de verdade ela roda no CI a cada pull request."}]}
```

`app/catalogue.py`:

```schooling-example
{"language": "python", "file": "app/catalogue.py", "parts": [{"code": "def catalogue_list(db):\n    return db.execute(\"SELECT * FROM products ORDER BY id\").fetchall()", "note": "Uma página do código da loja, escrita antes do ADR 4, do jeito que a aula 16 a encontrou."}]}
```

Imprima o log:

```
ana@vm:~/lab/adr$ bash adr-index.sh
1. Record architecture decisions              Accepted
2. Ask the stock service synchronously        Accepted
3. Charge cards idempotently                  Accepted
4. No SELECT * in application code            Accepted
```

Quatro decisões, cada uma com o status, e cada uma um arquivo que qualquer pessoa abre e lê em dois
minutos. Ferramentas como `adr-tools` e `log4brains` fazem isso e mais, criando arquivos numerados a partir
de um modelo e publicando o log como um site; o formato é simples o bastante para um script de cinco
linhas fazer a parte que importa.
