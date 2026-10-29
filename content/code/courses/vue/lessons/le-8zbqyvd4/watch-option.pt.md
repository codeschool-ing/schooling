---
title: A opção watch
version: 1
---

**A opção `watch` é um objeto cujas chaves nomeiam o que observar e cujos valores dizem o que fazer.**
É o `watch` da aula 4 com a fonte escrita como string, e a demo da seção anterior usou a forma mais
simples: `minutes(now, before) {}` rodou quando `this.minutes` mudou, e imprimiu `30 -> 45`.

As formas que você vai ler:

```javascript
watch: {
  // A data property or a prop, by name.
  minutes(now, before) {
    console.log(`${before} -> ${now}`)
  },

  // A nested property, by its path as a string.
  'session.minutes'(now) {
    this.save()
  },

  // With options: deep, immediate, flush, as in lesson 4.
  sessions: {
    handler(list) {
      localStorage.setItem('planner.sessions', JSON.stringify(list))
    },
    deep: true,
    immediate: true,
  },
},
```

Cada linha corresponde diretamente à Composition API:

| opção `watch` | `watch()` |
|---|---|
| `minutes(now, before) {}` | `watch(minutes, (now, before) => {})` |
| `'session.minutes'(now) {}` | `watch(() => session.value.minutes, (now) => {})` |
| `sessions: { handler, deep: true }` | `watch(sessions, handler, { deep: true })` |

## Duas diferenças que importam na tradução

**Um array ou objeto observado também é raso na forma de opção**, a menos que se diga `deep: true`, que
é o problema do push da aula 4 com outra grafia: `sessions(list) {}` não roda com
`this.sessions.push(…)`. O Vue 3 deixou isso mais estrito que o Vue 2, que observava mutações em arrays
por padrão, então um watcher num array que "parou de funcionar" depois de uma atualização para o Vue 3
está sem `deep: true`.

**Não há `watchEffect` nas opções.** O mais próximo é `this.$watch(() => …, handler)`, chamado em
`created`, que devolve uma função de parada. Um componente que precisa de rastreamento automático, ou de
watchers criados sob condição, é candidato à opção `setup()` do fim desta aula.
