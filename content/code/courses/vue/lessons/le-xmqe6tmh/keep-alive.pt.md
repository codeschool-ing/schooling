---
title: KeepAlive, e mais dois hooks
version: 1
---

**O `<KeepAlive>` mantém um componente vivo quando ele sai de cena, em vez de destruí-lo, e traz de
volta a mesma instância quando ele entra de novo.** O estado sobrevive, texto digitado pela metade
incluído, e dois hooks próprios avisam o componente quando ele é guardado e quando volta.

Um campo de notas por curso, atrás de duas abas:

```html
<!-- src/demos/Draft.vue -->
<script setup>
import { ref, onMounted, onActivated, onDeactivated, onUnmounted } from 'vue'

const { name } = defineProps({ name: String })
const note = ref('')
onMounted(() => console.log(`${name}: mounted`))
onActivated(() => console.log(`${name}: activated`))
onDeactivated(() => console.log(`${name}: deactivated`))
onUnmounted(() => console.log(`${name}: unmounted`))
</script>

<template>
  <label>Notes for {{ name }} <input v-model="note" /></label>
  <p>{{ note.length }} characters</p>
</template>
```

```html
<!-- src/demos/KeptAlive.vue -->
<script setup>
import { ref } from 'vue'
import Draft from './Draft.vue'

const tab = ref('statistics')
</script>

<template>
  <button id="stats" @click="tab = 'statistics'">Statistics</button>
  <button id="spanish" @click="tab = 'spanish'">Spanish</button>
  <KeepAlive>
    <Draft :key="tab" :name="tab" />
  </KeepAlive>
</template>
```

Digite uma nota para statistics, troque para Spanish e volte:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=KeptAlive' --do 'fill input verbs' --do 'click #spanish' --do 'click #stats'
[vite] connecting...
[vite] connected.
statistics: mounted
statistics: activated
-- fill input verbs
-- click #spanish
statistics: deactivated
spanish: mounted
spanish: activated
-- click #stats
spanish: deactivated
statistics: activated
== the text of #app
StatisticsSpanishNotes for statistics 

5 characters
```

**A nota de statistics voltou com os seus 5 caracteres**, e o log diz por quê: trocar de aba
*desativou* o componente de statistics em vez de desmontá-lo, e voltar *ativou* o mesmo componente. O
de Spanish foi montado uma vez, na primeira vez em que apareceu, e desativado na sua vez. Sem o
`<KeepAlive>`, a mudança de `:key` teria destruído cada componente na saída, e a nota estaria vazia na
volta.

(O texto do campo em si não aparece na transcrição, porque o `look` imprime o texto da página e o valor
de um campo não é texto. A contagem abaixo dele é.)

## Os dois hooks

- **`onActivated`** roda quando um componente guardado é mostrado, inclusive na primeira vez, logo
  depois do `onMounted`.
- **`onDeactivated`** roda quando ele é guardado.

São onde um componente guardado pausa e retoma o que estava fazendo: parar um timer ao ser desativado,
já que ninguém está olhando, e iniciá-lo de novo ao ser ativado; atualizar dados que podem ter ficado
velhos enquanto a aba estava escondida. O `onUnmounted` não vai rodar para um componente guardado até o
próprio `<KeepAlive>` sair, ou tirá-lo do cache por causa do `include`, do `exclude` ou do `max` logo abaixo.

## Quando manter as coisas vivas

O `<KeepAlive>` troca memória por estado. Cada componente guardado fica na memória com tudo o que
segura, então ele serve para um número pequeno de telas entre as quais o aluno vai e volta com
frequência, como as abas de um formulário, e aceita `include`, `exclude` e `max` para dizer quais
componentes e quantos. Para estado que precisa sobreviver de qualquer jeito, ficar na memória é uma
garantia fraca: um recarregamento o perde. O planner guarda as sessões no `localStorage` (aula 4) e, a
partir da aula 13, numa store, onde trocar de tela não encosta nelas. A aula 12 usa o `<KeepAlive>` em
volta das telas do router, que é onde ele é mais usado.
