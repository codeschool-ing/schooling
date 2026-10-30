---
title: Um formulário controlado
version: 1
---

**Um input controlado mostra o que o estado do React diz, e pede ao React para mudá-lo a cada
tecla.** As caixas de marcação da aula 4 eram controladas: o `checked` vinha dos dados, o `onChange`
pedia uma mudança. Um campo de texto funciona igual com `value`, e esse é o primeiro jeito de escrever
o formulário que a segunda tela da aula 1 prometeu: uma data, um número de minutos e um botão que
acrescenta a sessão.

Primeiro o planejador precisa de um jeito de acrescentar uma. O `usePlanner` ganha o `addSession`; o
resto do arquivo é o da aula 7:

```typescript
import { useCallback, useEffect, useState } from 'react'
import type { Course, Session } from './types'

type Status = 'loading' | 'ready' | 'failed'
export type NewSession = Pick<Session, 'course' | 'date' | 'minutes'>

export function usePlanner() {
  const [courses, setCourses] = useState<Course[]>([])
  const [sessions, setSessions] = useState<Session[]>([])
  const [status, setStatus] = useState<Status>('loading')

  useEffect(() => {
    let ignore = false
    fetch('/courses.json')
      .then((response) => {
        if (!response.ok) throw new Error(`HTTP ${response.status}`)
        return response.json()
      })
      .then((data: { courses: Course[]; sessions: Session[] }) => {
        if (ignore) return
        setCourses(data.courses)
        setSessions(data.sessions)
        setStatus('ready')
      })
      .catch((error) => {
        if (ignore) return
        console.error('could not load the planner:', error.message)
        setStatus('failed')
      })
    return () => {
      ignore = true
    }
  }, [])

  const toggleDone = useCallback((id: string) => {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }, [])

  const addSession = useCallback((session: NewSession) => {
    setSessions((all) => [...all, { ...session, id: crypto.randomUUID(), done: false }])
  }, [])

  return { status, courses, sessions, toggleDone, addSession }
}
```

O `NewSession` é uma sessão sem os dois campos que o próprio planejador preenche: o id, feito pelo
`crypto.randomUUID()` no momento em que a sessão é criada, que a aula 8 disse que uma key precisa, e o
`done`, que começa falso. O `Pick` monta esse tipo a partir de `Session`, então ele não tem como se
afastar dele. O array é substituído com `[...all, new]`, da tabela da aula 4, nunca empurrado.

O formulário, `src/AddSessionForm.tsx`, lê o `addSession` do context da aula 9:

```tsx
import { useState, type FormEvent } from 'react'
import { usePlannerContext } from './plannerContext'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()
  const [date, setDate] = useState('')
  const [minutes, setMinutes] = useState('30')

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    addSession({ course, date, minutes: Number(minutes) })
    setDate('')
  }

  return (
    <form onSubmit={submit}>
      <h2>Add a session</h2>
      <label>
        Date
        <input type="date" value={date} onChange={(e) => setDate(e.target.value)} />
      </label>
      <label>
        Minutes
        <input type="number" value={minutes} onChange={(e) => setMinutes(e.target.value)} />
      </label>
      <button type="submit">Add session</button>
    </form>
  )
}
```

- **Cada campo tem estado e um `onChange`.** Os minutos são guardados como string, porque é isso que
  um input guarda; o `Number(minutes)` converte uma vez, no envio.
- **`event.preventDefault()`** impede o envio do próprio navegador, que recarregaria a página e
  jogaria o app inteiro fora. Um `<form>` no React quase sempre começa com ele.
- **Um `<label>` em volta do input** dá o nome dele: um leitor de tela anuncia "Date", e clicar na
  palavra foca o campo.

O `CourseScreen` o desenha embaixo da lista, e um `sed` acrescenta as duas linhas:

```
ana@dev:~/planner$ sed -i "s|^import { usePlannerContext } from './plannerContext'$|import { AddSessionForm } from './AddSessionForm'\n&|; s|^    </>$|      <AddSessionForm course={course.id} />\n&|" src/CourseScreen.tsx
ana@dev:~/planner$ grep -n AddSessionForm src/CourseScreen.tsx
2:import { AddSessionForm } from './AddSessionForm'
44:      <AddSessionForm course={course.id} />
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 83ms on 16 files with 116 rules using 4 threads.
no errors
```

Abra Statistics, e o formulário está embaixo das duas sessões. Preencha uma data e aperte o botão:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
  - heading "Add a session" [level=2]
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'click button Add session' | sed -n '/list:/,/heading "Add/p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
    - listitem:
      - checkbox "Sat 24 Oct · 30 min"
      - text: Sat 24 Oct · 30 min
  - heading "Add a session" [level=2]
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'click button Add session' --do 'click button Back to courses' | grep minutes
    - paragraph: 80 of 225 minutes done
```

Uma terceira sessão, sábado, dia 24, 30 minutos do valor inicial do campo, posta no lugar pelo `sort`
da aula 4. De volta à primeira tela, a semana planeja **225 minutos**: os 195 que havia, e mais 30. A
lista, os totais e o formulário leem as mesmas `sessions`, então ninguém precisou ser avisado para se
atualizar.

## O formulário que aceita qualquer coisa

Aperte o botão sem escolher uma data:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Add session' | sed -n '/list:/,/heading "Add/p'
  - list:
    - listitem:
      - checkbox "Invalid Date · 30 min"
      - text: Invalid Date · 30 min
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
  - heading "Add a session" [level=2]
```

**"Invalid Date · 30 min", no topo da lista.** O formulário entregou ao `addSession` uma string vazia,
o planejador a guardou, e o `formatDay('')` fez o que pôde com ela; a string vazia fica antes de toda
data na ordenação. Nada impediu, porque nada conferiu. As duas próximas seções acrescentam a
conferência, uma com a ajuda do navegador e outra com a de uma biblioteca.
