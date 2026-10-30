---
title: Um banco de dados para os dados do planner
version: 1
---

**Os cursos e as sessões do planner são o trabalho da aluna, crescem toda semana, e as telas fazem
perguntas a eles: o total desta semana, as sessões de um curso, o que ainda não foi feito.** Esse é
o trabalho de um banco de dados. E num celular já existe um: o **SQLite**, que vem dentro do Android
e do iOS. Ele não é um servidor. É uma biblioteca que guarda um banco inteiro num único arquivo comum
na sandbox do app, que é exatamente o formato que um celular quer.

Cada plataforma põe a sua camada por cima, e os cursos depois da bifurcação as ensinam: o **Room** no
Android, o **SwiftData** no iOS, que pode guardar os dados em SQLite por baixo, e no React Native uma
biblioteca como o `expo-sqlite`. Elas acrescentam tipos, migrações e um jeito de observar uma
consulta para saber quando ela muda. Por baixo do Room e do `expo-sqlite`, o arquivo é SQLite.

No seu computador, o SQLite vem pelo `better-sqlite3`, uma biblioteca do Node.js que traz a própria
cópia dele. Instale-a em `~/planner`; o `-E` registra a versão exata no `package.json`:

```
ana@dev:~/planner$ npm install -E better-sqlite3@13.0.3

added 2 packages in 2s
ana@dev:~/planner$ cat package.json
{
  "name": "planner",
  "private": true,
  "type": "module",
  "dependencies": {
    "better-sqlite3": "13.0.3"
  }
}
```

## O planner em SQLite

O `store.ts` cria o `planner.db` com duas tabelas, põe nelas a semana da aula 1, e pede ao SQL o
mesmo total que o `weekTotal` calculava em TypeScript. Salve como `store.ts`:

```schooling-example
{"language": "typescript", "file": "store.ts", "parts": [{"code": "// store.ts: the planner's courses and sessions in SQLite, and the week's total in SQL\nimport Database from \"better-sqlite3\";\nimport { mondayOf } from \"./planner.ts\";\n\nconst db = new Database(\"planner.db\");\ndb.pragma(\"foreign_keys = ON\");\n", "note": "Abrir o `planner.db` cria o arquivo se ele não existir. O SQLite só faz valer o `REFERENCES courses` de uma sessão quando as chaves estrangeiras estão ligadas, o que é um `pragma` por conexão."}, {"code": "db.exec(`\n  CREATE TABLE IF NOT EXISTS courses (\n    id    TEXT PRIMARY KEY,\n    title TEXT NOT NULL\n  );\n  CREATE TABLE IF NOT EXISTS sessions (\n    id        TEXT PRIMARY KEY,\n    course_id TEXT NOT NULL REFERENCES courses (id),\n    date      TEXT NOT NULL,\n    minutes   INTEGER NOT NULL,\n    done      INTEGER NOT NULL\n  );\n`);\n", "note": "As duas listas do `Plan` da aula 1, como duas tabelas. Uma sessão continua apontando para o curso pelo id, e agora o banco recusa uma que aponte para o nada, como o `addSession` fazia. O SQLite não tem booleano, então `done` é 0 ou 1."}, {"code": "const addCourse = db.prepare(\"INSERT OR IGNORE INTO courses (id, title) VALUES (?, ?)\");\nconst addSession = db.prepare(\n  \"INSERT OR IGNORE INTO sessions (id, course_id, date, minutes, done) VALUES (?, ?, ?, ?, ?)\",\n);\ndb.transaction(() => {\n  addCourse.run(\"sql\", \"SQL Databases\");\n  addCourse.run(\"mobile\", \"Mobile Fundamentals\");\n  addSession.run(\"s1\", \"sql\", \"2026-10-19\", 50, 1);\n  addSession.run(\"s2\", \"mobile\", \"2026-10-20\", 40, 1);\n  addSession.run(\"s3\", \"sql\", \"2026-10-23\", 60, 0);\n  addSession.run(\"s4\", \"mobile\", \"2026-10-27\", 45, 0);\n  addSession.run(\"s5\", \"mobile\", \"2026-10-22\", 30, 1);\n})();\n", "note": "A semana da aula 1, com `s5` já concluída. Os `?` são preenchidos pelo `run`, nunca colados no SQL. A transação grava as sete linhas ou nenhuma, e o `OR IGNORE` deixa em paz uma linha cujo id já existe, então uma segunda execução não acrescenta nada."}, {"code": "const monday = mondayOf(process.argv[2]); // \"today\" is given, as in week.ts\nconst totals = db\n  .prepare(\n    `SELECT sum(minutes) AS planned,\n            sum(CASE WHEN done THEN minutes ELSE 0 END) AS done\n       FROM sessions\n      WHERE date >= ? AND date < date(?, '+7 days')`,\n  )\n  .get(monday, monday);\nconsole.log({ monday, ...totals });\ndb.close();", "note": "O `weekTotal` da aula 1, como uma consulta. Datas escritas `YYYY-MM-DD` se ordenam como texto na ordem das datas, então a semana é toda data da segunda-feira até a segunda seguinte, sem incluí-la."}]}
```

