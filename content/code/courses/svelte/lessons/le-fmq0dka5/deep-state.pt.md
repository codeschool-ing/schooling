---
title: Estado profundo, e mudá-lo no lugar
version: 1
---

**O `$state` aplicado a um array ou a um objeto o torna profundamente reativo: você o muda no lugar,
com JavaScript comum, e tudo o que leu a parte mudada se atualiza.** Fazer push no array, atribuir a
uma propriedade, tirar algo com splice: cada um é rastreado. Esta é a seção em que as sessões do
planner viram estado, para que a página consiga acrescentar uma e marcar uma como feita.

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\n\tlet sessions = $state(data.sessions);\n\tlet week = $state(mondayOf(sessions.at(-1).date));", "note": "As sessões viram estado. O `$state` envolve o array, e cada objeto dentro dele, num proxy que relata leituras e escritas."},
 {"code": "\tlet selected = $state(data.courses[0].id);\n\n\tlet thisWeek = $derived(sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));\n\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n\tlet course = $derived(data.courses.find((c) => c.id === selected));\n\tlet ofCourse = $derived(sessions.filter((s) => s.course === selected));", "note": "O curso selecionado é guardado pelo seu id, uma string comum, e não como o objeto do curso."},
 {"code": "\tfunction add() {\n\t\tsessions.push({ id: sessions.length + 1, course: selected, date: week, minutes: 30, done: false });\n\t}", "note": "Um `push` no array de estado é tudo o que é preciso. Todo valor derivado que leu `sessions` agora está desatualizado."},
 {"code": "\t$inspect(total).with(console.log);\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>", "note": "O `$inspect` relata um valor quando ele é lido pela primeira vez e cada vez que muda, só no desenvolvimento; `.with(console.log)` imprime cada relato como uma linha simples."},
 {"code": "\t<ul>\n\t\t{#each data.courses as c}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={c.id === selected} onclick={() => (selected = c.id)}>{c.name}</button>\n\t\t\t\t{byCourse[c.id] ?? 0} min\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<p>{total} minutes this week</p>", "note": "Cada curso agora é um botão. O `aria-pressed` diz a um leitor de tela qual está selecionado."},
 {"code": "\t<h2>{course.name}</h2>\n\t<ul>\n\t\t{#each ofCourse as session}\n\t\t\t<li>\n\t\t\t\t<button aria-pressed={session.done} onclick={() => (session.done = !session.done)}>\n\t\t\t\t\t{format(session.date)}, {session.minutes} min\n\t\t\t\t</button>\n\t\t\t</li>\n\t\t{/each}\n\t</ul>\n\t<button onclick={add}>Add 30 minutes on {format(week)}</button>\n</main>", "note": "Cada sessão é um botão de alternar: pressionado quando feita. O handler atribui a uma propriedade de um objeto dentro do array de estado."}
]}
```

Abra, acrescente uma sessão a Linear algebra e marque como feita a sessão do dia 24:

```
ana@dev:~/planner$ look http://localhost:5173/ --console --click 'Add 30 minutes on 19 Oct 2026' --click '24 Oct 2026, 60 min'
console: [vite] connecting...
console: [vite] connected.
console: init 225
-- click Add 30 minutes on 19 Oct 2026
console: update 255
-- click 24 Oct 2026, 60 min
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 19 Oct 2026
    - button "Next week"
  - list:
    - listitem:
      - button "Linear algebra" [pressed]
      - text: 180 min
    - listitem:
      - button "Spanish"
      - text: 30 min
    - listitem:
      - button "Guitar"
      - text: 45 min
  - paragraph: 255 minutes this week
  - heading "Linear algebra" [level=2]
  - list:
    - listitem:
      - button "13 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 90 min" [pressed]
    - listitem:
      - button "24 Oct 2026, 60 min" [pressed]
    - listitem:
      - button "19 Oct 2026, 30 min"
  - button "Add 30 minutes on 19 Oct 2026"
