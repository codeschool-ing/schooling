---
title: $derived
version: 1
---

**O `$derived` declara um valor calculado a partir de outros valores, e o mantém atualizado
sozinho.** O planner precisa de três: as sessões da semana mostrada, o total delas, e os minutos de
cada curso. Cada um depende de `week`, e nenhum deveria ser atribuído à mão. Esta versão do
`+page.svelte` os acrescenta:

```schooling-example
{"language": "html", "file": "src/routes/+page.svelte", "parts": [
 {"code": "<script>\n\timport data from '#lib/planner.json';\n\timport { mondayOf, addDays, inWeek, format } from '#lib/week.js';\n\n\tlet week = $state(mondayOf(data.sessions.at(-1).date));", "note": "`inWeek` entra nos imports."},
 {"code": "\tlet thisWeek = $derived(data.sessions.filter((s) => inWeek(s.date, week)));\n\tlet total = $derived(thisWeek.reduce((sum, s) => sum + s.minutes, 0));", "note": "Uma expressão em `$derived(…)` é recalculada quando algo que ela leu muda. `thisWeek` lê `week`."},
 {"code": "\tlet byCourse = $derived.by(() => {\n\t\tconst minutes = {};\n\t\tfor (const s of thisWeek) minutes[s.course] = (minutes[s.course] ?? 0) + s.minutes;\n\t\treturn minutes;\n\t});\n</script>\n\n<main>\n\t<h1>Study planner</h1>\n\t<p>\n\t\t<button onclick={() => (week = addDays(week, -7))}>Previous week</button>\n\t\tWeek of {format(week)}\n\t\t<button onclick={() => (week = addDays(week, 7))}>Next week</button>\n\t</p>", "note": "O `$derived.by` recebe uma função, para um valor que precisa de mais de uma expressão para ser calculado."},
 {"code": "\t<ul>\n\t\t{#each data.courses as course}\n\t\t\t<li>{course.name}: {byCourse[course.id] ?? 0} min</li>\n\t\t{/each}\n\t</ul>\n\t<p>{total} minutes this week</p>\n</main>", "note": "A marcação lê os valores derivados como qualquer variável."}
]}
```

```
ana@dev:~/planner$ look http://localhost:5173/ --click 'Previous week'
-- click Previous week
at /
- main:
  - heading "Study planner" [level=1]
  - paragraph:
    - button "Previous week"
    - text: Week of 12 Oct 2026
    - button "Next week"
  - list:
    - listitem: "Linear algebra: 60 min"
    - listitem: "Spanish: 30 min"
    - listitem: "Guitar: 0 min"
  - paragraph: 90 minutes this week
```

A semana de 12 de outubro tem uma hora de álgebra e meia hora de espanhol, e o total acompanha. Nada
no handler do botão menciona `total`: ele define `week`, `thisWeek` dependia de `week`, `total` e
`byCourse` dependiam de `thisWeek`, e a cadeia fez o resto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A cadeia de valores da página do planner. week é estado. thisWeek é derivado de week e das sessões. total e byCourse são os dois derivados de thisWeek. A marcação lê total, byCourse e week. Apertar Previous week define week, e a mudança percorre a cadeia até o rótulo, os minutos dos cursos e o total.\"><rect x=\"20\" y=\"40\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">week</text><text x=\"80.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$state</text><rect x=\"20\" y=\"140\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sessions</text><text x=\"80.0\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dados</text><rect x=\"200\" y=\"90\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">thisWeek</text><text x=\"265.0\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$derived</text><rect x=\"390\" y=\"40\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">total</text><text x=\"455.0\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$derived</text><rect x=\"390\" y=\"140\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"159\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">byCourse</text><text x=\"455.0\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">$derived.by</text><rect x=\"580\" y=\"40\" width=\"120\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a marcação</text><text x=\"640\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Week of …</text><text x=\"640\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">… min</text><text x=\"640\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">… minutes</text><line x1=\"140\" y1=\"65\" x2=\"198\" y2=\"108\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,108.0 190.2,106.1 193.9,101.1\" fill=\"var(--phosphor)\"></polygon><line x1=\"140\" y1=\"165\" x2=\"198\" y2=\"122\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,122.0 193.9,128.9 190.2,123.9\" fill=\"var(--wire)\"></polygon><line x1=\"330\" y1=\"108\" x2=\"388\" y2=\"68\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"388.0,68.0 383.7,74.7 380.2,69.6\" fill=\"var(--phosphor)\"></polygon><line x1=\"330\" y1=\"122\" x2=\"388\" y2=\"160\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"388.0,160.0 380.1,158.6 383.5,153.4\" fill=\"var(--phosphor)\"></polygon><line x1=\"520\" y1=\"65\" x2=\"578\" y2=\"155\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,155.0 571.4,150.5 576.6,147.1\" fill=\"var(--phosphor)\"></polygon><line x1=\"520\" y1=\"165\" x2=\"578\" y2=\"125\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"578.0,125.0 573.7,131.7 570.2,126.6\" fill=\"var(--phosphor)\"></polygon><path d=\"M80 40 C 80 15, 600 10, 620 36\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"617\" y1=\"32\" x2=\"621\" y2=\"38\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"621.0,38.0 614.3,33.6 619.5,30.1\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um botão define week; tudo o que vem depois é recalculado quando for lido de novo</text></svg>", "caption": "Só week é definido à mão. Todo outro valor no caminho até a tela é derivado dele.", "same": ["$derived", "$derived.by", "$state"]}
```

## Três propriedades de um valor derivado

**Ele é preguiçoso.** Um valor derivado não é recalculado no instante em que algo que ele leu muda.
Ele é marcado como desatualizado, e recalculado na próxima vez que alguém o lê. Se ninguém lê, ele
não custa nada.

**Ele é memorizado.** Leia `total` dez vezes na marcação e ele é calculado uma vez, até algo de que
ele depende mudar. É isso que o `useMemo` faz no React, só que aqui é o padrão e não há lista de
dependências para manter certa: as leituras são a lista, exatamente como para um efeito na aula 2.

**Ele não serve para efeitos colaterais.** A expressão deveria calcular um valor e não fazer mais
nada: nenhum `fetch`, nenhuma atribuição a outro estado, nenhuma escrita na página. Se algo deve
*acontecer* quando um valor muda, isso é um efeito, e a seção depois da próxima trata de quando você
realmente precisa de um.

## `$derived` contra uma função

`byCourse[course.id]` poderia ter sido uma função, `minutesFor(course)`, chamada a partir da marcação.
Isso também funciona, e não está errado. A diferença é que uma chamada de função na marcação roda cada
vez que aquele pedaço de marcação atualiza, e um valor derivado roda uma vez por mudança e é
compartilhado por todos os leitores. Num cálculo sobre seis sessões você não vai ver a diferença.
**Prefira `$derived` quando um valor tem nome**, porque o nome o documenta e a rune o torna barato.
