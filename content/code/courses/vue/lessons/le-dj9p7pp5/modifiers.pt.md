---
title: trim, number e lazy
version: 1
---

**Três modificadores mudam o que o `v-model` grava: `.trim` tira os espaços das pontas, `.number` converte
para número, e `.lazy` grava quando o campo muda em vez de a cada tecla.** Cada um é uma pequena função
entre o campo e o ref, e cada um resolve um bug que, sem ele, estaria em todo formulário.

```html
<!-- src/demos/Modifiers.vue -->
<script setup>
import { ref } from 'vue'

const plain = ref('')
const trimmed = ref('')
const number = ref('')
const lazy = ref('')
</script>

<template>
  <input id="plain" v-model="plain" />
  <input id="trimmed" v-model.trim="trimmed" />
  <input id="number" v-model.number="number" />
  <input id="lazy" v-model.lazy="lazy" />
  <p id="out">
    plain {{ JSON.stringify(plain) }} · trim {{ JSON.stringify(trimmed) }} · number
    {{ JSON.stringify(number) }} ({{ typeof number }}) · lazy {{ JSON.stringify(lazy) }}
  </p>
</template>
```

Digite nos quatro campos, com espaços, sem sair do último:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Modifiers' --do 'fill #plain  verbs ' --do 'fill #trimmed  verbs ' --do 'fill #number 45' --do 'fill #lazy verbs' --text '#out'
[vite] connecting...
[vite] connected.
-- fill #plain  verbs 
-- fill #trimmed  verbs 
-- fill #number 45
-- fill #lazy verbs
== the text of #out
plain " verbs " · trim "verbs" · number 45 (number) · lazy ""
```

Depois digite no último e aperte Tab para sair dele:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Modifiers' --do 'fill #lazy verbs' --do 'press Tab' --text '#out'
[vite] connecting...
[vite] connected.
-- fill #lazy verbs
-- press Tab
== the text of #out
plain "" · trim "" · number "" (string) · lazy "verbs"
```

- **`.trim`** guardou `"verbs"` onde o campo comum guardou `" verbs "`. Um título salvo com um espaço na
  frente fica em primeiro na ordenação e nunca aparece numa busca; use trim em tudo que uma pessoa digita
  como nome.
- **`.number`** guardou o número `45` vindo de um campo de texto comum. Ele usa `parseFloat`, e um valor
  que não se converte fica como string, então o `.number` é uma conveniência, não validação.
- **`.lazy`** não guardou nada enquanto o campo ainda tinha o foco, e guardou `"verbs"` quando o Tab tirou o
  foco dali. O campo dispara `change` quando é deixado, e não `input` a cada tecla.

## Quando o lazy é o certo

O `.lazy` serve para um campo cujo valor é caro de acompanhar: um que dispara uma requisição de busca, um
recálculo sobre uma lista longa ou uma checagem num servidor. Atualizar a cada tecla mandaria uma
requisição por letra. Para um campo cujo valor é mostrado ou checado localmente, o padrão é o que o aluno
espera: o erro some no momento em que a digitação o corrige.
