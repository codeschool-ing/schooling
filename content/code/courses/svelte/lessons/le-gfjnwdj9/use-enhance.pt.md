---
title: use:enhance, e os mesmos formulários sem recarregar
version: 1
---

**O `use:enhance` faz um formulário que já funciona se enviar com JavaScript, quando há JavaScript.**
Ele vem de `$app/forms` e vai no `<form>` como um atributo, `use:enhance`, que é a sintaxe do Svelte
para uma **action** no outro sentido da palavra: uma função que roda num elemento quando ele é criado.
Esta escuta o `submit`, impede o envio do próprio navegador, manda os mesmos campos para o mesmo
endereço com `fetch`, e então faz com a resposta o que o navegador teria feito, sem carregar uma página
nova.

Nada no servidor muda, e nada nos campos do formulário. Substitua o `src/lib/AddSession.svelte`:

```schooling-example
{"language": "html", "file": "src/lib/AddSession.svelte", "parts": [
 {"code": "<script>\n\timport { enhance } from '$app/forms';\n\timport { page } from '$app/state';\n\n\tlet { action } = $props();\n\tlet form = $derived(page.form);"},
 {"code": "\tlet sending = $state(false);", "note": "`sending` fica verdadeiro enquanto o formulário está a caminho, o que demora o bastante para importar numa conexão lenta."},
 {"code": "\tfunction submit() {\n\t\tsending = true;\n\t\treturn async ({ update }) => {\n\t\t\tawait update();\n\t\t\tsending = false;\n\t\t};\n\t}\n</script>", "note": "Chamada quando o formulário é enviado. O que ela devolve é chamado com a resposta; o `update()` então faz tudo o que o `use:enhance` teria feito sozinho."},
 {"code": "<form method=\"POST\" {action} use:enhance={submit}>\n\t{#if form?.problem}\n\t\t<p role=\"alert\">{form.problem}</p>\n\t{/if}\n\t<label>Date <input type=\"date\" name=\"date\" required value={form?.date ?? ''} /></label>\n\t<label>Minutes <input type=\"number\" name=\"minutes\" min=\"5\" max=\"600\" step=\"5\" required value={form?.minutes ?? 30} /></label>", "note": "Sem JavaScript este atributo não faz nada, e o formulário é enviado do jeito que as seções anteriores o enviaram."},
 {"code": "\t<button disabled={sending}>{sending ? 'Adding…' : 'Add session'}</button>\n</form>", "note": "Um botão desabilitado não pode ser apertado duas vezes, então uma resposta lenta não pode virar duas sessões."}
]}
```

e os formulários das linhas também ganham o atributo, simples, sem função. No
`src/routes/(planner)/courses/[id=slug]/+page.svelte`, que chega aqui à sua última versão:

```schooling-example
{"language": "html", "file": "src/routes/(planner)/courses/[id=slug]/+page.svelte", "parts": [
 {"code": "<script>\n\timport { enhance } from '$app/forms';\n\timport { format } from '#lib/week.js';\n\timport { getPlanner } from '#lib/context.js';\n\timport WeekNav from '#lib/WeekNav.svelte';\n\timport WeekTotal from '#lib/WeekTotal.svelte';\n\timport List from '#lib/List.svelte';\n\timport AddSession from '#lib/AddSession.svelte';\n\n\tlet { data } = $props();\n\n\tconst planner = getPlanner();\n\tlet course = $derived(data.course);\n\tlet sessions = $derived(planner.sessionsFor(course.id));\n</script>\n\n<svelte:head>\n\t<title>{course.name} · Study planner</title>\n</svelte:head>\n<h1>{course.name}</h1>\n<WeekNav week={planner.week} />\n<List items={sessions}>\n\t{#snippet row(session)}\n\t\t<form method=\"POST\" action=\"?week={planner.week}&/done\" use:enhance>\n\t\t\t<input type=\"hidden\" name=\"id\" value={session.id} />\n\t\t\t<input type=\"hidden\" name=\"done\" value={session.done ? 'no' : 'yes'} />\n\t\t\t<span class:done={session.done}>{format(session.date)}, {session.minutes} min</span>\n\t\t\t<button aria-label=\"{session.done ? 'Mark not done' : 'Mark done'}: {format(session.date)}\">\n\t\t\t\t{session.done ? 'Mark not done' : 'Mark done'}\n\t\t\t</button>\n\t\t</form>\n\t{/snippet}\n\t{#snippet empty()}\n\t\t<p>Nothing planned for {course.name} this week.</p>\n\t{/snippet}\n</List>\n<WeekTotal minutes={planner.byCourse[course.id] ?? 0} label=\"for {course.name} this week\" />\n{#key planner.week}\n\t<AddSession action=\"?week={planner.week}&/add\" />\n{/key}", "note": "`enhance` é importado aqui para os formulários das linhas. O `AddSession` importa o seu."},
 {"code": "<style>\n\t.done {\n\t\ttext-decoration: line-through;\n\t}\n</style>"}
]}
```

