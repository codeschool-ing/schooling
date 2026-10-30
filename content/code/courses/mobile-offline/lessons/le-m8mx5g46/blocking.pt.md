---
title: Uma consulta que para a tela
version: 1
---

**O `better-sqlite3` é síncrono: enquanto uma consulta roda, nada mais no programa roda.** É um
desenho deliberado, e num servidor ou num script é o jeito mais rápido de usar o SQLite. Ele também
faz do Node um modelo justo da thread principal de um celular, porque o Node roda o seu JavaScript
numa thread com um laço de eventos, e um timer vencido não dispara enquanto uma chamada ainda está
rodando.

Então o experimento precisa de uma tela e de uma consulta lenta. A tela é um timer que conta um
quadro a cada 16 ms, como uma tela de 60 Hz faria. A consulta precisa ser lenta em qualquer
computador, inclusive num rápido, então em vez de depender de um arquivo grande ela pede ao SQLite
que conte até três milhões. Ela faz o papel da consulta que é lenta no celular de alguém: uma busca
em todas as anotações, o histórico de um curso de três anos. Crie a pasta da aula,
`~/planner/threads`, e salve a consulta sozinha como `slow.ts`:

```typescript
// slow.ts: a query made slow on purpose, so it is slow on any computer: it counts to three million.
export const slow =
  "WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 3000000) SELECT count(*) AS rows FROM n";
```

Depois o programa que a roda na thread principal, como `blocking.ts`:

```typescript
// blocking.ts: a slow query on the main thread, and the frames that were due while it ran.
import Database from "better-sqlite3";
import { slow } from "./slow.ts";

let frames = 0;
const screen = setInterval(() => frames++, 16); // one frame every 16 ms, as at 60 Hz

setTimeout(() => {
  const before = frames;
  const db = new Database(":memory:");
  const { rows } = db.prepare(slow).get() as { rows: number };
  const drawn = frames - before;
  console.log(`main thread: ${rows} rows; frames drawn while the query ran: ${drawn > 0 ? "at least one" : "none"}`);
  clearInterval(screen);
}, 100);
```

Ele espera 100 ms para a tela já estar desenhando, anota a contagem de quadros, roda a consulta e
conta de novo. O programa imprime se algum quadro foi desenhado no meio, e não quantos nem quanto a
consulta demorou, porque os dois dependem do computador e a transcrição precisa ser a mesma no seu:

```
ana@dev:~/planner/threads$ node blocking.ts
main thread: 3000000 rows; frames drawn while the query ran: none
```

**Nenhum.** Por mais que a consulta tenha demorado no seu computador, o timer não disparou nenhuma
vez até ela voltar. Num celular isso é uma tela congelada: a lista não rola, um botão não aperta, o
indicador que você pôs para dizer "carregando" não gira, porque é desenhado pela mesma thread.

Repare no que não ajudou. A consulta está correta, o banco está na memória, e nada esperou um disco.
Travar é sobre onde o trabalho roda, não sobre quão eficiente ele é; uma consulta eficiente na thread
principal continua sendo uma consulta na thread principal.

A próxima seção mantém tudo igual e passa a consulta para outra thread.
