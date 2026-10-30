---
title: O bug que uma key de índice faz
version: 1
---

**Uma key de índice prende o estado a uma posição, então quando os itens se movem, o estado fica para
trás.** É fácil não ver porque a lista em si sempre parece certa: o React desenha o texto de cada item
a partir dos dados. Só o que os itens não pegam dos dados, o que foi digitado, marcado ou focado,
fica parado.

Um `CourseScreen` temporário torna isso visível. Cada sessão ganha um campo para uma nota, que guarda o
que você digita no DOM, como faz um input não controlado, e um botão inverte a ordem. A key é o
índice:

```tsx
import { useEffect, useRef, useState } from 'react'
import type { Course, Session } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  sessions: Session[]
  onToggle: (id: string) => void
  onBack: () => void
}

// For lesson 8 only: a note beside each session, and a button that reverses
// the order. The key is the session's position, which is the mistake.
export function CourseScreen({ course, sessions, onToggle, onBack }: CourseScreenProps) {
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])
  const [newestFirst, setNewestFirst] = useState(false)

  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  if (newestFirst) sorted.reverse()
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      <button type="button" onClick={() => setNewestFirst(!newestFirst)}>
        Reverse the order
      </button>
      <ul>
        {sorted.map((s, index) => (
          <li key={index}>
            <label>
              <input type="checkbox" checked={s.done} onChange={() => onToggle(s.id)} />
              {formatDay(s.date)} · {s.minutes} min
            </label>
            <input aria-label={`Note for ${formatDay(s.date)}`} />
          </li>
        ))}
      </ul>
    </>
  )
}
```

Digite uma nota na sessão de segunda, dia 19, depois inverta:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
      - textbox "Note for Mon 19 Oct": read chapter 3
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
      - textbox "Note for Wed 21 Oct"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' --do 'click button Reverse the order' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
      - textbox "Note for Wed 21 Oct": read chapter 3
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
      - textbox "Note for Mon 19 Oct"
```

**Depois de inverter, a nota diz "read chapter 3" ao lado de quarta, dia 21.** As sessões se moveram;
a nota não. O React comparou as duas renderizações pela key: a key `0` estava lá antes e está agora,
então o primeiro `<li>` foi mantido, com o input e o texto dentro, e só as partes desenhadas a partir
dos dados, a data, os minutos e o estado da caixa, foram atualizadas para a sessão que agora é a
primeira do array. O rótulo do campo mudou também, então um leitor de tela anunciaria "Note for Wed 21
Oct, read chapter 3", uma nota que ninguém escreveu para aquela sessão.

Com o id da sessão como key:

```
ana@dev:~/planner$ sed -i 's|<li key={index}>|<li key={s.id}>|; s|sorted.map((s, index) =>|sorted.map((s) =>|' src/CourseScreen.tsx
ana@dev:~/planner$ grep -n "<li key" src/CourseScreen.tsx
36:          <li key={s.id}>
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Note for Mon 19 Oct=read chapter 3' --do 'click button Reverse the order' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
      - textbox "Note for Wed 21 Oct"
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
      - textbox "Note for Mon 19 Oct": read chapter 3
ana@dev:~/planner$ cp /tmp/CourseScreen.tsx src/CourseScreen.tsx
```

A nota foi junto com a sessão de segunda para a segunda linha, porque a key `s1` identificava o mesmo
`<li>` antes e depois. **Nada mais mudou no código.** O último comando pôs o `CourseScreen` de verdade
de volta.

O bug precisa de três coisas ao mesmo tempo: uma key de índice, itens que mudam de ordem ou são
inseridos, e estado dentro dos itens que não vem dos dados. Listas com as três são comuns: uma lista
de linhas editáveis, uma lista de cartões que podem ser expandidos, uma lista com um item focado. A
key de id não custa nada nas listas que não têm, então é o único hábito que vale ter.
