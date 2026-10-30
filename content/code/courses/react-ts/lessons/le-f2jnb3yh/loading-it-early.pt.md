---
title: Carregando antes de precisar
version: 1
---

**Esperar o clique é o momento mais tarde para buscar o código; não precisa ser o mais cedo.** Quando
o planejador já está na tela, a rede fica parada enquanto o estudante lê a semana, e esse é um tempo em
que o arquivo da tela do curso poderia estar viajando. Buscá-lo então é **preload**.

A função que importa o módulo ganha um nome, para que o `lazy` e um efeito possam chamá-la:

```tsx
import { lazy, Suspense, useEffect, useState } from 'react'
import { CourseList } from './CourseList'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

const loadCourseScreen = () => import('./CourseScreen')
const CourseScreen = lazy(() =>
  loadCourseScreen().then((module) => ({ default: module.CourseScreen })),
)

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  // Once the planner is on the screen, fetch the course screen's code in the
  // background, so that opening a course does not wait for it.
  useEffect(() => {
    if (status === 'ready') void loadCourseScreen()
  }, [status])

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <LoadFailed />

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <Suspense fallback={<p>Loading the course…</p>}>
          <CourseScreen course={open} onBack={() => setOpenId(null)} />
        </Suspense>
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

- O `loadCourseScreen` é o mesmo import dinâmico de antes. **Chamá-lo duas vezes busca o arquivo uma
  vez**: o navegador guarda cada módulo que carregou, e um segundo `import()` dele resolve na hora.
- O efeito roda quando `status` vira `ready`, depois de a primeira tela ser desenhada, então o preload
  nunca disputa com o que o estudante veio ver.
- O `void` diz que a promise não é esperada de propósito: nada aqui precisa do resultado, e o `lazy`
  vai obter o módulo quando o componente renderizar.

```
ana@dev:~/planner$ npm run lint && npm run build | grep -E "assets|built"

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 71ms on 20 files with 116 rules using 4 threads.
dist/assets/index-C0qAAZg_.css          0.43 kB │ gzip:  0.25 kB
dist/assets/CourseScreen-BpXtaa6Z.js  111.03 kB │ gzip: 34.52 kB
dist/assets/index-Ckv6Cg16.js         261.57 kB │ gzip: 81.56 kB
✓ built in 634ms
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --network | grep -E 'assets|api'
net  GET /assets/index-C0qAAZg_.css  200
net  GET /assets/index-Ckv6Cg16.js  200
net  GET /api/planner  200
net  GET /assets/CourseScreen-BpXtaa6Z.js  200
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --do 'wait 5000' --do 'click button Statistics' | grep -E 'heading|alert|error'
  - heading "Statistics" [level=1]
  - heading "Add a session" [level=2]
```

O nome do arquivo principal mudou com o código; o da tela do curso também, porque ele importa do arquivo
principal. Depois, duas páginas. A primeira mostra a ordem: os dados do planejador e então, sem clique,
o `CourseScreen-BpXtaa6Z.js`. A segunda repete o deploy da seção anterior, o servidor parado três
segundos depois, e **o curso abre mesmo assim**, com título e formulário, porque o código dele tinha
chegado muito antes de o servidor sair.

Esse segundo resultado é um efeito colateral, não o motivo do preload: uma página deixada aberta durante
um deploy por mais tempo do que o preload levou já teria o código, e uma aberta depois ainda precisa que
os arquivos antigos sejam mantidos. O motivo é o primeiro resultado, um clique que não espera.

O preload também gasta algo: **todo visitante agora baixa a tela do curso**, 34,5 kB comprimidos,
inclusive os que nunca abrem um curso. A divisão ainda os ajuda, porque a primeira tela não espera mais
por ela, mas os bytes são gastos. Para uma tela que a maioria dos usuários abre, o preload depois da
primeira renderização é uma boa troca; para uma parte a que pouca gente chega, como uma página de
administração, mantenha sob demanda. Um meio-termo é começar o import quando o ponteiro passa sobre o
botão ou o botão recebe foco, algumas centenas de milissegundos antes de um provável clique.