```

Leia primeiro as linhas do console. O `$inspect(total)` imprimiu `init 225` quando a página apareceu e
`update 255` quando o push somou trinta minutos; sem o `.with(console.log)` ele imprime os mesmos
valores com um stack trace embaixo de cada update, o que é útil quando você precisa achar o que mudou
um valor e barulhento quando não precisa. Marcar uma sessão como feita não imprimiu nada, porque
`total` soma minutos e não lê `done`, então não mudou.

Depois, a árvore. A sessão nova está na lista com a data da segunda-feira da semana, os minutos de
Linear algebra foram de 150 para 180, e o botão do dia 24 agora está `[pressed]`, que é como um leitor
de tela fica sabendo que um botão de alternar está ligado. **Nada desse código menciona a lista, o
total ou os botões**: o `push` e uma atribuição a `session.done` bastaram, porque o proxy os relatou.

## O que o proxy faz, e o que não faz

O `$state` envolve arrays e objetos comuns num **proxy**, um objeto que intercepta leituras e
escritas. Leituras de `sessions[3].done` são registradas do jeito que a aula 2 desenhou, um signal
por propriedade, e uma escrita em `done` chega exatamente ao código que leu o `done` daquela sessão.
Ele entra em objetos dentro de arrays dentro de objetos, tão fundo quanto os dados vão.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O array de sessões dentro de um proxy $state. O proxy guarda um signal por propriedade que já foi lida: o length do array e, para a sessão do dia 24, os seus minutes e o seu done. O total leu minutes, então está na lista desse signal; o botão de alternar leu done. Atribuir session.done chega ao botão e não ao total; um push muda o length e chega a tudo o que percorreu o array.\"><rect x=\"20\" y=\"30\" width=\"330\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"36\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">proxy $state em volta de sessions</text><rect x=\"40\" y=\"66\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">length</text><text x=\"54\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sessions[5]</text><rect x=\"54\" y=\"154\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"114\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">minutes</text><rect x=\"194\" y=\"154\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"254\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">done</text><rect x=\"450\" y=\"60\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tudo o que percorreu o array</text><rect x=\"450\" y=\"120\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total, byCourse</text><rect x=\"450\" y=\"180\" width=\"250\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o botão de alternar da sessão</text><line x1=\"160\" y1=\"84\" x2=\"448\" y2=\"80\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"448.0,80.0 440.7,83.2 440.6,77.0\" fill=\"var(--phosphor)\"></polygon><path d=\"M114 154 C 114 112, 380 128, 440 139\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"436\" y1=\"138\" x2=\"446\" y2=\"140\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"446.0,140.0 438.2,141.6 439.4,135.5\" fill=\"var(--phosphor)\"></polygon><line x1=\"314\" y1=\"178\" x2=\"448\" y2=\"198\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"448.0,198.0 440.3,200.0 441.2,193.8\" fill=\"var(--phosphor)\"></polygon><text x=\"400\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leitores</text></svg>", "caption": "Um signal por propriedade lida. Marcar uma sessão como feita chega ao botão dela, e não ao total."}
```

Três consequências valem ser conhecidas antes que surpreendam você:

- **O proxy não é o original.** `sessions` é um proxy em volta dos dados, então
  `sessions[0] === data.sessions[0]` é falso. Esse é um dos motivos de o curso selecionado ser
  guardado como id: compare ids, que são strings, e a questão não aparece.
- **Classes e outros objetos ficam de fora.** Um `Date`, um `Map` ou uma instância de uma classe sua
  não recebem proxy, então mudá-los no lugar não é visto. O Svelte oferece versões reativas dos mais
  comuns em `svelte/reactivity`, e uma classe pode tornar os seus campos reativos com `$state`, o que
  a aula 10 faz.
- **Registrar um proxy mostra um proxy.** `console.log(sessions)` no navegador imprime um `Proxy`,
  que é difícil de ler. `$state.snapshot(sessions)` devolve uma cópia comum, e o `$inspect` faz isso
  por você.

## Quando você não quer estado profundo

Para um array grande que você só troca inteiro, o proxy é trabalho à toa. **`$state.raw(...)`** cria
um valor que é reativo quando a variável é atribuída e não quando o seu interior muda. As seis
sessões do planner são mudadas no lugar, então o `$state` comum é a escolha certa aqui; uma lista de
milhares de linhas carregada de um servidor e trocada a cada recarga seria um caso para o
`$state.raw`.
