---
title: reactive, e o proxy que ele devolve
version: 1
---

**`reactive()` recebe um objeto e devolve um Proxy dele: um substituto que se parece com o objeto e
relata ao Vue cada leitura e cada escrita.** Não há `.value`, porque o que é observado são as
propriedades do próprio objeto. Funciona só com objetos, arrays, Maps e Sets; `reactive(25)` não tem o
que observar, e a demonstração abaixo mostra o Vue dizendo isso.

```html
<!-- src/demos/ReactiveProxy.vue -->
<script setup>
import { reactive, isReactive } from 'vue'

const raw = { course: 'spanish', minutes: 30, tags: ['grammar'] }
const session = reactive(raw)

console.log(session === raw)
console.log(isReactive(session), isReactive(raw))
console.log(isReactive(session.tags))
console.log(reactive(25))

function viaProxy() {
  session.minutes += 10
}
function viaRaw() {
  raw.minutes += 10
  console.log(`raw.minutes is now ${raw.minutes}`)
}
</script>

<template>
  <p>{{ session.course }}: {{ session.minutes }} minutes</p>
  <button id="proxy" @click="viaProxy">Through the proxy</button>
  <button id="raw" @click="viaRaw">Through the original</button>
</template>
```

Clique no primeiro botão e depois no segundo:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ReactiveProxy' --do 'click #proxy' --do 'click #raw'
[vite] connecting...
[vite] connected.
false
true false
true
[warn] [Vue warn] value cannot be made reactive: 25
25
-- click #proxy
-- click #raw
raw.minutes is now 50
== the text of #app
spanish: 40 minutes

Through the proxyThrough the original
```

Leia primeiro as linhas de antes dos cliques:

- **`session === raw` é `false`.** O proxy é outro objeto. O Vue mantém um proxy por original, então
  `reactive(raw)` chamado duas vezes devolve o mesmo proxy, mas nunca o próprio original.
- **`isReactive(raw)` é `false`.** Criar um proxy não muda o objeto que ele embrulha.
- **`isReactive(session.tags)` é `true`.** Ler um objeto aninhado através do proxy devolve um proxy
  dele, criado na hora. É isso que "profundo" quer dizer aqui: por mais fundo que você mude algo, você
  passou por um proxy para chegar lá.

Por último vem `reactive(25)`: um aviso, e o número 25 devolvido sem mudança.

Depois, os cliques. O primeiro passou pelo proxy, 30 virou 40, e a página acompanhou. O segundo mudou
o original diretamente: `raw.minutes` é 50, e **a página ainda diz 40**. Nada avisou o Vue. Agora os
mesmos dois cliques e mais um pelo proxy:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ReactiveProxy' --do 'click #proxy' --do 'click #raw' --do 'click #proxy'
[vite] connecting...
[vite] connected.
false
true false
true
[warn] [Vue warn] value cannot be made reactive: 25
25
-- click #proxy
-- click #raw
raw.minutes is now 50
-- click #proxy
== the text of #app
spanish: 60 minutes

Through the proxyThrough the original
```

A página pulou para 60, recuperando os 10 que tinha perdido. Uma mudança feita pelas costas do Vue não
se perde, só fica invisível até que outra coisa provoque um redesenho. Isso é pior que perder, porque
parece que funciona.

**A regra: depois que um objeto se torna reativo, guarde só o proxy.** Jogue o original fora, ou nunca
dê um nome a ele: `const session = reactive({ … })`.

## ref ou reactive

Os dois criam estado reativo, e um `ref` que guarda um objeto usa `reactive` para o objeto. A
diferença está no que você pode fazer com a variável:

| | `ref` | `reactive` |
|---|---|---|
| guarda | qualquer valor | só objetos |
| leitura no script | `x.value` | `x.prop` |
| trocar a coisa inteira | `x.value = other` | impossível: a variável tem de continuar apontando para o proxy |
| desestruturar | o ref continua um ref | os pedaços deixam de ser reativos (próxima seção) |

**A documentação do Vue recomenda `ref` como padrão**, e este curso também. É mais longo de digitar e
tem menos jeitos de quebrar. `reactive` é agradável para um grupo de campos que sempre andam juntos,
como um formulário, e a aula 14 usa um para isso.
