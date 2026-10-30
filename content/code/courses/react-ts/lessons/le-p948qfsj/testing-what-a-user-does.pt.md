---
title: Testando o que uma pessoa faz
version: 1
---

**A maioria dos componentes vale ser testada pelo que acontece quando alguém os usa.** O `WeekNav` não tem
texto a conferir; todo o trabalho dele é pedir a próxima segunda-feira ou a anterior quando um botão é
apertado. O `src/WeekNav.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, it, vi } from 'vitest'
import { WeekNav } from './WeekNav'

it('asks for the next and the previous Monday', async () => {
  const user = userEvent.setup()
  const onChange = vi.fn()
  render(<WeekNav monday="2026-10-19" onChange={onChange} />)

  await user.click(screen.getByRole('button', { name: 'Next week' }))
  await user.click(screen.getByRole('button', { name: 'Previous week' }))

  expect(onChange).toHaveBeenNthCalledWith(1, '2026-10-26')
  expect(onChange).toHaveBeenNthCalledWith(2, '2026-10-12')
})
```

- **`vi.fn()`** é uma função que lembra como foi chamada. Ela faz o papel do `setMonday`, para o teste
  poder perguntar o que o `WeekNav` pediu.
- **`userEvent.setup()`** cria um usuário, e **`await user.click(…)`** aperta um botão como uma pessoa
  apertaria: ponteiro para baixo, foco, ponteiro para cima, clique, cada evento na ordem. O `await` é de
  verdade, porque os eventos são disparados um depois do outro.
- **`getByRole('button', { name: 'Next week' })`** acha o botão pelo que um leitor de tela anunciaria, o
  mesmo papel e nome que o `look` imprime. Um teste escrito assim falha quando o botão deixa de ser botão
  ou perde o nome, que são falhas que um usuário também notaria.

```schooling-figure
{"svg": "<svg data-fig=\"anatomy\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Os quatro passos de um teste de componente. Preparar: renderizar o componente no documento do jsdom, com funções falsas para o que ele chama. Agir: um usuário, do user-event, clica e digita. Achar: consultas por papel, rótulo ou texto, como uma pessoa ou um leitor de tela faria. Afirmar: esperar o que está na página, ou com que as funções falsas foram chamadas.\"><text x=\"94\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">preparar</text><rect x=\"14\" y=\"50\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"94.0\" y=\"75.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">render(…)</text><text x=\"94.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">vi.fn()</text><line x1=\"176\" y1=\"82\" x2=\"188\" y2=\"82\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,82.0 180.5,85.2 180.5,78.8\" fill=\"var(--wire)\"></polygon><text x=\"270\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">agir</text><rect x=\"190\" y=\"50\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"75.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">user.click(…)</text><text x=\"270.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">user.type(…)</text><line x1=\"352\" y1=\"82\" x2=\"364\" y2=\"82\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"364.0,82.0 356.5,85.2 356.5,78.8\" fill=\"var(--wire)\"></polygon><text x=\"446\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">achar</text><rect x=\"366\" y=\"50\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"75.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">getByRole(…)</text><text x=\"446.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">findByText(…)</text><line x1=\"528\" y1=\"82\" x2=\"540\" y2=\"82\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,82.0 532.5,85.2 532.5,78.8\" fill=\"var(--wire)\"></polygon><text x=\"622\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">afirmar</text><rect x=\"542\" y=\"50\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"75.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">toBeInTheDocument()</text><text x=\"622.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">toHaveBeenCalledWith</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no jsdom: um documento sem tela, dentro do Node.js</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">consultas por papel e nome falham quando um usuário notaria</text></svg>", "caption": "Desenhe, use, ache o que uma pessoa veria, confira."}
```

```
ana@dev:~/planner$ npm test -- WeekNav

> planner@0.0.0 test
> vitest run WeekNav


 RUN  v5.0.5 /home/ana/planner

 ✓ src/WeekNav.test.tsx (1 test) 214ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  23:16:05
   Duration  1.78s (environment 58%, transform 20%, tests 13%, setup 7%, import 2%)
```

