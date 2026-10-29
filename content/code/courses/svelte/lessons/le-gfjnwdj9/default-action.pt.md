---
title: Uma form action
version: 1
---

**Uma form action é uma função no `+page.server.js` de uma página que roda quando um formulário é
enviado a essa página com `POST`.** O navegador envia o formulário como os navegadores sempre fizeram,
como campos com nomes, e a action os lê, faz o trabalho e responde. Não há `fetch` nem JSON no
componente, e nenhum JavaScript necessário no navegador.

Salve isto ao lado da página do curso, como `src/routes/(planner)/courses/[id=slug]/+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's form does, on the server.\nimport { addSession } from '#lib/server/planner.js';"},
 {"code": "export const actions = {\n\tdefault: async ({ request, params }) => {", "note": "`actions` é um objeto de funções. Uma chamada `default` atende todo `POST` para a página."},
 {"code": "\t\tconst form = await request.formData();\n\t\tawait addSession({\n\t\t\tcourse: params.id,\n\t\t\tdate: String(form.get('date')),\n\t\t\tminutes: Number(form.get('minutes'))\n\t\t});\n\t}\n};", "note": "`request` é o `Request` padrão, e `formData()` lê os campos que o navegador enviou, pelo nome."}
]}
```

O formulário precisa ser um que o navegador consiga enviar sozinho: `method="POST"`, e um `name` em
cada campo. Ele não chama mais ninguém, então não precisa de props nem de script próprio. Substitua o
`src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<form method=\"POST\">"},
 {"code": "\t<label>Date <input type=\"date\" name=\"date\" required /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value=\"30\" /></label>\n\t<button>Add session</button>\n</form>", "note": "O `name` é a chave que a action lê com `form.get('date')`. O label continua nomeando o campo para uma pessoa."}
]}
```

Na página do curso, o `AddSession` perde o seu `onadd`, que ninguém mais chama. Substitua o
`src/routes/(planner)/courses/[id=slug]/+page.svelte`:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} onchange={(next) => (planner.week = next)} />\n<List items={sessions}>\n\t{#snippet row(session)}\n\t\t<label class:done={session.done}>\n\t\t\t<input type=\"checkbox\" bind:checked={session.done} />\n\t\t\t{format(session.date)}, {session.minutes} min\n\t\t</label>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />"},
 {"code": "{#key planner.week}\n\t<AddSession />\n{/key}", "note": "A única mudança: sem `onadd`. O formulário se envia sozinho."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

Agora, ainda com o JavaScript desligado:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --no-js --fill 'Date=2026-10-21' --click 'Add session'
-- fill Date=2026-10-21
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
  - paragraph: 75 minutes for Guitar this week (1 h 15 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

**Trinta minutos no dia 21, salvos.** O navegador enviou `date=2026-10-21&minutes=30` para
`/courses/guitar` com `POST`; o SvelteKit rodou a action default, depois as funções load da página, que
leram o arquivo que a action tinha acabado de escrever, e respondeu com a página. Está no arquivo:

```
ana@dev:~/planner$ tail -8 data/planner.json
			"id": 7,
			"course": "guitar",
			"date": "2026-10-21",
			"minutes": 30,
			"done": false
		}
	]
}
```

## Responda a um POST com um redirecionamento

A página que voltou é a resposta a um `POST`. Se o estudante agora recarregar, o navegador se oferece
para enviar o formulário de novo, e se ele aceitar, ficam duas sessões no dia 21. O botão Voltar pode
fazer o mesmo. A cura antiga e confiável é responder a um `POST` que deu certo com um
**redirecionamento** para uma página comum, para que o que o navegador tem na tela seja a resposta a um
`GET`, e recarregá-la só leia. O padrão tem nome, **Post/Redirect/Get**, e o status para ele é **303 See
Other**, que diz ao navegador para buscar o endereço novo com `GET`, seja qual for o método que o levou
até ali. Substitua o `+page.server.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(planner)/courses/[id=slug]/+page.server.js", "parts": [
 {"code": "// +page.server.js: what a course page's form does, on the server.\nimport { redirect } from '@sveltejs/kit';\nimport { addSession } from '#lib/server/planner.js';\n\nexport const actions = {\n\tdefault: async ({ request, params }) => {\n\t\tconst form = await request.formData();\n\t\tawait addSession({\n\t\t\tcourse: params.id,\n\t\t\tdate: String(form.get('date')),\n\t\t\tminutes: Number(form.get('minutes'))\n\t\t});"},
 {"code": "\t\tredirect(303, `/courses/${params.id}`);\n\t}\n};", "note": "`redirect()` lança, como o `error()`, então nada depois dele roda."}
]}
```

O `curl` também consegue enviar um formulário, com `-d` e os campos, e mostrar o que voltou:

```
ana@dev:~/planner$ curl -s -o /dev/null -w '%{http_code} %{redirect_url}\n' -H 'Accept: text/html' -d 'date=2026-10-23&minutes=30' http://localhost:5173/courses/guitar
303 http://localhost:5173/courses/guitar
```

`-H 'Accept: text/html'` diz o que um navegador diz, que quer uma página. Sem ele, o SvelteKit toma a
requisição por uma vinda do seu próprio JavaScript, assunto da última seção desta aula, e responde com
JSON.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Post/Redirect/Get, como três trocas entre o navegador à esquerda e o servidor à direita. Primeiro o navegador envia POST /courses/guitar com date e minutes; o servidor roda a action, que salva a sessão, e responde 303 See Other com um cabeçalho Location que aponta para /courses/guitar. Depois o navegador envia GET /courses/guitar; o servidor roda as funções load, que leem o arquivo de novo, e responde 200 com a página. O que o navegador mostra agora é a resposta a um GET, então recarregar só lê a página de novo.\"><text x=\"90\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">navegador</text><text x=\"630\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">servidor</text><line x1=\"90\" y1=\"32\" x2=\"90\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><line x1=\"630\" y1=\"32\" x2=\"630\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 4\"></line><line x1=\"92\" y1=\"60\" x2=\"520\" y2=\"60\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"520.0,60.0 512.6,63.1 512.6,56.9\" fill=\"var(--phosphor)\"></polygon><text x=\"300\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">POST /courses/guitar  date=2026-10-21&amp;minutes=30</text><rect x=\"522\" y=\"42\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"617\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a action salva</text><text x=\"617\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">addSession(…)</text><line x1=\"520\" y1=\"110\" x2=\"94\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"94.0,110.0 101.4,106.9 101.4,113.1\" fill=\"var(--amber)\"></polygon><text x=\"300\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">303 See Other   Location: /courses/guitar</text><line x1=\"92\" y1=\"160\" x2=\"520\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"520.0,160.0 512.6,163.1 512.6,156.9\" fill=\"var(--phosphor)\"></polygon><text x=\"300\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">GET /courses/guitar</text><rect x=\"522\" y=\"142\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"617\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">as funções load leem</text><text x=\"617\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">readPlanner()</text><line x1=\"520\" y1=\"210\" x2=\"94\" y2=\"210\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"94.0,210.0 101.4,206.9 101.4,213.1\" fill=\"var(--amber)\"></polygon><text x=\"300\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">200, a página com a sessão nova</text><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recarregar agora repete o GET, que só lê</text></svg>", "caption": "Um formulário que deu certo é respondido com um redirecionamento, então a página na tela é a resposta a um GET."}
```
