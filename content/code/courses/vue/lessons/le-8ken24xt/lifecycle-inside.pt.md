---
title: Hooks dentro de um composable
version: 1
---

**Um composable pode chamar `onMounted` e `onUnmounted`, e eles se prendem ao componente que chamou o
composable.** É isso que permite a um composable começar algo e limpar depois, sem que o componente que
o chamou fique sabendo. É também a origem da única regra que um composable não pode quebrar: ele precisa
ser chamado enquanto um componente está sendo montado.

```javascript
// src/demos/useTicker.js: a timer that belongs to whichever component calls it.
import { ref, onMounted, onUnmounted } from 'vue'

export function useTicker(name) {
  const ticks = ref(0)
  let timer
  onMounted(() => {
    timer = setInterval(() => ticks.value++, 100)
    console.log(`${name}: started`)
  })
  onUnmounted(() => {
    clearInterval(timer)
    console.log(`${name}: stopped after ${ticks.value} ticks`)
  })
  return ticks
}
```

Um componente que o usa, e um pai com dois deles e um botão que chama o composable na hora errada:

```html
<!-- src/demos/TickerUser.vue -->
<script setup>
import { useTicker } from './useTicker.js'

const { name } = defineProps({ name: String })
const ticks = useTicker(name)
</script>

<template>
  <p>{{ name }}: {{ ticks }}</p>
</template>
```

```html
<!-- src/demos/LifecycleInside.vue -->
<script setup>
import { ref } from 'vue'
import TickerUser from './TickerUser.vue'
import { useTicker } from './useTicker.js'

const shown = ref(true)

function tooLate() {
  useTicker('called from a click')
}
</script>

<template>
  <template v-if="shown">
    <TickerUser name="first" />
    <TickerUser name="second" />
  </template>
  <button id="remove" @click="shown = false">Remove both</button>
  <button id="late" @click="tooLate">Call the composable from a click</button>
</template>
```

Deixe-os contar, remova-os, e depois aperte o segundo botão:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LifecycleInside' --do 'wait 300' --do 'click #remove' --do 'click #late' --text -
[vite] connecting...
[vite] connected.
first: started
second: started
-- wait 300
-- click #remove
first: stopped after 9 ticks
second: stopped after 9 ticks
-- click #late
[warn] [Vue warn]: onMounted is called when there is no active component instance to be associated with. Lifecycle injection APIs can only be used during execution of setup(). If you are using async setup(), make sure to register lifecycle hooks before the first await statement.
[warn] [Vue warn]: onUnmounted is called when there is no active component instance to be associated with. Lifecycle injection APIs can only be used during execution of setup(). If you are using async setup(), make sure to register lifecycle hooks before the first await statement.
```

**Cada componente ganhou o seu próprio timer, começado quando foi montado e parado quando foi
removido**, e nenhum `TickerUser` tem uma linha sobre timers. Os hooks dentro de `useTicker` foram
registrados enquanto o `TickerUser` estava sendo montado, então o Vue os prendeu àquele `TickerUser`.

**Chamado de um clique, o mesmo composable não teve a que prender os hooks**, e o Vue disse isso duas
vezes, uma por hook: `no active component instance to be associated with`. O timer que ele pretendia
começar nunca começou, porque o `onMounted` nunca rodou. O aviso é explícito sobre o motivo, e menciona
o outro jeito de chegar aqui: uma função `async setup()` escrita à mão que chama o composable depois
de um `await`. O `<script setup>` escapa dessa, porque o compilador dele devolve o componente depois de
um `await` de nível superior; a aula 15 mostra esse compilador trabalhando.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Dois casos. Em cima: o setup do TickerUser chama useTicker, que chama onMounted e onUnmounted enquanto o TickerUser é o componente sendo montado, então os dois hooks ficam presos ao TickerUser e rodam quando ele é montado e removido. Embaixo: um handler de clique chama useTicker depois que o setup acabou; nenhum componente está sendo montado, então os hooks não se prendem a nada, o Vue avisa, e o timer nunca começa.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"90\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">durante o setup: os hooks acham o seu componente</text><rect x=\"40\" y=\"46\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">TickerUser</text><rect x=\"250\" y=\"46\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">useTicker()</text><rect x=\"460\" y=\"46\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"570\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">onMounted</text><text x=\"570\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">onUnmounted</text><line x1=\"192\" y1=\"68\" x2=\"248\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,68.0 240.6,71.1 240.6,64.9\" fill=\"var(--wire)\"></polygon><line x1=\"402\" y1=\"68\" x2=\"458\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"458.0,68.0 450.6,71.1 450.6,64.9\" fill=\"var(--wire)\"></polygon><path d=\"M570,44 C560,26 140,26 120,44\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"124\" y1=\"40\" x2=\"120\" y2=\"45\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"120.0,45.0 122.2,37.3 127.0,41.2\" fill=\"var(--phosphor)\"></polygon><rect x=\"20\" y=\"130\" width=\"680\" height=\"90\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">num clique: ninguém está sendo montado</text><rect x=\"40\" y=\"160\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"115\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">@click</text><rect x=\"250\" y=\"160\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"325\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">useTicker()</text><rect x=\"460\" y=\"160\" width=\"220\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"570\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">onMounted</text><text x=\"570\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">[Vue warn]: nenhuma instância</text><line x1=\"192\" y1=\"182\" x2=\"248\" y2=\"182\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"248.0,182.0 240.6,185.1 240.6,178.9\" fill=\"var(--wire)\"></polygon><line x1=\"402\" y1=\"182\" x2=\"458\" y2=\"182\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"458.0,182.0 450.6,185.1 450.6,178.9\" fill=\"var(--wire)\"></polygon></svg>", "caption": "Os hooks de um composable pertencem ao componente que está sendo montado quando ele é chamado, e a nada se nenhum estiver."}
```

## A regra, e como cumpri-la

**Chame composables no nível de cima do `<script setup>`.** Não num handler,
não num `setTimeout`, não num `.then()`. Quando algo precisa acontecer depois, chame o composable durante
o setup e faça-o devolver uma função que faz a parte posterior, como `useWeek` devolve `next`.

O React tem uma regra que soa igual e não é: a próxima seção é a comparação.
