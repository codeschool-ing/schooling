---
title: Um componente é uma função que devolve elementos
version: 1
---

**Um componente é uma função cujo nome começa com letra maiúscula e que devolve JSX.** Ela pode
receber um argumento, um objeto de props, que é o assunto da próxima seção. Essa é a definição
inteira; não há classe para estender nem etapa de registro. O `WeekSummary` era um. O `App` é outro,
e é o que o `main.tsx` renderiza. Troque o `src/App.tsx` do modelo pelo do planejador:

```tsx
import { CourseList } from './CourseList'
import { courses, sessions } from './sample'
import { inWeek } from './week'
import { WeekSummary } from './WeekSummary'

// Until lesson 4 lets you move between weeks, the planner shows this one.
const MONDAY = '2026-10-19'

function App() {
  const thisWeek = sessions.filter((s) => inWeek(s.date, MONDAY))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekSummary monday={MONDAY} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} />
    </main>
  )
}

export default App
```

O `App` filtra as sessões até sobrar uma semana e entrega o que calculou a dois componentes: o
`WeekSummary` que você tem, e um `CourseList` que a próxima seção escreve. Enquanto o
`CourseList.tsx` não existir, o painel do Vite diz que não consegue resolver o import, que é a falha
da aula 1 e é esperada agora.

O `export default` é o que o `main.tsx` espera, porque o modelo importou o `App` sem chaves. Todo
outro componente deste curso usa uma **exportação nomeada**, `export function CourseList`, e é
importado com chaves. Uma exportação nomeada não pode ser renomeada sem querer no caminho, e um
editor encontra cada lugar que a usa.

## Por que a letra maiúscula importa

Para o JSX, a primeira letra de uma tag decide o que ela é. **Minúscula é um elemento HTML, passado
para a chamada como string; maiúscula é um componente, passado como a própria função.** Escreva o
nome de um componente em minúscula e o JSX entrega ao React a string `"courseCard"`, que o React
obedientemente pede ao navegador para criar. Com a tela completa, no fim da seção "Children e
composição", isto é o que esse erro de uma letra produz:

```
ana@dev:~/planner$ sed -i 's/<CourseCard$/<courseCard/' src/CourseList.tsx
ana@dev:~/planner$ grep -n courseCard src/CourseList.tsx
13:        <courseCard
ana@dev:~/planner$ look http://localhost:5173/ 2>&1 | head -n 8
[error] <%s /> is using incorrect casing. Use PascalCase for React components, or lowercase for HTML elements. courseCard
[error] The tag <%s> is unrecognized in this browser. If you meant to render a React component, start its name with an uppercase letter. courseCard
[error] <%s /> is using incorrect casing. Use PascalCase for React components, or lowercase for HTML elements. courseCard
[error] <%s /> is using incorrect casing. Use PascalCase for React components, or lowercase for HTML elements. courseCard
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
ana@dev:~/planner$ sed -i 's/<courseCard$/<CourseCard/' src/CourseList.tsx
```

O React percebeu e disse duas vezes, uma pela caixa da letra e outra porque o navegador não conhece
um elemento `<courseCard>`; a segunda mensagem até diz o que você quis dizer. A página ainda
desenhou, sem os três cartões: um elemento desconhecido renderiza como uma caixa vazia, e as props
passadas a ele não foram a lugar nenhum. **Leia o console a cada mudança**, porque um erro como este
falha em silêncio na página e em voz alta só ali.

## Um componente por tarefa

A primeira tela do planejador agora são cinco componentes, e cada um faz uma coisa:

```schooling-figure
{"svg": "<svg data-fig=\"tree\" viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A primeira tela como uma árvore. App, no topo, passa monday e sessions para WeekSummary, e courses e sessions para CourseList. CourseList desenha três CourseCards, cada um com um curso e as sessões dele. Cada CourseCard desenha um Card com um title e children. As setas só apontam para baixo.\"><rect x=\"300\" y=\"14\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">App</text><rect x=\"80\" y=\"100\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">WeekSummary</text><rect x=\"470\" y=\"100\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseList</text><line x1=\"330\" y1=\"44\" x2=\"170\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"170.0,100.0 176.0,94.5 178.1,100.5\" fill=\"var(--wire)\"></polygon><line x1=\"390\" y1=\"44\" x2=\"550\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"550.0,100.0 541.9,100.5 544.0,94.5\" fill=\"var(--wire)\"></polygon><text x=\"150\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">monday, sessions</text><text x=\"570\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">courses, sessions</text><rect x=\"270\" y=\"186\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseCard</text><line x1=\"550\" y1=\"130\" x2=\"330\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"330.0,186.0 336.5,181.0 338.1,187.3\" fill=\"var(--wire)\"></polygon><rect x=\"290\" y=\"256\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Card</text><line x1=\"330\" y1=\"216\" x2=\"330\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"330.0,256.0 326.8,248.5 333.2,248.5\" fill=\"var(--wire)\"></polygon><rect x=\"410\" y=\"186\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseCard</text><line x1=\"550\" y1=\"130\" x2=\"470\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,186.0 474.3,179.1 478.0,184.3\" fill=\"var(--wire)\"></polygon><rect x=\"430\" y=\"256\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Card</text><line x1=\"470\" y1=\"216\" x2=\"470\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"470.0,256.0 466.8,248.5 473.2,248.5\" fill=\"var(--wire)\"></polygon><rect x=\"550\" y=\"186\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">CourseCard</text><line x1=\"550\" y1=\"130\" x2=\"610\" y2=\"186\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"610.0,186.0 602.3,183.2 606.7,178.5\" fill=\"var(--wire)\"></polygon><rect x=\"570\" y=\"256\" width=\"80\" height=\"28\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Card</text><line x1=\"610\" y1=\"216\" x2=\"610\" y2=\"256\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"610.0,256.0 606.8,248.5 613.2,248.5\" fill=\"var(--wire)\"></polygon><text x=\"380\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">course, sessions</text><text x=\"258\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">title, children</text><text x=\"60\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um por curso</text><line x1=\"150\" y1=\"200\" x2=\"262\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line></svg>", "caption": "As props descem pela árvore, do componente que tem os dados para os que os desenham."}
```

O `App` decide quais sessões estão na semana. O `WeekSummary` soma. O `CourseList` percorre os
cursos. O `CourseCard` descreve um curso, e o `Card` desenha uma moldura em volta de qualquer coisa.
Nenhum deles sabe como os outros funcionam por dentro; cada um sabe só o que recebe. É isso que
permite mudar a moldura sem ler a aritmética, e a aula 4 vai pôr a semana em estado sem tocar no
`CourseCard`.
