---
title: Código assíncrono, e um relógio que o teste acerta
version: 1
---

**Uma página que espera, por dados, por um timer, pela próxima renderização, é testada fazendo o
teste esperar exatamente por isso, e nunca dormindo.** A página da semana espera pelas três coisas:
os dados da store, o próximo tick depois deles, e o timer de um minuto do `useToday` da aula 10, que
muda o *hoje* à meia-noite. O teste dela:

```typescript
// src/views/HomeView.test.ts: the week page, on a clock the test sets.
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import HomeView from './HomeView.vue'
import { usePlannerStore } from '../stores/planner.js'
import courses from '../../public/courses.json'

describe('the week page', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
    // Wednesday 21 October 2026, ten in the morning, for every date the page asks for.
    vi.useFakeTimers({ now: new Date(2026, 9, 21, 10, 0) })
    vi.stubGlobal('fetch', async () => new Response(JSON.stringify(courses)))
  })
  afterEach(() => {
    vi.useRealTimers()
    vi.unstubAllGlobals()
  })

  async function page() {
    await usePlannerStore().load()
    // Links need a router and the dialog a body to go to; neither is what this test is about.
    const week = mount(HomeView, { global: { stubs: { RouterLink: true, Teleport: true } } })
    await flushPromises()
    return week
  }

  it('shows the week of the day it is opened, with its totals', async () => {
    const week = await page()
    expect(week.get('section:nth-of-type(2) h2').text()).toBe('Week of 19 October 2026')
    expect(week.text()).toContain('75 of 195 minutes done')
  })

  it('moves today to the next day when midnight passes', async () => {
    const week = await page()
    expect(week.get('li.today').text()).toContain('21 October 2026')
    vi.setSystemTime(new Date(2026, 9, 22, 0, 0, 30))
    await vi.advanceTimersByTimeAsync(60_000)
    expect(week.get('li.today').text()).toContain('22 October 2026')
  })
})
```

Três ferramentas, uma para cada tipo de espera:

- **`flushPromises()`** espera até que toda promise já iniciada tenha se resolvido, o `load` da store
  e o que veio depois dele, e então deixa o Vue redesenhar. É o *espere o trabalho assíncrono
  terminar* genérico, quando não há uma única promise para dar `await`.
- **`vi.useFakeTimers({ now })`** troca o relógio: o `new Date()` diz o que o teste diz, e o
  `setInterval` e o `setTimeout` não rodam até o teste deixar o tempo passar. As duas datas da página
  da semana, a segunda-feira e o hoje, vêm desse relógio.
- **`vi.advanceTimersByTimeAsync(60_000)`** deixa um minuto passar de uma vez, rodando os timers que
  vencem nele e as promises que eles iniciam. O segundo teste primeiro move o relógio para depois da
  meia-noite, depois deixa o minuto passar, e o *hoje* da página muda junto.

O `stubs` troca dois componentes por substitutos vazios: o `RouterLink`, que precisa de um router que
este teste não usa, e o `Teleport`, para que o diálogo da aula 15 seja desenhado onde está escrito,
em vez de ser mandado para um `<body>` que o wrapper não olha.

```
ana@dev:~/vue/planner$ npx vitest run src/views/HomeView.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/views/HomeView.test.ts (2 tests) 114ms

 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  22:07:19
   Duration  1.12s (environment 57%, transform 19%, import 13%, tests 11%)
```

**A meia-noite, testada em cerca de um décimo de segundo.** Sem timers falsos, o segundo teste ou
esperaria um minuto de verdade, ou entraria no `useToday` para chamar o callback dele, o que testa uma
função e não a página. Com eles, o teste se lê como o que confere: às 00:00:30 do dia 22, um minuto
depois, a linha destacada é a do dia 22.

## A regra por baixo

Cada uma dessas esperas diz pelo que está esperando. Um teste que chama `setTimeout(…, 500)` e torce
para a página estar pronta até lá passa num computador rápido e falha numa máquina de CI ocupada uma
vez em vinte, e um teste que falha às vezes é pior que nenhum, porque as pessoas aprendem a rodá-lo de
novo até passar. Se um teste precisa esperar e não há ferramenta que diga pelo quê, o código testado é
o que deve mudar: ele deve devolver a sua promise, como o `load` da store faz.
