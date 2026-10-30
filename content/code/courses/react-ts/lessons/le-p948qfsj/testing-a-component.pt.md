---
title: Um componente, e os números da aula 1
version: 1
---

**A aula 1 abriu o planejador pronto e leu *80 of 195 minutes done* na tela, e prometeu um teste que
conferisse isso.** Este é o teste, `src/WeekSummary.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { expect, it } from 'vitest'
import type { Session } from './types'
import { WeekSummary } from './WeekSummary'

// The week of 19 October 2026 as public/courses.json has it.
const week: Session[] = [
  { id: 's1', course: 'statistics', date: '2026-10-19', minutes: 50, done: true },
  { id: 's2', course: 'statistics', date: '2026-10-21', minutes: 40, done: false },
  { id: 's3', course: 'spanish', date: '2026-10-20', minutes: 30, done: true },
  { id: 's4', course: 'spanish', date: '2026-10-23', minutes: 30, done: false },
  { id: 's6', course: 'chemistry', date: '2026-10-22', minutes: 45, done: false },
]

it('says how much of the week is done', () => {
  render(<WeekSummary monday="2026-10-19" sessions={week} />)
  expect(screen.getByText('Week of 19 Oct 2026')).toBeInTheDocument()
  expect(screen.getByText('80 of 195 minutes done')).toBeInTheDocument()
})
```

- **`render`** desenha o componente no documento do jsdom, como o `createRoot` o desenha num navegador.
- **`screen.getByText`** acha o elemento cujo texto é exatamente essa frase, e lança se não houver, então
  uma frase ausente falha o teste antes mesmo de o `expect` rodar.
- **Os dados estão escritos no teste**: as cinco sessões daquela semana, como o arquivo inicial as tem. Um
  teste que lesse o arquivo quebraria sempre que alguém editasse os dados iniciais, por um motivo que não
  tem nada a ver com o resumo.

`npm test -- WeekSummary` roda só os arquivos cujo nome contém `WeekSummary`:

```
ana@dev:~/planner$ npm test -- WeekSummary

> planner@0.0.0 test
> vitest run WeekSummary


 RUN  v5.0.5 /home/ana/planner

 ✓ src/WeekSummary.test.tsx (1 test) 61ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  23:15:59
   Duration  1.27s (environment 53%, transform 32%, setup 9%, tests 5%, import 1%)
```

**Um teste que passa diz pouco até você vê-lo falhar.** Mude a frase esperada para um número errado, e leia
o que o Vitest diz:

```
ana@dev:~/planner$ sed -i 's/80 of 195 minutes done/85 of 195 minutes done/' src/WeekSummary.test.tsx && npm test -- WeekSummary

> planner@0.0.0 test
> vitest run WeekSummary


 RUN  v5.0.5 /home/ana/planner

 ❯ src/WeekSummary.test.tsx (1 test | 1 failed) 55ms
   × says how much of the week is done 53ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/WeekSummary.test.tsx > says how much of the week is done
TestingLibraryElementError: Unable to find an element with the text: 85 of 195 minutes done. This could be because the text is broken up by multiple elements. In this case, you can provide a function for your text matcher to make your matcher more flexible.

Ignored nodes: comments, script, style
<body>
  <div>
    <section
      aria-label="This week"
    >
      <p>
        Week of 
        19 Oct 2026
      </p>
      <p>
        80
         of 
        195
         minutes done
      </p>
    </section>
  </div>
</body>
 ❯ Object.getElementError node_modules/@testing-library/dom/dist/config.js:37:19
 ❯ node_modules/@testing-library/dom/dist/query-helpers.js:76:38
 ❯ node_modules/@testing-library/dom/dist/query-helpers.js:52:17
 ❯ node_modules/@testing-library/dom/dist/query-helpers.js:95:19
 ❯ src/WeekSummary.test.tsx:18:17
     16|   render(<WeekSummary monday="2026-10-19" sessions={week} />)
     17|   expect(screen.getByText('Week of 19 Oct 2026')).toBeInTheDocument()
     18|   expect(screen.getByText('85 of 195 minutes done')).toBeInTheDocument…
       |                 ^
     19| })
     20|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  23:16:01
   Duration  1.16s (environment 60%, transform 23%, setup 10%, tests 5%, import 1%)

ana@dev:~/planner$ sed -i 's/85 of 195 minutes done/80 of 195 minutes done/' src/WeekSummary.test.tsx && npm test -- WeekSummary | grep Tests
      Tests  1 passed (1)
```

Leia de cima:

- **`×` e o nome do teste**, abaixo do arquivo, e `FAIL` com os dois de novo: que teste falhou.
- **`Unable to find an element with the text: 85 of 195 minutes done`**: o que deu errado, nas palavras do
  Testing Library.
- **O documento, como o teste o viu.** O segundo parágrafo está desenhado como quatro pedaços de texto,
  `80`, `of`, `195` e `minutes done`, as quatro partes da expressão JSX; o `getByText` compara com o texto
  juntado deles, e por isso a frase certa passa. Aqui diz `80`, e o teste esperava `85`.
- **A pilha**, terminando na linha 18 do teste, com a própria linha e um circunflexo sob a chamada.

O segundo comando devolveu o número certo. Uma expectativa errada e um componente errado falham do mesmo
jeito, e é por isso que a mensagem de falha mostra o que realmente estava lá: quem lê decide qual lado está
errado.
