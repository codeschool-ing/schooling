---
title: memo, e o que o faz funcionar
version: 1
---

**O `memo` envolve um componente para o React pulá-lo quando as props não mudaram.** Antes de renderizar
um componente memoizado, o React compara cada prop nova com a antiga, com `Object.is`; se todas são as
mesmas, reaproveita o último resultado e nem chama o componente. Envolva o `SessionRow`, com um `sed` que
muda a primeira e a última linha dele:

```
ana@dev:~/planner$ sed -i 's/^export function SessionRow(/export const SessionRow = memo(function SessionRow(/; s/^import { Profiler } from .react./import { memo, Profiler } from '\''react'\''/' src/SessionRow.tsx && sed -i '$s/^}$/})/' src/SessionRow.tsx && cat src/SessionRow.tsx
import { memo, Profiler } from 'react'
import { logRender } from './logRender'
import type { Session } from './types'
import { formatDay } from './week'

type SessionRowProps = {
  session: Session
  onToggle: (id: string) => void
}

export const SessionRow = memo(function SessionRow({ session, onToggle }: SessionRowProps) {
  return (
    <Profiler id={`row ${session.id}`} onRender={logRender}>
      <label>
        <input type="checkbox" checked={session.done} onChange={() => onToggle(session.id)} />
        {formatDay(session.date)} · {session.minutes} min
      </label>
    </Profiler>
  )
})
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 99ms on 31 files with 116 rules using 4 threads.
no errors
```

Abra o diálogo de novo:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
```

**Nada desenhado depois do clique.** O `CourseScreen` e o `List` ainda renderizaram de novo, mas cada
linha recebeu o mesmo objeto `session` e a mesma função `onToggle`, então o React pulou as duas. Marque a
quarta:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click checkbox Wed 21 Oct · 40 min'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click checkbox Wed 21 Oct · 40 min
drawn: row s2 (update)
```

**Uma linha desenhada, uma vez: aquela cuja sessão mudou.** A linha de segunda foi pulada nas duas
mudanças do planejador. Essa é a promessa que a aula 4 fez, quando disse que substituir um objeto e manter
o resto deixaria o `memo` da aula 21 pular o que não mudou.

Duas coisas mantiveram as props iguais, e nenhuma é por acaso:

- **Os objetos de sessão.** Depois do `PATCH`, o React Query buscou o planejador inteiro de novo, e JSON
  vindo de um servidor é sempre objeto novo. O React Query compara a resposta nova com a guardada e
  **mantém o objeto antigo onde nada nele mudou**, o que ele chama de compartilhamento estrutural. A sessão
  de segunda é o mesmo objeto de antes do refetch; a de quarta é nova.
- **O `toggleDone`.** É o `mutate` do React Query, que é a mesma função a cada renderização, como a aula 11
  observou.

```schooling-figure
{"svg": "<svg data-fig=\"skip\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Marcando a sessão de quarta com o SessionRow memoizado. O CourseScreen e o List renderizam de novo. A linha s1 recebe o mesmo objeto de sessão e o mesmo onToggle, então o React compara, não acha mudança e a pula. A linha s2 recebe um objeto de sessão novo, done true, então é desenhada.\"><rect x=\"270\" y=\"14\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"29.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseScreen</text><rect x=\"270\" y=\"64\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">List</text><line x1=\"360\" y1=\"44\" x2=\"360\" y2=\"64\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"90\" y=\"130\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"205.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SessionRow · s1</text><text x=\"205.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mesma sessão, mesmo onToggle</text><rect x=\"400\" y=\"130\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"515.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SessionRow · s2</text><text x=\"515.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma sessão nova: done true</text><line x1=\"360\" y1=\"94\" x2=\"205\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"360\" y1=\"94\" x2=\"515\" y2=\"130\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"205\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pulada</text><text x=\"515\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">desenhada</text></svg>", "caption": "O memo compara cada prop; o mesmo objeto é uma renderização pulada.", "same": ["SessionRow · s1", "SessionRow · s2"]}
```
