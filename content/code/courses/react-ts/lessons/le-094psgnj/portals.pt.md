---
title: Portais, para o que precisa morar em outro lugar
version: 1
---

**O `createPortal` renderiza filhos num nó do DOM à sua escolha**, fora do elemento em que o componente
deles normalmente desenharia, enquanto eles continuam onde estão na árvore do React. O planejador tem
uso para um: depois que o diálogo fecha, nada na tela diz que a sessão foi salva. Uma mensagem curta
deveria dizer, num canto da janela, e ser anunciada a um leitor de tela.

O `src/StatusMessage.tsx` é o componente inteiro:

```tsx
import { createPortal } from 'react-dom'

export function StatusMessage({ message }: { message: string }) {
  return createPortal(
    <div role="status" className="status-message">
      {message}
    </div>,
    document.body,
  )
}
```

e algumas linhas de estilo no fim do `src/index.css` o põem no canto:

```css

.status-message:not(:empty) {
  position: fixed;
  bottom: 1rem;
  left: 1rem;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  background: Canvas;
  border: 1px solid #8888;
}
```

A tela do curso guarda a mensagem no estado, muda-a quando o formulário informa uma sessão e
**renderiza o `StatusMessage` sempre**, com uma mensagem vazia até haver algo a dizer:

```tsx
import { useEffect, useRef, useState } from 'react'
import { AddSessionForm } from './AddSessionForm'
import { Dialog } from './Dialog'
import { usePlannerContext } from './plannerContext'
import { StatusMessage } from './StatusMessage'
import type { Course } from './types'
import { formatDay } from './week'

type CourseScreenProps = {
  course: Course
  onBack: () => void
}

export function CourseScreen({ course, onBack }: CourseScreenProps) {
  const { sessions, toggleDone } = usePlannerContext()
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
Finished in 79ms on 23 files with 116 rules using 4 threads.
no errors
```

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --html 'body > [role=status]' | sed -n '/^-- click button Add/,$p'
-- click button Add session
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
    - listitem:
      - checkbox "Sat 24 Oct · 45 min"
      - text: Sat 24 Oct · 45 min
  - button "Plan a session"
- status: Planned Sat 24 Oct · 45 min.
<div role="status" class="status-message">Planned Sat 24 Oct · 45 min.</div>
```

O retrato tem um `status` depois do `main`, não dentro dele, e o HTML impresso em seguida é o próprio
elemento: `body > [role=status]` combinou, então ele é filho do `<body>`. Onde ele mora, com a página
recém-aberta e nada planejado ainda:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --html 'body' | grep -o '<div role="status"[^>]*>'
<div role="status" class="status-message">
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --html '#root' | grep -c 'role="status"'
0
```

Encontrado sob o `<body>`, e nem uma vez sob `#root`, embora o `CourseScreen`, que o renderiza, esteja
dentro de `#root`.

```schooling-figure
{"svg": "<svg data-fig=\"portal\" viewBox=\"0 0 720 245\" role=\"img\" aria-label=\"Duas árvores lado a lado. Na árvore do React, StatusMessage é filho de CourseScreen, dentro do App, então lê os mesmos contextos e os eventos dele sobem até CourseScreen. Na árvore do DOM, o body tem a div raiz, que tem a página, e a div de status é outro filho do body, ao lado da raiz.\"><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">a árvore do React</text><rect x=\"90\" y=\"36\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">App</text><rect x=\"90\" y=\"96\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CourseScreen</text><rect x=\"90\" y=\"156\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">StatusMessage</text><line x1=\"170\" y1=\"66\" x2=\"170\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"170\" y1=\"126\" x2=\"170\" y2=\"156\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"170\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">contextos, eventos: pelos pais no React</text><text x=\"540\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">o DOM</text><rect x=\"460\" y=\"36\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;body&gt;</text><rect x=\"380\" y=\"96\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;div id=root&gt;</text><rect x=\"380\" y=\"156\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;main&gt; …</text><rect x=\"560\" y=\"96\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"111.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&lt;div role=status&gt;</text><line x1=\"540\" y1=\"66\" x2=\"455\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"540\" y1=\"66\" x2=\"635\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><line x1=\"455\" y1=\"126\" x2=\"455\" y2=\"156\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><path d=\"M 252 171 C 420 230 650 215 635 128\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><polygon points=\"635.0,128.0 638.9,135.1 632.6,135.8\" fill=\"var(--amber)\"></polygon><text x=\"560\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">position: fixed a partir do &lt;body&gt;, seja qual for o CSS acima</text></svg>", "caption": "Um portal muda o elemento de lugar no DOM e o deixa no lugar no React."}
```

**Por que um portal, aqui.** A mensagem é posicionada com `position: fixed`, em relação à janela. Isso
funciona de qualquer lugar, até algum ancestral ganhar uma propriedade `transform`, `filter` ou
`contain`: aí o `fixed` passa a ser em relação a esse ancestral, e a mensagem anda com ele, ou é
cortada nas bordas dele. Nada acima da tela do curso tem uma hoje; uma animação de cartão no ano que vem
pode ter. Um filho do `<body>` não tem esses ancestrais, e **o portal deixa a mensagem independente do
que o resto do CSS da página vier a ser**.

**Por que a região é sempre renderizada.** Um leitor de tela anuncia mudanças numa região
`role="status"` que já conhece; uma região que aparece já com o texto dentro pode nem ser anunciada.
Então a `div` vazia está lá desde o início, e só o texto muda. O `:not(:empty)` do CSS a mantém
invisível enquanto não há nada nela.

**O que um portal não muda** é a árvore do React. O `StatusMessage` continua filho do `CourseScreen`:
lê os mesmos contextos, e **um evento dentro de um portal sobe até os pais no React**, não até os do
DOM. Um handler de clique num elemento em volta de `<StatusMessage />` ouviria um clique na mensagem,
embora no DOM os dois estejam longe um do outro.

**Quando um portal não é preciso.** O diálogo desta aula não tem, porque o `showModal()` põe o diálogo
na **camada superior** do navegador, acima de todo contexto de empilhamento, seja qual for o CSS dos
ancestrais. O atributo `popover` faz o mesmo para menus e tooltips. Os portais continuam sendo a
ferramenta para o que nenhum dos dois cobre: mensagens como esta, e bibliotecas escritas antes de a
camada superior existir.
