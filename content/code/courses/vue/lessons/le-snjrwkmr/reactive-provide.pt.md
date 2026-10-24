---
title: Provendo algo que muda
version: 1
---

**O `provide` entrega o que recebe, uma vez.** Dê a ele um valor simples e quem injeta recebe esse
valor para sempre; dê a ele um ref e quem injeta recebe o ref, e o acompanha conforme ele muda. Por isso
um valor que muda é provido como ref ou como `computed`, nunca como `.value`, pelo mesmo motivo que a
aula 2 deu para passar um ref a uma função.

Isso levanta a pergunta que a aula 6 respondeu para props: se um filho tem o ref do pai, ele pode
escrever nele? Pode, a não ser que quem provê o impeça. Esta demo impede, e mostra tanto o que o filho
pode fazer quanto o que não pode:

```html
<!-- src/demos/TotalBadge.vue -->
<script setup>
import { inject } from 'vue'
import { plannerKey } from './keys.js'

const { total, addFive } = inject(plannerKey)

function cheat() {
  total.value = 999
}
</script>

<template>
  <p id="badge">Total: {{ total }} minutes</p>
  <button id="add" @click="addFive">Add five</button>
  <button id="cheat" @click="cheat">Write to it directly</button>
</template>
```

```html
<!-- src/demos/ReactiveProvide.vue -->
<script setup>
import { ref, readonly, provide } from 'vue'
import TotalBadge from './TotalBadge.vue'
import { plannerKey } from './keys.js'

const total = ref(75)

provide(plannerKey, {
  total: readonly(total),
  addFive: () => {
    total.value += 5
  },
})
</script>

<template>
  <TotalBadge />
  <p id="owner">The provider has {{ total }}</p>
</template>
```

Some cinco, depois tente escrever 999:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ReactiveProvide' --do 'click #add' --do 'click #cheat'
[vite] connecting...
[vite] connected.
-- click #add
-- click #cheat
[warn] [Vue warn] Set operation on key "value" failed: target is readonly. RefImpl
== the text of #app
Total: 80 minutes

Add fiveWrite to it directly

The provider has 80
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A demo ReactiveProvide. À esquerda, o provider é dono de total, um ref que começa em 75. No meio, o que ele fornece sob plannerKey: readonly de total, e a função addFive. À direita, o TotalBadge injeta os dois e mostra Total: 80 minutes. Clicar em Add five chama addFive, e o provider muda o próprio ref, de 75 para 80, que os dois mostram. Escrever total.value igual a 999 a partir do badge é recusado, porque o que ele tem é uma visão somente leitura do ref.\"><rect x=\"20\" y=\"50\" width=\"180\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ReactiveProvide.vue</text><text x=\"110\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">total = ref(75)</text><text x=\"110\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">75, depois 80</text><rect x=\"270\" y=\"40\" width=\"180\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">plannerKey</text><rect x=\"285\" y=\"70\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">readonly(total)</text><rect x=\"285\" y=\"112\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">addFive</text><rect x=\"520\" y=\"50\" width=\"180\" height=\"90\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">TotalBadge.vue</text><text x=\"610\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Total: 80 minutes</text><line x1=\"202\" y1=\"96\" x2=\"266\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"266.0,96.0 258.6,99.1 258.6,92.9\" fill=\"var(--wire)\"></polygon><text x=\"234\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">provide</text><line x1=\"452\" y1=\"96\" x2=\"516\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"516.0,96.0 508.6,99.1 508.6,92.9\" fill=\"var(--wire)\"></polygon><text x=\"484\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">inject</text><path d=\"M 570 142 V 196 H 110\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><line x1=\"110\" y1=\"196\" x2=\"110\" y2=\"144\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"110.0,144.0 113.1,151.4 106.9,151.4\" fill=\"var(--phosphor)\"></polygon><text x=\"340\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">Add five: o dono muda o próprio ref</text><text x=\"620\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">total.value = 999</text><text x=\"620\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado: uma visão somente leitura</text></svg>", "caption": "Forneça o estado como somente leitura e as formas de mudá-lo como funções."}
```

**O `Add five` funcionou, e tanto o badge quanto quem provê mostram 80.** O badge chamou a função que
quem provê entregou a ele, e quem provê mudou o próprio ref. **A escrita de 999 foi recusada** com um
aviso, porque o badge recebeu `readonly(total)`: uma visão só de leitura do mesmo ref, que acompanha
toda mudança e não aceita nenhuma.

## O padrão

Prover **o estado só para leitura, e as operações sobre ele como funções.** É o contrato de props e
emits da aula 6, esticado por cima das camadas do meio: quem injeta lê o que recebe, e pede mudanças por
funções que o dono escreveu. O dono mantém um lugar só onde o seu estado muda, e é isso que torna
possível descobrir depois por que ele mudou.

| provide | quem injeta pode |
|---|---|
| `'hours'`, um valor simples | lê-lo, uma vez; ele nunca vai mudar |
| `total`, um ref | lê-lo e acompanhá-lo, *e escrever nele*, sem o dono perceber |
| `readonly(total)` | lê-lo e acompanhá-lo; uma escrita é recusada |
| `readonly(total)` e `addFive` | lê-lo, acompanhá-lo, e pedir ao dono que o mude |

O `readonly` funciona com um ref, um objeto `reactive` ou um `computed`; um `computed` sem setter já é
só de leitura, e é por isso que o planner pode prover os seus `titles` como estão, mais adiante nesta
aula.