Rode para a semana de 21 de outubro, e veja o arquivo que ele criou:

```
ana@dev:~/planner$ node store.ts 2026-10-21
{ monday: '2026-10-19', planned: 180, done: 120 }
ana@dev:~/planner$ ls -l planner.db
-rw-r--r-- 1 ana ana 20480 Oct 30 03:27 planner.db
```

**Os mesmos dois números da aula 1, 180 planejados e 120 feitos**, agora calculados pelo banco em
vez de por um laço sobre um array. A diferença importa quando o plano tem um ano: a consulta lê as
sessões de uma semana, e um índice em `date` deixaria o banco encontrá-las sem ler o resto.

O `planner.db` é um arquivo de 20.480 bytes, cinco páginas de 4.096: uma para o catálogo de tabelas
do próprio SQLite, e duas para cada tabela, uma para as linhas e uma para o índice que a sua
`PRIMARY KEY` de texto cria. Ele guarda o esquema e os dados, e é o arquivo que o backup leva.
**Rodar o `store.ts` uma segunda vez não muda nada**, porque o `INSERT OR IGNORE` deixa em paz uma
linha cujo id já existe. O total é o mesmo, e a pasta agora guarda tudo o que os programas desta aula
mantêm, o substituto da sandbox do planner:

```
ana@dev:~/planner$ node store.ts 2026-10-21
{ monday: '2026-10-19', planned: 180, done: 120 }
ana@dev:~/planner$ ls -l
total 48
drwxr-xr-x 4 ana ana  4096 Oct 30 03:27 node_modules
-rw-r--r-- 1 ana ana   986 Oct 30 03:27 package-lock.json
-rw-r--r-- 1 ana ana   119 Oct 30 03:27 package.json
-rw-r--r-- 1 ana ana 20480 Oct 30 03:27 planner.db
-rw-r--r-- 1 ana ana  1451 Oct 30 03:27 planner.ts
-rw-r--r-- 1 ana ana    33 Oct 30 03:27 prefs.json
-rw-r--r-- 1 ana ana   867 Oct 30 03:27 prefs.ts
-rw-r--r-- 1 ana ana  1541 Oct 30 03:27 store.ts
```

## O que o arquivo não faz por você

**Um arquivo de banco num celular sobrevive a todas as versões do app que o escreveram.** No dia em
que o planner acrescentar uma coluna `notes`, os celulares do mundo ainda guardam a tabela antiga, e
a versão nova precisa mudá-la no lugar, num aparelho em que ninguém consegue entrar, sem perder uma
linha. Isso é uma *migração*, e é um assunto à parte: o curso `mobile-offline` o ensina na aula 5,
depois de a aula 3 comparar SQLite, Room, SwiftData e Realm.

**E o banco é a coisa mais lenta por que a thread principal pode esperar.** O `better-sqlite3`
responde de forma síncrona, o que serve para um script que roda uma vez. Num app, uma consulta na
thread principal segura o quadro pelo tempo que levar, que é o travamento da aula 6; as bibliotecas
das plataformas rodam as consultas em outra thread, e a aula 6 do `mobile-offline` trata da lista que
engasga quando elas não fazem isso.
