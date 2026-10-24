---
title: computed, um valor calculado a partir de outros
version: 1
---

**Uma propriedade computed é um valor definido por uma função de outros valores reativos, e o Vue o
mantém correto para você.** Você escreve como calculá-lo; o Vue roda a função quando o valor é
necessário pela primeira vez, guarda o resultado e só roda de novo depois que um dos valores que ela
leu mudou. Você nunca atribui a ele e nunca precisa lembrá-lo de se atualizar.

A aula 2 terminou com uma lista de jeitos de guardar uma cópia desatualizada, e a última linha era um
total calculado uma vez no script. Esta é a correção:

```html
<!-- src/demos/ComputedTotal.vue -->
<script setup>
import { ref, computed } from 'vue'

const sessions = ref([
  { course: 'statistics', minutes: 45 },
  { course: 'spanish', minutes: 30 },
])

const total = computed(() => {
  console.log('computing total')
  return sessions.value.reduce((sum, s) => sum + s.minutes, 0)
})

function totalByHand() {
  console.log('totalByHand called')
  return sessions.value.reduce((sum, s) => sum + s.minutes, 0)
}

function addGuitar() {
  sessions.value.push({ course: 'guitar', minutes: 20 })
}
</script>

<template>
  <p>Planned: {{ total }} minutes</p>
  <p>That is {{ total / 60 }} hours, {{ total % 60 }} minutes over the hour.</p>
  <p>By hand: {{ totalByHand() }}, {{ totalByHand() }}, {{ totalByHand() }}</p>
  <button @click="addGuitar">Add guitar</button>
</template>
```

Inicie o servidor de desenvolvimento do sandbox num segundo terminal, como na aula 2, e clique no
botão uma vez:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ComputedTotal' --do 'click button'
[vite] connecting...
[vite] connected.
computing total
totalByHand called
totalByHand called
totalByHand called
-- click button
computing total
totalByHand called
totalByHand called
totalByHand called
== the text of #app
Planned: 95 minutes

That is 1.5833333333333333 hours, 35 minutes over the hour.

By hand: 95, 95, 95

Add guitar
```

O `computed()` devolveu um ref, e como todo ref de nível superior ele é desembrulhado no template:
`{{ total }}`, e não `{{ total.value }}`. No script ele é `total.value`, só de leitura. Quando o botão
acrescentou uma terceira sessão, o total foi de 75 para 95 sem uma linha de código dizendo isso,
porque a função tinha lido `sessions.value` e o push o mudou.

## Para que serve um computed

Para tudo o que a tela mostra que é **derivado** e não **próprio**. O planner é dono da lista de
sessões: elas vieram de um arquivo e o aluno as edita. Ele não é dono do total da semana, que é um
fato sobre as sessões. Guardar o total como uma segunda peça de estado significa dois lugares que
podem discordar, e o resto desta aula é sobre o que dá errado quando discordam.

| próprio: um `ref` | derivado: um `computed` |
|---|---|
| as sessões | o total da semana |
| a segunda-feira mostrada | as sessões dentro daquela semana |
| o texto digitado numa caixa de busca | os cursos cujo título bate com ele |

Um hábito útil é perguntar de cada `ref` novo: **dá para calcular isto a partir do que eu já tenho?**
Se der, é um `computed`.

## Um computed no template, ou uma função

A demo também tem `totalByHand()`, uma função comum que soma os mesmos números, chamada três vezes no
template. Os dois mostram 95. A transcrição mostra a diferença: **`computing total` foi impresso uma
vez por mudança, e `totalByHand called` três vezes por renderização**, porque uma função no template
é chamada toda vez que o template roda, e o template roda a cada mudança em qualquer coisa que ele lê.
Para somar dois números isso não custou nada. Para filtrar e ordenar alguns milhares de sessões a
cada tecla digitada, é a diferença entre uma página que acompanha e uma que não acompanha. A próxima
seção é sobre esse cache.
