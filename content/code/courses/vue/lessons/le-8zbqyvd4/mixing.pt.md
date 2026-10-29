---
title: As duas APIs num componente
version: 1
---

**Um componente Options API pode ter uma opção `setup()`, que roda primeiro e cujos valores devolvidos
entram no `this`.** É assim que uma base de código passa de uma API para a outra aos poucos: um
componente antigo começa a usar um composable novo sem ser reescrito, e o resto das opções dele continua
funcionando.

```html
<!-- src/demos/Mixing.vue -->
<script>
import { useWeek } from './useWeek.js'

export default {
  setup() {
    // A composable, used from an Options API component.
    const { monday, next } = useWeek('2026-10-19')
    return { monday, next }
  },
  data() {
    return { moves: 0 }
  },
  methods: {
    forward() {
      this.next()
      this.moves++
    },
  },
}
</script>

<template>
  <p>Week of {{ monday }}, after {{ moves }} moves</p>
  <button @click="forward">Next week</button>
</template>
```

O `useWeek` da aula 10 já está no sandbox. Dois cliques:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Mixing' --do 'click button' --do 'click button'
[vite] connecting...
[vite] connected.
-- click button
-- click button
== the text of #app
Week of 2026-11-02, after 2 moves

Next week
```

**O método `forward` chamou `this.next()`, que o composable devolveu pelo `setup()`, e contou os próprios
`moves` em `data`.** A semana andou duas semanas, até 2 de novembro, e a contagem diz 2. As duas APIs se
encontram no `this`: o que o `setup()` devolve está nele, desempacotado, ao lado de todo o resto.

`setup()` é a forma longa em que o `<script setup>` é compilado. Dentro dele não há `this`: ele roda
antes de as opções da instância serem montadas, e recebe `props` como primeiro argumento no lugar. O que
ele devolve é o que o template e as outras opções podem usar.

## Passando um componente para o outro lado

Um componente não é reescrito de uma vez, ele é mudado de lugar:

1. Deixe-o funcionando. Acrescente `setup()` e use composables novos a partir dele, como acima.
2. Leve um assunto de cada vez para o `setup()`: o estado dele que está em `data`, os valores derivados
   em `computed`, o watcher, os hooks, tudo junto, porque essas partes andam juntas.
3. Quando não sobrar nada fora do `setup()`, troque `<script>` por `<script setup>`, tire o `return` e
   substitua `export default` por `defineProps` e `defineEmits`.

Não há nada a ganhar com o passo 3 num componente que ninguém precisa mudar. **O planner fica como está
nesta aula**, escrito na Composition API desde o começo: a habilidade que esta aula deixa com você é ler
a outra, e traduzir entre as duas quando um trabalho pedir.
