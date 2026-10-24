---
title: lazy, e Suspense em volta
version: 1
---

**O `lazy` recebe uma função que importa um módulo, e devolve um componente que a chama na primeira vez
que é renderizado.** Até o módulo chegar, o componente não está pronto, e o React mostra a reserva do
`Suspense` mais próximo acima dele. A mudança inteira está no `src/App.tsx`:

```tsx
import { lazy, Suspense, useState } from 'react'
import { CourseList } from './CourseList'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

const CourseScreen = lazy(() =>
  import('./CourseScreen').then((module) => ({ default: module.CourseScreen })),
)

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

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

Três mudanças, e cada uma importa:

- **O `import { CourseScreen }` estático sumiu.** Um import estático no topo de um arquivo faz parte
  desse arquivo, e enquanto restar um em qualquer lugar, o bundler mantém o módulo no arquivo principal.
- **`import('./CourseScreen')` é a forma dinâmica**, uma chamada de função que devolve uma promise do
  módulo. Os bundlers a tratam como um lugar de corte, e põem o módulo num arquivo próprio. O `lazy`
  espera que o módulo tenha um export **default**, e o `CourseScreen.tsx` exporta um nomeado, então o
  `.then` entrega ao `lazy` um objeto cujo `default` é o export nomeado.
- **`Suspense` em volta do lugar onde ele é desenhado**, com a frase a mostrar enquanto o código
  carrega. Ele fica dentro do `<main>`, então só o conteúdo é trocado, nunca o marco da página.

```
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 48ms on 20 files with 116 rules using 4 threads.
```

Faça o build de novo:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 175 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                         0.45 kB │ gzip:  0.29 kB
dist/assets/index-C0qAAZg_.css          0.43 kB │ gzip:  0.25 kB
dist/assets/CourseScreen-rKGK0gfi.js  111.03 kB │ gzip: 34.52 kB
dist/assets/index-BDKi8Zd8.js         261.51 kB │ gzip: 81.53 kB

✓ built in 609ms
```

```schooling-figure
{"svg": "<svg data-fig=\"split\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Dois builds lado a lado. Antes: um arquivo JavaScript de 371 kB, carregado antes da primeira tela. Depois: um arquivo principal de 262 kB, carregado na hora, e um arquivo CourseScreen de 111 kB com a tela do curso, o React Hook Form e o Zod, carregado quando um curso é aberto.\"><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">antes</text><rect x=\"20\" y=\"36\" width=\"260\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">index-CkcBpHKM.js</text><text x=\"150.0\" y=\"103.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">371 kB</text><text x=\"150\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tudo antes da primeira tela</text><text x=\"520\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">depois</text><rect x=\"360\" y=\"36\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">index-BDKi8Zd8.js</text><text x=\"455.0\" y=\"103.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">262 kB</text><rect x=\"570\" y=\"36\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">CourseScreen-…js</text><text x=\"635.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">111 kB</text><text x=\"635\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a tela do curso,</text><text x=\"635\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">react-hook-form, zod</text><text x=\"455\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">na hora</text><text x=\"635\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">no primeiro clique</text></svg>", "caption": "As bibliotecas do formulário saem do primeiro download."}
```

**Dois arquivos JavaScript agora.** O `index-BDKi8Zd8.js` ficou 110 kB menor, e a diferença está no
`CourseScreen-rKGK0gfi.js`: a tela do curso, o formulário, o React Hook Form e o Zod, tudo o que só a
tela do curso alcança. O bundler deu ao arquivo novo o nome do módulo de onde ele parte.

Para ver quando cada arquivo é buscado, sirva o build. O `npm run preview` serve o `dist/` como um
servidor de produção pequeno serviria, na porta 4173, com o mesmo proxy para a API que o servidor de
desenvolvimento; deixe-o rodando num terminal próprio:

```

> planner@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

```
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --network | grep -E 'assets|api'
net  GET /assets/index-C0qAAZg_.css  200
net  GET /assets/index-BDKi8Zd8.js  200
net  GET /api/planner  200
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --network --do 'click button Statistics' | grep -E 'assets|api|^-- |heading'
net  GET /assets/index-C0qAAZg_.css  200
net  GET /assets/index-BDKi8Zd8.js  200
net  GET /api/planner  200
-- click button Statistics
net  GET /assets/CourseScreen-rKGK0gfi.js  200
  - heading "Statistics" [level=1]
  - heading "Add a session" [level=2]
```

A primeira página carrega a folha de estilo, o arquivo principal e o planejador, e **nada da tela do
curso**. A segunda clica num curso: só então o `CourseScreen-rKGK0gfi.js` chega, e a tela é desenhada
com o título e o formulário. No meio, pelo tempo que esse arquivo levou para vir, a página mostrou
*Loading the course…*. Numa conexão rápida é breve demais para ver; numa rede de celular lenta, é o que
o estudante vê no lugar de uma página congelada.