Reinicie o servidor de desenvolvimento para que o terminal fique vazio, e acrescente uma sessão com o
JavaScript ligado:

```
ana@dev:~/planner$ look http://localhost:5173/courses/guitar --fill 'Date=2026-10-21' --click 'Add session' --wait 500
-- fill Date=2026-10-21
-- click Add session
-- wait 500
at /courses/guitar?week=2026-10-19
title: Guitar · Study planner
- main:
  - heading "Guitar" [level=1]
  - paragraph:
    - link "Previous week":
      - /url: "?week=2026-10-12"
    - text: Week of 19 Oct 2026
    - link "Next week":
      - /url: "?week=2026-10-26"
  - list:
    - listitem:
      - text: 20 Oct 2026, 45 min
      - 'button "Mark done: 20 Oct 2026"': Mark done
    - listitem:
      - text: 21 Oct 2026, 30 min
      - 'button "Mark done: 21 Oct 2026"': Mark done
  - paragraph: 75 minutes for Guitar this week (1 h 15 min)
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
```

A página abriu na semana do dia 12, a semana da sessão acrescentada por último, e foi para a semana do
dia 19, em que cai o dia 21, quando a resposta chegou. O `--wait 500` dá tempo para a linha do dia 14 terminar de deslizar
para fora da lista, como fazem as transições da aula 9. O resultado é o mesmo que o JavaScript
desligado deu, e o terminal que roda o `npm run dev` mostra que ele chegou de outro jeito:

```
ana@dev:~/planner$ npm run dev

> planner@0.0.1 dev
> vite dev

9:41:13 PM [vite] (ssr) connected.

  VITE v8.3.5  ready in 597 ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
200 GET /courses/guitar
200 POST /courses/guitar?week=2026-10-12&/add
200 GET /courses/guitar/__data.json?week=2026-10-19&x-sveltekit-invalidated=011
```

**Um `POST` e um pedido de dados, onde o JavaScript desligado fez um `POST` e depois pediu uma página
inteira.** Depois da primeira página, não há nenhum `GET` de página. A resposta da action voltou como
JSON, a resposta que "Uma form action" disse que uma requisição sem `Accept: text/html` recebe. O
`curl` pode pedir do mesmo jeito:

```
ana@dev:~/planner$ curl -s -w '\n' -d 'date=2026-10-22&minutes=30' 'http://localhost:5173/courses/guitar?week=2026-10-19&/add'
{"type":"redirect","status":303,"location":"/courses/guitar?week=2026-10-19"}
```

