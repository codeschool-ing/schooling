---
title: O mesmo componente, escrito do outro jeito
version: 1
---

**A Options API é o jeito como os componentes Vue eram escritos antes da Composition API, e ela
continua com suporte completo: um componente é um objeto cujas propriedades, `data`, `computed`,
`methods`, `props`, `mounted` e as outras, guardam cada uma um tipo de coisa.** Quase todo código Vue 2 é
escrito assim (a Composition API só chegou ao Vue 2 na última versão, a 2.7), e muito código Vue 3
também. Você vai encontrá-la no seu primeiro emprego antes de
escrever qualquer linha nela, então esta aula é sobre lê-la, traduzi-la e saber por que o planner não é
escrito nela.

Aqui está um card, escrito duas vezes, uma em cada API. A versão Options:

```html
<!-- src/demos/OptionsCard.vue -->
<script>
export default {
  name: 'OptionsCard',
  props: {
    title: { type: String, required: true },
    goal: { type: Number, required: true },
    done: { type: Number, default: 0 },
  },
  emits: ['more'],
  data() {
    return { clicks: 0 }
  },
  computed: {
    percent() {
      return Math.round((this.done / this.goal) * 100)
    },
  },
  methods: {
    ask() {
      this.clicks++
      this.$emit('more', 15)
    },
  },
  mounted() {
    console.log(`${this.title}: mounted at ${this.percent}%`)
  },
}
</script>

<template>
  <h3>{{ title }}</h3>
  <p>{{ done }} of {{ goal }} minutes, {{ percent }}% ({{ clicks }} requests)</p>
  <button @click="ask">15 more</button>
</template>
```

A versão Composition, que é o estilo do resto deste curso:

```html
<!-- src/demos/CompositionCard.vue -->
<script setup>
import { ref, computed, onMounted } from 'vue'

const { title, goal, done } = defineProps({
  title: { type: String, required: true },
  goal: { type: Number, required: true },
  done: { type: Number, default: 0 },
})
const emit = defineEmits(['more'])

const clicks = ref(0)
const percent = computed(() => Math.round((done / goal) * 100))

function ask() {
  clicks.value++
  emit('more', 15)
}

onMounted(() => console.log(`${title}: mounted at ${percent.value}%`))
</script>

<template>
  <h3>{{ title }}</h3>
  <p>{{ done }} of {{ goal }} minutes, {{ percent }}% ({{ clicks }} requests)</p>
  <button @click="ask">15 more</button>
</template>
```

E os dois, lado a lado, compartilhando uma mesma contagem de minutos:

```html
<!-- src/demos/TwoApis.vue -->
<script setup>
import { ref } from 'vue'
import OptionsCard from './OptionsCard.vue'
import CompositionCard from './CompositionCard.vue'

const done = ref(45)
</script>

<template>
  <OptionsCard title="Options" :goal="180" :done="done" @more="(m) => (done += m)" />
  <CompositionCard title="Composition" :goal="180" :done="done" @more="(m) => (done += m)" />
</template>
```

Aperte o botão do primeiro card uma vez:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TwoApis' --do 'click button'
[vite] connecting...
[vite] connected.
Options: mounted at 25%
Composition: mounted at 25%
-- click button
== the text of #app
Options

60 of 180 minutes, 33% (1 requests)

15 more
Composition

60 of 180 minutes, 33% (0 requests)

15 more
```

**Eles se comportam de forma idêntica**: os dois montaram em 25%, os dois foram para 33% quando a
contagem compartilhada passou de 45 para 60, e só o card clicado contou um pedido, porque `clicks` é
estado de cada card. As duas APIs são dois jeitos de escrever para o mesmo runtime; a reatividade por
baixo é a da aula 2.

## Como ler a diferença

Ponha os dois arquivos lado a lado e o formato é a lição:

| | Options API | Composition API |
|---|---|---|
| o componente é | um objeto exportado com `export default` | o nível de cima do `<script setup>` |
| o código é agrupado por | tipo: todo o estado em `data`, todos os valores derivados em `computed`, todas as funções em `methods` | assunto: o que anda junto fica junto |
| o estado é alcançado por | `this`: `this.clicks`, `this.percent`, `this.done` | variáveis: `clicks.value`, `percent.value`, `done` |
| o template enxerga | tudo o que está em `props`, `data`, `computed` e `methods` | todo nome do nível de cima do script |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"O mesmo componente em duas colunas. À esquerda, a Options API agrupa o código por tipo: data, computed, watch, mounted e beforeUnmount, e as partes de dois assuntos, a semana e o timer, ficam espalhadas pelos cinco. À direita, a Composition API agrupa o código por assunto: tudo sobre a semana fica junto, e tudo sobre o timer fica junto.\"><text x=\"180\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Options API: por tipo</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Composition API: por assunto</text><rect x=\"30\" y=\"32\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data</text><rect x=\"160\" y=\"39\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">semana</text><rect x=\"240\" y=\"39\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">timer</text><rect x=\"30\" y=\"74\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">computed</text><rect x=\"160\" y=\"81\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">semana</text><rect x=\"30\" y=\"116\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">watch</text><rect x=\"160\" y=\"123\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">semana</text><rect x=\"30\" y=\"158\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mounted</text><rect x=\"160\" y=\"165\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">timer</text><rect x=\"30\" y=\"200\" width=\"300\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"42\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">beforeUnmount</text><rect x=\"160\" y=\"207\" width=\"70\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"195\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">timer</text><rect x=\"390\" y=\"32\" width=\"300\" height=\"98\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a semana</text><text x=\"540\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ref</text><text x=\"540\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">computed</text><text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">watch</text><rect x=\"390\" y=\"140\" width=\"300\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">o timer</text><text x=\"540\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ref</text><text x=\"540\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">onMounted</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">onBeforeUnmount</text></svg>", "caption": "Mudar o timer exige visitar três opções à esquerda, e um bloco à direita.", "same": ["timer"]}
```

A segunda linha é o motivo de a Composition API existir. Num card pequeno, agrupar por tipo é
arrumado. Num componente de quinhentas linhas que faz quatro coisas, o estado de uma delas está em
`data`, os valores derivados dela cem linhas abaixo em `computed`, o watcher mais abaixo ainda e a
limpeza em `beforeUnmount`, e mudar essa uma coisa significa visitar quatro lugares. A Composition API
deixa as quatro partes juntas, e os composables da aula 10 deixam que elas saiam do componente de vez.

Nenhuma das duas está errada, e a documentação do Vue ainda oferece as duas. Código novo neste curso é
Composition; o resto desta aula é a Options API que vão pedir para você ler.
