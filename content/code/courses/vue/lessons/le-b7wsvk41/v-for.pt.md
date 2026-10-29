---
title: v-for, sobre qualquer coisa que se repete
version: 1
---

**O `v-for` repete um elemento uma vez para cada item de uma lista, e dá a cada cópia o item sob um
nome que você escolhe.** Ele também repete sobre as propriedades de um objeto e sobre um intervalo de
números, e é a única diretiva com uma regra sobre qual outra diretiva pode ficar ao lado dela.

```html
<!-- src/demos/ForLoops.vue -->
<script setup>
const sessions = [
  { id: 's2', course: 'statistics', minutes: 45, done: true },
  { id: 's4', course: 'statistics', minutes: 60, done: false },
  { id: 's5', course: 'guitar', minutes: 20, done: false },
]
const goal = { course: 'statistics', minutes: 180 }
</script>

<template>
  <ol>
    <li v-for="(session, index) in sessions" :key="session.id">
      {{ index }}: {{ session.course }}, {{ session.minutes }} minutes
    </li>
  </ol>
  <p>
    <span v-for="(value, key) in goal" :key="key">{{ key }} = {{ value }}; </span>
  </p>
  <p><span v-for="n in 3" :key="n">{{ n }} </span></p>
  <ul>
    <template v-for="session in sessions" :key="session.id">
      <li v-if="session.done">{{ session.course }} is done</li>
    </template>
  </ul>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ForLoops'
[vite] connecting...
[vite] connected.
== the text of #app
0: statistics, 45 minutes
1: statistics, 60 minutes
2: guitar, 20 minutes

course = statistics; minutes = 180;

123

statistics is done
```

Quatro formas, na ordem do template:

- **`(session, index) in sessions`**: o item e a posição dele, começando em 0.
- **`(value, key) in goal`**: sobre um objeto, o valor primeiro e o nome da propriedade em segundo, na
  ordem em que o `Object.keys` os dá.
- **`n in 3`**: um intervalo, e ele começa em **1**, não em 0. É o único lugar do Vue em que a contagem
  começa em um, e a transcrição mostra `123`.
- **`<template v-for>`** repete o conteúdo sem um elemento invólucro próprio, que é como um filtro entra
  dentro de um laço. Mais sobre isso abaixo.

Todo `v-for` acima tem um `:key`, que é o assunto da próxima seção.

## v-if e v-for no mesmo elemento

O jeito tentador de mostrar só as sessões feitas é pôr as duas diretivas no `<li>`:

```html
<!-- src/demos/IfInsideFor.vue -->
<script setup>
const sessions = [
  { id: 's2', course: 'statistics', done: true },
  { id: 's4', course: 'statistics', done: false },
]
</script>

<template>
  <ul>
    <li v-for="session in sessions" v-if="session.done" :key="session.id">{{ session.course }}</li>
  </ul>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=IfInsideFor'
[vite] connecting...
[vite] connected.
[warn] [Vue warn]: Property "session" was accessed during render but is not defined on instance. 
  at <IfInsideFor>
[warn] [Vue warn]: Unhandled error during execution of render function 
  at <IfInsideFor>
Uncaught TypeError: Cannot read properties of undefined (reading 'done')
== the text of #app
```

**No Vue 3, o `v-if` é avaliado antes do `v-for`** quando os dois estão num mesmo elemento, então
`session` ainda não existia quando o `v-if` pediu `session.done`. A página fica vazia e o console tem o
erro. (O Vue 2 fazia o contrário, e é por isso que respostas antigas na web sugerem esse padrão.)

Dois jeitos corretos, e a escolha depende de o filtro ser ou não um fato sobre os dados:

- **Um `computed` que filtra**, e um `v-for` simples sobre ele. Quando a lista filtrada significa
  algo, "as sessões feitas", ela merece um nome, e a aula 3 diz onde ficam os valores derivados.
- **`<template v-for>` com um `v-if` dentro**, como faz a última lista da primeira demonstração,
  quando o filtro é só sobre a exibição.
