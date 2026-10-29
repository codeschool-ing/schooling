---
title: Observando uma store inteira com $subscribe
version: 1
---

**O `store.$subscribe(callback)` chama o callback depois de cada mudança no estado da store, com uma
descrição da mudança e o estado depois dela.** É um watcher sobre a store inteira, com uma coisa que um
watcher não dá: o *tipo* de mudança.

```html
<!-- src/demos/Subscribe.vue -->
<script setup>
import { useSessionsStore } from './sessionsStore.js'

const store = useSessionsStore()

store.$subscribe((mutation, state) => {
  console.log(`${mutation.type}: ${state.sessions.length} sessions, ${store.done} minutes done`)
})
</script>

<template>
  <button id="toggle" @click="store.toggle('s4')">Toggle s4</button>
  <button id="patch" @click="store.$patch({ sessions: [] })">Empty it</button>
  <button id="direct" @click="store.sessions = [{ id: 's9', minutes: 20, done: true }]">Replace directly</button>
</template>
```

Uma action, um patch e uma atribuição direta:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Subscribe' --do 'click #toggle' --do 'click #patch' --do 'click #direct' --text -
[vite] connecting...
[vite] connected.
-- click #toggle
direct: 2 sessions, 105 minutes done
-- click #patch
patch object: 0 sessions, 0 minutes done
-- click #direct
direct: 1 sessions, 20 minutes done
```

O `mutation.type` diz como o estado mudou: **`patch object`** para `$patch` com um objeto (`patch
function` com uma função), e **`direct`** para todo o resto, o que inclui o toggle. Uma action não é um
tipo de mudança: dentro dela, `this.sessions = …` é uma atribuição direta como a do terceiro botão. Para ver
as próprias actions, com os nomes e os argumentos, uma store tem o `$onAction`.

## $subscribe ou watch

| | `store.$subscribe(fn)` | `watch(() => store.sessions, fn)` |
|---|---|---|
| dispara em | qualquer mudança em qualquer parte do estado da store | mudanças no que o getter lê |
| sabe o tipo de mudança | sim | não |
| um `$patch` de cinco campos | uma chamada | uma chamada também, porque o Vue agrupa os watchers, se o getter leu algum deles |
| pertence a | o componente que se inscreveu, a não ser com `{ detached: true }` | o componente que o criou |

Dois usos combinam bem com o `$subscribe`: salvar uma store inteira em algum lugar, e registrar cada
mudança enquanto você depura. **A store do planner salva só `sessions`, com um `watch` dentro da store**:
é o único pedaço que vale guardar, e um watch dentro da store roda enquanto a store existir, seja qual for o
componente na tela, sem nada para inscrever de fora. Um `$subscribe` chamado num componente para quando
esse componente é removido, a não ser que esteja desanexado, o que é um jeito silencioso de perder o
salvamento no dia em que uma página é redesenhada.
