---
title: O zero que aparece do nada
version: 1
---

**`count && <p>…</p>` desenha um `0` quando `count` é zero.** A expressão `a && b` devolve `a` quando
`a` é falso, e `0` é falso, então a expressão inteira é o número `0`, e o React desenha números. É a
surpresa mais comum com o `&&`, e fica invisível nos testes até os dados de alguém terem um zero.

Aqui está uma versão do `CourseCard` que esconde a linha quando um curso não tem sessões na semana:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

// For lesson 8 only: the line is drawn only when there are sessions.
export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const title = (
    <button type="button" onClick={() => onOpen(course.id)}>
      {course.name}
    </button>
  )
  return (
    <Card title={title}>
      {count && (
        <p>
          {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
        </p>
      )}
    </Card>
  )
}
```

Na semana de 19 de outubro todo curso tem sessões, então toda linha é desenhada e nada parece
errado. A semana seguinte não tem nenhuma:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n '/region "Courses"/,$p'
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
      - text: "0"
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
      - text: "0"
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
      - text: "0"
ana@dev:~/planner$ sed -i 's|^      {count && ($|      {count > 0 \&\& (|' src/CourseCard.tsx
ana@dev:~/planner$ grep -n "count > 0" src/CourseCard.tsx
21:      {count > 0 && (
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n '/region "Courses"/,$p'
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
ana@dev:~/planner$ cp /tmp/CourseCard.tsx src/CourseCard.tsx
```

**Três cartões, cada um com um `0` perdido embaixo do nome.** Para um leitor de tela é pior que uma
mancha: o cartão é anunciado como "Statistics, botão, 0". A correção é dar ao `&&` um booleano, para
que o caso falso seja `false` e não desenhe nada; o `sed` transformou `count &&` em `count > 0 &&`, e
o segundo `look` mostra os cartões sem linha nenhuma.

A regra que evita isso: **o lado esquerdo do `&&` no JSX é sempre um booleano.** `count > 0`,
`items.length > 0`, `Boolean(value)`, ou um ternário com `null` do outro lado. Strings têm uma versão
mais branda do mesmo problema, porque `''` é falso e o React a desenha como um nó de texto vazio, que
pelo menos não mostra nada.

Esta versão do `CourseCard` foi uma demonstração, não uma mudança: a primeira tela do planejador
mostra "0 sessions · 0 min" numa semana vazia, nos quatro cursos da bifurcação, e o `cp` pôs essa
versão de volta.
