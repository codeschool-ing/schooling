---
title: A migração que falha, e o que ela deixa
version: 1
---

**Uma migração um dia vai falhar no celular de alguém, e a única coisa que você controla é o estado
que ela deixa para trás.** Um disco cheio, uma linha que ninguém esperava, um comando que o SQLite
recusa: nada disso aparece num aparelho de teste com três linhas. O que importa é se o dado da
pessoa continua intacto e se a próxima versão do app ainda consegue migrá-lo.

A versão 5 abaixo renomeia a coluna de anotações e depois acrescenta uma coluna de lembrete que o
SQLite recusa, uma coluna `NOT NULL` sem valor padrão numa tabela que já tem linhas. O programa a
roda duas vezes em cada modo, como duas aberturas do app, uma vez comando a comando e outra numa
transação. Salve como `broken.ts` na `~/planner/migrate`:

```typescript
// broken.ts: a fifth step that fails halfway, run without a transaction and inside one.
import Database from "better-sqlite3";
import { migrate, version } from "./migrations.ts";

// Step 5 renames a column, then adds one that SQLite refuses on a table that has rows.
const step5 = [
  "ALTER TABLE sessions RENAME COLUMN notes TO note",
  "ALTER TABLE sessions ADD COLUMN reminder TEXT NOT NULL",
];
const columns = (db: Database.Database) =>
  (db.prepare("SELECT name FROM pragma_table_info('sessions')").all() as { name: string }[]).map((c) => c.name).join(", ");

for (const mode of ["statement by statement", "in a transaction"]) {
  const db = new Database(":memory:");
  migrate(db);
  db.prepare("INSERT INTO courses VALUES ('statistics', 'Statistics')").run();
  db.prepare("INSERT INTO sessions (id, course, date, minutes) VALUES ('s5', 'statistics', '2026-10-26', 60)").run();
  const run = () => { for (const sql of step5) db.exec(sql); db.pragma("user_version = 5"); };
  for (const launch of [1, 2]) {
    try {
      if (mode === "in a transaction") db.transaction(run)(); else run();
    } catch (e) {
      console.log(`${mode}, launch ${launch}: ${(e as Error).message}`);
    }
    console.log(`  version ${version(db)}; columns: ${columns(db)}`);
  }
}
```

```
ana@dev:~/planner/migrate$ node broken.ts
statement by statement, launch 1: Cannot add a NOT NULL column with default value NULL
  version 4; columns: id, course, date, minutes, note, synced, done_at
statement by statement, launch 2: no such column: "notes"
  version 4; columns: id, course, date, minutes, note, synced, done_at
in a transaction, launch 1: Cannot add a NOT NULL column with default value NULL
  version 4; columns: id, course, date, minutes, notes, synced, done_at
in a transaction, launch 2: Cannot add a NOT NULL column with default value NULL
  version 4; columns: id, course, date, minutes, notes, synced, done_at
```

**Comando a comando, a primeira abertura renomeou `notes` para `note` e depois falhou, e o arquivo
ainda diz versão 4.** O banco agora tem um formato que nenhuma versão do app conhece: o código da
versão 4 procura `notes`, que sumiu. Na segunda abertura o próprio renomear falha, porque não sobrou
`notes` para renomear, então nem um passo 5 corrigido, publicado amanhã, funcionaria neste celular.
Nada consegue migrá-lo sem código especial para um estado que nunca deveria ter existido.

Numa transação, a falha desfez o renomear junto com todo o resto. As duas aberturas falham, o que a
pessoa vê como um app que não abre, mas o arquivo é exatamente a versão 4, cada coluna onde a versão
4 a deixou, e um passo 5 corrigido na próxima versão o migra normalmente. **Uma migração que falha
sem mudar nada é um bug; uma que muda metade é perda de dado.**

O SQLite é incomum porque `ALTER TABLE`, `CREATE` e `DROP` participam de uma transação como
qualquer outro comando. O Room roda cada migração dentro de uma transação para você, o que é um
motivo para deixar que ele faça isso.

## O que o app faz quando ela falha

A falha ainda precisa ir para algum lugar. Três coisas valem a pena, e uma vale a pena recusar.

- **Relatar.** Um relator de falhas, ou um registro que a próxima abertura bem-sucedida envia, com
  as versões de origem e de destino. Uma migração que falha em 0,1% dos celulares é invisível nas
  avaliações da loja.
- **Guardar o arquivo antigo.** Copie o banco antes de migrar, com os três arquivos WAL da aula 3 ou
  a API de backup do SQLite, e apague a cópia quando a migração confirmar.
- **Dizer à pessoa algo verdadeiro**, como "o planner não conseguiu atualizar os dados; eles estão
  seguros, e uma atualização vai corrigir isso", em vez de uma tela em branco.
- **Não apagar o banco para o erro sumir.** Esse é o assunto da próxima seção.
