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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 215\" role=\"img\" aria-label=\"Quatro momentos da demo LazyComputed, em colunas. Quando a página abre, minutes é 90, showHours é false, e hours não é calculado. Depois do primeiro clique em change, minutes é 150, depois de duas mudanças de 30, e hours continua sem ser calculado, porque ninguém o lê. Depois do clique em show, showHours é true e hours é calculado uma vez, a partir de 150. Depois do segundo clique em change, minutes é 210 e hours é calculado uma vez, a partir de 210, embora tenham sido duas escritas.\"><text x=\"215\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a página abre</text><text x=\"355\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">click #change</text><text x=\"495\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">click #show</text><text x=\"635\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">click #change</text><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">minutes</text><rect x=\"150\" y=\"44\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">90</text><rect x=\"290\" y=\"44\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">150</text><rect x=\"430\" y=\"44\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"495\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">150</text><rect x=\"570\" y=\"44\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">210</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">showHours</text><rect x=\"150\" y=\"94\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"215\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">false</text><rect x=\"290\" y=\"94\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">false</text><rect x=\"430\" y=\"94\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"495\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">true</text><rect x=\"570\" y=\"94\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">true</text><text x=\"20\" y=\"160\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">hours rodou</text><rect x=\"150\" y=\"144\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"215\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não roda</text><rect x=\"290\" y=\"144\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"355\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não roda</text><rect x=\"430\" y=\"144\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"495\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma vez, de 150</text><rect x=\"570\" y=\"144\" width=\"130\" height=\"32\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">uma vez, de 210</text><text x=\"355\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duas escritas, ninguém lendo</text><text x=\"635\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duas escritas, lido uma vez</text></svg>", "caption": "Um computed roda quando é lido, e uma vez só, por mais escritas que tenham vindo antes."}
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
