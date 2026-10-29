---
title: O que isso custa, e o único uso que o planner faz disso
version: 1
---

**`provide` e `inject` tiram as props do meio, e com elas a única coisa que as props davam a você: uma
dependência que se vê.** Um componente que injeta algo deixa de dizer, nas props, tudo de que precisa.
Ele só funciona em algum lugar abaixo de quem provê, e nada na tag dele, onde ele é usado, diz isso.
Esse é o preço da saída de emergência, e só vale pagá-lo por valores que são mesmo ambiente.

## O que você perde

- **Visibilidade.** `<SessionRow :session="s" />` parece completo, e não está: ele também precisa dos
  títulos dos cursos, providos por algo acima dele. Um leitor descobre isso pelo script do componente,
  não pelo lugar onde ele é usado.
- **Portabilidade.** Mova o componente para outra parte da árvore, fora da subárvore de quem provê, e
  ele recebe o padrão, ou `undefined`. A mudança compila e roda.
- **Facilidade de testar.** Um teste de um componente que injeta precisa prover o valor também. A aula
  21 faz isso para o `SessionRow`, com a opção `global.provide` do Vue Test Utils, e é mais uma coisa
  para saber.

## Quando vale a pena

| o valor é | passe como |
|---|---|
| usado pelo componente que o tem e pelos filhos dele | props |
| usado dois ou três níveis abaixo, por componentes que também precisam de outras props do mesmo pai | props; o drilling é curto e honesto |
| usado em muitas profundidades, definido num lugar só para uma subárvore inteira | `provide` / `inject` |
| compartilhado pela aplicação inteira e alterado de muitos lugares | uma store, aula 13 |

A última linha é onde a maior parte dos "preciso de provide para isso" acaba. Uma store é provide e
inject com regras: um módulo é dono do estado, tudo o que o altera é uma action com nome, e as
ferramentas do Vue no navegador mostram cada mudança. A aula 13 move as sessões do planner para uma.

## Os títulos do planner

Os títulos dos cursos são uma consulta de que toda linha de sessão precisa, em qualquer profundidade em
que as linhas acabem, e que só o `App` consegue montar, porque só o `App` carrega os cursos. É a terceira
linha da tabela, então o `App` os provê. Primeiro, a chave:

```javascript
// src/keys.js: the keys the planner provides values under. A Symbol is unique,
// so no other code can provide or inject under the same key by accident.
export const titlesKey = Symbol('course titles')
```

O `App.vue` ganha duas linhas: `provide` nos imports, e a chamada em si, logo depois de `titles` ser
declarado. Ele também para de passar `:title` a cada linha:

```javascript
provide(titlesKey, titles)
```

`titles` é um `computed` sem setter, então já é só de leitura, e as linhas o acompanham quando os cursos
chegam. O `SessionRow` perde a prop `title` e injeta a consulta no lugar:

```html
<!-- src/components/SessionRow.vue -->
<script setup>
import { computed, inject } from 'vue'
import { formatDay } from '../planner.js'
import { titlesKey } from '../keys.js'

const { session } = defineProps({
  session: { type: Object, required: true },
})
const emit = defineEmits(['toggle'])

// The titles of every course, provided by App. Without a provider, the id is
// shown instead of the title, rather than nothing.
const titles = inject(titlesKey, null)
const title = computed(() => titles?.value[session.course] ?? session.course)
</script>

<template>
  <li :class="{ done: session.done }">
    <label>
      <input type="checkbox" :checked="session.done" @change="emit('toggle', session.id)" />
      {{ formatDay(session.date) }}, {{ title }}, {{ session.minutes }} minutes
    </label>
  </li>
</template>

<style scoped>
.done {
  text-decoration: line-through;
}
</style>
```

O padrão é `null`, e o título cai para o id do curso, `statistics`, quando não há quem proveja: a
terceira resposta da tabela da seção anterior. `titles?.value` lê o `computed` injetado pelo `.value`
dele, porque um ref injetado não é desembrulhado no script, só no template.

Com o servidor do planner rodando, a lista fica exatamente como antes:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --text 'main section:nth-child(2) ul'
[vite] connecting...
[vite] connected.
== the text of main section:nth-child(2) ul
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
```

**A tela não mudou, e era essa a ideia**: os títulos agora chegam às linhas sem passar pela lista que as
contém. Se isso é melhor é o julgamento desta seção. Para uma consulta de que toda linha precisa e nada
mais precisa, é. Para `session`, que é toda a razão de a linha existir, uma prop continua sendo a
resposta certa, e continuou sendo uma.