O `use:enhance` seguiu essa resposta com uma navegação no cliente até o `location`, que rodou de novo
as funções load, a linha do `__data.json`; o `+layout.js` leu a semana do endereço novo, e o planner,
que lê os seus dados em vez de copiá-los, mostrou a sessão nova. **É a seção anterior dando resultado.**
Um planner criado uma vez a partir de `untrack(() => data)` teria mantido as sessões antigas na tela,
com as novas salvas no disco.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"O mesmo formulário enviado de dois jeitos. À esquerda, com JavaScript desligado: o navegador envia o formulário com POST, a action responde 303, o navegador pede a página inteira com GET, e o servidor a renderiza. À direita, com use:enhance: o script do navegador interrompe o envio e manda os mesmos campos com fetch; a action responde com JSON dizendo redirect; o script pede __data.json, os dados das funções load e não uma página, e atualiza a página que já está na tela. A action e as funções load são o mesmo código nos dois.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">JavaScript desligado</text><rect x=\"20\" y=\"40\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">POST</text><text x=\"140\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o navegador envia o formulário</text><line x1=\"180\" y1=\"86\" x2=\"180\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,102.0 176.9,94.6 183.1,94.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"20\" y=\"104\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">303</text><text x=\"140\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a action salva e redireciona</text><line x1=\"180\" y1=\"150\" x2=\"180\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,166.0 176.9,158.6 183.1,158.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"20\" y=\"168\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">GET</text><text x=\"140\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o navegador pede a página</text><line x1=\"180\" y1=\"214\" x2=\"180\" y2=\"230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"180.0,230.0 176.9,222.6 183.1,222.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"20\" y=\"232\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"34\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">HTML</text><text x=\"140\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma página nova inteira</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">use:enhance</text><rect x=\"380\" y=\"40\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"394\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">fetch POST</text><text x=\"500\" y=\"63\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os mesmos campos, de um script</text><line x1=\"540\" y1=\"86\" x2=\"540\" y2=\"102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,102.0 536.9,94.6 543.1,94.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"104\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"394\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">JSON</text><text x=\"500\" y=\"127\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a mesma action, a resposta como dados</text><line x1=\"540\" y1=\"150\" x2=\"540\" y2=\"166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,166.0 536.9,158.6 543.1,158.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"168\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"394\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">__data.json</text><text x=\"500\" y=\"191\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as funções load rodam de novo</text><line x1=\"540\" y1=\"214\" x2=\"540\" y2=\"230\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,230.0 536.9,222.6 543.1,222.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"380\" y=\"232\" width=\"320\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"394\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">DOM</text><text x=\"500\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a página que já está na tela</text><text x=\"360\" y=\"312\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a action e as funções load são o mesmo código dos dois lados</text></svg>", "caption": "O use:enhance muda como o formulário viaja e o que volta, não o que o servidor faz com ele."}
```

## O que mais ele faz

Sem função, ou quando a função chama `update()`, o `use:enhance` faz no lugar o que um navegador teria
feito:

- **Um redirecionamento** vira uma navegação no cliente até o seu endereço, com todas as funções load
  rodando de novo.
- **Um `fail()`** atualiza o `page.form` e o status da página, então a mensagem com `role="alert"`
  aparece, e nada navega. Os campos mantêm o que foi digitado.
- **Um sucesso sem redirecionamento** roda de novo todas as funções load, o `refreshAll`, e esvazia o
  formulário, como uma página recarregada o mostraria.
- **Um erro** renderiza o `+error.svelte` mais próximo.
- **O foco** se move como se moveria numa página nova, para que um leitor de tela não fique num botão
  que mudou de sentido.

O `sending` não aparece numa transcrição: a resposta chega em milissegundos num computador falando
consigo mesmo. Para ver o botão dizer "Adding…", abra a página do curso no seu próprio navegador, abra
as ferramentas de desenvolvedor, ponha a rede num dos perfis lentos do painel Network, e acrescente uma
sessão.

## Form actions e remote functions

O SvelteKit 3 também tem **remote functions**, um recurso experimental cuja função `form` cobre o que
as actions fazem, com outro formato e alguns acréscimos. A documentação diz que as actions estão
completas e vão continuar funcionando, e que o desenvolvimento novo está indo para as remote functions,
cuja interface ainda pode mudar enquanto forem experimentais. Este curso ensina actions porque elas são
estáveis, e porque aquilo em que elas se apoiam, um formulário que o navegador consegue enviar sozinho,
é o mesmo nos dois casos.
