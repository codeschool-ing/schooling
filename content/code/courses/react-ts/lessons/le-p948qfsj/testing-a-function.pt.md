---
title: O teste mais simples, uma função
version: 1
---

**O código mais barato de testar é o que não tem React.** O `src/week.ts` é a aritmética de datas da aula
3: funções puras, uma string entra e uma string sai. Os testes dele, `src/week.test.ts`:

```ts
import { describe, expect, it } from 'vitest'
import type { Session } from './types'
import { addDays, inWeek, minutes, mondayOf } from './week'

describe('week', () => {
  it('finds the Monday of any day of the week', () => {
    expect(mondayOf('2026-10-19')).toBe('2026-10-19')
    expect(mondayOf('2026-10-21')).toBe('2026-10-19')
    expect(mondayOf('2026-10-25')).toBe('2026-10-19')
  })

  it('moves across the end of a month', () => {
    expect(addDays('2026-10-26', 7)).toBe('2026-11-02')
  })

  it('counts Sunday in the week and the next Monday out of it', () => {
    expect(inWeek('2026-10-25', '2026-10-19')).toBe(true)
    expect(inWeek('2026-10-26', '2026-10-19')).toBe(false)
  })

  it('adds up the minutes of some sessions', () => {
    const sessions = [{ minutes: 50 }, { minutes: 40 }] as Session[]
    expect(minutes(sessions)).toBe(90)
    expect(minutes([])).toBe(0)
  })
})
```

- **`describe`** agrupa testes sob um nome; **`it`** é um teste, com o nome do que ele confere, numa frase
  que se lê como um fato sobre o código.
- **`expect(value).toBe(expected)`** compara com `Object.is`, a mesma comparação do estado da aula 4 e do
  `memo` da aula 21.
- **Os casos são as bordas**: a própria segunda-feira, o domingo na outra ponta da semana, uma semana que
  entra em novembro. É aí que código de data erra, e a aula 3 escolheu o meio-dia UTC justamente para
  mantê-los certos.
- O `as Session[]` deixa o último teste passar objetos só com `minutes`, o único campo que `minutes()` lê.

O Vitest acha todo arquivo terminado em `.test.ts` ou `.test.tsx`:

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/week.test.ts (4 tests) 5ms

 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  23:15:57
   Duration  1.29s (environment 58%, transform 27%, setup 14%, import 1%)
```

Quatro testes num arquivo, todos passando. A linha `Duration` diz para onde foi o tempo; a maior parte é
iniciar o ambiente, não rodar os testes.
