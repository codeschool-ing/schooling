---
title: Tipos para os dados
version: 1
---

**TypeScript num projeto SvelteKit é uma questão de nomes de arquivo e de um arquivo de configuração.**
Um arquivo `.ts` é TypeScript, um componente com `<script lang="ts">` é TypeScript, e todo o resto
continua JavaScript e continua funcionando ao lado deles. O build tira os tipos; o navegador e o Node
nunca os veem. Então um projeto pode ser convertido um arquivo de cada vez, e este é, começando por onde
os dados são descritos.

Primeiro a configuração. `jsconfig.json` e `tsconfig.json` são o mesmo arquivo com dois nomes, o segundo
sendo o que projetos TypeScript usam, e os módulos do próprio Node precisam dos seus tipos instalados:

```
ana@dev:~/planner$ git mv jsconfig.json tsconfig.json
```

```
ana@dev:~/planner$ npm install --save-dev @types/node@22.20.5

added 2 packages, removed 1 package, and audited 59 packages in 797ms

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

O `@types/node` descreve os módulos embutidos do Node, como `node:fs/promises`, e a sua versão principal
acompanha a do Node: 22, como o `node --version` disse na aula 1.

## O formato de uma sessão

**O arquivo de dados tem um formato, e nada até agora o escreveu.** Salve-o como `src/lib/types.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/types.ts", "parts": [
 {"code": "// types.ts: the shape of the planner's data, as the file holds it.\nexport interface Course {\n\tid: string;\n\tname: string;\n}\n\nexport interface Session {\n\tid: number;\n\tcourse: string;\n\tdate: string;\n\tminutes: number;\n\tdone: boolean;\n}\n\nexport interface PlannerData {\n\tcourses: Course[];\n\tsessions: Session[];\n}", "note": "Uma `interface` dá nome a um formato. Ela existe só para o verificador: o build a remove, e nada dela sobra na hora da execução."}
]}
```

Três arquivos usam esses formatos primeiro: as datas, a checagem e o módulo que lê e escreve o arquivo.
Renomeie-os, para o Git guardar o histórico deles:

```
ana@dev:~/planner$ git mv src/lib/week.js src/lib/week.ts
ana@dev:~/planner$ git mv src/lib/server/check.js src/lib/server/check.ts
ana@dev:~/planner$ git mv src/lib/server/planner.js src/lib/server/planner.ts
```

Os imports nos outros arquivos continuam dizendo `#lib/week.js`. O TypeScript e o Vite procuram
`week.ts` quando `week.js` não existe, e é isso que deixa as duas linguagens importarem uma da outra à
vontade. Substitua `src/lib/week.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/week.ts", "parts": [
 {"code": "// week.ts: dates as 'YYYY-MM-DD' strings, and the week they fall in.\n// Weeks start on Monday.\nconst DAY = 24 * 60 * 60 * 1000;\nconst toTime = (date: string) => Date.parse(`${date}T00:00:00Z`);\nconst toDate = (time: number) => new Date(time).toISOString().slice(0, 10);"},
 {"code": "/** Whether `text` is a real date, written as 'YYYY-MM-DD'. */\nexport function isDate(text: unknown): text is string {\n\treturn typeof text === 'string' && /^\\d{4}-\\d{2}-\\d{2}$/.test(text) && toDate(toTime(text)) === text;\n}", "note": "`text is string` é um type guard: onde `isDate(x)` é verdadeiro, o verificador trata `x` como string. Ele recebe `unknown` porque o seu trabalho é checar valores que ninguém checou ainda."},
 {"code": "/** The Monday of the week `date` falls in. */\nexport function mondayOf(date: string) {\n\tconst day = new Date(toTime(date)).getUTCDay();\n\treturn toDate(toTime(date) - ((day + 6) % 7) * DAY);\n}\n\n/** `date` moved by `days`, which may be negative. */\nexport function addDays(date: string, days: number) {\n\treturn toDate(toTime(date) + days * DAY);\n}\n\n/** Whether `date` falls in the week that starts on `monday`. */\nexport function inWeek(date: string, monday: string) {\n\treturn date >= monday && date < addDays(monday, 7);\n}\n\n/** `2026-10-19` as `19 Oct 2026`. */\nexport function format(date: string) {\n\treturn new Date(toTime(date)).toLocaleDateString('en-GB', {\n\t\tday: 'numeric',\n\t\tmonth: 'short',\n\t\tyear: 'numeric',\n\t\ttimeZone: 'UTC'\n\t});\n}"}
]}
```

