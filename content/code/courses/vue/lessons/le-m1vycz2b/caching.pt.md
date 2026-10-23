---
title: O cache, e quando ele é esvaziado
version: 1
---

**Um computed roda a sua função de forma preguiçosa e guarda o resultado em cache.** Preguiçosa: não
quando as entradas mudam, mas na próxima vez que alguém o lê. Em cache: até que um dos valores
reativos que ele leu na última execução mude, cada leitura devolve o resultado guardado sem rodar
nada.

São duas afirmações, e as duas podem ser vistas:

```html
<!-- src/demos/LazyComputed.vue -->
<script setup>
import { ref, computed } from 'vue'

const minutes = ref(90)
const showHours = ref(false)

const hours = computed(() => {
  console.log(`computing hours from ${minutes.value}`)
  return minutes.value / 60
})

function change() {
  minutes.value += 30
  minutes.value += 30
  console.log('two changes made')
}
</script>

<template>
  <p>{{ minutes }} minutes</p>
  <p v-if="showHours">{{ hours }} hours</p>
  <button id="change" @click="change">Add an hour</button>
  <button id="show" @click="showHours = true">Show hours</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=LazyComputed' --do 'click #change' --do 'click #show' --do 'click #change'
[vite] connecting...
[vite] connected.
-- click #change
two changes made
-- click #show
computing hours from 150
-- click #change
two changes made
computing hours from 210
== the text of #app
210 minutes

3.5 hours

Add an hourShow hours
```

Passo a passo:

1. **Nada foi calculado quando a página abriu.** O `hours` só é mostrado sob `v-if="showHours"`, que
   é falso, então ninguém o leu, então a função dele nunca rodou.
2. O primeiro clique mudou `minutes` duas vezes. Ainda nada: um computed que ninguém lê nunca é
   calculado.
3. **O `Show hours` o leu pela primeira vez**, e ele foi calculado uma vez, a partir de 150, o valor
   naquele momento.
4. O segundo clique em `Add an hour` somou mais uma hora em dois passos, e `hours` foi calculado **uma
   vez**, a partir de 210. As duas escritas o marcaram como desatualizado; a renderização o leu uma
   vez.

## Como ele sabe do que depende

Não há lista de dependências para escrever, e isso não é mágica. Enquanto a função roda, o Vue
registra cada valor reativo que ela lê, exatamente como faz numa renderização (aula 2). **As
dependências são o que a última execução leu.** Um computed com uma condição dentro depende de coisas
diferentes em momentos diferentes:

```javascript
const label = computed(() => (showHours.value ? `${hours.value} hours` : `${minutes.value} minutes`))
```

Enquanto `showHours` é falso, `label` depende de `showHours` e de `minutes`, e mudar `hours` não o
recalcula. Isso está certo, já que `hours` não foi usado, e é também por isso que um computed precisa
ler as suas entradas *toda vez que roda*. Um valor lido uma vez numa variável fora da função, e usado
dentro dela, é uma cópia, e o computed nunca vai perceber que ele mudou.

## Quanto custa

Um computed guarda o último resultado e a lista do que leu. Isso é um objeto pequeno por computed, e o
trabalho de conferir se ele está desatualizado é mais barato do que refazer quase qualquer cálculo.
**Não há motivo para evitar `computed` em coisas pequenas**; o motivo para usá-lo não é velocidade, e
sim correção, e a velocidade vem junto.

Vale conhecer um caso: um computed que devolve um **objeto novo** toda vez, como os totais por curso do
planner (seção 07 desta aula), faz tudo o que o lê ser redesenhado sempre que é recalculado, mesmo
quando os números dentro saíram iguais. O Vue 3.4 em diante compara o resultado antigo com o novo e
pula a renderização para um número ou uma string que não mudou; para um objeto novo ele não tem como
saber sem olhar dentro, e não olha.
