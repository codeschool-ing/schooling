---
title: Um diálogo nativo, aberto pelo React
version: 1
---

**O elemento `<dialog>` é o diálogo do próprio navegador**, e o `showModal()` o abre como modal: por
cima de tudo, com o resto da página inerte, de modo que nada atrás dele possa ser clicado, alcançado
com Tab ou lido por um leitor de tela até ele fechar. O React renderiza o elemento; um ref e um efeito
chamam o método. Tudo isso é o `src/Dialog.tsx`:

```tsx
import { useEffect, useId, useRef, type ReactNode } from 'react'

type DialogProps = {
  open: boolean
  title: string
  onClose: () => void
  children: ReactNode
}

export function Dialog({ open, title, onClose, children }: DialogProps) {
  const ref = useRef<HTMLDialogElement>(null)
  const titleId = useId()

  useEffect(() => {
    const dialog = ref.current
    if (!dialog) return
    if (open && !dialog.open) dialog.showModal()
    if (!open && dialog.open) dialog.close()
  }, [open])

  return (
    <dialog ref={ref} aria-labelledby={titleId} onClose={onClose}>
      <h2 id={titleId}>{title}</h2>
      {children}
      <button type="button" onClick={onClose}>
        Close
      </button>
    </dialog>
  )
}
```

- **`open` é uma prop, e o efeito faz o elemento concordar com ela.** Quando a prop diz aberto e o
  diálogo não está, ele chama `showModal()`; quando a prop diz fechado e o diálogo está aberto, ele
  chama `close()`. Conferir `dialog.open` antes faz a segunda execução do efeito no strict mode
  encontrar o diálogo já aberto e deixá-lo como está.
- **`onClose` é o evento `close` do próprio diálogo.** O navegador o dispara seja qual for o jeito como
  o diálogo fechou: o botão Close, o `close()` do efeito, ou a **tecla Escape**, que fecha um diálogo
  modal sem código nenhum seu. O pai fica sabendo de cada um, e o estado dele nunca diz aberto com o
  diálogo fechado.
- **`aria-labelledby` dá nome ao diálogo** a partir do título, com um id do `useId`, como a aula 10
  fez para os erros do formulário.

No `src/CourseScreen.tsx`, o formulário vai para um diálogo, aberto por um botão:

```tsx
import { useEffect, useRef, useState } from 'react'
import { AddSessionForm } from './AddSessionForm'
import { Dialog } from './Dialog'
import { usePlannerContext } from './plannerContext'
import type { Course } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  onBack: () => void
}

export function CourseScreen({ course, onBack }: CourseScreenProps) {
  const { sessions, toggleDone } = usePlannerContext()
  const [planning, setPlanning] = useState(false)
  const heading = useRef<HTMLHeadingElement>(null)
  useEffect(() => {
    heading.current?.focus()
  }, [])

  const sorted = sessions
    .filter((s) => s.course === course.id)
    .sort((a, b) => a.date.localeCompare(b.date))
  return (
    <>
      <button type="button" onClick={onBack}>
        Back to courses
      </button>
      <h1 ref={heading} tabIndex={-1}>
        {course.name}
      </h1>
      {sorted.length === 0 ? (
        <p>No sessions planned for this course yet.</p>
      ) : (
        <ul>
          {sorted.map((s) => (
            <li key={s.id}>
              <label>
                <input type="checkbox" checked={s.done} onChange={() => toggleDone(s.id)} />
                {formatDay(s.date)} · {s.minutes} min
              </label>
            </li>
          ))}
        </ul>
      )}
      <button type="button" onClick={() => setPlanning(true)}>
        Plan a session
      </button>
      <Dialog open={planning} title="Plan a session" onClose={() => setPlanning(false)}>
        <AddSessionForm course={course.id} onAdded={() => setPlanning(false)} />
      </Dialog>
    </>
  )
}
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 77ms on 22 files with 116 rules using 4 threads.
no errors
```

Primeiro a tela do curso, com o diálogo fechado:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics'
-- click button Statistics
- main:
  - button "Back to courses"
  - heading "Statistics" [level=1]
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
  - button "Plan a session"
```

**Nenhum formulário, e nenhum diálogo no retrato.** Um `<dialog>` fechado está na página mas não é
mostrado, nem anunciado. Aperte *Plan a session*:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session'
-- click button Statistics
-- click button Plan a session
- main:
  - button "Back to courses"
  - heading "Statistics" [level=1]
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
  - button "Plan a session"
  - dialog "Plan a session":
    - heading "Plan a session" [level=2]
    - text: Date
    - textbox "Date"
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
    - button "Close"
```

`dialog "Plan a session"`, com o nome do título, o formulário e um botão Close dentro. O `look` ainda
lista a página atrás dele, porque lê todos os elementos da página; num navegador, essa parte agora está
inerte. Então, Escape:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session' --do 'press Escape' | grep -E 'dialog|button'
-- click button Statistics
-- click button Plan a session
  - button "Back to courses"
  - button "Plan a session"
```

O diálogo sumiu do retrato, e o estado concorda: o Escape disparou o `close`, e o `onClose` pôs
`planning` de volta em `false`.

```schooling-figure
{"svg": "<svg data-fig=\"dialog-sync\" viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Duas direções entre o React e o diálogo. Do React: o estado planning vira true, o efeito roda e chama showModal no elemento do ref. Do navegador: o Escape ou o botão Close fecham o diálogo, o evento close dispara, o onClose põe planning em false, e o efeito encontra o diálogo já fechado.\"><rect x=\"20\" y=\"70\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"92.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">planning</text><text x=\"110.0\" y=\"107.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">true / false</text><rect x=\"520\" y=\"70\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"92.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;dialog&gt;</text><text x=\"610.0\" y=\"107.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">ref.current</text><line x1=\"202\" y1=\"86\" x2=\"518\" y2=\"86\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"518.0,86.0 510.5,89.2 510.5,82.8\" fill=\"var(--phosphor)\"></polygon><text x=\"360\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">useEffect → showModal() / close()</text><line x1=\"518\" y1=\"116\" x2=\"202\" y2=\"116\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"202.0,116.0 209.5,112.8 209.5,119.2\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">close event → onClose()</text><text x=\"610\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Escape, botão Close</text><text x=\"110\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o estado do React</text><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o navegador é dono de como um diálogo modal se comporta</text></svg>", "caption": "A prop pede aberto ou fechado; o evento close relata o que o navegador fez."}
```

**O que o navegador fez e que este código nunca menciona:**

- Quando o diálogo abriu, **o foco foi para dentro dele**, para o primeiro campo, Date.
- Quando fechou, pelo Escape ou pelo botão Close, **o foco voltou para *Plan a session***, o botão que
  o tinha antes.
- Enquanto estava aberto, **nada atrás dele podia ser clicado**.

Esses três pontos foram conferidos num navegador enquanto esta aula era escrita, e são o que um usuário
de teclado ou de leitor de tela precisa de um diálogo. Cada um é código que um diálogo feito à mão com
`<div>`s teria de carregar, e testar, por conta própria.
