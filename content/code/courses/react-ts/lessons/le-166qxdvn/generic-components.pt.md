---
title: Um componente que aceita qualquer coisa
version: 1
---

**Um genérico é um tipo com um parâmetro**, preenchido onde é usado. `useState<string | null>`, para o
curso aberto, foi um na aula 4, e `useLoaderData<typeof courseLoader>` na aula 17. Um componente também
pode ter um, e o caso clássico é uma lista: o código que desenha uma lista não liga para o que há nela,
mas o código que desenha cada item liga.

O `src/List.tsx`:

```tsx
import type { ReactNode } from 'react'

type ListProps<T> = {
  items: T[]
  keyOf: (item: T) => string
  render: (item: T) => ReactNode
  empty: ReactNode
}

// A list of anything: the caller says how to key an item and how to draw one.
export function List<T>({ items, keyOf, render, empty }: ListProps<T>) {
  if (items.length === 0) return <p>{empty}</p>
  return (
    <ul>
      {items.map((item) => (
        <li key={keyOf(item)}>{render(item)}</li>
      ))}
    </ul>
  )
}
```

- **`<T>` depois do nome** declara o parâmetro. O `ListProps<T>` o usa: `items` é um `T[]`, e `keyOf` e
  `render` recebem cada um um `T`.
- **O componente nunca olha dentro de um `T`.** Ele pede a quem chama a key e o desenho, que é o que o
  deixa aceitar qualquer coisa.
- **Uma lista vazia desenha uma frase**, então uma lista desenhada com ele ganha o estado vazio da aula 8
  sem repeti-lo.

A lista da tela do curso o usa, o `src/CourseScreen.tsx`:

```tsx
import { useEffect, useRef, useState } from 'react'
import { Link, useLoaderData } from 'react-router'
import { AddSessionForm } from './AddSessionForm'
import type { courseLoader } from './courseLoader'
import { Dialog } from './Dialog'
import { List } from './List'
import { useReadyPlanner } from './plannerContext'
import { StatusMessage } from './StatusMessage'
import { formatDay } from './week'

export function CourseScreen() {
  const course = useLoaderData<typeof courseLoader>()
  const { sessions, toggleDone } = useReadyPlanner()
  const [planning, setPlanning] = useState(false)
  const [message, setMessage] = useState('')
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <Link to="/">Back to courses</Link>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      <List
        items={sorted}
        keyOf={(s) => s.id}
        render={(s) => (
          <label>
            <input type="checkbox" checked={s.done} onChange={() => toggleDone(s.id)} />
            {formatDay(s.date)} · {s.minutes} min
          </label>
        )}
        empty="No sessions planned for this course yet."
      />
      <button type="button" onClick={() => setPlanning(true)}>
        Plan a session
      </button>
      <Dialog open={planning} title="Plan a session" onClose={() => setPlanning(false)}>
        <AddSessionForm
          course={course.id}
          onAdded={(s) => {
            setPlanning(false)
            setMessage(`Planned ${formatDay(s.date)} · ${s.minutes} min.`)
          }}
        />
      </Dialog>
      <StatusMessage message={message} />
    </>
  )
}
```

Nenhum `<Session>` está escrito em lugar nenhum. **O TypeScript infere `T` a partir de `items`**: o
`sorted` é um `Session[]`, então `T` é `Session`, e o `s` em `keyOf` e `render` é um `Session` sem dizer
uma palavra.

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 82ms on 28 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 | sed -n '/list/,/Plan a session/p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
  - button "Plan a session"
```

A lista é desenhada como antes, com as duas caixas. Para ver que a inferência é real, peça um campo que
uma sessão não tem:

```
ana@dev:~/planner$ sed -i 's/{formatDay(s.date)} · {s.minutes} min/{s.title}/' src/CourseScreen.tsx && npx tsc -b
src/CourseScreen.tsx(36,16): error TS2339: Property 'title' does not exist on type 'Session'.
ana@dev:~/planner$ sed -i 's/{s.title}/{formatDay(s.date)} · {s.minutes} min/' src/CourseScreen.tsx && npx tsc -b && echo no errors
no errors
```

**`Property 'title' does not exist on type 'Session'`**, sobre um parâmetro cujo tipo nunca foi escrito. O
segundo comando devolveu a linha.

Componentes genéricos valem a pena onde a mesma forma de interface é desenhada para dados diferentes:
listas, tabelas, seleções, autocompletes. Não valem para um componente usado uma vez, e um parâmetro de
tipo que ninguém preenche de outro jeito é uma coisa a mais para ler.