O formulário das aulas 10 e 14 é o componente mais interessante de testar, porque lê o contexto do
planejador. **Um teste pode fornecer um contexto próprio**, com ações falsas dentro, o
`src/AddSessionForm.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { AddSessionForm } from './AddSessionForm'
import { PlannerContext, type Planner } from './plannerContext'

function renderForm() {
  const addSession = vi.fn()
  const planner: Planner = {
    status: 'ready',
    courses: [],
    sessions: [],
    toggleDone: vi.fn(),
    addSession,
  }
  render(
    <PlannerContext value={planner}>
      <AddSessionForm course="statistics" onAdded={vi.fn()} />
    </PlannerContext>,
  )
  return { addSession, user: userEvent.setup() }
}

describe('AddSessionForm', () => {
  it('says what is missing, and sends nothing', async () => {
    const { addSession, user } = renderForm()
    await user.click(screen.getByRole('button', { name: 'Add session' }))

    expect(await screen.findByText('Choose the day of the session.')).toBeInTheDocument()
    expect(screen.getByLabelText('Date')).toHaveAttribute('aria-invalid', 'true')
    expect(addSession).not.toHaveBeenCalled()
  })

  it('sends the session that was typed', async () => {
    const { addSession, user } = renderForm()
    await user.type(screen.getByLabelText('Date'), '2026-10-24')
    await user.clear(screen.getByLabelText('Minutes'))
    await user.type(screen.getByLabelText('Minutes'), '45')
    await user.click(screen.getByRole('button', { name: 'Add session' }))

    expect(addSession).toHaveBeenCalledWith(
      { course: 'statistics', date: '2026-10-24', minutes: 45 },
      expect.anything(),
    )
  })
})
```

- **`renderForm`** desenha o formulário dentro de um `PlannerContext` com um planejador pronto e um
  `addSession` falso, e devolve o que cada teste precisa. O TypeScript confere o falso contra o tipo
  `Planner` de verdade, então um falso sem algum campo não compila.
- **O primeiro teste** envia um formulário vazio e espera, com `findByText`, a mensagem do schema: o React
  Hook Form valida de forma assíncrona, e o `find…` continua procurando até o texto aparecer ou um tempo
  limite passar. O campo de data fica então marcado inválido, e **nada foi enviado**, que é o ponto.
- **O segundo** digita uma data e 45 minutos, e confere o que o `addSession` recebeu: a sessão, e um
  segundo argumento, o `onSuccess` que a aula 14 passou, que o `expect.anything()` aceita sem ligar para
  o que é.

```
ana@dev:~/planner$ npm test -- AddSessionForm

> planner@0.0.0 test
> vitest run AddSessionForm


 RUN  v5.0.5 /home/ana/planner

 ✓ src/AddSessionForm.test.tsx (2 tests) 282ms

 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  23:16:07
   Duration  1.68s (environment 38%, transform 32%, tests 18%, setup 7%, import 5%)
```

E tudo junto, com o lint e a checagem de tipos antes, como uma mudança deve ser conferida:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && npm test

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 72ms on 36 files with 116 rules using 4 threads.

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/WeekSummary.test.tsx (1 test) 66ms
 ✓ src/WeekNav.test.tsx (1 test) 259ms
 ✓ src/AddSessionForm.test.tsx (2 tests) 288ms
 ✓ src/week.test.ts (4 tests) 5ms

 Test Files  4 passed (4)
      Tests  8 passed (8)
   Start at  23:16:13
   Duration  2.29s (environment 71%, tests 12%, setup 10%, import 4%, transform 2%)

Environment  jsdom was created 4 times · 3.61s total, 71% of tracked time
             create it once per worker with pool: 'vmThreads' (keeps per-file isolation) or isolate: false (shares it across files)
             learn more: https://vitest.dev/guide/improving-performance#test-environments
```

Oito testes em quatro arquivos. A nota do fim é um conselho do próprio Vitest: cada arquivo de teste ganha
um jsdom novo, que é a maior parte do tempo gasto, e ele nomeia dois jeitos de compartilhar um. Quatro
arquivos não precisam disso.

**O que vale um teste** é o que doeria se quebrasse em silêncio: a aritmética de onde vem todo número da
tela, o que um formulário manda, o que a tela diz para um estado dado. O que não vale é o que a biblioteca
já testa, ou a marcação exata: um teste que falha quando um `<p>` vira uma `<div>` é um teste que vai ser
apagado.
