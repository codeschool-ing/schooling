---
title: Children e composição
version: 1
---

**Um componente pode deixar um espaço para o pai preencher.** O que um pai escreve entre a tag de
abertura e a de fechamento de um componente chega como mais uma prop, chamada `children`, e o
componente a põe onde quiser. É assim que o React compartilha um layout entre partes de um app: não
com um componente estendendo outro, mas com um componente envolvendo o que recebe.

O `Card` do planejador é uma moldura com um título. O que vai embaixo do título não é problema dele.
Salve como `src/Card.tsx`:

```tsx
import type { ReactNode } from 'react'

type CardProps = {
  title: string
  children: ReactNode
}

export function Card({ title, children }: CardProps) {
  return (
    <article className="card">
      <h2>{title}</h2>
      {children}
    </article>
  )
}
```

O `ReactNode` é o tipo de qualquer coisa que o React sabe desenhar: um elemento, uma string, um
número, um array disso, ou nada. O `CourseCard` preenche o espaço com um parágrafo:

```tsx
<Card title={course.name}>
  <p>
    {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
  </p>
</Card>
```

```schooling-figure
{"svg": "<svg data-fig=\"slot\" viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Card desenhado como uma moldura com um título e um espaço vazio chamado children. À direita, CourseCard escreve um parágrafo entre as tags de Card, e uma seta mostra o parágrafo caindo no espaço. Card decide onde fica o espaço; o pai decide o que o preenche.\"><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Card: a moldura</text><rect x=\"30\" y=\"36\" width=\"240\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;article&gt;</text><text x=\"58\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;h2&gt;{title}&lt;/h2&gt;</text><rect x=\"58\" y=\"100\" width=\"190\" height=\"52\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"153.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{children}</text><text x=\"46\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;/article&gt;</text><text x=\"520\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CourseCard: o que vai dentro</text><rect x=\"380\" y=\"36\" width=\"300\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;Card title={course.name}&gt;</text><rect x=\"408\" y=\"84\" width=\"250\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;p&gt;2 sessions · 90 min&lt;/p&gt;</text><text x=\"396\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;/Card&gt;</text><path d=\"M 408 111 C 330 111 330 126 250 126\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><polygon points=\"250.0,126.0 257.2,122.2 257.7,128.6\" fill=\"var(--amber)\"></polygon></svg>", "caption": "O filho decide onde; o pai decide o quê."}
```

O `Card` nunca fica sabendo que está mostrando um curso. Na semana que vem ele pode emoldurar uma
sessão, um formulário, uma mensagem de erro, e nenhum deles precisa saber como a moldura é
desenhada. **O pai decide o que vai dentro, e o filho decide onde.** Essa divisão é o que o React
chama de composição, e é a resposta a toda pergunta do tipo "como faço uma variação deste
componente" que, numa linguagem construída em volta de classes, seria herança.

## A primeira tela

Com o `Card.tsx` salvo, todo import se resolve e a tela se desenha:

```
ana@dev:~/planner$ look http://localhost:5173/
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
```

**80 de 195 minutos, e 90, 60 e 45 para os três cursos**: os números que a aula 1 disse que toda
versão desta tela precisa alcançar. O retrato também mostra a estrutura que os componentes montaram.
Os dois elementos `section` com `aria-label` viraram regiões com nome, cada `article` tem um título
de nível 2 vindo do `Card`, e o "1 session" no singular veio do ternário do `CourseCard`.
