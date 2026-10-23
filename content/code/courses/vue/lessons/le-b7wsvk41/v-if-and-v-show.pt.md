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
