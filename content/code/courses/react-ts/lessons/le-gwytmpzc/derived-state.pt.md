---
title: O estado que você não deve guardar
version: 1
---

**Se um valor pode ser calculado a partir de props ou de estado que você já tem, calcule. Não
guarde.** Estado é uma cópia, e uma cópia precisa ser mantida em dia com aquilo de que foi copiada.
Ninguém a mantém em dia, então ela fica velha. É o erro de estado mais comum no React, e esta seção o
comete de propósito. O `WeekSummary` do planejador soma os minutos em toda renderização; aqui está
uma versão que os soma uma vez, para dentro do estado:

```tsx
import { useState } from 'react'
import type { Session } from './types'
import { formatWeek, minutes } from './week'

type WeekSummaryProps = {
  monday: string
  sessions: Session[]
}

// A mistake, on purpose: the totals copied into state.
export function WeekSummary({ monday, sessions }: WeekSummaryProps) {
  const [planned] = useState(minutes(sessions))
  const [done] = useState(minutes(sessions.filter((s) => s.done)))
  return (
    <section aria-label="This week">
      <p>Week of {formatWeek(monday)}</p>
      <p>
        {done} of {planned} minutes done
      </p>
    </section>
  )
}
```

Depois de "Next week":

```
ana@dev:~/planner$ cp src/WeekSummary.tsx /tmp/WeekSummary.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n 6,9p
    - button "Next week"
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 80 of 195 minutes done
ana@dev:~/planner$ cp /tmp/WeekSummary.tsx src/WeekSummary.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Next week' | sed -n 6,9p
    - button "Next week"
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 0 of 0 minutes done
```

**"Week of 26 Oct 2026" e "80 of 195 minutes done"**, lado a lado, os dois na tela ao mesmo tempo. A
linha da semana vem da prop, que é nova. Os totais vêm do estado, cujo valor inicial foi calculado na
primeira renderização e nunca mais, porque um valor inicial é usado uma vez. O segundo `look` põe o
`WeekSummary` original de volta, e os totais acompanham a semana: 0 de 0.

O planejador já guarda três pedaços de estado, e todo número da primeira tela é calculado a partir
deles durante a renderização:

| guardado, porque nada mais sabe | calculado, porque outra coisa sabe |
|---|---|
| `monday`, qual semana o usuário escolheu | as sessões da semana: um filtro de `sessions` por `monday` |
| `sessions`, os dados do planejador | os minutos planejados e feitos: somas sobre as sessões da semana |
| `openId`, qual curso está aberto | o curso aberto: um `courses.find` por `openId` |

**O teste para um pedaço de estado é perguntar o que o definiria.** Se a resposta for "o usuário, ou
o servidor", é estado. Se a resposta for "precisa ser recalculado sempre que aquela outra coisa
mudar", é um cálculo, e o lugar certo para um cálculo é a renderização. A aula 7 mostra o que fazer
quando um cálculo é caro o bastante para importar, o que um filtro sobre seis sessões não é.
