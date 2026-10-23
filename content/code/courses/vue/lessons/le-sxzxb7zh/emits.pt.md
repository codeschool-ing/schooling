---
title: Emits, o que um componente responde
version: 1
---

**Um filho avisa o pai de que algo aconteceu emitindo um evento, e o pai decide o que fazer com isso.** É
a outra metade do fluxo num sentido só: os dados descem como props, e as notícias sobem como eventos. O
filho não muda o estado do pai; ele relata, com o detalhe de que o pai vai precisar, e o listener do pai
muda o próprio estado.

```html
<!-- src/demos/DoneButton.vue -->
<script setup>
const props = defineProps({ id: String, minutes: Number })
const emit = defineEmits({
  // An event with a check: Vue warns when it returns false.
  done: (id, minutes) => typeof id === 'string' && minutes > 0,
  // An event with no check.
  undo: null,
})
</script>

<template>
  <button class="done" @click="emit('done', id, minutes)">Done ({{ minutes }} minutes)</button>
  <button class="undo" @click="emit('undo', id)">Undo</button>
</template>
```

```html
<!-- src/demos/Emits.vue -->
<script setup>
import { ref } from 'vue'
import DoneButton from './DoneButton.vue'

const log = ref([])
function onDone(id, minutes) {
  log.value.push(`${id} done, ${minutes} minutes`)
}
</script>

<template>
  <DoneButton id="s4" :minutes="60" @done="onDone" @undo="(id) => log.push(`${id} undone`)" />
  <DoneButton id="s9" :minutes="0" @done="onDone" />
  <ul>
    <li v-for="(line, i) in log" :key="i">{{ line }}</li>
  </ul>
</template>
```

Clique no primeiro `Done`, no `Undo` dele e depois no segundo `Done`, cuja sessão tem 0 minutos:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Emits' --do 'click .done' --do 'click .undo' --do 'click :nth-match(.done, 2)'
[vite] connecting...
[vite] connected.
-- click .done
-- click .undo
-- click :nth-match(.done, 2)
[warn] [Vue warn]: Invalid event arguments: event validation failed for event "done".
== the text of #app
Done (60 minutes)UndoDone (0 minutes)Undo
s4 done, 60 minutes
s4 undone
s9 done, 0 minutes
```

`defineEmits` é uma macro do compilador como `defineProps`, e devolve a função `emit`. `emit('done', id,
minutes)` chama o listener do pai com `id` e `minutes` como argumentos. No pai, `@done="onDone"` os
passa para `onDone`, e `@undo="(id) => log.push(…)"` mostra a forma inline. (O `log.push` no template
funciona porque o template desembrulha `log`; no script seria `log.value.push`.)

**A checagem de `done` falhou para 0 minutos, e o Vue avisou e entregou o evento assim mesmo**, como fez
com as props. Um validator está ali para pegar os seus próprios erros em desenvolvimento; não é um
filtro, e um build de produção o pula.

## Declarando os eventos

Como as props, os emits têm uma forma de lista, `defineEmits(['done', 'undo'])`, e uma forma de objeto
com checagens. Declare todo evento, mesmo na forma de lista, por dois motivos que não são de estilo:

- **Isso documenta o componente.** Quem lê vê tudo o que o componente pode dizer num lugar só, em vez de
  sair caçando chamadas a `emit(`.
- **Isso muda onde um listener se prende.** Um evento que *não* está declarado é tratado como atributo
  fallthrough (próxima seção): `@click` num componente que não declara `click` prende um listener de
  clique nativo no elemento raiz do componente. Declarado, ele é só o evento do próprio componente. Um
  componente que emite `click` por conta própria, sem declará-lo, pode disparar o handler do pai duas
  vezes para um clique.

## Nomes

Emita em camelCase, `emit('weekChanged')`, e escute em kebab-case ou camelCase, `@week-changed` ou
`@weekChanged`; o Vue faz a correspondência. **Dê ao evento o nome do que aconteceu, não do que o pai
deveria fazer**: `toggle`, `done`, `remove-requested`, em vez de `update-total` ou `save-to-storage`.
O filho sabe o que o aluno fez; só o pai sabe o que isso significa.
