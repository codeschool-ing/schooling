---
title: ref, e o seu .value
version: 1
---

**`ref()` embrulha um valor num objeto com uma propriedade, `value`, e o Vue observa essa
propriedade.** Qualquer valor cabe: um número, uma string, um array, um objeto. Ler `minutes.value` é
percebido por quem estiver renderizando naquele momento, e escrever nele diz ao Vue para redesenhar o
que o leu. Esse é o contrato inteiro.

```html
<!-- src/demos/RefBasics.vue -->
<script setup>
import { ref } from 'vue'

const minutes = ref(25)
console.log(minutes.value)
console.log(typeof minutes, minutes.constructor.name)

const session = ref({ course: 'statistics', minutes: 25 })
function longer() {
  session.value.minutes += 5
}
</script>

<template>
  <p>{{ minutes }} minutes</p>
  <p>{{ session.course }}: {{ session.minutes }} minutes</p>
  <button @click="longer">Five more</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=RefBasics' --do 'click button'
[vite] connecting...
[vite] connected.
25
object RefImpl
-- click button
== the text of #app
25 minutes

statistics: 30 minutes

Five more
```

Três coisas nessa transcrição:

- **`minutes.value` é `25`**, o número. O próprio `minutes` é um objeto, um `RefImpl`: o invólucro.
  Imprimir `minutes` sem `.value` imprime o invólucro, e esse é o primeiro erro que todo mundo comete
  uma vez.
- **O template escreveu `{{ minutes }}`, sem `.value`**, e mostrou 25. Um ref no nível de cima do
  `<script setup>` é desembrulhado automaticamente no template. No script, você sempre escreve
  `.value`; no template, nunca.
- **`session.value.minutes += 5` redesenhou a página.** Um ref que guarda um objeto torna o objeto
  reativo também, até o fundo, então mudar uma propriedade dentro dele é percebido, tanto quanto
  trocar o objeto inteiro.

## Por que um invólucro, afinal

O JavaScript não consegue perceber que uma variável comum foi lida. `let minutes = 25` é um valor numa
posição, e nada roda quando alguém lê essa posição. O que o JavaScript *consegue* fazer é rodar código
quando uma propriedade de um objeto é lida ou escrita: um getter, ou um Proxy. Então o Vue põe o valor
dentro de um objeto e observa a propriedade `value` dele. **O `.value` que você digita é o preço de ser
percebido.**

A mesma restrição é o motivo de um ref ser passado adiante como o ref, e não como o valor dele. Uma
função que recebe `minutes` pode ler o valor atual quando quiser; uma função que recebe `minutes.value`
ganhou o número 25 e vai guardar 25 para sempre.

## O desembrulhar, com precisão

O template desembrulha um ref quando ele é um nome do **nível de cima** do `<script setup>`. Um ref
aninhado dentro de um objeto comum não é desembrulhado dentro de uma expressão, e a diferença aparece
assim que você faz conta com ele:

```html
<!-- src/demos/Unwrapping.vue -->
<script setup>
import { ref } from 'vue'

const total = ref(0)
const counts = { total: ref(0) }
</script>

<template>
  <p>{{ total + 1 }}</p>
  <p>{{ counts.total }}</p>
  <p>{{ counts.total + 1 }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Unwrapping'
[vite] connecting...
[vite] connected.
== the text of #app
1

0

[object Object]1
```

`{{ total + 1 }}` dá 1, porque `total` está no nível de cima e foi desembrulhado antes do `+`.
`{{ counts.total }}` dá 0, porque a última coisa que uma interpolação faz é desembrulhar o que está
para imprimir. Mas **`{{ counts.total + 1 }}` dá `[object Object]1`**: o `+` encontrou o invólucro,
transformou-o em string e colou um 1 nele. Mantenha os refs no nível de cima do script, ou dentro de
um objeto `reactive` (próxima seção), onde eles são desembrulhados sempre que são lidos.

## Quando o valor inteiro é trocado

Dados de um servidor chegam como um array ou objeto novo, e o movimento de costume é trocar o valor do
ref por eles:

```javascript
const courses = ref([])
courses.value = loaded
```

Tudo o que leu `courses.value` é redesenhado. Se os dados são grandes e você só vai trocá-los, nunca
mudá-los no lugar, **`shallowRef`** observa `.value` e nada dentro dele, o que poupa o trabalho de
tornar reativos mil objetos aninhados. O planner é pequeno e usa `ref` em todo lugar.
