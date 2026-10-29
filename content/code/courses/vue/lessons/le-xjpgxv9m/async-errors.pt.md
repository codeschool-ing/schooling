---
title: Quando a espera falha
version: 1
---

**Um setup assíncrono que lança um erro, uma requisição que falha ou um JSON que não se interpreta,
rejeita; e uma rejeição é capturada pelo ancestral mais próximo que tenha `onErrorCaptured`.** O
`<Suspense>` em si não tem slot de erro, então o estado de erro é trabalho de um componente: capturar,
lembrar e desenhar outra coisa no lugar do Suspense.

```html
<!-- src/demos/ErrorsDemo.vue -->
<script setup>
import { ref, onErrorCaptured } from 'vue'
import SlowCourse from './SlowCourse.vue'

const problem = ref('')
onErrorCaptured((error) => {
  problem.value = `The notes could not be loaded: ${error.message}`
  return false
})
</script>

<template>
  <p v-if="problem" role="alert">{{ problem }}</p>
  <Suspense v-else>
    <SlowCourse id="guitar" />
    <template #fallback><p>Loading the notes…</p></template>
  </Suspense>
</template>
```

Guitar não tem arquivo de notas:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ErrorsDemo'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of #app
The notes could not be loaded: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

O endereço `/notes/guitar.json` não existe, o servidor de dev respondeu com a página, como a aula 2
mostrou, e o `response.json()` falhou no `<`. O erro subiu a partir do `SlowCourse`, passou pelo
Suspense e chegou ao `onErrorCaptured` do `ErrorsDemo`, que guardou a mensagem e retornou `false`.

## O que o hook recebe e retorna

O `onErrorCaptured((error, instance, info) => …)` recebe o erro, o componente que o lançou e uma string
curta dizendo onde ele foi lançado: uma função de setup, um render, um watcher. Ele roda para erros em
qualquer descendente, e **retornar `false` impede o erro de seguir adiante**: sem isso, o erro
continuaria até o handler da própria aplicação, o `app.config.errorHandler`, e seria registrado como não
capturado, além de tratado.

Dois hábitos fazem isso funcionar:

- **Ponha a fronteira onde o estudante ainda pode fazer alguma coisa**: em volta da parte da página que
  falhou, para que o resto continue funcionando, com uma mensagem que diga o que está faltando. Uma
  fronteira na raiz transforma qualquer falha pequena numa aplicação em branco.
- **Mostre o erro numa live region**, `role="alert"` como a demo faz, para que um leitor de tela o
  anuncie quando ele substituir o texto de carregamento.

O React tem a mesma ideia com o nome *error boundary*, e o `react-ts` dá a ela uma aula própria; no Vue
ela é um hook que qualquer componente pode usar, e não um tipo especial de componente.
