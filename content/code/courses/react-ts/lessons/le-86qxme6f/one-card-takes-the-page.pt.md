---
title: Um cartão derruba a página inteira
version: 1
---

**Um erro lançado enquanto o React renderiza um componente, sem nada que o capture, remove a página
inteira.** Não o componente que falhou, nem o pai dele: tudo o que o React desenhou sob a raiz. É uma
escolha deliberada, e para ver por quê, comece por um recurso pequeno escrito sem cuidado.

Cada cartão de curso vai dizer quando é a próxima sessão: a primeira desta semana que ainda não foi
feita. O `src/CourseCard.tsx`, com a linha nova:

```tsx
import { Card } from './Card'
import type { Course, Session } from './types'
import { formatDay, minutes } from './week'

type CourseCardProps = {
  course: Course
  sessions: Session[]
  onOpen: (id: string) => void
}

export function CourseCard({ course, sessions, onOpen }: CourseCardProps) {
  const count = sessions.length
  const next = sessions.find((s) => !s.done)!
  const title = (
    <button type="button" onClick={() => onOpen(course.id)}>
      {course.name}
    </button>
  )
  return (
    <Card title={title}>
      <p>
        {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
      </p>
      <p>Next: {formatDay(next.date)}</p>
    </Card>
  )
}
```

O `find` devolve a sessão que achou, ou `undefined` quando nenhuma combina, então o TypeScript tipa
`next` como `Session | undefined` e recusaria `next.date`. **O `!` depois da chamada diz ao compilador
que o valor nunca é `undefined`**, e o compilador acredita. As duas verificações passam:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 85ms on 18 files with 116 rules using 4 threads.
no errors
```

A página também parece certa, na semana em que os dados iniciais começam, onde todo curso ainda tem
uma sessão por fazer:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
      - paragraph: 2 sessions · 90 min
      - paragraph: "Next: Wed 21 Oct"
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

Agora faça o que um estudante deste planejador faz cedo ou tarde: termine a última sessão de
estatística da semana. Abra o curso, marque a sessão de quarta e volte:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' --html '#root'
-- click button Statistics
-- click checkbox Wed 21 Oct · 40 min
-- click button Back to courses
Uncaught TypeError: Cannot read properties of undefined (reading 'date')
[warn] %s

%s
 An error occurred in the <CourseCard> component. Consider adding an error boundary to your tree to customize error handling behavior.
Visit https://react.dev/link/error-boundaries to learn more about error boundaries.

<div id="root"></div>
```

O `--html '#root'` pediu ao `look` o elemento em que o React desenha, e ele está vazio. **O retrato
falta porque não há nada na página**: nenhum título, nenhum botão de semana, nenhum cartão de
espanhol, que não tinha problema nenhum. Num navegador, é uma página branca.

Três linhas dizem o que aconteceu. O `Uncaught TypeError` é do navegador: o cartão de estatística leu
`.date` de `undefined`, porque o `find` não achou sessão restante. O `[warn]` é do React, nomeando o
componente de onde veio o erro, `<CourseCard>`, e sugerindo a correção que esta aula constrói. Os
marcadores `%s` vêm do jeito como o React escreve no console: ele passa um modelo com `%s` dentro e as
partes separadas. O console de um navegador põe cada parte no seu lugar; o `look` imprime o modelo,
depois as partes, e por isso os marcadores aparecem.

**Por que o React remove tudo**, e não só o cartão quebrado: depois de um erro no meio de uma
renderização, o React não tem como saber em que estado está o resto da árvore. Poderia deixar uma
página desenhada pela metade, com números que não fecham, ou um botão que salva no curso errado. A
equipe do React preferiu uma página vazia a uma página que pode estar mentindo, e deixa para você dizer
quais partes da tela podem falhar sozinhas. É isso que um error boundary é.
