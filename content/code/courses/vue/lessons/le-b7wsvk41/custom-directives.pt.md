---
title: Uma diretiva sua
version: 1
---

**Uma diretiva personalizada é um objeto de hooks que o Vue chama sobre o elemento em que ela está, e
ela existe para o trabalho raro que precisa do elemento real do DOM e de nada mais.** Pôr o foco num
campo quando ele aparece é o exemplo clássico. A maioria das coisas que parecem uma diretiva ficam
melhores como componente ou como composable (aula 10), e a documentação do Vue também diz isso; esta
seção existe para que você consiga ler uma e escrever as pequenas.

```html
<!-- src/demos/FocusDirective.vue -->
<script setup>
import { onMounted } from 'vue'

// A directive is an object of hooks. Named vSomething, it is used as v-something.
const vFocus = {
  mounted: (el) => el.focus(),
}

onMounted(() => console.log(`focus is on #${document.activeElement.id}`))
</script>

<template>
  <label>Course <input id="course" /></label>
  <label>Minutes <input id="minutes" v-focus /></label>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FocusDirective' --text -
[vite] connecting...
[vite] connected.
focus is on #minutes
```

**O foco foi para o segundo campo, `minutes`, porque é lá que o `v-focus` está**, e não para o primeiro
campo da página. Essa é a diretiva inteira: assim que o elemento foi posto na página, o hook `mounted`
dela rodou com o elemento e chamou `focus()` nele.

## Os hooks

Um objeto de diretiva pode ter qualquer um destes, cada um chamado com o elemento e um `binding` que
carrega o valor escrito depois do `=`:

| hook | quando |
|---|---|
| `created` | antes de os atributos e listeners do elemento serem aplicados |
| `beforeMount`, `mounted` | antes e depois de o elemento ser posto na página |
| `beforeUpdate`, `updated` | antes e depois de o componente em volta dele se redesenhar |
| `beforeUnmount`, `unmounted` | antes e depois de o elemento ser removido |

`mounted` e `updated` são quase tudo o que as diretivas usam, e quando os dois fazem a mesma coisa uma
diretiva pode ser uma função simples, que o Vue chama para os dois: `const vColour = (el, binding) => { el.style.color =
binding.value }`, usada como `v-colour="'#2f6f4e'"`.

## A regra do nome

No `<script setup>`, **qualquer variável cujo nome começa com `v` seguido de uma letra maiúscula fica
disponível como diretiva**, `vFocus` como `v-focus`. Nada precisa ser registrado. Uma diretiva usada
na aplicação inteira é registrada uma vez no `main.js`, com `app.directive('focus', vFocus)`.

## Quando o foco é coisa de uma diretiva e quando não é

Mover o foco é uma decisão de acessibilidade tanto quanto uma conveniência. Pôr o foco no primeiro
campo de um formulário que o aluno acabou de abrir ajuda; pôr o foco num campo ao carregar a página,
antes de o aluno ter feito qualquer coisa, tira um usuário de leitor de tela do começo da página sem
avisá-lo, o que é o contrário de ajudar. Use isso em algo que apareceu porque o aluno pediu.
