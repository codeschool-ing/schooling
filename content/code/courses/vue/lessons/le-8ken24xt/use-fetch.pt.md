---
title: Um composable que busca dados
version: 1
---

**Um composable que busca dados recebe um endereço, que pode mudar, e devolve os dados, o erro e se
está carregando, como refs; quando o endereço muda, ele cancela a requisição velha e começa uma nova.**
É o watcher cuidadoso da aula 4, embrulhado uma vez para que nenhum componente precise escrevê-lo de
novo.

```javascript
// src/demos/useFetchJson.js: fetch JSON from an address that may change.
import { ref, watchEffect, toValue, onWatcherCleanup } from 'vue'

export function useFetchJson(url) {
  const data = ref(null)
  const error = ref(null)
  const loading = ref(false)

  watchEffect(async () => {
    const address = toValue(url)
    const controller = new AbortController()
    onWatcherCleanup(() => controller.abort())
    loading.value = true
    error.value = null
    try {
      const response = await fetch(address, { signal: controller.signal })
      if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)
      data.value = await response.json()
    } catch (e) {
      if (e.name === 'AbortError') {
        console.log(`gave up on ${address}: a newer address was asked for`)
        return
      }
      error.value = e.message
    }
    loading.value = false
  })

  return { data, error, loading }
}
```

É um `watchEffect`, então roda na hora e de novo sempre que muda o que ele leu antes do primeiro
`await`. Isso é só `toValue(url)`, lido na primeira linha, de propósito: o endereço é a única entrada,
e tudo depois do `await` já está fora da janela de rastreamento de qualquer forma. A limpeza aborta a
requisição da execução anterior, e uma requisição abortada não é um erro que o usuário deva ver, então
ela é registrada no console e descartada.

O sandbox precisa de algo para buscar. Dois arquivos pequenos, na pasta `public/notes` dele:

```json
{ "course": "statistics", "notes": ["mean", "median", "variance"] }
```

salvo como `public/notes/statistics.json`, e

```json
{ "course": "spanish", "notes": ["ser and estar", "the subjunctive"] }
```

salvo como `public/notes/spanish.json`. Depois, um componente que pede as notas do curso escolhido:

```html
<!-- src/demos/FetchDemo.vue -->
<script setup>
import { ref } from 'vue'
import { useFetchJson } from './useFetchJson.js'

const course = ref('statistics')
const { data, error, loading } = useFetchJson(() => `/notes/${course.value}.json`)
</script>

<template>
  <button id="spanish" @click="course = 'spanish'">Spanish</button>
  <button id="nope" @click="course = 'nope'">A course with no notes</button>
  <p v-if="loading">Loading…</p>
  <p v-else-if="error">Could not load: {{ error }}</p>
  <p v-else-if="data">{{ data.course }}: {{ data.notes.join(', ') }}</p>
</template>
```

Três execuções: ao abrir, depois de escolher Spanish, e depois de escolher um curso que não tem notas.

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FetchDemo'
[vite] connecting...
[vite] connected.
== the text of #app
SpanishA course with no notes

statistics: mean, median, variance
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FetchDemo' --do 'click #spanish'
[vite] connecting...
[vite] connected.
-- click #spanish
== the text of #app
SpanishA course with no notes

spanish: ser and estar, the subjunctive
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FetchDemo' --do 'click #nope'
[vite] connecting...
[vite] connected.
-- click #nope
== the text of #app
SpanishA course with no notes

Could not load: Unexpected token '<', "<!DOCTYPE "... is not valid JSON
```

O componente não tem `fetch`, nem `watch`, nem limpeza. Ele nomeia a sua entrada, como um getter, e
desenha os três refs que recebeu de volta. **A terceira execução é a lição da aula 2 num lugar novo**:
o endereço não existe, o servidor de desenvolvimento respondeu com a página, e o composable informou o
erro de JSON que isso causou. O composable não consegue distinguir um arquivo que falta de um arquivo
quebrado; só um servidor que respondesse 404 para um arquivo que falta conseguiria.

## Duas melhorias que ele não faz

Uma aplicação de verdade ia querer mais, e cada uma é um motivo para recorrer a uma biblioteca em vez de
fazer esta crescer à mão:

- **Um cache.** Dois componentes pedindo o mesmo endereço fazem duas requisições. Bibliotecas como
  TanStack Query e Pinia Colada guardam as respostas por endereço e as compartilham.
- **Uma nova tentativa, e uma atualização sob demanda.** Um `refresh()` devolvido ao lado dos dados,
  como fazem os composables do Nuxt da aula 20.

Para o planner, que carrega um arquivo uma vez, nenhuma das duas é necessária. O composable de dados do
próprio planner, no fim desta aula, é ainda mais simples.
