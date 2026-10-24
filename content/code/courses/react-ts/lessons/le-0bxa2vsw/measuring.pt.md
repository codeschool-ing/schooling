---
title: Medindo antes de mudar qualquer coisa
version: 1
---

**A aula 3 deixou uma pergunta aberta: o React chama um componente de novo sempre que o pai renderiza, e
se isso é barato ficou para depois.** Esta aula responde do único jeito honesto, medindo primeiro. O React
tem um componente para isso, o **`<Profiler>`**: ele envolve uma parte da árvore e chama uma função a cada
commit dessa parte, com o motivo e o tempo que levou.

A função, `src/logRender.ts`, imprime uma linha por commit:

```ts
import type { ProfilerOnRenderCallback } from 'react'

// For a <Profiler>: one line in the console each time what it wraps is drawn.
export const logRender: ProfilerOnRenderCallback = (id, phase) => {
  console.log(`drawn: ${id} (${phase})`)
}
```

`phase` é `'mount'` na primeira vez e `'update'` depois. O callback também recebe quanto a renderização
levou, `actualDuration`, e quanto levaria sem nada pulado, `baseDuration`; as transcrições os deixam de
fora porque mudam de execução para execução, mas são eles que você lê quando a pergunta é velocidade.

As linhas da tela do curso vão para um componente próprio, `src/SessionRow.tsx`, cada uma envolvida num
profiler com o nome da sua sessão:

```tsx
import { Profiler } from 'react'
import { logRender } from './logRender'
import type { Session } from './types'
import { formatDay } from './week'

type SessionRowProps = {
  session: Session
  onToggle: (id: string) => void
}

export function SessionRow({ session, onToggle }: SessionRowProps) {
  return (
    <Profiler id={`row ${session.id}`} onRender={logRender}>
      <label>
        <input type="checkbox" checked={session.done} onChange={() => onToggle(session.id)} />
        {formatDay(session.date)} · {session.minutes} min
      </label>
    </Profiler>
  )
}
```

e a tela as desenha, `src/CourseScreen.tsx`:

```tsx
import { useEffect, useRef, useState } from 'react'
import { Link, useLoaderData } from 'react-router'
import { AddSessionForm } from './AddSessionForm'
import type { courseLoader } from './courseLoader'
import { Dialog } from './Dialog'
import { List } from './List'
import { useReadyPlanner } from './plannerContext'
import { SessionRow } from './SessionRow'
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
        render={(s) => <SessionRow session={s} onToggle={toggleDone} />}
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

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 88ms on 31 files with 116 rules using 4 threads.
no errors
```

O `--quiet` guarda só o console, que é tudo de que esta aula precisa. Abrindo estatística:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet
drawn: row s1 (mount)
drawn: row s2 (mount)
```

Duas linhas montadas, como esperado. Agora abra o diálogo, que não muda nada em nenhuma das sessões:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
drawn: row s1 (update)
drawn: row s2 (update)
```

**As duas linhas desenhadas de novo.** O `setPlanning(true)` renderizou de novo o `CourseScreen`, que
renderizou o `List`, que renderizou as duas linhas, com as mesmas sessões de antes. Essa é **a
renderização que ninguém pediu**. Marque a sessão de quarta:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click checkbox Wed 21 Oct · 40 min'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click checkbox Wed 21 Oct · 40 min
drawn: row s1 (update)
drawn: row s2 (update)
drawn: row s1 (update)
drawn: row s2 (update)
```

**Cada linha foi desenhada duas vezes**: o estado do planejador mudou duas vezes enquanto a mudança ia ao
servidor e voltava, e cada mudança renderizou de novo a tela inteira. A linha de segunda foi desenhada
duas vezes embora nada em segunda tenha mudado.

Nada disso está errado, e nesta tela nada disso é lento: duas linhas não são nada. A mesma forma numa
lista de quinhentas linhas, ou em linhas que desenham um gráfico cada, é onde começa a importar, e o
profiler é como você saberia em qual caso está.
