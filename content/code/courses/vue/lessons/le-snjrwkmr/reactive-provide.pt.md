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
