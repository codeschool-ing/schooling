---
title: Setup ou onMounted
version: 1
---

**Trabalho que precisa da página vai no `onMounted`; todo o resto vai no setup.** A pergunta aparece
mais quando o assunto é carregar dados, e a resposta ali surpreende quem aprendeu React primeiro: comece
a requisição no setup, não no `onMounted`.

```html
<!-- src/demos/SetupOrMounted.vue -->
<script setup>
import { onMounted } from 'vue'

console.log(`setup: the heading is ${document.querySelector('h2')}`)
fetch('/courses.json').then(() => console.log('setup: the request started in setup has answered'))
onMounted(() => {
  console.log(`mounted: the heading is ${document.querySelector('h2').outerHTML}`)
})
</script>

<template>
  <h2>Statistics</h2>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=SetupOrMounted' --text -
[vite] connecting...
[vite] connected.
setup: the heading is null
mounted: the heading is <h2>Statistics</h2>
setup: the request started in setup has answered
```

- **No setup, o título é `null`**: o template não foi renderizado. Tudo o que precisa de um elemento
  espera o `onMounted`.
- **No `onMounted`, o título está lá.**
- **A requisição começada no setup respondeu depois dos dois.** Ela foi enviada antes de o componente
  sequer estar na página, então estava a caminho enquanto o Vue renderizava e montava. Começá-la no
  `onMounted` teria esperado a renderização antes, sem ganhar nada: uma requisição não precisa da página.

O planner carrega os cursos assim desde a aula 2, com o `fetch` no nível de cima do script.

## Por que o código React faz o contrário

O corpo de um componente React roda a cada renderização, então uma requisição escrita ali seria enviada
a cada renderização. O código React começa as requisições num effect, que roda depois da renderização,
uma vez. O setup do Vue roda uma vez por construção (aula 2), então o motivo não se aplica, e mover a
requisição para o `onMounted` só a atrasa. **Traga a intenção, não o hook.**

## O caso que decide isso mais tarde

As aulas 18 a 20 renderizam o planner num servidor. **No servidor, o setup roda e o `onMounted`
não**: não há página onde montar. Então o código no setup roda nos dois lugares, e o código no
`onMounted` roda só no navegador. Uma requisição no setup vai ser feita no servidor, o que muitas vezes é
o que você quer e é a base do `useFetch` do Nuxt (aula 20); uma chamada a `localStorage` ou a `window`
no setup vai falhar no servidor, porque nenhum dos dois existe lá. Quando o planner passar para o Nuxt,
as leituras de `localStorage` dele vão para o `onMounted` exatamente por esse motivo.
