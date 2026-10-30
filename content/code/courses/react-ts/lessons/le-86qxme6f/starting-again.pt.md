---
title: Recomeçando
version: 1
---

**Um boundary que falhou continua falho até ser desmontado.** O estado dele diz `failed: true`, e nada
nele muda esse estado de volta. Para ver o que isso significa, vá a uma semana em que o planejador não
tem nada por fazer, a semana anterior:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Previous week' --quiet | grep -c 'ErrorBoundary:'
3
```

O `--quiet` imprimiu só o console, e o `grep -c` contou os boundaries que relataram: três. Aquela
semana não tem sessões de estatística nem de espanhol, e de química só uma já feita, então o `find`
volta vazio em todos os cartões e todos mostram a reserva. Até aqui, correto. Agora volte para esta
semana, onde os cartões funcionavam um momento atrás:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Previous week' --do 'click button Next week' | grep -E 'heading|paragraph'
  - heading "Study planner" [level=1]
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
      - heading "Statistics" [level=2]
      - paragraph: This course could not be shown.
      - heading "Spanish" [level=2]
      - paragraph: This course could not be shown.
      - heading "Organic chemistry" [level=2]
      - paragraph: This course could not be shown.
```

O resumo voltou para a semana de 19 de outubro e diz 80 de 195, mas **os três cartões continuam dizendo
que não puderam ser mostrados**, embora nada esteja errado com os dados desta semana. A aula 3 explica:
um componente mantém o estado enquanto fica na mesma posição com a mesma key. Os boundaries têm key
pelo id do curso, os ids não mudaram, e assim cada boundary manteve o `failed: true` de uma semana
atrás.

A saída é a mesma regra usada de propósito. **Uma key nova é um componente novo, com estado novo**, e a
lista deve recomeçar sempre que a semana muda. No `src/App.tsx`, a única mudança é a `key` no
`CourseList`:

```tsx
import { useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen course={open} onBack={() => setOpenId(null)} />
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
```

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Previous week' --do 'click button Next week' | grep -E 'heading|paragraph'
  - heading "Study planner" [level=1]
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
      - heading "Statistics" [level=2]:
      - paragraph: 2 sessions · 90 min
      - paragraph: "Next: Wed 21 Oct"
      - heading "Spanish" [level=2]:
      - paragraph: 2 sessions · 60 min
      - paragraph: "Next: Fri 23 Oct"
      - heading "Organic chemistry" [level=2]:
      - paragraph: 1 session · 45 min
      - paragraph: "Next: Thu 22 Oct"
```

Os mesmos dois cliques, e os cartões desta semana estão de volta. Cada semana agora ganha uma lista só
dela, construída do zero, e um boundary que falhou em outra semana vai embora com a lista daquela
semana.

```schooling-figure
{"svg": "<svg data-fig=\"reset\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas linhas, cada uma indo da semana de 12 de outubro para a de 19 de outubro. Linha de cima, boundaries com key pelo id do curso: na semana de 12 o boundary falha, e na semana de 19 é o mesmo boundary, ainda falho. Linha de baixo, a lista com key pela semana: a semana de 12 tem a sua lista, que falha; a semana de 19 ganha uma lista nova com boundaries novos, e os cartões aparecem.\"><text x=\"20\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">key={course.id}</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"57.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">semana de 12 Oct</text><text x=\"120.0\" y=\"72.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failed: true</text><line x1=\"222\" y1=\"65\" x2=\"298\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,65.0 290.5,68.2 290.5,61.8\" fill=\"var(--wire)\"></polygon><text x=\"260\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Next week</text><rect x=\"300\" y=\"40\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"410.0\" y=\"57.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">semana de 19 Oct</text><text x=\"410.0\" y=\"72.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failed: true</text><text x=\"410\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o mesmo boundary</text><text x=\"540\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">ainda a reserva</text><text x=\"20\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">key={monday}</text><rect x=\"20\" y=\"135\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"152.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">semana de 12 Oct</text><text x=\"120.0\" y=\"167.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failed: true</text><line x1=\"222\" y1=\"160\" x2=\"298\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"298.0,160.0 290.5,163.2 290.5,156.8\" fill=\"var(--wire)\"></polygon><text x=\"260\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Next week</text><rect x=\"300\" y=\"135\" width=\"220\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"410.0\" y=\"152.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">semana de 19 Oct</text><text x=\"410.0\" y=\"167.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">failed: false</text><text x=\"410\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um boundary novo</text><text x=\"540\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">os cartões aparecem</text></svg>", "caption": "Um boundary guarda a falha enquanto a key fica; uma key nova o recomeça.", "same": ["failed: true", "failed: false"]}
```

Escolher a key é escolher **o que conta como uma nova tentativa**. A semana é a escolha certa aqui
porque é o que muda os dados de que um cartão é desenhado. Muitos projetos usam o pacote
`react-error-boundary` em vez de escrever a classe, e a prop `resetKeys` dele é a mesma ideia: uma lista
de valores que, quando qualquer um muda, faz o boundary voltar a renderizar os filhos.

Um botão "Tentar de novo" dentro da reserva do cartão seria o outro jeito de recomeçar, e aqui seria um
botão que não tem como funcionar: tentar de novo renderiza o mesmo cartão com os mesmos dados, e ele
falha do mesmo jeito. Uma nova tentativa só vale a pena quando algo pode ter mudado no meio, como um
servidor que estava fora do ar. A última seção desta aula tem uma.
