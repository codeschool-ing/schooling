---
title: v-if e v-show
version: 1
---

**Uma diretiva é um atributo que começa com `v-` e diz ao compilador de templates para fazer algo com
o elemento em que está.** Você já usou três: `v-for` na aula 1, `v-if` e `v-else` na aula 2. Esta aula
traz as diretivas que você vai escrever todo dia, e o erro que cada uma convida a cometer.

`v-if` e `v-show` escondem um elemento, e fazem isso de jeitos completamente diferentes:

- **`v-if` decide se o elemento existe.** Falso, e o elemento e tudo dentro dele saem da página,
  componentes destruídos incluídos. Verdadeiro de novo, e ele é construído outra vez do zero.
- **`v-show` decide se o elemento está visível.** O elemento está sempre lá; o Vue só põe
  `display: none` nele.

A diferença fica fácil de ver com um componente que anuncia a própria vida. Ele usa duas coisas que
aulas posteriores explicam, `defineProps` (aula 6) e os hooks `onMounted` e `onUnmounted` (aula 9);
aqui elas só imprimem:

```html
<!-- src/demos/Noisy.vue -->
<script setup>
import { onMounted, onUnmounted } from 'vue'

const props = defineProps(['name'])
console.log(`${props.name}: created`)
onMounted(() => console.log(`${props.name}: on the page`))
onUnmounted(() => console.log(`${props.name}: removed`))
</script>

<template>
  <p>{{ name }}</p>
</template>
```

```html
<!-- src/demos/IfAndShow.vue -->
<script setup>
import { ref } from 'vue'
import Noisy from './Noisy.vue'

const open = ref(true)
</script>

<template>
  <div id="panels">
    <Noisy v-if="open" name="with v-if" />
    <Noisy v-show="open" name="with v-show" />
  </div>
  <button @click="open = !open">Toggle</button>
</template>
```

Alterne três vezes e imprima o HTML dos dois painéis no fim:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=IfAndShow' --do 'click button' --do 'click button' --do 'click button' --html '#panels' --text -
[vite] connecting...
[vite] connected.
with v-if: created
with v-show: created
with v-if: on the page
with v-show: on the page
-- click button
with v-if: removed
-- click button
with v-if: created
with v-if: on the page
-- click button
with v-if: removed
== the HTML of #panels
<div id="panels"><!--v-if--><p style="display: none;">with v-show</p></div>
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Os dois componentes Noisy da demo IfAndShow ao longo de três cliques em Toggle, em quatro colunas: a página abrindo com open true, o primeiro clique com open false, o segundo com open true, o terceiro com open false. O que tem v-if é criado e posto na página, removido e trocado por um comentário v-if, criado e posto na página de novo, e removido de novo: criado duas vezes, removido duas vezes. O que tem v-show é criado e posto na página uma vez, e depois só alterna entre display none e visível.\"><text x=\"180\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a página abre</text><text x=\"180\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">open = true</text><text x=\"330\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">clique 1</text><text x=\"330\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">open = false</text><text x=\"480\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">clique 2</text><text x=\"480\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">open = true</text><text x=\"630\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">clique 3</text><text x=\"630\" y=\"38\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">open = false</text><text x=\"20\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">v-if</text><text x=\"20\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">v-show</text><rect x=\"110\" y=\"60\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">criado, na página</text><rect x=\"260\" y=\"60\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">removido</text><text x=\"330\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;!--v-if--&gt;</text><rect x=\"410\" y=\"60\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">criado, na página</text><rect x=\"560\" y=\"60\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"630\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">removido</text><text x=\"630\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;!--v-if--&gt;</text><rect x=\"110\" y=\"130\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">criado, na página</text><rect x=\"260\" y=\"130\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">display: none</text><rect x=\"410\" y=\"130\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"480\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">visível de novo</text><rect x=\"560\" y=\"130\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">display: none</text><text x=\"410\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o parágrafo do v-show é o mesmo elemento o tempo todo</text></svg>", "caption": "O v-if constrói e destrói o componente; o v-show o constrói uma vez e muda um estilo."}
```

**O componente com `v-if` foi criado duas vezes e removido duas vezes; o com `v-show` foi criado uma
vez e continua lá.** No HTML final, onde estava o parágrafo do `v-if` só há um comentário,
`<!--v-if-->`, que o Vue deixa como marcador para saber onde pôr o elemento de volta. O parágrafo do
`v-show` está presente, com `style="display: none;"`.

## Qual usar

| | `v-if` | `v-show` |
|---|---|---|
| escondido quer dizer | fora da página | na página, sem ser exibido |
| custo da primeira renderização escondido | nenhum | tudo é construído mesmo assim |
| custo de cada alternância | construir ou destruir tudo o que está dentro | mudar um estilo |
| estado dentro dele, um campo meio digitado por exemplo | perdido ao esconder | mantido |
| funciona com `v-else` e `<template>` | sim | não |

**Use `v-if` por padrão**: a maioria das coisas escondidas continua escondida, e não construir nada é
o mais barato. Use `v-show` para algo alternado com frequência, como um painel que o aluno abre e
fecha muitas vezes, ou quando o estado dentro dele precisa sobreviver a ser escondido.

`v-else-if` e `v-else` precisam vir logo depois de um elemento com `v-if` ou `v-else-if`, sem nada
entre eles, ou o compilador os recusa. Para esconder vários elementos sob uma condição sem acrescentar
um invólucro à página, ponha o `v-if` num elemento `<template>`, que renderiza os filhos e nada de si
mesmo.

Um leitor de tela não lê um elemento com `display: none`, nem um removido pelo `v-if`, então para a
acessibilidade os dois são iguais: escondido é escondido. Um texto que deve ser lido mas não visto
precisa de uma classe visualmente oculta, que nenhuma das duas diretivas oferece.
