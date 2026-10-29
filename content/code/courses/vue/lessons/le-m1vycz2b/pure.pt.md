---
title: Um computed não muda nada
version: 1
---

**A função de um computed só pode ler e devolver.** Ela não pode mudar estado reativo, iniciar uma
requisição, escrever no armazenamento nem mexer na página, porque não é você que decide quando ela
roda: é o Vue, de forma preguiçosa, sempre que alguém a lê depois de uma mudança, e talvez nunca.
Qualquer coisa que um computed faça além de devolver um valor acontece num momento que ninguém
escolheu.

O caso perigoso é aquele que nem parece uma mudança:

```html
<!-- src/demos/SortInPlace.vue -->
<script setup>
import { ref, computed } from 'vue'

const sessions = ref([
  { date: '2026-10-23', minutes: 40 },
  { date: '2026-10-19', minutes: 45 },
  { date: '2026-10-21', minutes: 60 },
])

// Wrong: sort() rearranges the array it is called on.
const byDateWrong = computed(() => sessions.value.sort((a, b) => a.date.localeCompare(b.date)))
// Right: toSorted() returns a sorted copy and leaves the original alone.
const byDate = computed(() => sessions.value.toSorted((a, b) => a.date.localeCompare(b.date)))

const first = sessions.value[0].date
</script>

<template>
  <p id="order">The data, as it was written: {{ sessions.map((s) => s.date).join(', ') }}</p>
  <p id="sorted">Sorted: {{ byDate.map((s) => s.date).join(', ') }}</p>
  <p id="wrong">Sorted with sort(): {{ byDateWrong.map((s) => s.date).join(', ') }}</p>
  <p>The first one written was {{ first }}.</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=SortInPlace'
[vite] connecting...
[vite] connected.
== the text of #app
The data, as it was written: 2026-10-19, 2026-10-21, 2026-10-23

Sorted: 2026-10-19, 2026-10-21, 2026-10-23

Sorted with sort(): 2026-10-19, 2026-10-21, 2026-10-23

The first one written was 2026-10-23.
```

A primeira linha devia mostrar os dados na ordem em que foram escritos, 23, 19, 21. **Ela os mostra
ordenados**, e a última linha confirma que a primeira sessão escrita foi a do dia 23. O
`Array.prototype.sort` reorganiza o array em que é chamado e devolve esse mesmo array, então o
`byDateWrong` ordenou o próprio `sessions.value`, através do proxy, na primeira vez que rodou. Cada
um dos outros leitores de `sessions` recebeu a ordem ordenada dali em diante.

Nada avisou. A página parece correta, porque ordenado é o que você queria ver. O estrago está em outro
lugar: uma lista que o aluno arrumou à mão volta em outra ordem, o índice de uma sessão deixa de
apontar para a mesma sessão, e o bug aparece numa parte do planner que nunca falou de ordenação.

**O `toSorted()` devolve uma cópia ordenada** e deixa o array em paz, e o mesmo fazem `toReversed()` e
`toSpliced()`. Eles estão em todo navegador desde 2023 e no Node 20 em diante. Onde você não puder
usá-los, copie antes: `[...sessions.value].sort(…)`. Os métodos que mudam um array no lugar, `sort`,
`reverse`, `splice`, `push`, `pop`, `shift`, `unshift` e `fill`, não têm nada que fazer dentro de
um computed.

## Requisições também não

Um computed é síncrono: ele devolve um valor, e uma função `async` devolve uma promise.

```html
<!-- src/demos/AsyncComputed.vue -->
<script setup>
import { computed } from 'vue'

const status = computed(async () => {
  const response = await fetch('/courses.json')
  return response.status
})
</script>

<template>
  <p>The request answered {{ status }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=AsyncComputed'
[vite] connecting...
[vite] connected.
== the text of #app
The request answered "[object Promise]"
```

**O valor do computed é a promise**, não o que a promise vai conter, e o template o imprimiu do único
jeito que consegue imprimir um objeto: `"[object Promise]"`, com aspas e tudo. A requisição rodou, sim,
e a resposta dela não foi para lugar nenhum. Buscar dados é um efeito colateral que leva tempo, e o
lugar dele é um watcher (aula 4) ou um composable que envolve um (aula 10).

## O teste

Você consegue chamar a função dez vezes seguidas, ou nenhuma, e a página ficar igual? Se sim, ela
pertence a um computed. Se chamá-la muda alguma coisa, não pertence.