`src/lib/server/check.ts` recebe valores de formulários e requisições, que podem ser qualquer coisa:

```schooling-example
{"language": "typescript", "file": "src/lib/server/check.ts", "parts": [
 {"code": "// check.ts: what a session must look like, wherever it comes from.\nimport { isDate } from '#lib/week.js';"},
 {"code": "/** What is wrong with a session's date and minutes, or undefined if nothing is. */\nexport function problemWith({ date, minutes }: { date: unknown; minutes: unknown }) {\n\tif (!isDate(date)) return 'The session needs a date.';\n\tif (typeof minutes !== 'number' || !Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\treturn 'Minutes must be a whole number from 5 to 600.';\n\t}\n}", "note": "`unknown` quer dizer \"cheque antes de usar\", e o verificador cobra isso da função: `minutes < 5` só é permitido depois que `typeof minutes !== 'number'` descartou o resto."}
]}
```

e `src/lib/server/planner.ts` diz o que lê e o que cada mudança recebe:

```schooling-example
{"language": "typescript", "file": "src/lib/server/planner.ts", "parts": [
 {"code": "// planner.ts: the planner's data, read from and written to the file the server keeps it in.\nimport { readFile, writeFile, rename } from 'node:fs/promises';\nimport type { PlannerData, Session } from '#lib/types.js';\n\nconst FILE = 'data/planner.json';"},
 {"code": "export async function readPlanner(): Promise<PlannerData> {\n\treturn JSON.parse(await readFile(FILE, 'utf8'));\n}\n\n// Changes run one at a time: each waits for the one before it to finish, so two\n// requests arriving together cannot both read the old file and lose a change.\nlet queue: Promise<unknown> = Promise.resolve();", "note": "`Promise<PlannerData>` é uma afirmação, não uma checagem: o `JSON.parse` devolve o que o arquivo tiver, e esta linha manda o verificador acreditar que é um planner. A última seção desta aula volta a isso."},
 {"code": "\nfunction change<T>(edit: (planner: PlannerData) => T): Promise<T> {\n\tconst result = queue.then(async () => {\n\t\tconst planner = await readPlanner();\n\t\tconst answer = edit(planner);\n\t\t// Write a new file and then put it in the old one's place, so that a crash\n\t\t// halfway through leaves the old file whole rather than half of a new one.\n\t\tawait writeFile(`${FILE}.new`, JSON.stringify(planner, null, '\\t') + '\\n');\n\t\tawait rename(`${FILE}.new`, FILE);\n\t\treturn answer;\n\t});\n\tqueue = result.catch(() => {});\n\treturn result;\n}\n\n/** Add a session; false if there is no such course. */\nexport function addSession({ course, date, minutes }: Omit<Session, 'id' | 'done'>) {\n\treturn change((planner) => {\n\t\tif (!planner.courses.some((c) => c.id === course)) return false;\n\t\tconst id = Math.max(0, ...planner.sessions.map((s) => s.id)) + 1;\n\t\tplanner.sessions.push({ id, course, date, minutes, done: false });\n\t\treturn true;\n\t});\n}\n\n/** Mark a session done or not done; the session, or undefined if there is none. */\nexport function setDone(id: number, done: boolean) {\n\treturn change((planner) => {\n\t\tconst session = planner.sessions.find((s) => s.id === id);\n\t\tif (session) session.done = done;\n\t\treturn session;\n\t});\n}", "note": "`change` é genérica: `T` é o que `edit` devolver, então `addSession` recebe de volta um booleano e `setDone` uma sessão, cada um com o seu tipo."}
]}
```

`Omit<Session, 'id' | 'done'>` é uma sessão sem os dois campos que o módulo preenche sozinho, que é
exatamente o que quem chama precisa fornecer. Conte de novo:

```
ana@dev:~/planner$ npm run check 2>&1 | tail -1
svelte-check found 36 errors and 0 warnings in 9 files
```

**Trinta e seis, de sessenta e seis**, e nenhum arquivo mudou de comportamento: cada linha que roda é a
linha que rodava antes. Os erros que sobram estão nos arquivos que usam esses módulos, que ainda não
dizem o que são os seus próprios parâmetros.
