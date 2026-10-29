---
title: Um computed em que você pode escrever
version: 1
---

**Um computed é só de leitura a menos que você lhe dê um setter, e aí escrever nele escreve nos
valores de que ele é feito.** O setter não é uma segunda cópia do estado. É uma tradução: quem lê pede
horas, o estado é guardado em minutos, e o setter transforma uma hora em minutos e guarda esses
minutos.

```html
<!-- src/demos/WritableHours.vue -->
<script setup>
import { ref, computed } from 'vue'

const minutes = ref(90)

const hours = computed({
  get: () => minutes.value / 60,
  set: (value) => {
    minutes.value = Math.round(value * 60)
  },
})

const readOnly = computed(() => minutes.value / 60)

function setTwoHours() {
  hours.value = 2
}
function tryReadOnly() {
  readOnly.value = 3
}
</script>

<template>
  <p>{{ minutes }} minutes = {{ hours }} hours</p>
  <button id="two" @click="setTwoHours">Make it two hours</button>
  <button id="three" @click="tryReadOnly">Make it three, the wrong way</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=WritableHours' --do 'click #two' --do 'click #three'
[vite] connecting...
[vite] connected.
-- click #two
-- click #three
[warn] [Vue warn] Write operation failed: computed value is readonly
== the text of #app
120 minutes = 2 hours

Make it two hoursMake it three, the wrong way
```

O `computed({ get, set })` recebe as duas funções como um objeto. **Fazer `hours.value = 2` rodou o
setter**, que guardou 120 em `minutes`; o getter então calculou 2 a partir dos 120, e a página mostra
os dois. O segundo botão tentou escrever num computed sem setter, e **o Vue recusou com um aviso e não
mudou nada**. O aviso só aparece em desenvolvimento: um build de produção o remove, e a escrita é
ignorada em silêncio, o que é mais um motivo para ler o console enquanto você trabalha.

## Onde ele vale a pena

Um computed gravável é a ferramenta para **um valor mostrado em duas formas**:

- minutos guardados, horas editadas, como acima;
- uma lista de tags guardada como array, editada num campo de texto como `"grammar, verbs"`;
- uma data guardada como `YYYY-MM-DD`, editada em três campos separados.

Em cada caso uma forma é a verdade e a outra é uma visão dela, e o setter é o único lugar em que a
visão é transformada de volta na verdade. A aula 14 o encontra de novo, ligado a um campo de
formulário com `v-model`, que é onde ele é mais usado.

## E onde não vale

Um setter que escreve em algo *diferente* do que o getter leu é um computed fingindo ser estado. Se o
`set` guarda o valor em algum lugar e o `get` o devolve de lá, você escreveu um ref com passos a mais.
**O teste é que, depois de qualquer `set`, um `get` precisa devolver o valor que acabou de ser
escrito**, ou o mais próximo que a verdade consegue guardar. `hours.value = 1.5` guarda 90 e lê de
volta 1.5; `hours.value = 0.01` guarda 1 minuto e lê de volta 0.016666…, que é o mais próximo que os
minutos conseguem guardar, e é honesto quanto a isso.
