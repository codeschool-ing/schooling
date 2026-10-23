---
title: Num sentido só, para baixo
version: 1
---

**Props correm num sentido só: o pai é dono do valor, e o filho só o lê.** Se o filho pudesse mudar uma
prop, o estado do pai mudaria pelas costas dele, e um valor usado por cinco filhos seria mudado por
quem escrevesse por último. Por isso o Vue deixa o objeto de props somente leitura, e um filho que
precisa mudar alguma coisa pede ao pai, com um evento (próxima seção).

```html
<!-- src/demos/Counter.vue -->
<script setup>
const props = defineProps({
  minutes: Number,
  session: Object,
})

function addToNumber() {
  props.minutes += 5
}
function addInsideObject() {
  props.session.minutes += 5
}
</script>

<template>
  <p>Child sees {{ minutes }} and {{ session.minutes }}</p>
  <button id="number" @click="addToNumber">Change the number prop</button>
  <button id="object" @click="addInsideObject">Change inside the object prop</button>
</template>
```

```html
<!-- src/demos/OneWay.vue -->
<script setup>
import { ref } from 'vue'
import Counter from './Counter.vue'

const minutes = ref(30)
const session = ref({ course: 'spanish', minutes: 30 })
</script>

<template>
  <Counter :minutes="minutes" :session="session" />
  <p id="parent">Parent has {{ minutes }} and {{ session.minutes }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=OneWay' --do 'click #number' --do 'click #object'
[vite] connecting...
[vite] connected.
-- click #number
[warn] [Vue warn] Set operation on key "minutes" failed: target is readonly. Proxy(Object)
-- click #object
== the text of #app
Child sees 30 and 35

Change the number propChange inside the object prop

Parent has 30 and 35
```

**Atribuir à prop numérica foi recusado**, com um aviso, e o pai continua com 30. **Mudar uma propriedade
dentro da prop objeto não foi recusado**: os minutos da sessão foram de 30 para 35, no filho *e no pai*.
O objeto de props é somente leitura um nível só, a propriedade `session` em si; o objeto para o qual
ela aponta é o próprio objeto reativo do pai, e o filho mexeu dentro dele.

Esse segundo caso é o perigoso, porque funciona. Nada avisa, a tela está certa, e os dados do pai foram
mudados por um componente que só deveria mostrá-los. Quando isso causa um bug, o bug é procurado no
pai, que não tem nenhuma linha que mude os minutos. **Trate uma prop objeto como somente leitura até o
fundo**, como se ela tivesse sido congelada.

## Quando o filho precisa da sua própria cópia

Duas necessidades legítimas parecem mudar uma prop, e nenhuma muda:

- **Um valor inicial de que o filho passa a ser dono**, como o texto inicial de um campo que o aluno vai
  editar. Copie-o para um ref uma vez: `const draft = ref(props.initial)`. Daí em diante ele é do
  filho, e uma mudança posterior no pai não chega até ele, que é o que "initial" quer dizer.
- **Um valor derivado de uma prop**, como uma porcentagem. Isso é um `computed` da prop, aula 3, e ele
  acompanha o pai para sempre.

Se nenhuma serve, o filho está tentando mudar o estado do pai, e a próxima seção é como ele pede.
