---
title: Salvando no arquivo
version: 1
---

Primeiro, tire as duas linhas de `console.log` que a aula 13 acrescentou para observar as funções load,
para que o terminal do servidor de desenvolvimento mostre só o que esta aula faz. O
`src/routes/(planner)/+layout.server.js` volta a ser:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/+layout.server.js", "parts": [
 {"code": "// +layout.server.js: the data every page of the planner needs, read on the server.\nimport { readPlanner } from '#lib/server/planner.js';\n\nexport async function load() {\n\treturn readPlanner();\n}", "note": "Como a aula 13 o escreveu primeiro, antes do `console.log`."}
]}
```

e o `src/routes/(planner)/courses/[id=slug]/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.js", "parts": [
 {"code": "// +page.js: the course a course page is about, or a 404.\nimport { error } from '@sveltejs/kit';\n\nexport async function load({ params, parent }) {\n\tconst { courses } = await parent();\n\tconst course = courses.find((c) => c.id === params.id);\n\tif (!course) error(404, `There is no course called “${params.id}”.`);\n\treturn { course };\n}", "note": "Como a aula 13 o escreveu primeiro, antes do `console.log`."}
]}
```

## Escrevendo o arquivo

**Antes que um formulário possa salvar qualquer coisa, o servidor precisa de código que escreva o
arquivo do planner.** Ele vai no módulo que já o lê, `src/lib/server/planner.js`, que fica no servidor.
Duas mudanças valem a pena desde o início, e as duas tratam do que acontece quando algo dá errado.
Substitua o arquivo:

```schooling-example
{"language": "javascript", "file": "src/lib/server/planner.js", "parts": [
 {"code": "// planner.js: the planner's data, read from and written to the file the server keeps it in.\nimport { readFile, writeFile, rename } from 'node:fs/promises';\n\nconst FILE = 'data/planner.json';\n\nexport async function readPlanner() {\n\treturn JSON.parse(await readFile(FILE, 'utf8'));\n}"},
 {"code": "// Changes run one at a time: each waits for the one before it to finish, so two\n// requests arriving together cannot both read the old file and lose a change.\nlet queue = Promise.resolve();", "note": "Cada mudança espera a anterior. Sem isso, duas requisições chegando juntas leriam as duas o arquivo antigo, e a segunda a escrever desfaria a primeira."},
 {"code": "function change(edit) {\n\tconst result = queue.then(async () => {\n\t\tconst planner = await readPlanner();\n\t\tconst answer = edit(planner);", "note": "`edit` altera o objeto planner que recebe, e o que ele devolve é o que quem chamou recebe de volta."},
 {"code": "\t\t// Write a new file and then put it in the old one's place, so that a crash\n\t\t// halfway through leaves the old file whole rather than half of a new one.\n\t\tawait writeFile(`${FILE}.new`, JSON.stringify(planner, null, '\\t') + '\\n');\n\t\tawait rename(`${FILE}.new`, FILE);\n\t\treturn answer;\n\t});", "note": "`rename` troca um arquivo num passo só, então o arquivo no disco é sempre um planner inteiro, o antigo ou o novo."},
 {"code": "\tqueue = result.catch(() => {});\n\treturn result;\n}\n\n/** Add a session; false if there is no such course. */\nexport function addSession({ course, date, minutes }) {\n\treturn change((planner) => {\n\t\tif (!planner.courses.some((c) => c.id === course)) return false;\n\t\tconst id = Math.max(0, ...planner.sessions.map((s) => s.id)) + 1;\n\t\tplanner.sessions.push({ id, course, date, minutes, done: false });\n\t\treturn true;\n\t});\n}\n\n/** Mark a session done or not done; the session, or undefined if there is none. */\nexport function setDone(id, done) {\n\treturn change((planner) => {\n\t\tconst session = planner.sessions.find((s) => s.id === id);\n\t\tif (session) session.done = done;\n\t\treturn session;\n\t});\n}", "note": "Uma mudança que falhou não pode travar as seguintes, então a fila segue em frente tendo dado certo ou não. Quem chamou ainda recebe a falha, por meio de `result`."}
]}
```

**A fila funciona porque existe um único processo de servidor.** Toda requisição é respondida pelo
mesmo processo Node, então uma cadeia de promises num módulo vê todas as mudanças. Uma aplicação com
vários servidores, ou que roda como muitas funções de vida curta na nuvem, não tem um lugar único para
uma fila, e esse é um dos motivos pelos quais aplicações assim guardam os dados num banco de dados, que
põe as mudanças em ordem sozinho. Para o planner de uma pessoa num computador, um arquivo e uma fila
bastam, e mantêm a aula sobre formulários e não sobre bancos de dados.

O id de uma sessão nova é um a mais que o maior id que existe. O id é o que o planner usa para
distinguir as sessões, como faz a chave do `{#each}` da aula 8, então ele nunca pode ser reaproveitado
enquanto a sessão que ele nomeava ainda existir. Contar as sessões, em vez disso, reaproveitaria um id
no momento em que uma sessão fosse apagada.
