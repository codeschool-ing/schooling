---
title: A store, e uma rede que o teste controla
version: 1
---

**Um teste não pode depender de um servidor estar no ar, então, onde o código chama `fetch`, o teste
põe um `fetch` seu, que responde o que o teste escolher.** A store do planner da aula 13 carrega os
dados com `fetch(import.meta.env.VITE_DATA_URL)`, mantém uma só requisição não importa quantos
chamem, relata uma falha em `error` e salva as sessões no `localStorage`. As quatro coisas merecem um
teste:

```typescript
// src/stores/planner.test.ts: the store, with the network replaced by an answer the test chooses.
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import { usePlannerStore } from './planner.js'

const data = {
  courses: [{ id: 'spanish', title: 'Spanish', goal: 120 }],
  sessions: [{ id: 's1', course: 'spanish', date: '2026-10-19', minutes: 30, done: false }],
}

// What fetch will answer, for the test that calls this.
function answer(body: unknown, status = 200, statusText = 'OK') {
  const fetch = vi.fn(async () => new Response(JSON.stringify(body), { status, statusText }))
  vi.stubGlobal('fetch', fetch)
  return fetch
}

describe('the planner store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
  })
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('loads the courses and sessions from the data address', async () => {
    const fetch = answer(data)
    const planner = usePlannerStore()
    await planner.load()
    expect(fetch).toHaveBeenCalledWith('/courses.json')
    expect(planner.titles).toEqual({ spanish: 'Spanish' })
    expect(planner.source).toBe('courses.json')
  })

  it('asks once, however many times it is asked to load', async () => {
    const fetch = answer(data)
    const planner = usePlannerStore()
    await Promise.all([planner.load(), planner.load(), planner.load()])
    expect(fetch).toHaveBeenCalledTimes(1)
  })

  it('says what went wrong when the server fails', async () => {
    answer({}, 503, 'Service Unavailable')
    const planner = usePlannerStore()
    await planner.load()
    expect(planner.error).toBe('Could not load the courses: 503 Service Unavailable')
  })

  it('keeps a tick in this browser', async () => {
    answer(data)
    const planner = usePlannerStore()
    await planner.load()
    const saved = () => JSON.parse(localStorage.getItem('planner.sessions') ?? '[]')
    planner.toggle('s1')
    // The watcher that saves runs before the next render, not on the spot.
    expect(saved()[0].done).toBe(false)
    await nextTick()
    expect(saved()[0].done).toBe(true)
  })
})
```

O `vi.fn` cria uma função que registra como foi chamada, e o `vi.stubGlobal('fetch', …)` a põe onde a
store vai procurar o `fetch`; o `vi.unstubAllGlobals()` depois de cada teste devolve o de verdade. O
falso responde com um `Response` de verdade, a classe que o próprio `fetch` devolve, então a store o
lê com `response.ok` e `response.json()` exatamente como lê o de um servidor. O
`import.meta.env.VITE_DATA_URL` é `/courses.json` num teste também, porque o Vitest lê o `.env` como
o Vite.

```
ana@dev:~/vue/planner$ npx vitest run src/stores/planner.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/stores/planner.test.ts (4 tests) 14ms

 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  22:07:18
   Duration  787ms (environment 82%, import 11%, transform 5%, tests 2%, worker 1%)
```

## Dois deles são sobre tempo

**O segundo teste é o `loading ??=` da aula 13 cobrado pela sua promessa**: três chamadas, uma
requisição. Uma mudança que perdesse a linha ainda passaria no primeiro teste e falharia neste, que é
o que o primeiro teste jamais poderia dizer.

**O último é sobre quando, não sobre o quê.** A store salva com um `watch`, e a aula 4 mostrou que um
watcher roda antes da próxima renderização, e não na hora. Então, logo depois do `toggle`, a cópia
salva no `localStorage` ainda é a gravada no load, com a sessão não feita, e depois do `nextTick()`
ela é a nova. Um teste que lesse o `localStorage` sem esperar falharia, e um que esperasse sem
conferir o momento anterior não perceberia se o salvamento um dia virasse síncrono. Escrever as duas
linhas faz do tempo parte do que é testado.

O próprio `localStorage` é o do jsdom, vazio a cada teste porque o `beforeEach` o limpa, assim como a
store é nova a cada teste porque o `setActivePinia(createPinia())` cria uma nova. A Pinia também
publica o `@pinia/testing`, cujo `createTestingPinia` troca cada action por uma que só registra, para
o teste de um componente que deve conferir apenas que ele *chamou* a store. Os testes do planner usam
a store de verdade, que é pequena e rápida o bastante para ser a escolha mais barata.
