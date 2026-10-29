---
title: Quando um watcher é a ferramenta errada
version: 1
---

**O uso errado mais comum de um watcher é manter uma peça de estado em sincronia com outra, que é
para o que serve um computed.** Parece razoável: quando as sessões mudam, recalcule o total e guarde.
Tem dois defeitos, e esta demo mostra os dois de uma vez.

```html
<!-- src/demos/SyncedByWatch.vue -->
<script setup>
import { ref, watch } from 'vue'

const sessions = ref([
  { course: 'statistics', minutes: 45 },
  { course: 'spanish', minutes: 30 },
])

// The wrong tool: a second piece of state, kept in step by hand.
const total = ref(0)
watch(sessions, (list) => {
  total.value = list.reduce((sum, s) => sum + s.minutes, 0)
  console.log(`watcher set total to ${total.value}`)
})

function shown() {
  console.log(`render shows total = ${total.value}`)
  return total.value
}
function addGuitar() {
  sessions.value.push({ course: 'guitar', minutes: 20 })
}
function replaceAll() {
  sessions.value = [...sessions.value, { course: 'guitar', minutes: 20 }]
}
</script>

<template>
  <p>Planned: {{ shown() }} minutes</p>
  <button id="push" @click="addGuitar">Add guitar (push)</button>
  <button id="replace" @click="replaceAll">Add guitar (replace)</button>
</template>
```

Clique no primeiro botão, depois no segundo:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=SyncedByWatch' --do 'click #push' --do 'click #replace'
[vite] connecting...
[vite] connected.
render shows total = 0
-- click #push
-- click #replace
watcher set total to 115
render shows total = 115
== the text of #app
Planned: 115 minutes

Add guitar (push)Add guitar (replace)
```

**A primeira renderização disse 0.** O watcher só roda quando a origem dele muda, não quando é criado,
então até algo mudar o `total` guardou o valor inicial enquanto a página mostrava duas sessões. O
número correto não existia em lugar nenhum.

**Depois, o `push` não mudou nada.** Nenhuma linha `watcher set total` vem depois dele. Um watcher
sobre um ref dispara quando o `.value` é substituído, e o `push` acrescenta um item ao array que já
está lá. O total agora estava errado em 20 minutos, em silêncio. Só o segundo botão, que montou um
array novo e o atribuiu, acordou o watcher, e o total finalmente alcançou as duas adições de uma vez:
115.

Os dois defeitos têm correção, `{ immediate: true }` e `{ deep: true }`, que a aula 4 explica. Mas
**cada correção responde a um sintoma de ter uma segunda cópia do valor**. Com um computed não há nada
para manter em sincronia:

```javascript
const total = computed(() => sessions.value.reduce((sum, s) => sum + s.minutes, 0))
```

Ele está correto na primeira renderização, porque é calculado na primeira vez que é lido. Ele percebe
o `push`, porque o `reduce` leu cada item através do proxy. E ele nunca fica desatualizado, porque
não existe cópia guardada para ficar desatualizada.

## A regra prática

| você quer | use |
|---|---|
| um valor que decorre de outros valores | `computed` |
| **fazer** algo quando um valor muda: salvá-lo, buscar algo, chamar uma biblioteca, mover o foco | um watcher, aula 4 |

Um watcher é para efeitos colaterais, coisas que alcançam algo fora do estado do próprio componente.
Se o corpo do seu watcher só atribui a outro ref, ele era um computed desde o começo.
