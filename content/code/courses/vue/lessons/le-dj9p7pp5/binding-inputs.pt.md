---
title: Todo tipo de campo, ligado
version: 1
---

**O `v-model` liga todo tipo de campo de formulário que o navegador tem, e cada tipo devolve um valor do
seu próprio tipo: um campo de data, uma string; um select, o valor da opção escolhida; um campo numérico,
um número.** A aula 5 viu o `v-model` num campo de texto e em duas caixas de seleção. Um formulário para
uma sessão de estudo precisa de um curso, uma data e um número de minutos, e esta aula constrói um, então
ela começa pelos próprios campos.

```html
<!-- src/demos/Fields.vue -->
<script setup>
import { ref } from 'vue'

const date = ref('2026-10-24')
const course = ref('spanish')
const minutes = ref(30)
const kind = ref('reading')
const note = ref('')
</script>

<template>
  <label>Date <input id="date" type="date" v-model="date" /></label>
  <label>
    Course
    <select id="course" v-model="course">
      <option value="statistics">Statistics</option>
      <option value="spanish">Spanish</option>
      <option value="guitar">Guitar</option>
    </select>
  </label>
  <label>Minutes <input id="minutes" type="number" v-model="minutes" /></label>
  <fieldset>
    <legend>Kind</legend>
    <label><input type="radio" value="reading" v-model="kind" /> Reading</label>
    <label><input id="practice" type="radio" value="practice" v-model="kind" /> Practice</label>
  </fieldset>
  <label>Note <textarea id="note" v-model="note"></textarea></label>
  <pre id="state">{{ { date, course, minutes, kind, note } }}</pre>
  <p id="types">{{ typeof date }}, {{ typeof course }}, {{ typeof minutes }}</p>
</template>
```

Mude a data, os minutos, o tipo e a nota:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=Fields' --do 'fill #date 2026-10-30' --do 'fill #minutes 45' --do 'check #practice' --do 'fill #note verbs' --text '#app'
[vite] connecting...
[vite] connected.
-- fill #date 2026-10-30
-- fill #minutes 45
-- check #practice
-- fill #note verbs
== the text of #app
Date  Course 
Statistics
Spanish
Guitar
Minutes 
Kind
 Reading Practice
Note 
{
  "date": "2026-10-30",
  "course": "spanish",
  "minutes": 45,
  "kind": "practice",
  "note": "verbs"
}

string, string, number
```

`{{ { date, course, minutes, kind, note } }}` imprime um objeto como JSON, o que é um jeito rápido de ver
o estado inteiro de um formulário enquanto você o constrói.

## O que cada campo dá

| campo | o `v-model` guarda | para saber |
|---|---|---|
| `<input type="date">` | `"2026-10-30"`, uma string em `YYYY-MM-DD` | o formato que o planner já usa, então não precisa de conversão; o que o aluno *vê* está no formato do idioma dele |
| `<select>` | o `value` do `<option>` escolhido | uma opção sem `value` dá o seu texto; ligue `:value` para entregar um número ou um objeto |
| `<input type="number">` | um número | o Vue converte sozinho para este tipo, como a aula 5 disse; um campo vazio dá `""` |
| botões de rádio que dividem um `v-model` | o `value` do escolhido | coloque-os num `<fieldset>` com uma `<legend>`, para que um leitor de tela anuncie a pergunta com cada opção |
| `<textarea>` | o texto | escreva `v-model`: `{{ note }}` entre as tags mostra o ref, e o que o aluno digita nunca chega a ele |

O `<select>` guarda `"spanish"` embora o aluno tenha visto *Spanish*: o valor é o id, o texto é o título,
que é a regra do planner da aula 5 para qualquer lista. E todo campo acima fica dentro do seu `<label>`,
então clicar nas palavras chega ao campo e um leitor de tela lhe dá nome.

## O que dá uma string quando você quer um número

O campo numérico é a exceção que confirma a regra: o Vue lê o `type` do campo e converte. Um campo de
qualquer outro tipo dá uma string, mesmo que tenha só dígitos, e esse é o assunto da próxima seção.
