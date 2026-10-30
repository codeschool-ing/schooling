---
title: O que renderiza de novo, e por que tudo
version: 1
---

**Quando o estado de um componente muda, o React renderiza aquele componente e todo componente
abaixo dele.** Não os que tiveram as props mudadas: todos. O jeito de ver é fazer cada componente
dizer quando é chamado. Este arquivo é temporário, só para esta aula; salve como `src/rendered.ts`:

```typescript
// For lesson 3 only: each component calls this while it renders, and the
// console says who rendered, in order.
export function rendered(name: string) {
  console.log(`render ${name}`)
}
```

Depois, uma chamada a ele no topo de cada um dos seis componentes. Dois comandos `sed` fazem isso de
uma vez, o primeiro importando a função e o segundo acrescentando uma linha depois de cada linha
`function`:

```
ana@dev:~/planner$ sed -i '1i import { rendered } from "./rendered"' src/App.tsx src/WeekNav.tsx src/WeekSummary.tsx src/CourseList.tsx src/CourseCard.tsx src/Card.tsx
ana@dev:~/planner$ sed -i 's/^\(export \)\?function \([A-Za-z]*\)(\(.*\)) {$/&\n  rendered('"'"'\2'"'"')/' src/App.tsx src/WeekNav.tsx src/WeekSummary.tsx src/CourseList.tsx src/CourseCard.tsx src/Card.tsx
ana@dev:~/planner$ grep -n "rendered(" src/*.tsx
src/App.tsx:10:  rendered('App')
src/Card.tsx:10:  rendered('Card')
src/CourseCard.tsx:12:  rendered('CourseCard')
src/CourseList.tsx:11:  rendered('CourseList')
src/WeekNav.tsx:10:  rendered('WeekNav')
src/WeekSummary.tsx:11:  rendered('WeekSummary')
```

## A primeira renderização

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet
render App
render App
render WeekNav
render WeekNav
render WeekSummary
render WeekSummary
render CourseList
render CourseList
render CourseCard
render CourseCard
render Card
render Card
render CourseCard
render CourseCard
render Card
render Card
render CourseCard
render CourseCard
render Card
render Card
```

Leia como a ordem em que o React chamou as suas funções: o `App` primeiro, depois os filhos de cima
para baixo, depois os filhos deles. O `CourseList` renderiza antes de qualquer `CourseCard`, e cada
`CourseCard` antes do seu `Card`. **Cada linha aparece duas vezes**, e isso é o `<StrictMode>` do
`main.tsx`; a próxima seção o tira para mostrar a diferença, e explica por que ele está ali.

## Depois de um clique

Sem o `StrictMode`, para que cada chamada saia uma vez só, isto é a página inteira carregando e
depois "Next week" sendo apertado:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week'
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
-- click button Next week
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
```

O clique mudou um valor, `monday`, no `App`. **O React chamou todos os componentes de novo.** O
`WeekNav` recebeu a mesma função e uma segunda nova; o `WeekSummary` e o `CourseList` receberam um
array novo de sessões; cada `CourseCard` recebeu um array filtrado novo; cada `Card` recebeu o mesmo
título e um parágrafo novo. Nenhum foi pulado, e nenhum poderia ter sido: o React não compara as
props antes de renderizar um filho a menos que você peça, o que é o `memo`, assunto da aula 21.

```schooling-figure
{"svg": "<svg data-fig=\"cascade\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A árvore do planejador com o estado do App mudado. Todo componente abaixo do App aparece destacado, porque todos renderizaram de novo: WeekNav, WeekSummary, CourseList, os três CourseCards e os três Cards. Uma nota diz dez chamadas para um valor mudado.\"><rect x=\"290\" y=\"14\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"23.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">App</text><text x=\"360.0\" y=\"36.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">monday ← changed</text><rect x=\"70\" y=\"86\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"145.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">WeekNav</text><line x1=\"360\" y1=\"46\" x2=\"145\" y2=\"86\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"145.0,86.0 151.8,81.5 153.0,87.8\" fill=\"var(--amber)\"></polygon><rect x=\"250\" y=\"86\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"325.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">WeekSummary</text><line x1=\"360\" y1=\"46\" x2=\"325\" y2=\"86\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"325.0,86.0 327.5,78.2 332.3,82.5\" fill=\"var(--amber)\"></polygon><rect x=\"470\" y=\"86\" width=\"150\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseList</text><line x1=\"360\" y1=\"46\" x2=\"545\" y2=\"86\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,86.0 537.0,87.5 538.3,81.3\" fill=\"var(--amber)\"></polygon><rect x=\"330\" y=\"150\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseCard</text><line x1=\"545\" y1=\"114\" x2=\"385\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"385.0,150.0 391.6,145.2 393.0,151.5\" fill=\"var(--amber)\"></polygon><rect x=\"350\" y=\"206\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"385.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Card</text><line x1=\"385\" y1=\"176\" x2=\"385\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"385.0,206.0 381.8,198.5 388.2,198.5\" fill=\"var(--amber)\"></polygon><rect x=\"460\" y=\"150\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseCard</text><line x1=\"545\" y1=\"114\" x2=\"515\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"515.0,150.0 517.3,142.2 522.3,146.3\" fill=\"var(--amber)\"></polygon><rect x=\"480\" y=\"206\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Card</text><line x1=\"515\" y1=\"176\" x2=\"515\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"515.0,206.0 511.8,198.5 518.2,198.5\" fill=\"var(--amber)\"></polygon><rect x=\"590\" y=\"150\" width=\"110\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"163.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">CourseCard</text><line x1=\"545\" y1=\"114\" x2=\"645\" y2=\"150\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"645.0,150.0 636.9,150.5 639.0,144.4\" fill=\"var(--amber)\"></polygon><rect x=\"610\" y=\"206\" width=\"70\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Card</text><line x1=\"645\" y1=\"176\" x2=\"645\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"645.0,206.0 641.8,198.5 648.2,198.5\" fill=\"var(--amber)\"></polygon><text x=\"30\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">1 valor mudou,</text><text x=\"30\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">10 componentes chamados</text></svg>", "caption": "Uma mudança de estado no App renderiza o App e tudo abaixo dele."}
```

A regra tem uma borda útil. **Um componente acima daquele cujo estado mudou não é renderizado.** Se
o `WeekNav` guardasse a semana no próprio estado, um clique renderizaria só o `WeekNav` e o resumo
nunca ficaria sabendo. É por isso que o estado mora no `App`: os componentes que o leem estão abaixo
dele, e a aula 4 transforma esse posicionamento numa regra com nome.
