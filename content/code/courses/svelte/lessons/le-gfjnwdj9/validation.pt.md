---
title: Quando o formulário está errado
version: 1
---

**O navegador confere um formulário antes de enviá-lo, e o servidor precisa conferir de novo.** O
`required`, o `min` e o `max` dos inputs são conferidos pelo próprio navegador, com ou sem JavaScript, e
ele se recusa a enviar um formulário que os desrespeite. Tente três minutos:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --no-js --fill 'Date=2026-10-22' --fill 'Minutes=3' --click 'Add session'
-- fill Date=2026-10-22
-- fill Minutes=3
-- click Add session
at /courses/guitar
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
    - listitem:
      - checkbox "21 Oct 2026, 30 min"
      - text: 21 Oct 2026, 30 min
    - listitem:
      - checkbox "23 Oct 2026, 30 min"
      - text: 23 Oct 2026, 30 min
  - paragraph: 105 minutes for Guitar this week (1 h 45 min)
  - text: Date
  - textbox "Date": 2026-10-22
  - text: Minutes
  - spinbutton "Minutes": "3"
  - button "Add session"
```

Continua `at /courses/guitar`, nenhuma sessão no dia 22, e os dois valores ainda nos seus campos: o
formulário nunca foi enviado. Uma pessoa usando a página vê a mensagem do próprio navegador ao lado do
campo, na sua própria língua. **Isso é uma conveniência, não uma proteção.** Qualquer coisa pode enviar
um `POST` para a página, o `curl` fez isso na seção anterior, e a action, do jeito que está, grava o
que chegar:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-10-22&minutes=-40' http://localhost:5173/courses/guitar
303
```

Um 303, a resposta da action para uma sessão salva, e o planner acredita:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar | grep min
      - checkbox "20 Oct 2026, 45 min"
      - text: 20 Oct 2026, 45 min
      - checkbox "21 Oct 2026, 30 min"
      - text: 21 Oct 2026, 30 min
      - checkbox "22 Oct 2026, -40 min"
      - text: 22 Oct 2026, -40 min
      - checkbox "23 Oct 2026, 30 min"
      - text: 23 Oct 2026, 30 min
  - paragraph: 65 minutes for Guitar this week (1 h 5 min)
```

Quarenta minutos negativos de violão, somados na semana. Devolva o arquivo ao estado em que o Git o viu
pela última vez, o que também tira as sessões que a seção anterior acrescentou, antes de seguir:

```
ana@dev:~/planner$ git checkout data/planner.json
Updated 1 path from the index
```

## `fail()`

**`fail(status, data)` é como uma action diz que o formulário estava errado.** Ele não é lançado, é
devolvido, e não mostra a página de erro: a página renderiza de novo, como resposta ao `POST`, com o
status dado e `data` disponível para ela como o **resultado do formulário**, para que ela possa dizer o
que estava errado e manter o que a pessoa digitou. Substitua o `+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's form does, on the server.\nimport { error, fail, redirect } from '@sveltejs/kit';\nimport { addSession } from '#lib/server/planner.js';\nimport { isDate } from '#lib/week.js';\n\nexport const actions = {\n\tdefault: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tconst date = String(form.get('date') ?? '');\n\t\tconst minutes = Number(form.get('minutes'));"},
 {"code": "\t\tif (!isDate(date)) return fail(400, { date, minutes, problem: 'The session needs a date.' });\n\t\tif (!Number.isInteger(minutes) || minutes < 5 || minutes > 600) {\n\t\t\treturn fail(400, { date, minutes, problem: 'Minutes must be a whole number from 5 to 600.' });\n\t\t}", "note": "400 é Bad Request: o problema está no que foi enviado. O objeto volta para a página, então deve conter só o que a página pode mostrar."},
 {"code": "\t\tif (!(await addSession({ course: params.id, date, minutes }))) error(404, 'There is no such course.');\n\n\t\tredirect(303, `/courses/${params.id}`);\n\t}\n};", "note": "Um curso que não existe não é um erro no formulário, então é `error()` e a página de erro, como na função load."}
]}
```

O `isDate` é novo. Uma data que casa com `YYYY-MM-DD` ainda pode não ser data nenhuma, o 31 de
fevereiro, então ele escreve a data de volta e confere se o mesmo texto volta. Acrescente-o ao
`src/lib/week.js`, que agora fica assim:

```schooling-example
{"language": "javascript", "file": "src/lib/week.js", "parts": [
 {"code": "// week.js: dates as 'YYYY-MM-DD' strings, and the week they fall in.\n// Weeks start on Monday.\nconst DAY = 24 * 60 * 60 * 1000;\nconst toTime = (date) => Date.parse(`${date}T00:00:00Z`);\nconst toDate = (time) => new Date(time).toISOString().slice(0, 10);"},
 {"code": "/** Whether `text` is a real date, written as 'YYYY-MM-DD'. */\nexport function isDate(text) {\n\treturn /^\\d{4}-\\d{2}-\\d{2}$/.test(text) && toDate(toTime(text)) === text;\n}\n\n/** The Monday of the week `date` falls in. */\nexport function mondayOf(date) {\n\tconst day = new Date(toTime(date)).getUTCDay();\n\treturn toDate(toTime(date) - ((day + 6) % 7) * DAY);\n}\n\n/** `date` moved by `days`, which may be negative. */\nexport function addDays(date, days) {\n\treturn toDate(toTime(date) + days * DAY);\n}\n\n/** Whether `date` falls in the week that starts on `monday`. */\nexport function inWeek(date, monday) {\n\treturn date >= monday && date < addDays(monday, 7);\n}\n\n/** `2026-10-19` as `19 Oct 2026`. */\nexport function format(date) {\n\treturn new Date(toTime(date)).toLocaleDateString('en-GB', {\n\t\tday: 'numeric',\n\t\tmonth: 'short',\n\t\tyear: 'numeric',\n\t\ttimeZone: 'UTC'\n\t});\n}", "note": "`2026-02-31` é lido como 3 de março, e escrito de volta como `2026-03-03`, que não é o que entrou."}
]}
```

O formulário mostra o problema e devolve os valores. O resultado do formulário chega a qualquer
componente por `page.form`, de `$app/state`, então a página do curso não precisa repassá-lo. Substitua o
`src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\timport { page } from '$app/state';"},
 {"code": "\tlet form = $derived(page.form);\n</script>\n\n<form method=\"POST\">", "note": "`page.form` é o que a última action devolveu, enquanto a página mostra a resposta dessa action, e `undefined` fora disso."},
 {"code": "\t{#if form?.problem}\n\t\t<p role=\"alert\">{form.problem}</p>\n\t{/if}\n\t<label>Date <input type=\"date\" name=\"date\" required value={form?.date ?? ''} /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value={form?.minutes ?? 30} /></label>\n\t<button>Add session</button>\n</form>", "note": "`role=\"alert\"` faz um leitor de tela anunciar a mensagem quando ela aparece, sem que a pessoa precise procurá-la."}
]}
```

```
ana@dev:~/planner$ curl -s -w '%{http_code}\n' -H 'Accept: text/html' -d 'date=2026-02-31&minutes=30' http://localhost:5173/courses/guitar | grep -o '<p role="alert">[^<]*</p>\|^[0-9]*$'
<p role="alert">The session needs a date.</p>
400
```

**Um 400, e a página com o problema nela**, renderizada no servidor. Uma pessoa com o JavaScript
desligado cujo formulário passasse pelas conferências do navegador veria exatamente essa página, com os
seus valores ainda nos campos. As conferências do navegador tornam os erros baratos de corrigir; as da
action os tornam impossíveis de salvar.
