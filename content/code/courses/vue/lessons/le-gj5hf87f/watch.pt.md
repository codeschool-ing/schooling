---
title: watch, e o que ele pode observar
version: 1
---

**Um watcher roda uma função sua quando um valor reativo muda, e ele existe para efeitos colaterais:
trabalho que sai do estado do próprio componente.** Salvar no armazenamento, buscar dados, chamar uma
biblioteca que não é Vue, mover o foco. A aula 3 traçou a linha: um valor que decorre de outros
valores é um `computed`; uma ação que decorre de uma mudança é um watcher.

`watch(source, callback)` recebe a coisa a observar e a função a chamar. O callback recebe o valor
novo e o antigo. O que conta como fonte é mais estreito do que "qualquer coisa", e os três formatos que
ele aceita cobrem quase todos os casos:

```html
<!-- src/demos/WatchSources.vue -->
<script setup>
import { ref, watch } from 'vue'

const minutes = ref(30)
const course = ref('spanish')

// A ref: the callback gets the new value and the old one.
watch(minutes, (now, before) => console.log(`minutes: ${before} -> ${now}`))

// A getter: anything computed from reactive values.
watch(
  () => minutes.value >= 60,
  (long) => console.log(`at least an hour: ${long}`),
)

// An array of sources: fires when any of them changes.
watch([course, minutes], ([c, m]) => console.log(`now ${c} for ${m} minutes`))

function longer() {
  minutes.value += 15
}
</script>

<template>
  <p>{{ course }}, {{ minutes }} minutes</p>
  <button id="longer" @click="longer">15 more</button>
  <button id="guitar" @click="course = 'guitar'">Guitar</button>
</template>
```

Inicie o sandbox num segundo terminal e clique em `15 more` duas vezes, depois em `Guitar`:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=WatchSources' --do 'click #longer' --do 'click #longer' --do 'click #guitar' --text -
[vite] connecting...
[vite] connected.
-- click #longer
minutes: 30 -> 45
now spanish for 45 minutes
-- click #longer
minutes: 45 -> 60
at least an hour: true
now spanish for 60 minutes
-- click #guitar
now guitar for 60 minutes
```

`--text -` diz ao `look` para não imprimir texto nenhum no fim, porque aqui só o console importa.

## Os três formatos

- **Um ref.** `watch(minutes, …)` dispara quando `minutes.value` é substituído, e entrega `now` e
  `before`: 30 → 45, depois 45 → 60. Passe o próprio ref, nunca `minutes.value`: isso é o número 30,
  e um número não pode ser observado. O Vue avisa se você tentar.
- **Um getter**, uma função que devolve um valor calculado a partir de estado reativo. O Vue a roda,
  registra o que ela leu e chama o seu callback **só quando o resultado dela muda**. É por isso que `at
  least an hour` apareceu uma vez, em 60, e não em 45: o getter tinha devolvido `false` as duas vezes
  antes.
- **Um array de fontes**, para "quando qualquer uma destas mudar". O callback recebe um array de
  valores novos na mesma ordem. `Guitar` mudou só `course`, e o terceiro watcher disparou com os dois
  valores.

O getter é o que você usa quando a coisa que importa é uma propriedade: `watch(() =>
props.courseId, …)` na aula 6, ou `watch(() => route.params.id, …)` na aula 12. Escrever
`watch(route.params.id, …)` passa uma string, que é o mesmo erro de `minutes.value`.

## O que o callback não deve fazer

O callback roda depois da mudança, fora de qualquer renderização. Ele pode atribuir a refs, e isso é
permitido; mas se tudo o que ele faz é atribuir um valor calculado a partir da fonte, você reconstruiu a
demo do total sincronizado da aula 3, com os dois defeitos dela. **Pergunte o que o callback faz que a
tela não consegue ver.** Se a resposta for nada, é um computed.
