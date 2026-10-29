---
title: v-model, a ligação nos dois sentidos
version: 1
---

**O `v-model` liga um campo de formulário a um ref nos dois sentidos: o campo mostra o valor do ref,
e digitar no campo escreve no ref.** Ele é um atalho para duas coisas que você poderia escrever à mão,
uma ligação do valor do campo e um listener do seu evento de input, e a aula 14 o abre e o constrói
num componente seu.

```html
<!-- src/demos/ModelBasics.vue -->
<script setup>
import { ref } from 'vue'

const note = ref('')
const done = ref(false)
const kinds = ref([])
</script>

<template>
  <label>Note <input id="note" v-model="note" /></label>
  <label><input id="done" type="checkbox" v-model="done" /> Done</label>
  <label><input id="reading" type="checkbox" value="reading" v-model="kinds" /> Reading</label>
  <label><input id="exercises" type="checkbox" value="exercises" v-model="kinds" /> Exercises</label>
  <p id="state">note = "{{ note }}", done = {{ done }}, kinds = {{ kinds }}</p>
</template>
```

Digite uma nota, marque `Done` e marque `Exercises`:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ModelBasics' --do 'fill #note verbs' --do 'check #done' --do 'check #exercises' --text '#state'
[vite] connecting...
[vite] connected.
-- fill #note verbs
-- check #done
-- check #exercises
== the text of #state
note = "verbs", done = true, kinds = [ "exercises" ]
```

A mesma diretiva fez três coisas diferentes, escolhidas pelo tipo de campo:

| campo | o valor que ele lê e escreve | o evento que ele escuta |
|---|---|---|
| input de texto, `<textarea>` | o texto, como string | `input`, a cada tecla |
| uma checkbox sozinha | `true` ou `false` | `change` |
| várias checkboxes com um array | o array dos `value`s marcados | `change` |
| botões de rádio | o `value` do escolhido | `change` |
| `<select>` | o `value` da opção escolhida (um array com `multiple`) | `change` |

**O ref é a verdade, e o atributo `value` do próprio campo no HTML é ignorado.** Se você escrever
`<input v-model="note" value="hello">`, o campo mostra o que `note` guarda e o atributo `value` é
ignorado. Os valores iniciais vão no ref.

## Um campo de texto dá uma string

Um campo devolve o que guarda, que é texto: digitar `45` num `<input v-model="minutes">` comum dá a
`minutes` o valor `"45"`, e `"45" + 15` é `"4515"`. O Vue abre uma exceção por conta própria: num
`<input type="number">`, o `v-model` converte o texto em número antes de gravá-lo. Em qualquer outro
campo, o modificador `.number` pede a mesma conversão; `.trim` tira os espaços das pontas; `.lazy`
atualiza no `change` em vez de a cada tecla. A aula 14 é sobre formulários, e mostra todos eles
funcionando.

## Onde o v-model não serve

O `v-model` escreve no ref, no lugar. Isso serve para um campo que *é* o estado, como uma nota sendo
digitada. Não serve para as sessões do planner, porque a aula 3 decidiu que a lista é substituída por
meio do `toggleDone` em vez de mudada no lugar; um `v-model` em `session.done` viraria a propriedade
dentro da lista pelas costas das regras. A última seção desta aula marca sessões como feitas com as
duas metades escritas por extenso, que é exatamente o que o `v-model` teria gerado.
