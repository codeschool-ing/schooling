---
title: O ciclo de vida, pelos nomes antigos
version: 1
---

**Todo hook de ciclo de vida da aula 9 existe na Options API como uma opção com o mesmo nome sem o
`on`: `mounted()`, `updated()`, `unmounted()`.** Dois deles não têm par na Composition API, e são os
dois que você mais vai ver em código antigo: `beforeCreate` e `created`.

```html
<!-- src/demos/OptionsLifecycle.vue -->
<script>
export default {
  data() {
    return { minutes: 30 }
  },
  watch: {
    minutes(now, before) {
      console.log(`watch: ${before} -> ${now}`)
    },
  },
  beforeCreate() {
    console.log(`beforeCreate: minutes is ${this.minutes}`)
  },
  created() {
    console.log(`created: minutes is ${this.minutes}, the element is ${this.$el}`)
  },
  mounted() {
    console.log(`mounted: the element is a ${this.$el.nodeName}`)
  },
  beforeUnmount() {
    console.log('beforeUnmount')
  },
}
</script>

<template>
  <p>{{ minutes }} minutes</p>
  <button @click="minutes += 15">15 more</button>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=OptionsLifecycle' --do 'click button' --text -
[vite] connecting...
[vite] connected.
beforeCreate: minutes is undefined
created: minutes is 30, the element is null
mounted: the element is a #text
-- click button
watch: 30 -> 45
```

Os quatro momentos da transcrição:

- **`beforeCreate`: `minutes` é `undefined`.** A instância existe e `data` ainda não foi montado. Quase
  nada tem lugar aqui.
- **`created`: `minutes` é 30, e o elemento é `null`.** O estado existe e nada foi renderizado. É aqui
  que código Options API começa suas requisições, e é exatamente o que o código do nível de cima do
  `<script setup>` é: a aula 9 disse que o setup *é* a criação.
- **`mounted`: o elemento é um `#text`.** Surpreendente, e vale uma linha: `this.$el` é o nó raiz do
  componente, e este componente tem duas raízes, um `<p>` e um `<button>`. Um componente com várias
  raízes não tem um elemento único, então o Vue aponta `$el` para um nó de texto vazio que ele usa como
  marcador. Código escrito para o Vue 2, em que um componente sempre tinha exatamente uma raiz, muitas
  vezes supõe que `$el` é esse elemento raiz; com um componente de várias raízes no Vue 3, essa
  suposição quebra. Um template ref, da aula 9, nomeia o elemento que você quer de verdade.
- **O watcher** imprimiu `30 -> 45`, o assunto da próxima seção.

## Os nomes, lado a lado

| Options API | Composition API |
|---|---|
| `beforeCreate`, `created` | o nível de cima do `<script setup>` |
| `beforeMount`, `mounted` | `onBeforeMount`, `onMounted` |
| `beforeUpdate`, `updated` | `onBeforeUpdate`, `onUpdated` |
| `beforeUnmount`, `unmounted` | `onBeforeUnmount`, `onUnmounted` |
| `activated`, `deactivated` | `onActivated`, `onDeactivated` |

O Vue 2 chamava os dois hooks de remoção de `beforeDestroy` e `destroyed`. O Vue 3 os renomeou;
código que ainda usa os nomes antigos é código cuja migração não terminou, e a limpeza dele nunca roda.
