---
title: Montando um componente
version: 1
---

**O `mount(Component, { props })` cria um componente no jsdom, como o app criaria, e devolve um
*wrapper*: um objeto para ler o que ele desenhou e agir sobre ele.** O primeiro componente a testar é
o `SessionRow`, uma linha da semana, porque é pequeno e o planner o desenha em todo lugar:

```typescript
// src/components/SessionRow.test.ts: one row of the week, mounted on its own.
import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import SessionRow from './SessionRow.vue'
import { usePlannerStore } from '../stores/planner.js'

const session = { id: 's4', course: 'statistics', date: '2026-10-21', minutes: 60, done: false }

describe('SessionRow', () => {
  // A store of its own for every test, so no test sees another's data.
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('shows the course id until the courses have loaded', () => {
    const row = mount(SessionRow, { props: { session } })
    expect(row.text()).toBe('21 October 2026, statistics, 60 minutes')
  })

  it('shows the course title once the store has it', () => {
    usePlannerStore().courses = [{ id: 'statistics', title: 'Statistics', goal: 180 }]
    const row = mount(SessionRow, { props: { session } })
    expect(row.text()).toBe('21 October 2026, Statistics, 60 minutes')
  })

  it('marks a done session and today', () => {
    const row = mount(SessionRow, { props: { session: { ...session, done: true }, today: true } })
    expect(row.classes()).toEqual(['done', 'today'])
    expect(row.get('strong').text()).toBe('(today)')
  })

  it('asks its parent to toggle it when the box is ticked', async () => {
    const row = mount(SessionRow, { props: { session } })
    await row.get('input').setValue(true)
    expect(row.emitted('toggle')).toEqual([['s4']])
  })
})
```

O `SessionRow` lê os títulos dos cursos da store, então um teste precisa de uma Pinia, e o
`setActivePinia(createPinia())` antes de cada teste dá a ele uma nova, vazia; sem uma nova, o título
do segundo teste ainda estaria na store do terceiro. Os métodos do wrapper fazem o resto: `text()` é o
que um leitor vê, `classes()` as classes do elemento, `get(selector)` o primeiro elemento que casa, e
uma falha se não houver nenhum.

```
ana@dev:~/vue/planner$ npx vitest run src/components/SessionRow.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/components/SessionRow.test.ts (4 tests) 59ms

 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  22:07:14
   Duration  1.14s (environment 52%, transform 30%, import 12%, tests 6%)
```

## O que os testes dizem, e o que deixam de fora

**Cada teste nomeia o que a linha faz pelo seu leitor**, em palavras que um leitor usaria: o id do
curso até os títulos chegarem, o título depois, uma sessão riscada e a marca de hoje. Nenhum deles
menciona um ref, um computed, ou como a linha decide; todos continuariam passando se o componente
fosse escrito de novo de outro jeito e desenhasse a mesma coisa, e é esse o ponto. Um teste que
entrasse no componente, `row.vm.title`, quebraria a cada refatoração e não pegaria nada que um aluno
pudesse ver.

O último teste é a outra metade da linha, o que ela diz ao componente pai. O `setValue(true)` marca a
caixa e dispara o evento `change`, como um clique faria, e o `emitted('toggle')` lista cada `toggle`
que a linha emitiu, cada um como a lista dos seus argumentos: um, levando `s4`. A linha não alterna
nada sozinha; a aula 6 fez disso trabalho do pai, e o teste a obriga a isso.
