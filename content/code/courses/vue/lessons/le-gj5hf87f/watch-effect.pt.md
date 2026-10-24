---
title: watchEffect, que encontra as próprias fontes
version: 1
---

**O `watchEffect` roda uma função na hora, registra cada valor reativo que ela leu e a roda de novo
sempre que um deles muda.** Não há argumento de fonte: a função é a fonte. É o mesmo rastreamento que
uma renderização e um `computed` usam, aplicado a um efeito colateral.

```html
<!-- src/demos/EffectTracking.vue -->
<script setup>
import { ref, watchEffect } from 'vue'

const course = ref('statistics')
const minutes = ref(45)
const note = ref('')

// No list of sources: whatever the function reads is a source.
watchEffect(() => {
  console.log(`effect: ${course.value}, ${minutes.value} minutes`)
})

// Only what is read before the first await is tracked.
watchEffect(async () => {
  const c = course.value
  await Promise.resolve()
  console.log(`async effect: ${c}, note "${note.value}"`)
})
</script>

<template>
  <button id="course" @click="course = 'spanish'">Spanish</button>
  <button id="minutes" @click="minutes += 15">15 more</button>
  <button id="note" @click="note = 'verbs'">Add a note</button>
</template>
```

Clique em `15 more`, depois em `Add a note`, depois em `Spanish`:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=EffectTracking' --do 'click #minutes' --do 'click #note' --do 'click #course' --text -
[vite] connecting...
[vite] connected.
effect: statistics, 45 minutes
async effect: statistics, note ""
-- click #minutes
effect: statistics, 60 minutes
-- click #note
-- click #course
effect: spanish, 60 minutes
async effect: spanish, note "verbs"
```

Os dois efeitos rodaram quando a página abriu; um `watchEffect` é sempre imediato, porque rodá-lo é
como ele descobre o que observar. Depois:

- **`15 more`** rodou de novo o primeiro efeito, que tinha lido `minutes`, e não o segundo, que não
  tinha.
- **`Add a note` não rodou nada de novo.** O efeito assíncrono lê `note`, sim, mas só depois do
  `await`, e a essa altura o Vue já tinha parado de registrar. O rastreamento acontece enquanto a função
  roda de forma síncrona; quando ela pausa num `await`, o resto dela roda depois, fora da janela, e as
  leituras dele não contam nada.
- **`Spanish`** rodou os dois de novo, porque os dois leem `course` antes de qualquer outra coisa. O
  assíncrono imprimiu `note "verbs"`, o valor que por acaso encontrou, embora uma mudança só na nota
  nunca pudesse tê-lo acordado.

Esse segundo item é a armadilha do `watchEffect`, e ela é silenciosa: o código lê o valor, o valor está
certo quando é impresso, e mesmo assim o efeito não o acompanha. **Num efeito assíncrono, leia cada
fonte de que você depende antes do primeiro `await`**, em constantes locais, como a demo faz com
`course`. Ou use `watch` e nomeie as fontes explicitamente.

## watch ou watchEffect

| | `watch` | `watchEffect` |
|---|---|---|
| fontes | nomeadas por você | o que a função leu na última execução |
| primeira execução | na primeira mudança, a não ser com `immediate` | na hora |
| dá o valor antigo | sim | não |
| quando é mais claro | o gatilho e o trabalho são coisas diferentes: "quando o curso mudar, busque as notas dele" | o trabalho *é* a leitura: "mantenha o título da página igual ao curso e aos minutos" |

Na dúvida, `watch`. Nomear as fontes custa uma linha e declara a intenção, e uma fonte nomeada
explicitamente não se perde atrás de um `await`.
