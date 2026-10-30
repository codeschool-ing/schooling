---
title: Buscando os dados do planejador
version: 1
---

**Desde a aula 2 o planejador lê os dados do `sample.ts`, uma cópia do `public/courses.json`. Agora
ele busca o próprio arquivo**, do jeito que vai buscar de um servidor de verdade na aula 11. Isso
quer dizer que os dados não estão lá na primeira renderização, o que quer dizer uma tela para "ainda
não", e uma tela para "não deu certo". Este é o novo `src/App.tsx` inteiro, com os três efeitos desta
aula:

```tsx
import { useEffect, useState } from 'react'
import { CourseList } from './CourseList'
import { CourseScreen } from './CourseScreen'
import type { Course, Session } from './types'
import { addDays, formatWeek, inWeek, mondayOf, today } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

type Status = 'loading' | 'ready' | 'failed'

function App() {
  const [monday, setMonday] = useState(() => mondayOf(today()))
  const [courses, setCourses] = useState<Course[]>([])
  const [sessions, setSessions] = useState<Session[]>([])
  const [status, setStatus] = useState<Status>('loading')
  const [openId, setOpenId] = useState<string | null>(null)

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

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
  }, [monday])

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') setMonday((m) => addDays(m, -7))
      if (event.key === 'ArrowRight') setMonday((m) => addDays(m, 7))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  function toggleDone(id: string) {
    setSessions((all) => all.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <p role="alert">The planner could not be loaded.</p>

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <CourseScreen
          course={open}
          sessions={sessions.filter((s) => s.course === open.id)}
          onToggle={toggleDone}
          onBack={() => setOpenId(null)}
        />
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
```

O primeiro efeito é o que importa aqui. Leia de cima para baixo:

- **`useState<Course[]>([])`** e o vizinho começam vazios, e `status` começa em `'loading'`, uma união
  de três strings que diz qual de três telas desenhar. A aula 19 chama esse tipo de união
  discriminada, e a aula 11 substitui todo o arranjo por uma biblioteca.
- **`fetch('/courses.json')`** pede ao servidor de desenvolvimento o arquivo em `public/`. Uma
  resposta chega qualquer que seja o status, então o `response.ok` é conferido à mão, e qualquer
  coisa que não seja 2xx vira erro.
- **O `.then` que define o estado** roda quando o JSON foi lido, o que é depois da renderização que o
  começou; o React renderiza de novo com os dados.
- **`ignore`** é a limpeza. Se o componente sumir, ou o efeito for limpo por qualquer outro motivo,
  antes de a resposta chegar, `ignore` vira true e a resposta atrasada é descartada em vez de escrita
  num estado que ninguém deveria ver. A seção depois da próxima mostra quando isso acontece.
- **`[]`** diz que o efeito não depende de nada, então ele roda uma vez depois que o componente
  aparece.

O `sample.ts` sai, e a checagem de tipos concorda que nada mais precisava dele:

```
ana@dev:~/planner$ rm src/sample.ts
ana@dev:~/planner$ npx tsc -b && echo no errors
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --network | grep -v 'GET /[@sn]'
net  GET /  200
net  GET /courses.json  200
net  GET /courses.json  200
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]:
        - button "Statistics"
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]:
        - button "Spanish"
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]:
        - button "Organic chemistry"
      - paragraph: 1 session · 45 min
```

O `--network` lista as requisições que a página fez, e as que o Vite faz para cada módulo são
filtradas pelo `grep`, sobrando a própria página e os dados. **O `/courses.json` foi buscado duas
vezes.** É o strict mode de novo: em desenvolvimento ele roda cada efeito, o limpa e o roda de novo,
então o `ignore` da primeira requisição virou true e a resposta dela foi jogada fora. A resposta da
segunda desenhou a tela. No build que você publica, o efeito roda uma vez.

Essa requisição dupla é o motivo de a limpeza existir. Sem o `ignore`, as duas respostas definiriam o
estado, o que aqui é inofensivo porque são idênticas. Deixa de ser inofensivo no momento em que duas
requisições podem responder coisas diferentes: o usuário escolhe um curso, depois outro, e a resposta
do primeiro chega por último.
