---
title: Funções puras primeiro
version: 1
---

**Os testes mais baratos num projeto Vue não são sobre o Vue.** A aula 3 pôs as regras do planner em
`planner.ts` como funções simples, valores entrando e valores saindo, nada sobre a página ou o
relógio, e disse que a aula 21 as testaria. Cada teste abaixo dá uma entrada a uma função e afirma a
resposta:

```typescript
// src/planner.test.ts: the planner's rules, checked one function at a time.
import { describe, it, expect } from 'vitest'
import { weekStart, addDays, weekTotal, addSession, toggleDone, type Session } from './planner.js'

const sessions: Session[] = [
  { id: 's1', course: 'statistics', date: '2026-10-19', minutes: 45, done: true },
  { id: 's2', course: 'spanish', date: '2026-10-21', minutes: 30, done: false },
  { id: 's3', course: 'spanish', date: '2026-10-26', minutes: 40, done: false },
]

describe('weekStart', () => {
  it('gives the Monday of the week a date falls in', () => {
    expect(weekStart(new Date(2026, 9, 21))).toBe('2026-10-19')
  })
  it('puts a Sunday in the week that began six days before', () => {
    expect(weekStart(new Date(2026, 9, 25))).toBe('2026-10-19')
  })
})

describe('addDays', () => {
  it('crosses the end of a month', () => {
    expect(addDays('2026-10-30', 3)).toBe('2026-11-02')
  })
})

describe('weekTotal', () => {
  it('adds the minutes planned and done in that week and no other', () => {
    expect(weekTotal(sessions, '2026-10-19')).toEqual({ planned: 75, done: 45 })
  })
})

describe('addSession', () => {
  it('gives the new session the next id, not yet done', () => {
    const after = addSession(sessions, { course: 'guitar', date: '2026-10-22', minutes: 20 })
    expect(after.at(-1)).toEqual({ id: 's4', course: 'guitar', date: '2026-10-22', minutes: 20, done: false })
  })
  it('leaves the list it was given as it was', () => {
    const before = structuredClone(sessions)
    addSession(sessions, { course: 'guitar', date: '2026-10-22', minutes: 20 })
    expect(sessions).toEqual(before)
  })
})

describe('toggleDone', () => {
  it('flips one session and no other', () => {
    const after = toggleDone(sessions, 's2')
    expect(after.map((s) => s.done)).toEqual([true, true, false])
  })
})
```

O `describe` agrupa testes sob um nome, o `it` é um teste, e o `expect(value)` seguido de um
*matcher* afirma o que o valor tem de ser: `toBe` para um valor comparado com `===`, `toEqual` para um
objeto ou uma lista comparados campo a campo. O `new Date(2026, 9, 21)` é 21 de outubro, porque o
JavaScript conta os meses a partir de zero; um comentário ao lado de uma data assim, como o do teste
da página da semana mais adiante, poupa a conta ao próximo leitor.

```
ana@dev:~/vue/planner$ npx vitest run src/planner.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/planner.test.ts (7 tests) 6ms

 Test Files  1 passed (1)
      Tests  7 passed (7)
   Start at  22:07:11
   Duration  718ms (environment 88%, transform 8%, import 2%, tests 1%, worker 1%)
```

## Um teste que justifica o seu lugar

Um teste vale o que ele pega. Suponha que alguém arrume o `weekStart`, achando
`(date.getDay() + 6) % 7` obscuro, e escreva o que parece ser a mesma coisa:

```
ana@dev:~/vue/planner$ sed -i 's/(date.getDay() + 6) % 7/date.getDay() - 1/' src/planner.ts
ana@dev:~/vue/planner$ npx vitest run src/planner.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ❯ src/planner.test.ts (7 tests | 1 failed) 11ms
   ❯ weekStart (2)
     ✓ gives the Monday of the week a date falls in 2ms
     × puts a Sunday in the week that began six days before 6ms
   ✓ addDays (1)
     ✓ crosses the end of a month 0ms
   ✓ weekTotal (1)
     ✓ adds the minutes planned and done in that week and no other 0ms
   ✓ addSession (2)
     ✓ gives the new session the next id, not yet done 0ms
     ✓ leaves the list it was given as it was 0ms
   ✓ toggleDone (1)
     ✓ flips one session and no other 0ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/planner.test.ts > weekStart > puts a Sunday in the week that began six days before
AssertionError: expected '2026-10-26' to be '2026-10-19' // Object.is equality

Expected: "2026-10-19"
Received: "2026-10-26"

 ❯ src/planner.test.ts:16:46
     14|   })
     15|   it('puts a Sunday in the week that began six days before', () => {
     16|     expect(weekStart(new Date(2026, 9, 25))).toBe('2026-10-19')
       |                                              ^
     17|   })
     18| })

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed (1)
      Tests  1 failed | 6 passed (7)
   Start at  22:07:12
   Duration  789ms (environment 91%, transform 5%, import 2%, tests 2%, worker 1%)
```

**O teste do domingo falha, e diz como**: o `getDay()` é 0 num domingo, então a versão arrumada
volta `-1` dias, ou seja, avança para a segunda seguinte, e põe toda sessão de domingo na semana
seguinte. Todos os dias úteis continuam funcionando, então o planner pareceria certo cinco dias em
sete, e o teste que diz o contrário é o que o segundo `it` de `weekStart` registrou, o caso em que
alguém pensou uma vez. Ponha a linha de volta:

```
ana@dev:~/vue/planner$ sed -i 's/date.getDay() - 1/(date.getDay() + 6) % 7/' src/planner.ts
```

Escrever o teste para a borda, o domingo, o fim do mês, a lista deixada como estava, é a maior parte
do ofício. O caso comum está lá para mostrar que a função funciona, para começo de conversa.
