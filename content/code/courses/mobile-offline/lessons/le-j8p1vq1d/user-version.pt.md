---
title: Um número de versão no arquivo, e uma lista de passos
version: 1
---

**O banco de um servidor é migrado uma vez, por alguém olhando; o de um celular é migrado um milhão
de vezes, pelo app, em aparelhos nos quais ninguém consegue entrar.** A atualização chega da loja
enquanto a pessoa dorme, o app abre de manhã, e antes da primeira tela ele precisa transformar o
banco que encontrar naquele que esta versão espera. Ninguém está lá para olhar um erro, e o banco
guarda dados que não existem em nenhum outro lugar.

Então a migração tem de ser sem graça: um número no arquivo que diz em que formato ele está, e uma
lista ordenada de passos que cada um leva uma versão adiante. O SQLite guarda o número para você.
`PRAGMA user_version` é um inteiro no cabeçalho do arquivo, 0 num arquivo novo, que o SQLite nunca
muda por conta própria. O Room, o Core Data e o Realm guardam uma versão própria do mesmo jeito, e
a documentação do `expo-sqlite` sugere exatamente esse pragma para o React Native.

Crie a pasta da aula, `~/planner/migrate`, e salve isto como `migrations.ts`:

```typescript
// migrations.ts: the planner's schema as an ordered list of steps, and the function that applies them.
import type { Database } from "better-sqlite3";

// steps[0] takes an empty file to version 1, steps[1] takes version 1 to 2, and so on.
// A step that has shipped is never edited again: a phone may still be about to run it.
export const steps: string[] = [
  `CREATE TABLE courses (id TEXT PRIMARY KEY, name TEXT NOT NULL);
   CREATE TABLE sessions (id TEXT PRIMARY KEY, course TEXT NOT NULL REFERENCES courses (id),
                          date TEXT NOT NULL, minutes INTEGER NOT NULL, done INTEGER NOT NULL DEFAULT 0);`,
  `ALTER TABLE sessions ADD COLUMN notes TEXT NOT NULL DEFAULT '';`,
  `ALTER TABLE sessions ADD COLUMN synced INTEGER NOT NULL DEFAULT 1;`,
  `ALTER TABLE sessions ADD COLUMN done_at TEXT;
   UPDATE sessions SET done_at = date WHERE done = 1;
   ALTER TABLE sessions DROP COLUMN done;
   CREATE INDEX sessions_unsent ON sessions (id) WHERE synced = 0;`,
];

export function version(db: Database): number {
  return db.pragma("user_version", { simple: true }) as number;
}

// Run every step after the file's version, in order, in one transaction with the new version number.
export function migrate(db: Database, to = steps.length): void {
  const from = version(db);
  db.transaction(() => {
    for (let v = from; v < to; v++) db.exec(steps[v]);
    db.pragma(`user_version = ${to}`);
  })();
}
```

A história do planner são quatro passos. A versão 1 é as duas tabelas da aula 3. A versão 2 deu às
sessões uma anotação. A versão 3 acrescentou `synced`, que a aula 4 usou para decidir o que pode ser
apagado; as linhas que existiam antes dela já estavam todas no servidor, então o padrão é 1. A
versão 4 trocou `done`, um sim ou não, por `done_at`, o dia em que foi feita, copiando as respostas
antigas antes de remover a coluna antiga, e acrescentou um índice nas linhas que ainda esperam para
ser enviadas.

Três regras estão escritas nesse arquivo, e cada uma está lá porque quebrá-la perde dado:

- **Os passos rodam em ordem, da versão do arquivo até a última.** Nunca "o esquema mais recente",
  sempre o caminho até ele.
- **Um passo publicado nunca é editado.** Se a versão 3 estava errada, a versão 5 corrige. Algum
  celular ainda está na versão 2 e vai rodar a versão 3 exatamente como ela saiu.
- **Os passos e o número novo confirmam juntos**, numa transação. A seção depois da próxima mostra o
  que acontece quando não confirmam.

`version` e `migrate` são tudo o que o app chama na abertura: abrir o arquivo, `migrate(db)`, depois
desenhar. Numa instalação nova o arquivo está vazio, a versão é 0, e a mesma função o constrói a
partir do passo 1, então uma instalação nova e um celular antigo terminam no mesmo lugar pelo mesmo
código. A próxima seção confere essa afirmação em vez de confiar nela.
