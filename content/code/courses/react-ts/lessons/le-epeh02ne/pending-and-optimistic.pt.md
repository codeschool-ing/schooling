---
title: Enquanto o servidor trabalha
version: 1
---

**Uma Server Function demora o que o servidor demorar, e até agora a tela não dizia nada enquanto
isso.** Reinicie a API com `DELAY=2000`, para toda requisição esperar dois segundos, e aperte de novo a
sessão de quarta:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 80 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min"
    - option "Statistics" [selected]
```

Esta é a página cerca de um terço de segundo depois do clique: **nada mudou**. O `PATCH` espera dois
segundos e o `GET` do `refresh()` espera mais dois, então por quatro segundos o botão não faz nada
visível, e o usuário aperta de novo. O React tem dois hooks para essa espera.

O **`useTransition`** devolve uma flag, `isPending`, e uma função, `startTransition`. Uma função `async`
passada ao `startTransition` é uma **Action**: o React marca tudo o que ela começa como um trabalho só,
e a flag fica true até ele terminar, com a resposta do servidor.

O **`useOptimistic`** mostra um valor como se a mudança já tivesse dado certo. Ele recebe o valor real,
a prop que vem do servidor, e devolve uma cópia que você pode mudar durante uma Action. Quando a Action
termina, a cópia é descartada e o valor real volta a aparecer, seja ele qual for então.

Os dois vão para um Client Component de uma sessão, o `app/SessionToggle.tsx`:

```tsx
'use client'

import { useOptimistic, useTransition } from 'react'
import { setDone } from './actions'

type SessionToggleProps = {
  id: string
  done: boolean
  label: string
}

export function SessionToggle({ id, done, label }: SessionToggleProps) {
  const [shownDone, setShownDone] = useOptimistic(done)
  const [saving, startTransition] = useTransition()

  function toggle() {
    startTransition(async () => {
      setShownDone(!shownDone)
      await setDone(id, !shownDone)
    })
  }

  return (
    <button type="button" aria-pressed={shownDone} onClick={toggle}>
      {label}
      {saving && ' · saving…'}
    </button>
  )
}
```

Num clique, dentro da Action, ele muda primeiro o valor otimista, que aparece na hora, e depois espera
o servidor. O `saving` acrescenta *· saving…* ao nome do botão pelo tempo que isso levar. A lista entrega
cada sessão a ele em vez de desenhar um formulário:

```tsx
import type { Course, Session } from '@/lib/types'
import { formatDay } from '@/lib/week'
import { SessionToggle } from './SessionToggle'

type SessionListProps = {
  sessions: Session[]
  courses: Course[]
}

export function SessionList({ sessions, courses }: SessionListProps) {
  const name = (id: string) => courses.find((c) => c.id === id)?.name ?? id
  const sorted = [...sessions].sort((a, b) => a.date.localeCompare(b.date))
  return (
    <section aria-labelledby="sessions-heading">
      <h2 id="sessions-heading">Sessions this week</h2>
      <ul>
        {sorted.map((s) => (
          <li key={s.id}>
            <SessionToggle
              id={s.id}
              done={s.done}
              label={`${formatDay(s.date)} · ${name(s.course)} · ${s.minutes} min`}
            />
          </li>
        ))}
      </ul>
    </section>
  )
}
```

```
ana@dev:~/planner-next$ npx tsc --noEmit && echo no errors
no errors
```

O mesmo momento de antes, um terço de segundo depois do clique:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' | grep -E 'minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 80 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min · saving…" [pressed]
    - option "Statistics" [selected]
```

**Pressionado, e dizendo que está salvando**, embora o servidor não tenha respondido: o resumo ainda diz
80, porque é desenhado a partir dos dados do servidor e eles ainda não mudaram. Seis segundos depois:

```
ana@dev:~/planner-next$ look http://localhost:3000/?week=2026-10-19 --today 2026-10-21 --do 'click button Wed 21 Oct · Statistics · 40 min' --do 'wait 6000' | grep -E 'minutes done|Statistics'
-- click button Wed 21 Oct · Statistics · 40 min
    - paragraph: 120 of 195 minutes done
        - button "Mon 19 Oct · Statistics · 50 min" [pressed]
        - button "Wed 21 Oct · Statistics · 40 min" [pressed]
    - option "Statistics" [selected]
```

A resposta do servidor chegou, com 120 minutos e a quarta pressionada. A cópia otimista foi descartada e
o valor real é o mesmo, então nada no botão se mexeu: ele estava certo desde o começo.

```schooling-figure
{"svg": "<svg data-fig=\"optimistic\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas do tempo do estado pressionado do botão. Sucesso: no clique o valor mostrado vira pressionado, enquanto o valor do servidor ainda é não pressionado; depois de quatro segundos o servidor diz pressionado e o valor mostrado o acompanha, sem mudar. Falha: o valor mostrado vira pressionado no clique; quando a Action termina sem nada salvo, o valor mostrado volta ao do servidor, não pressionado, e um alerta diz por quê.\"><text x=\"20\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">deu certo</text><rect x=\"120\" y=\"40\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não pressionado</text><line x1=\"252\" y1=\"58\" x2=\"278\" y2=\"58\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"278.0,58.0 270.5,61.2 270.5,54.8\" fill=\"var(--wire)\"></polygon><rect x=\"280\" y=\"40\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"385.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pressionado · saving…</text><line x1=\"492\" y1=\"58\" x2=\"518\" y2=\"58\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"518.0,58.0 510.5,61.2 510.5,54.8\" fill=\"var(--wire)\"></polygon><rect x=\"520\" y=\"40\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor: pressionado</text><text x=\"385\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cópia otimista, durante a Action</text><text x=\"20\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">falhou</text><rect x=\"120\" y=\"135\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não pressionado</text><line x1=\"252\" y1=\"153\" x2=\"278\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"278.0,153.0 270.5,156.2 270.5,149.8\" fill=\"var(--wire)\"></polygon><rect x=\"280\" y=\"135\" width=\"210\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"385.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pressionado · saving…</text><line x1=\"492\" y1=\"153\" x2=\"518\" y2=\"153\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"518.0,153.0 510.5,156.2 510.5,149.8\" fill=\"var(--wire)\"></polygon><rect x=\"520\" y=\"135\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"153.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidor: não pressionado + alerta</text><text x=\"385\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a cópia otimista, durante a Action</text><text x=\"185\" y=\"32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">clique</text></svg>", "caption": "Durante a Action aparece a cópia; depois dela, o valor do servidor."}
```

**O que uma atualização otimista promete**: que a mudança muito provavelmente vai dar certo, então
mostrá-la cedo é honesto. Uma marcação no próprio planejador é um bom caso. Um pagamento não é: mostrar
*pago* antes de o banco responder diz ao usuário algo que pode ser falso, e ele pode fechar a página
acreditando nisso.
