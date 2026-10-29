---
title: A sintaxe de opções, e $patch e $reset
version: 1
---

**Uma store do Pinia também pode ser escrita como um objeto com `state`, `getters` e `actions`, a versão
da store da Options API da aula 11.** Ela é comum em código existente, é o que a maioria dos exemplos de
Pinia na web mostra, e dá de graça duas coisas que uma setup store precisa escrever à mão.

```javascript
// src/demos/sessionsStore.js: one store, written in the options syntax.
import { defineStore } from 'pinia'

export const useSessionsStore = defineStore('sessions', {
  state: () => ({
    sessions: [
      { id: 's2', minutes: 45, done: true },
      { id: 's4', minutes: 60, done: false },
    ],
  }),
  getters: {
    planned: (state) => state.sessions.reduce((sum, s) => sum + s.minutes, 0),
    done: (state) => state.sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
  },
  actions: {
    toggle(id) {
      this.sessions = this.sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s))
    },
  },
})
```

- **`state` é uma função que retorna o estado inicial**, como o `data()` de um componente, pelo mesmo
  motivo: o contêiner de cada aplicação recebe estado novo.
- **Os `getters` recebem o estado** como argumento, e são valores computados.
- **As `actions` usam `this`** para a store, então são escritas como métodos, nunca como arrow functions: a
  armadilha da aula 11 vale aqui sem mudança.

Um componente a usa exatamente como usaria uma setup store:

```html
<!-- src/demos/OptionsStore.vue -->
<script setup>
import { useSessionsStore } from './sessionsStore.js'

const store = useSessionsStore()
</script>

<template>
  <p id="totals">{{ store.done }} of {{ store.planned }} minutes done</p>
  <button id="toggle" @click="store.toggle('s4')">Toggle s4</button>
  <button id="patch" @click="store.$patch({ sessions: [] })">Empty it</button>
  <button id="reset" @click="store.$reset()">Reset</button>
</template>
```

Alterne a sessão que não está feita:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=OptionsStore' --do 'click #toggle' --text '#totals'
[vite] connecting...
[vite] connected.
-- click #toggle
== the text of #totals
105 of 105 minutes done
```

Depois esvazie a store, e reinicie-a:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=OptionsStore' --do 'click #patch' --do 'click #reset' --text '#totals'
[vite] connecting...
[vite] connected.
-- click #patch
-- click #reset
== the text of #totals
45 of 105 minutes done
```

## As duas coisas que a sintaxe de opções dá

**O `$patch` altera vários pedaços do estado de uma vez**, registrados como uma mudança só. Recebendo um
objeto, ele o mescla; recebendo uma função, ele a chama com o estado a alterar. Toda store tem, setup
stores inclusive.

**O `$reset()` devolve o estado ao que o `state()` retornou na primeira vez**, e é por isso que a segunda
execução mostra 45 de 105 depois de a store ter sido esvaziada. O Pinia consegue fazer isso porque `state`
é uma função que ele pode chamar de novo. **Uma setup store não tem essa função**, então o `$reset()` numa
setup store lança um erro em desenvolvimento, dizendo que a store "does not implement $reset()", e não
faz nada num build de produção. Uma setup store que precisa de reset escreve a própria action que põe cada
ref de volta.

## Qual escrever

As duas têm suporte completo e as duas aparecem em código real. **Este curso escreve setup stores**, pelo
mesmo motivo por que escreve `<script setup>`: um só jeito de pensar para componentes, composables e
stores, e a liberdade de usar qualquer composable dentro de uma store. Leia a sintaxe de opções
traduzindo-a, como a aula 11 fez com os componentes: `state` são refs, `getters` são valores computados,
`actions` são funções, e `this` é a store.
