---
title: Recebendo dados, e conferindo-os num lugar só
version: 1
---

**Um endpoint também pode receber dados, com `POST`, e para um programa, e não uma pessoa, muitas vezes
essa é a porta certa.** Um script que importa sessões de uma agenda, ou um atalho no celular, não tem uso
para um formulário HTML; ele manda JSON e lê JSON de volta. O planner pode receber sessões assim em
`/api/sessions`.

Um endpoint que acrescenta sessões precisa conferi-las exatamente como a action do formulário faz, e
uma regra escrita duas vezes são duas regras que vão se afastar uma da outra. Então a conferência sai da
action para um módulo próprio, e os dois o usam. Salve isto como `src/lib/server/check.js`:

```schooling-example
{"language": "javascript", "file": "src/lib/server/check.js", "parts": [
 {"code": "// check.js: what a session must look like, wherever it comes from.\nimport { isDate } from '#lib/week.js';"},
 {"code": "/** What is wrong with a session's date and minutes, or undefined if nothing is. */\nexport function problemWith({ date, minutes }) {\n\tif (!isDate(date)) return 'The session needs a date.';\n\tif (!Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\treturn 'Minutes must be a whole number from 5 to 600.';\n\t}\n}", "note": "Ela devolve a frase a mostrar, ou nada quando a sessão está boa, então cada um que a chama decide como responder."}
]}
```

A action o usa. Substitua `src/routes/(planner)/courses/[id=slug]/+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's forms do, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession, setDone } from '#lib/server/planner.js';\nimport { problemWith } from '#lib/server/check.js';\nimport { mondayOf } from '#lib/week.js';\n\nexport const actions = {\n\tadd: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));"},
 {"code": "\t\tconst problem = problemWith({ date, minutes });\n\t\tif (problem) return fail(400, { date, minutes, problem });\n\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(date)}`);\n\t},\n\n\tdone: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst session = await setDone(Number(form.get('id')), form.get('done') === 'yes');\n\t\tif (!session) error(404, 'There is no such session.');\n\n\t\tredirect(303, `/courses/${params.id}?week=${mondayOf(session.date)}`);\n\t}\n};", "note": "Os dois `if` da aula 14 viraram uma chamada. O que a action faz com um problema, o `fail()` e os valores de volta para o formulário, fica aqui, porque é coisa de formulário."}
]}
```

e o endpoint também. Salve isto como `src/routes/api/sessions/+server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/api/sessions/+server.js", "parts": [
 {"code": "// +server.js: add a session from another program, as JSON, at /api/sessions.\nimport { error, json } from '@sveltejs/kit';\nimport { addSession } from '#lib/server/planner.js';\nimport { problemWith } from '#lib/server/check.js';\n\nexport async function POST({ request }) {"},
 {"code": "\tif (!request.headers.get('content-type')?.startsWith('application/json')) {\n\t\terror(415, 'Send the session as JSON, with Content-Type: application/json.');\n\t}\n\tconst body = await request.json().catch(() => error(400, 'The body is not valid JSON.'));", "note": "Recusar tudo o que não é JSON é uma proteção além de uma gentileza: a próxima parte diz por quê."},
 {"code": "\tconst session = { course: body.course, date: body.date, minutes: body.minutes };\n\tconst problem = problemWith(session);\n\tif (problem) error(400, problem);\n\tif (!(await addSession(session))) error(404, `There is no course called “${session.course}”.`);", "note": "Só os três campos de que uma sessão precisa são tirados do corpo. Qualquer outra coisa nele, um `id` ou um `done`, é ignorada em vez de ir para o arquivo."},
 {"code": "\treturn json(session, { status: 201 });\n}", "note": "201 Created é o status de uma requisição que criou algo novo."}
]}
```

```
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{"course":"spanish","date":"2026-10-24","minutes":20}' http://localhost:5173/api/sessions
{"course":"spanish","date":"2026-10-24","minutes":20} 201
```

```
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -H 'Content-Type: application/json' -d '{"course":"spanish","date":"2026-10-24","minutes":2}' http://localhost:5173/api/sessions
{"status":400,"message":"Minutes must be a whole number from 5 to 600."} 400
```

**Um 201 com a sessão, e um 400 com a frase da action**, saídos da única função que os dois usam. O
formulário diz a mesma coisa:

```
ana@dev:~/planner$ curl -s -H 'Accept: text/html' -d 'date=2026-10-24&minutes=2' 'http://localhost:5173/courses/spanish?/add' | grep -o '<p role="alert">[^<]*</p>'
<p role="alert">Minutes must be a whole number from 5 to 600.</p>
```

## O formulário que podia se passar por JSON

A checagem da aula 15 recusa formulários enviados de outros sites, e um endpoint não é um formulário. O
que o protege? Uma página em outro site não consegue mandar `Content-Type: application/json` com
`fetch` ao planner sem o navegador perguntar antes ao planner, com uma requisição `OPTIONS`, se isso é
permitido. O planner não tem handler de `OPTIONS` e não diz nada que permita, então o navegador se recusa
a mandar a requisição de verdade. Um formulário HTML comum nesse site não consegue escolher o tipo: ele só
manda os três tipos que formulários mandam, `application/x-www-form-urlencoded`, `multipart/form-data` e
`text/plain`, e `text/plain` pode levar um corpo igualzinho a JSON.

**É por isso que o endpoint confere o `Content-Type` antes de ler o corpo.** O `request.json()` interpreta
o texto que chegar, diga o cabeçalho o que disser, então sem a conferência um formulário forjado em
`text/plain` com `{"course":"spanish",...}` dentro seria lido como JSON e salvo. Com ela, a requisição é
respondida com 415 antes de qualquer coisa ser lida. A checagem do próprio SvelteKit, da aula 15, também
recusa envios `text/plain` de outros sites num build, então há duas trancas nessa porta; cada uma
seguraria sozinha, e nenhuma custa nada.

```
ana@dev:~/planner$ curl -s -w ' %{http_code}\n' -H 'Content-Type: text/plain' -d '{"course":"spanish","date":"2026-10-24","minutes":20}' http://localhost:5173/api/sessions
{"status":415,"message":"Send the session as JSON, with Content-Type: application/json."} 415
```
