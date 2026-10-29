---
title: Transition, para um elemento que entra e sai
version: 1
---

**O `<Transition>` envolve um elemento que aparece ou desaparece, por `v-if` ou `v-show`, e acrescenta
classes CSS a ele em cada etapa, para que uma folha de estilo possa animar a mudança.** O Vue não anima
nada sozinho: ele só põe a classe certa no momento certo e a tira quando o navegador avisa que a
transição CSS terminou.

```html
<!-- src/demos/FadeDemo.vue -->
<script setup>
import { ref } from 'vue'

const shown = ref(false)
let started = 0

function beforeEnter() {
  started = performance.now()
}
function afterEnter() {
  console.log(`the enter transition took about ${Math.round((performance.now() - started) / 100) * 100} ms`)
}
</script>

<template>
  <button @click="shown = !shown">Toggle</button>
  <Transition name="fade" @before-enter="beforeEnter" @after-enter="afterEnter">
    <p v-if="shown" id="note">Saved in this browser.</p>
  </Transition>
</template>

<style>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.6s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
@media (prefers-reduced-motion: reduce) {
  .fade-enter-active,
  .fade-leave-active {
    transition: none;
  }
}
</style>
```

Alterne e imprima o parágrafo logo em seguida, enquanto o fade ainda está rodando:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FadeDemo' --do 'click button' --html '#note' --text -
[vite] connecting...
[vite] connected.
-- click button
== the HTML of #note
<p id="note" class="fade-enter-active fade-enter-to">Saved in this browser.</p>
```

**O parágrafo carrega `fade-enter-active` e `fade-enter-to`**, pego no meio dos seus 600
milissegundos. Alterne de novo e espere o fim:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FadeDemo' --do 'click button' --do 'wait 1000' --text -
[vite] connecting...
[vite] connected.
-- click button
-- wait 1000
the enter transition took about 600 ms
```

O hook `after-enter` rodou quando a transição terminou, uns 600 milissegundos depois de ela começar,
que é a duração que a folha de estilo definiu: o Vue lê a duração do estilo computado do elemento e
espera o `transitionend` do navegador.

## As seis classes

Para uma transição chamada `fade`, o Vue põe estas no elemento:

| entrando | saindo | quando |
|---|---|---|
| `fade-enter-from` | `fade-leave-from` | o primeiro quadro: o estado inicial |
| `fade-enter-active` | `fade-leave-active` | o tempo todo: onde se escreve o `transition:` |
| `fade-enter-to` | `fade-leave-to` | do segundo quadro até o fim: o estado de destino |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha do tempo de um elemento entrando com uma transição chamada fade, de 600 milissegundos. fade-enter-active fica ligada o tempo todo. fade-enter-from fica só no primeiro quadro. fade-enter-to fica do segundo quadro até o fim. Quando o navegador avisa transitionend, fade-enter-active e fade-enter-to saem e o after-enter roda.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fade-enter-from</text><rect x=\"170\" y=\"29\" width=\"24\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fade-enter-active</text><rect x=\"170\" y=\"67\" width=\"480\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">fade-enter-to</text><rect x=\"194\" y=\"105\" width=\"456\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><line x1=\"170\" y1=\"160\" x2=\"690\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"690.0,160.0 682.6,163.1 682.6,156.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"170\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 ms</text><text x=\"650\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">600 ms</text><line x1=\"650\" y1=\"24\" x2=\"650\" y2=\"152\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></line><text x=\"644\" y=\"140\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">transitionend: after-enter</text><text x=\"200\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um quadro</text></svg>", "caption": "O Vue liga e desliga classes; a folha de estilo decide como cada uma fica e quanto tempo dura.", "same": ["transitionend: after-enter"]}
```

Na demo, `enter-from` e `leave-to` são `opacity: 0`, e o `-active` diz quanto tempo dura e com qual
curva. Na saída, o Vue mantém o elemento na página até a `fade-leave-active` terminar, e só então o
remove, que é a única coisa que o CSS sozinho não consegue fazer: animar um elemento que o `v-if` está
prestes a apagar.

Os hooks, `@before-enter`, `@after-enter`, `@leave` e os outros, servem para transições conduzidas por
JavaScript ou, como aqui, para saber quando uma terminou. As classes são o caminho de costume.
