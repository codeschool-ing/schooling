---
title: Quando o servidor diz não
version: 1
---

**A cópia otimista é só metade da promessa; a outra metade é o que acontece quando o servidor recusa.**
Aqui a API é parada enquanto a página está aberta, como um servidor cai enquanto alguém o usa, e o botão
é apertado depois disso:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'wait 4000' --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 1000' | grep -E 'error|minutes done|Statistics|heading'
-- click button Wed 21 Oct · Statistics · 40 min
[error] Failed to load resource: the server responded with a status of 500 (Internal Server Error)
- heading "This page couldn’t load" [level=1]
- paragraph: A server error occurred. Reload to try again.
```

**A página inteira sumiu.** O `setDone` chamou o `fetch`, que falhou sem ninguém escutando na porta
3001, então a função lançou. **Um erro lançado dentro de uma Action é lançado na árvore de
componentes**, como seria um erro durante a renderização, e sobe até o error boundary mais próximo. Este
projeto ainda não tem um próprio, então o do Next.js tomou a página inteira, como o boundary da raiz do
planejador teria feito na aula 12.

Um boundary o conteria, mas um servidor que não responde não é uma exceção no sentido da aula 12: é uma
resposta conhecida a uma requisição, e o botão deve dizê-lo onde está. Então o `setDone` para de lançar
e passa a responder, no `app/actions.ts`:

```ts
'use server'

import { refresh } from 'next/cache'
import { z } from 'zod'

// Server Functions. The browser calls them; they run here, on the server.

// Answers null when the change was kept, or a sentence saying why it was not.
export async function setDone(id: string, done: boolean): Promise<string | null> {
  try {
    const response = await fetch(`http://localhost:3001/api/sessions/${id}`, {
      method: 'PATCH',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ done }),
    })
    if (!response.ok) return `The server refused the change (HTTP ${response.status}).`
  } catch {
    return 'The server did not answer, so nothing was saved.'
  }
  refresh()
  return null
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

`null` quando a mudança foi mantida, uma frase quando não foi: uma recusa da API, com o status, ou
nenhuma resposta, capturada. Só uma mudança mantida pede o `refresh()`. O alternador mostra a frase, no
`app/SessionToggle.tsx`:

```tsx
'use client'

import { useOptimistic, useState, useTransition } from 'react'
import { setDone } from './actions'

type SessionToggleProps = {
  id: string
  done: boolean
  label: string
}

export function SessionToggle({ id, done, label }: SessionToggleProps) {
  const [shownDone, setShownDone] = useOptimistic(done)
  const [saving, startTransition] = useTransition()
  const [problem, setProblem] = useState<string | null>(null)

  function toggle() {
    startTransition(async () => {
      setShownDone(!shownDone)
      setProblem(await setDone(id, !shownDone))
    })
  }

  return (
    <>
      <button type="button" aria-pressed={shownDone} onClick={toggle}>
        {label}
        {saving && ' · saving…'}
      </button>
      {problem && <p role="alert">{problem}</p>}
    </>
  )
}
```

```
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

A mesma falha de novo:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'wait 4000' --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 1000' | grep -E 'alert|minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 80 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min"
        - alert: The server did not answer, so nothing was saved.
    - option "Statistics" [selected]
- alert
```

**A página ficou, o botão não está pressionado, e um alerta diz por quê.** Durante a Action o botão
mostrou *pressionado*; quando a Action terminou sem nada salvo, o `useOptimistic` descartou a cópia e
mostrou o valor real, ainda não feito. Essa é a metade da promessa que torna o otimismo seguro: **a tela
volta sozinha para a verdade**, e o código só precisa dizer o que aconteceu.

O alerta fica ao lado do botão e não dentro dele, para ser anunciado uma vez, quando aparece, e não
virar parte do nome do botão.
