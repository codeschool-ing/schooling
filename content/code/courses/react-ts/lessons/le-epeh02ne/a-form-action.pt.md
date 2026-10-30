---
title: Um formulário cuja ação roda no servidor
version: 1
---

**O React 19 deixa a `action` de um formulário ser uma função.** Com uma Server Function, os campos do
formulário chegam ao servidor como um `FormData`, e o que a função devolve volta para a página. O
planejador precisa de um jeito de acrescentar uma sessão, e o servidor é o lugar certo para conferi-la,
porque um formulário não é a única coisa que pode enviá-la.

A conferência usa o Zod, como na aula 10, agora instalado neste projeto:

```
ana@dev:~/planner-next$ npm install zod@4.6.7 2>&1 | tail -n 1; grep zod package.json
found 0 vulnerabilities
    "zod": "4.6.7"
ana@dev:~/planner-next$ sed -i 's|      <SessionList sessions={thisWeek} courses={courses} />|&\n      <AddSession courses={courses} />|' app/Planner.tsx && sed -i "4i import { AddSession } from './AddSession'" app/Planner.tsx && sed -n '1,6p;34,36p' app/Planner.tsx
import Link from 'next/link'
import { getPlanner } from '@/lib/planner'
import { addDays, formatWeek, inWeek, minutes, mondayOf, today } from '@/lib/week'
import { AddSession } from './AddSession'
import { SessionList } from './SessionList'
import { WeekKeys } from './WeekKeys'
    </>
  )
}
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

Os dois comandos `sed` acrescentam o formulário ao `Planner`, abaixo da lista, e o import dele no topo,
e o `sed -n` imprime os dois lugares. A nova Server Function está no `app/actions.ts`, abaixo do
`setDone`:

```ts
'use server'

import { refresh } from 'next/cache'
import { z } from 'zod'

// Server Functions. The browser calls them; they run here, on the server.

export async function setDone(id: string, done: boolean) {
  const response = await fetch(`http://localhost:3001/api/sessions/${id}`, {
    method: 'PATCH',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ done }),
  })
  if (!response.ok) throw new Error(`HTTP ${response.status} from the planner API`)
  refresh()
}

const sessionSchema = z.object({
  course: z.string().min(1, 'Choose a course.'),
  date: z.iso.date({ error: 'Choose the day of the session.' }),
  minutes: z.coerce
    .number({ error: 'Enter how many minutes.' })
    .int('Use whole minutes.')
    .min(5, 'A session is at least 5 minutes.')
    .max(240, 'A session is at most 240 minutes.'),
})

export type AddResult = { error?: string; added?: string }

export async function addSession(_previous: AddResult, form: FormData): Promise<AddResult> {
  const parsed = sessionSchema.safeParse(Object.fromEntries(form))
  if (!parsed.success) return { error: parsed.error.issues[0].message }

  const response = await fetch('http://localhost:3001/api/sessions', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(parsed.data),
  })
  if (!response.ok) return { error: 'The server did not keep the session.' }
  refresh()
  return { added: `Planned ${parsed.data.minutes} min on ${parsed.data.date}.` }
}
```

- **`(_previous, form)` é a forma com que o `useActionState` a chama**: o resultado do último envio, e
  os dados do formulário. O primeiro argumento não é usado aqui, como diz o sublinhado.
- **`Object.fromEntries(form)`** transforma os campos num objeto para o Zod. Todo campo chega como
  string, e por isso os minutos usam `z.coerce.number`.
- **Ela devolve os erros em vez de lançá-los.** Uma falha de validação é uma resposta esperada, e o
  formulário deve mostrá-la, não cair.

O formulário é um Client Component, o `app/AddSession.tsx`, porque mostra o que o último envio disse:

```tsx
'use client'

import { useActionState } from 'react'
import { useFormStatus } from 'react-dom'
import type { Course } from '@/lib/types'
import { addSession } from './actions'

function Submit() {
  const { pending } = useFormStatus()
  return (
    <button type="submit" disabled={pending}>
      {pending ? 'Adding…' : 'Add session'}
    </button>
  )
}

export function AddSession({ courses }: { courses: Course[] }) {
  const [result, action] = useActionState(addSession, {})
  return (
    <form action={action}>
      <h2>Plan a session</h2>
      <label htmlFor="course">Course</label>
      <select id="course" name="course">
        {courses.map((c) => (
          <option key={c.id} value={c.id}>
            {c.name}
          </option>
        ))}
      </select>
      <label htmlFor="date">Date</label>
      <input id="date" name="date" type="date" />
      <label htmlFor="minutes">Minutes</label>
      <input id="minutes" name="minutes" type="number" defaultValue={30} />
      <Submit />
      <p role="status">{result.error ?? result.added}</p>
    </form>
  )
}
```

- **`useActionState(addSession, {})`** devolve o resultado mais recente, `{}` antes do primeiro envio,
  e uma `action` para dar ao formulário. O React chama o `addSession` com o resultado anterior e os
  dados do formulário, e renderiza de novo com o que ele devolve.
- **O `useFormStatus` lê o estado do formulário em que está**, e por isso o `Submit` é um componente
  próprio: chamado no `AddSession`, que renderiza o formulário, não veria formulário nenhum em volta.
  Enquanto o envio roda, o botão fica desabilitado e diz *Adding…*.
- **O resultado fica numa região `role="status"`**, que um leitor de tela anuncia quando o texto muda,
  como a mensagem da aula 14.

Enviado vazio:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click button Add session' | sed -n '/Plan a session/,$p'
  - heading "Plan a session" [level=2]
  - text: Course
  - combobox "Course":
    - option "Statistics" [selected]
    - option "Spanish"
    - option "Organic chemistry"
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
  - status: Choose the day of the session.
- alert
```

A resposta do servidor, na linha de status. A seleção de curso começa em Statistics. Preenchido
direito:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | grep -E 'minutes done|Sat|status|textbox|spinbutton'
    - paragraph: 80 of 240 minutes done
        - button "Sat 24 Oct · Statistics · 45 min"
  - textbox "Date"
  - spinbutton "Minutes": "30"
  - status: Planned 45 min on 2026-10-24.
```

Os 45 minutos de sábado estão na lista, a semana planeja 240, e o status diz o que foi planejado. **E o
formulário está vazio de novo**: Date em branco, Minutes de volta a 30. O React 19 reinicia os campos de
um formulário quando a ação dele termina, para que um formulário que funcionou fique pronto para a
próxima entrada. Ele faz isso seja qual for a resposta da ação:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'fill Date=2026-10-24' --do 'fill Minutes=500' --do 'click button Add session' | grep -E 'status|textbox|spinbutton'
  - textbox "Date"
  - spinbutton "Minutes": "30"
  - status: A session is at most 240 minutes.
```

O erro está certo, e **o 500 e a data que o usuário digitou sumiram**, então ele precisa digitar os dois
de novo para corrigir um deles. A cura de costume é devolver os valores enviados no resultado e usá-los
como `defaultValue` dos campos; o React Hook Form da aula 10, que guarda os valores ele mesmo, não tem o
problema.
