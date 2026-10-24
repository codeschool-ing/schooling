---
title: Interagindo, do jeito que um aluno faz
version: 1
---

**Um formulário é testado preenchendo-o e enviando-o, e depois lendo o que um aluno leria.** O
`SessionForm`, da aula 14, confere três campos, diz o que está errado só depois da primeira
tentativa, e, quando dá certo, adiciona a sessão à store e anuncia isso. Os testes dele:

```typescript
// src/components/SessionForm.test.ts: the form, filled in the way a student fills it.
import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import SessionForm from './SessionForm.vue'
import { usePlannerStore } from '../stores/planner.js'

describe('SessionForm', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    usePlannerStore().courses = [{ id: 'guitar', title: 'Guitar', goal: 90 }]
  })

  it('says nothing is wrong before the first try', () => {
    const form = mount(SessionForm, { props: { date: '' } })
    expect(form.findAll('.error')).toHaveLength(0)
  })

  it('names every field that is wrong once the student tries', async () => {
    const form = mount(SessionForm, { props: { date: '' } })
    await form.get('form').trigger('submit')
    expect(form.findAll('.error').map((e) => e.text())).toEqual(['Choose a course.', 'Choose a date.'])
    expect(usePlannerStore().sessions).toEqual([])
  })

  it('adds a valid session to the store and says what it added', async () => {
    const form = mount(SessionForm, { props: { date: '2026-10-24' } })
    await form.get('select').setValue('guitar')
    await form.get('input[type=number]').setValue('25')
    await form.get('form').trigger('submit')
    expect(usePlannerStore().sessions).toEqual([
      { id: 's1', course: 'guitar', date: '2026-10-24', minutes: 25, done: false },
    ])
    expect(form.emitted('added')).toEqual([['Added 25 minutes of Guitar on 24 October 2026.']])
  })
})
```

O `setValue` preenche um campo e dispara os eventos que o `v-model` escuta, então o `'25'` digitado
no campo numérico chega ao formulário como o número `25`, pelo `v-model.number` da aula 14. O
`trigger('submit')` envia o formulário. Cada um deles devolve uma promise, e o `await` na frente
importa: o Vue redesenha depois de uma mudança no próximo tick, a fila de atualizações da aula 2, e a
promise se resolve quando isso acontece. Sem o `await`, a linha seguinte leria a página de antes da
mudança.

```
ana@dev:~/vue/planner$ npx vitest run src/components/SessionForm.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/components/SessionForm.test.ts (3 tests) 86ms

 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  22:07:16
   Duration  1.05s (environment 60%, transform 18%, import 12%, tests 9%)
```

**O segundo teste confere a store além da tela**: um formulário inválido não só precisa mostrar seus
erros, como não pode ter adicionado nada. O terceiro confere o que o aluno ouve, a mesma frase que a
linha de status da aula 14 anunciava, e, pelo `emitted`, o que a página em volta do formulário ouve.

## Encontrando um elemento

Os testes encontram os elementos pelo que eles são, `select`, `input[type=number]`, `form`, e pela
classe de um erro. A aula 14 deu a cada campo um `<label>` ligado a ele, então um teste também
poderia achar um campo pelo seu label, que é como quem usa um leitor de tela o acha; o Vue Test Utils
não faz isso sozinho, e a biblioteca companheira *Testing Library* (`@testing-library/vue`) é
construída exatamente em torno dessa ideia. Para um formulário pequeno assim, os seletores são claros
o bastante, e só quebram quando o markup quebra.
