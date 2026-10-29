---
title: Pais e filhos, em ordem
version: 1
---

**O setup de um pai roda antes de os filhos existirem, e o `onMounted` dele roda depois que todos eles
estão na página.** A remoção espelha isso: o pai é avisado primeiro de que vai sair, e é o último a
sumir. Essa ordem decide o que um pai pode supor sobre os filhos, e o contrário.

Um componente que registra seus momentos, usado três vezes, como um pai com dois filhos no slot:

```html
<!-- src/demos/Child.vue -->
<script setup>
import { onBeforeMount, onMounted, onBeforeUnmount, onUnmounted } from 'vue'

const { name } = defineProps({ name: String })
console.log(`${name}: setup`)
onBeforeMount(() => console.log(`${name}: beforeMount`))
onMounted(() => console.log(`${name}: mounted`))
onBeforeUnmount(() => console.log(`${name}: beforeUnmount`))
onUnmounted(() => console.log(`${name}: unmounted`))
</script>

<template>
  <p>{{ name }}</p>
  <slot />
</template>
```

```html
<!-- src/demos/Order.vue -->
<script setup>
import { ref } from 'vue'
import Child from './Child.vue'

const shown = ref(true)
</script>

<template>
  <Child v-if="shown" name="parent">
    <Child name="first child" />
    <Child name="second child" />
  </Child>
  <button @click="shown = false">Remove all three</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Order' --do 'click button' --text -
[vite] connecting...
[vite] connected.
parent: setup
parent: beforeMount
first child: setup
first child: beforeMount
second child: setup
second child: beforeMount
first child: mounted
second child: mounted
parent: mounted
-- click button
parent: beforeUnmount
first child: beforeUnmount
second child: beforeUnmount
first child: unmounted
second child: unmounted
parent: unmounted
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O tempo corre da esquerda para a direita. Três linhas: o pai, o primeiro filho, o segundo filho. O setup e o beforeMount do pai vêm primeiro; depois o setup e o beforeMount de cada filho; depois o mounted do primeiro filho, o do segundo e, por último, o mounted do pai. A criação desce a árvore e a montagem volta subindo.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pai</text><line x1=\"130\" y1=\"50\" x2=\"705\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">primeiro filho</text><line x1=\"130\" y1=\"110\" x2=\"705\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">segundo filho</text><line x1=\"130\" y1=\"170\" x2=\"705\" y2=\"170\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 4\"></line><rect x=\"135\" y=\"37\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"164.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">setup</text><rect x=\"198\" y=\"37\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"227.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">before…</text><line x1=\"193\" y1=\"50\" x2=\"198\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"261\" y=\"97\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">setup</text><line x1=\"256\" y1=\"50\" x2=\"261\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"324\" y=\"97\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"353.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">before…</text><line x1=\"319\" y1=\"110\" x2=\"324\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"387\" y=\"157\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">setup</text><line x1=\"382\" y1=\"110\" x2=\"387\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"450\" y=\"157\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"479.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">before…</text><line x1=\"445\" y1=\"170\" x2=\"450\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"513\" y=\"97\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"542.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">mounted</text><line x1=\"508\" y1=\"170\" x2=\"513\" y2=\"110\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"576\" y=\"157\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">mounted</text><line x1=\"571\" y1=\"110\" x2=\"576\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><rect x=\"639\" y=\"37\" width=\"58\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"668.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">mounted</text><line x1=\"634\" y1=\"170\" x2=\"639\" y2=\"50\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></line><text x=\"260\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">criados, descendo</text><text x=\"600\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">montados, voltando</text></svg>", "caption": "O pai é montado por último, então o onMounted dele pode contar com todos os filhos já na página."}
```

**A criação desce, e a montagem volta subindo.** O setup e o `beforeMount` do pai rodam primeiro;
depois cada filho é criado e preparado, um de cada vez; depois os filhos são montados, do primeiro ao
último, e só então o pai. O `onMounted` de um pai pode, portanto, contar com todos os filhos na página e
com o `onMounted` de cada um já executado. O `onMounted` de um filho pode contar com a página, porque o
Vue só roda os hooks de montagem depois que a árvore inteira foi inserida, mas não com nada que o pai
faça no próprio `onMounted`, que ainda não rodou.

**A remoção começa no topo e termina no topo.** O `beforeUnmount` roda primeiro no pai, depois nos
filhos; o `unmounted` roda primeiro nos filhos, depois no pai. Então, no próprio `onUnmounted`, um pai
sabe que os filhos já terminaram de limpar o que deixaram.

## O que isso significa na prática

- **Não mexa num filho a partir do setup do pai.** Ele ainda não existe. Um ref de template para um
  componente filho, seção 04, é `null` até o `onMounted` do pai.
- **Não faça um filho depender de algo que o pai prepara no `onMounted`.** O `onMounted` do filho roda
  primeiro e não vai encontrar nada. Faça o provide durante o setup do pai, como a aula 8 fez, e a coisa
  está lá antes de qualquer filho ser criado.
- **Limpe no componente que começou o trabalho.** O `onUnmounted` de cada componente roda para ele,
  faça o pai o que fizer, então um timer pertence ao componente que o iniciou.
