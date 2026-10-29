---
title: Uma interação lenta, achada e corrigida
version: 1
---

**O INP precisa de uma interação que faça trabalho de verdade, e as do planner quase não fazem nenhum
com três cursos.** O `gen.ts` da aula 3 faz um plano de qualquer tamanho. Com cinco mil cursos, o
tamanho do catálogo de uma escola grande, abra uma página de curso num processador quatro vezes mais
lento e clique em *All courses*, que desenha a página inicial a partir do plano no navegador:

```
ana@dev:~/planner$ node gen.ts 5000 && node tools/vitals.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"
5000 courses
[vitals] LCP 144 ms good #notice
[vitals] CLS 0.000 good 
[vitals] INP 1888 ms poor  (input 1, processing 1762, presentation 125)
```

O `gen.ts` escreve o `dist/courses.json`, que o `server.ts` lê a cada requisição, então não é preciso
reiniciar. **O clique levou quase dois segundos para mostrar alguma coisa, e quase tudo foi
processamento**: o atraso de entrada foi nada, o tratador foi tudo. O tratador é o `draw`, que chama o
`homePage`, e o `homePage` conta as sessões de cada curso filtrando todas as sessões, para cada curso.
Cinco mil cursos vezes cinco mil sessões são vinte e cinco milhões de comparações, numa tarefa só,
enquanto a página não consegue pintar.

## Passo um: contar uma vez

Contar as sessões de todos os cursos precisa de uma passada pelas sessões, não de uma por curso. No
`src/view.ts`, substitua as primeiras linhas do `homePage`, até o `courses` que ele monta, inclusive,
por estas:

```typescript
export function homePage(plan: Plan): string {
  // One pass over the sessions counts every course's, however many courses there are.
  const count = new Map<string, number>();
  for (const s of plan.sessions) count.set(s.course, (count.get(s.course) ?? 0) + 1);
  const courses = plan.courses.map((c) =>
    `<li><a href="/courses/${esc(c.slug)}">${esc(c.title)}</a> · ${count.get(c.slug) ?? 0} sessions</li>`);
```

Build, reinício, e clique de novo:

```
ana@dev:~/planner$ node gen.ts 5000 && node tools/vitals.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"
5000 courses
[vitals] LCP 152 ms good #notice
[vitals] CLS 0.000 good 
[vitals] INP 848 ms poor  (input 3, processing 723, presentation 123)
```

**Mais da metade do tempo foi embora, e a interação ainda é ruim.** A contagem saiu do processamento;
o que sobra é montar cinco mil itens de lista. O `innerHTML` os interpreta e o navegador cria cada um
dentro do mesmo tratador, e depois faz o layout deles no atraso de apresentação.

## Passo dois: desenhar menos

Ninguém lê cinco mil cursos numa página. Uma página com cem e uma linha dizendo quantos mais há é o
que uma pessoa consegue usar, e são cem itens de lista para montar. Substitua as duas linhas que
montam o `courses` por estas quatro:

```typescript
  // A page shows the first hundred courses; a list of thousands is a search, not a page.
  const courses = plan.courses.slice(0, 100).map((c) =>
    `<li><a href="/courses/${esc(c.slug)}">${esc(c.title)}</a> · ${count.get(c.slug) ?? 0} sessions</li>`);
  if (plan.courses.length > 100) courses.push(`<li>and ${plan.courses.length - 100} more</li>`);
```

```
ana@dev:~/planner$ node gen.ts 5000 && node tools/vitals.ts http://localhost:3000/courses/course-1 --cpu 4 --click "text=All courses"
5000 courses
[vitals] LCP 148 ms good #notice
[vitals] CLS 0.000 good 
[vitals] INP 88 ms good  (input 1, processing 61, presentation 25)
```

**Bom.** O mesmo clique, os mesmos dados e o mesmo processador mais lento. A primeira correção tirou
trabalho de que ninguém precisava; a segunda tirou trabalho que ninguém veria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três medidas do mesmo clique em All courses, com cinco mil cursos e o processador quatro vezes mais lento. Como estava: INP 1888 ms, dos quais 1762 de processamento. Contando uma vez: 848 ms, 723 de processamento. Desenhando cem cursos: 88 ms.\"><text x=\"148\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">como estava</text><rect x=\"160.23\" y=\"40\" width=\"405.26\" height=\"24\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"565.49\" y=\"40\" width=\"28.75\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.24\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1888 ms</text><text x=\"148\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">contar uma vez</text><rect x=\"160.69\" y=\"92\" width=\"166.29000000000002\" height=\"24\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"326.98\" y=\"92\" width=\"28.290000000000003\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"363.04\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">848 ms</text><text x=\"148\" y=\"156\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">desenhar cem</text><rect x=\"160.23\" y=\"144\" width=\"14.030000000000001\" height=\"24\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"174.26\" y=\"144\" width=\"5.75\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"188.24\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">88 ms</text><line x1=\"206.0\" y1=\"30\" x2=\"206.0\" y2=\"186\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"210.0\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">200 ms: bom</text><rect x=\"420\" y=\"194\" width=\"12\" height=\"12\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"438\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">processamento</text><rect x=\"540\" y=\"194\" width=\"12\" height=\"12\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"558\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">apresentação</text></svg>", "caption": "A primeira correção tirou trabalho de que ninguém precisava; a segunda, trabalho que ninguém veria."}
```

## Quando o trabalho não pode ser tirado

Algum trabalho é de verdade e precisa rodar: um gráfico, um cálculo longo. Aí a correção é **dar ao
navegador a chance de pintar antes de fazê-lo**. Um tratador que muda algo pequeno na hora, mostra que
o clique foi recebido, e deixa a parte pesada para uma tarefa seguinte, com `setTimeout`, ou com
`scheduler.yield()` num navegador que o tenha, termina a sua interação na primeira pintura. Dividir um
trabalho longo em pedaços que cedem a vez cada um mantém todo outro toque respondido também. O trabalho
ainda custa o que custa; o INP mede quanto a pessoa esperou para ver que algo aconteceu.

Devolva o plano de verdade quando terminar: `npm run build` copia o `public/courses.json` para o
`dist/` de novo.
