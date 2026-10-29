---
title: deep, immediate e once
version: 1
---

**Por padrão, um watcher num ref é raso, preguiçoso e permanente**: ele só percebe quando `.value` é
substituído, não roda até a primeira mudança e continua rodando até o componente sumir. Três opções
mudam cada uma dessas coisas, e vale ver os cinco watchers abaixo respondendo aos mesmos três cliques.

```html
<!-- src/demos/DeepAndOnce.vue -->
<script setup>
import { ref, reactive, watch } from 'vue'

const sessions = ref([{ course: 'statistics', minutes: 45 }])
const plan = reactive({ sessions: [{ course: 'statistics', minutes: 45 }] })

watch(sessions, () => console.log('shallow: the ref was replaced'))
watch(sessions, () => console.log('deep: something inside changed'), { deep: true })
watch(plan, () => console.log('a reactive object: something inside changed'))
watch(sessions, () => console.log('immediate: runs at once, and on every change'), { immediate: true })
watch(sessions, () => console.log('once: the first change, and never again'), { once: true, deep: true })

function push() {
  sessions.value.push({ course: 'guitar', minutes: 20 })
  plan.sessions.push({ course: 'guitar', minutes: 20 })
}
function replace() {
  sessions.value = [...sessions.value]
}
</script>

<template>
  <button id="push" @click="push">Push a session</button>
  <button id="replace" @click="replace">Replace the list</button>
</template>
```

Empurre, depois substitua, depois empurre de novo:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=DeepAndOnce' --do 'click #push' --do 'click #replace' --do 'click #push' --text -
[vite] connecting...
[vite] connected.
immediate: runs at once, and on every change
-- click #push
deep: something inside changed
once: the first change, and never again
a reactive object: something inside changed
-- click #replace
shallow: the ref was replaced
deep: something inside changed
immediate: runs at once, and on every change
-- click #push
deep: something inside changed
a reactive object: something inside changed
```

Leia por watcher:

| watcher | quando a página abriu | primeiro push | replace | segundo push |
|---|---|---|---|---|
| simples, no ref | | | disparou | |
| `deep: true` | | disparou | disparou | disparou |
| num objeto `reactive` | | disparou | | disparou |
| `immediate: true` | disparou | | disparou | |
| `once: true` (e deep) | | disparou | | |

**Um watcher simples perdeu os dois pushes.** O `push` muda o array que já está em `.value`; nada foi
substituído. É o bug do total sincronizado da aula 3, visto do lado do watcher.

**O `deep: true` viu tudo**, porque o Vue percorre o valor inteiro e registra uma leitura de cada
propriedade dentro dele, então uma mudança em qualquer lugar é uma mudança na fonte. **Um objeto
`reactive` é observado em profundidade sem você pedir**, pelo mesmo motivo: não há `.value` para ser
substituído, só propriedades. Repare que o watcher do reactive não disparou no `replace`, que mudou
só o ref.

**O `immediate: true` rodou uma vez logo de cara**, antes de qualquer mudança, e depois como um watcher
simples. Ele serve para um watcher cujo trabalho também precisa ser feito no começo: buscar os dados do
curso que você abriu, e de novo quando você abre outro.

**O `once: true` rodou na primeira mudança e nunca mais.** O Vue 3.4 o acrescentou; antes disso você
parava o watcher na mão, como a seção sobre parar watchers desta aula mostra.

## Quanto o deep custa

Para perceber uma mudança em qualquer lugar, um watcher deep lê tudo, a cada mudança: cada sessão, cada
campo de cada sessão. Para seis sessões isso não é nada. Para uma lista de dez mil linhas com objetos
aninhados, é um passeio pela árvore inteira toda vez que uma caixinha é marcada. Dois hábitos mais
baratos dão o mesmo resultado:

- **Substitua em vez de mudar**, como as regras do planner já fazem: `toggleDone` devolve um array novo,
  então um watcher simples no ref dispara, e nada precisa ser percorrido.
- **Observe só a coisa de que você precisa**, com um getter: `watch(() => sessions.value.length, …)`
  dispara quando a contagem muda e não lê mais nada.

O `deep` também aceita um número desde o Vue 3.5, `{ deep: 1 }`, para "o array e os itens dele, mas
não o que há dentro dos itens".
