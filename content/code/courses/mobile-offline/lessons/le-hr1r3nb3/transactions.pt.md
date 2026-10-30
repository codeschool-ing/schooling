---
title: Transações, e o lote que chegou pela metade
version: 1
---

**Uma transação transforma várias escritas numa só: todas chegam ao banco, ou nenhuma chega.** Sem
ela, cada comando confirma sozinho, e um lote que falha no meio deixa a primeira metade no lugar.
Num aparelho, esse lote costuma ser um download do servidor, o assunto da aula 11, e metade de um é
um planner errado de um jeito que ninguém escolheu.

## Um lote com uma linha ruim

O programa abaixo adiciona 1.000 sessões duas vezes, num banco guardado na memória. A sessão 501
dura zero minutos, o que o `CHECK` recusa. Na primeira vez cada inserção vai sozinha; na segunda
elas rodam dentro de `db.transaction`, que o `better-sqlite3` transforma em `BEGIN`, as inserções e
`COMMIT`, ou `ROLLBACK` se algo lançar erro. Salve como `batch.ts` na `~/planner/db`:

```typescript
// batch.ts: add 1,000 sessions in one go, where session 501 is wrong, with and without a transaction.
import Database from "better-sqlite3";

const db = new Database(":memory:");
db.exec(`CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL, date TEXT NOT NULL,
                                minutes INTEGER NOT NULL CHECK (minutes > 0), done INTEGER NOT NULL)`);
const add = db.prepare("INSERT INTO sessions VALUES (?, 'statistics', '2026-10-20', ?, 0)");
const batch = Array.from({ length: 1000 }, (_, i) => ({ id: `b${i + 1}`, minutes: i === 500 ? 0 : 30 }));
const count = () => (db.prepare("SELECT count(*) AS n FROM sessions").get() as { n: number }).n;

try {
  for (const s of batch) add.run(s.id, s.minutes); // each insert commits on its own
} catch (e) {
  console.log(`one at a time: ${(e as Error).message}; ${count()} rows stayed`);
}

db.exec("DELETE FROM sessions");
const all = db.transaction((rows: typeof batch) => {
  for (const s of rows) add.run(s.id, s.minutes);
});
try {
  all(batch); // one transaction: every insert, or none
} catch (e) {
  console.log(`in a transaction: ${(e as Error).message}; ${count()} rows stayed`);
}
```

```
ana@dev:~/planner/db$ node batch.ts
one at a time: CHECK constraint failed: minutes > 0; 500 rows stayed
in a transaction: CHECK constraint failed: minutes > 0; 0 rows stayed
```

**Quinhentas linhas ficaram na primeira vez.** A tela as mostraria, a pessoa veria meio download, e
o programa teria de descobrir qual metade. Na transação, a falha desfez tudo, e o banco está
exatamente como estava antes de o lote começar: o download pode ser tentado de novo desde o
começo.

A mesma transação é também o motivo de o lote ser rápido, embora este curso não cite tempo nenhum.
Cada confirmação espera o disco confirmar a escrita, então mil confirmações esperam mil vezes e uma
confirmação espera uma. O `big.ts` põe as 20.000 inserções numa transação só por esse motivo.

## Registro de escrita antecipada

Por padrão, o SQLite grava uma mudança no arquivo do banco e guarda as páginas antigas num diário
separado, para poder desfazer. O **registro de escrita antecipada** (*write-ahead logging*, WAL)
inverte isso: as mudanças vão primeiro para um arquivo `-wal`, e são copiadas para o banco depois.
Quem lê continua lendo o banco enquanto uma escrita está em andamento, o que num celular quer dizer
que a tela pode consultar enquanto uma sincronização grava. Salve isto como `wal.ts`:

```typescript
// wal.ts: switch planner.db to write-ahead logging, and see what it adds beside the file.
import Database from "better-sqlite3";
import { readdirSync } from "node:fs";

const db = new Database("planner.db");
console.log("before:", db.pragma("journal_mode", { simple: true }));
console.log("after: ", db.pragma("journal_mode = WAL", { simple: true }));
db.prepare("UPDATE sessions SET done = 1 WHERE id = 's3'").run();
console.log(readdirSync(".").filter((f) => f.startsWith("planner.db")));
db.close();
console.log(readdirSync(".").filter((f) => f.startsWith("planner.db")));
```

```
ana@dev:~/planner/db$ node wal.ts
before: delete
after:  wal
[ 'planner.db', 'planner.db-shm', 'planner.db-wal' ]
[ 'planner.db' ]
```

O `journal_mode` era `delete`, o padrão, e agora é `wal`, e a configuração fica guardada no
arquivo, então permanece. Enquanto o banco está aberto, dois arquivos ficam ao lado dele: o
registro e o `-shm`, um índice do registro em memória compartilhada. Quando a última conexão fecha,
o SQLite copia o registro de volta e remove os dois.

**Esses dois arquivos fazem parte do banco.** Copiar só o `planner.db` enquanto o app o tem aberto
copia um banco sem as escritas mais recentes. O Room liga o WAL por padrão e os armazenamentos
SQLite do Core Data também o usam; uma ferramenta de backup, ou uma exportação, precisa levar os
três arquivos juntos, ou pedir ao SQLite uma cópia pela API de backup dele.
