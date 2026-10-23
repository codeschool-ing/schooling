---
title: Parando um watcher
version: 1
---

**Um watcher criado enquanto um componente está sendo montado pertence a esse componente, e para quando
o componente é removido.** Um watcher criado em qualquer outro momento não pertence a ninguém, e roda
até a página ser fechada. Essa é a regra inteira, e a segunda metade é um vazamento de memória
esperando por um componente que é mostrado e escondido cem vezes.

A demo tem um ref num módulo próprio, para que ele sobreviva a qualquer componente:

```javascript
// src/demos/clock.js: one ref shared by every component that imports it.
import { ref } from 'vue'

export const tick = ref(0)
```

Um componente que o observa de três jeitos:

```html
<!-- src/demos/Listener.vue -->
<script setup>
import { watch } from 'vue'
import { tick } from './clock.js'

// Created during setup: stopped when this component goes away.
watch(tick, (n) => console.log(`setup watcher saw tick ${n}`))

// Created later, after the component exists: belongs to nobody.
setTimeout(() => {
  watch(tick, (n) => console.log(`late watcher saw tick ${n}`))
}, 0)

// Created during setup and stopped by hand, after the first change.
const stop = watch(tick, (n) => {
  console.log(`stoppable watcher saw tick ${n}, and stops`)
  stop()
})
</script>

<template>
  <p>The listener is here.</p>
</template>
```

E um pai que pode fazer o relógio andar e remover o listener:

```html
<!-- src/demos/StopWatching.vue -->
<script setup>
import { ref } from 'vue'
import Listener from './Listener.vue'
import { tick } from './clock.js'

const shown = ref(true)
</script>

<template>
  <Listener v-if="shown" />
  <button id="tick" @click="tick++">Tick</button>
  <button id="remove" @click="shown = false">Remove the listener</button>
</template>
```

Faça o relógio andar duas vezes, remova o listener e faça andar de novo:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=StopWatching' --do 'click #tick' --do 'click #tick' --do 'click #remove' --do 'click #tick'
[vite] connecting...
[vite] connected.
-- click #tick
late watcher saw tick 1
setup watcher saw tick 1
stoppable watcher saw tick 1, and stops
-- click #tick
late watcher saw tick 2
setup watcher saw tick 2
-- click #remove
-- click #tick
late watcher saw tick 3
== the text of #app
TickRemove the listener
```

**Depois que o listener foi removido, o watcher tardio ainda viu o tick 3.** O componente sumiu da
página, e uma função dentro dele continua rodando a cada mudança, segurando tudo o que consegue
alcançar. O watcher criado durante o setup parou junto com o componente, como deveria.

## Por que "durante o setup" decide

O `<script setup>` roda de forma síncrona, e enquanto ele roda o Vue sabe qual componente está sendo
montado. Um watcher criado nessa janela é registrado com esse componente, e remover o componente o
para. O callback do `setTimeout` rodou um instante depois, quando nenhum componente estava sendo
montado, então o watcher dele foi registrado com nada. O mesmo vale para um watcher criado depois de um
`await` no setup, ou dentro de um `.then()`: **se você não o vê no nível de cima do script, suponha que
ele não vai parar sozinho.**

## Parando um na mão

`watch` e `watchEffect` devolvem os dois uma função que para o watcher. O terceiro watcher a chamou de
dentro do próprio callback, depois do primeiro tick, e nunca mais rodou. Dois casos precisam dela:

- um watcher criado tarde, como acima: guarde a função de parar e chame-a quando o componente for
  removido (o `onUnmounted` da aula 9 é o lugar);
- um watcher que já fez o seu trabalho: esperar um valor aparecer, agir uma vez, parar. `{ once: true }`
  é o jeito mais curto de dizer isso, desde o Vue 3.4.

O Vue 3.5 também deixa você fazer `pause()` e `resume()` num watcher pela mesma alça, para um watcher
que deve dormir enquanto, digamos, um painel está recolhido, sem perder o lugar.
