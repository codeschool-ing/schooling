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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 255\" role=\"img\" aria-label=\"A demo OneWay. O pai, OneWay.vue, tem minutes, 30, e session, que aponta para o próprio objeto reativo dele, com course spanish e minutes 30. Os dois descem como props para o Counter.vue, cujas props são somente leitura. A prop session dele aponta para o mesmo objeto, não para uma cópia. Escrever props.minutes mais 5 é recusado com um aviso, e o pai continua com 30. Escrever props.session.minutes mais 5 é permitido: muda o objeto do pai, e os minutos vão de 30 a 35 no filho e no pai.\"><rect x=\"20\" y=\"30\" width=\"180\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">OneWay.vue</text><text x=\"110\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o pai</text><text x=\"110\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">minutes: 30</text><text x=\"110\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">session</text><rect x=\"520\" y=\"30\" width=\"180\" height=\"110\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">Counter.vue</text><text x=\"610\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">props somente leitura</text><text x=\"610\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">minutes: 30</text><text x=\"610\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">session</text><line x1=\"202\" y1=\"88\" x2=\"516\" y2=\"88\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"516.0,88.0 508.6,91.1 508.6,84.9\" fill=\"var(--wire)\"></polygon><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passados como props</text><rect x=\"240\" y=\"168\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"355\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">{ course: 'spanish',</text><text x=\"355\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">  minutes: 30 → 35 }</text><text x=\"355\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o objeto reativo do pai, uma cópia só</text><line x1=\"110\" y1=\"142\" x2=\"270\" y2=\"166\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"270.0,166.0 262.3,168.0 263.2,161.8\" fill=\"var(--phosphor)\"></polygon><line x1=\"560\" y1=\"142\" x2=\"445\" y2=\"166\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"445.0,166.0 451.6,161.4 452.8,167.5\" fill=\"var(--phosphor)\"></polygon><text x=\"525\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">props.minutes += 5</text><text x=\"525\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">recusado; o pai continua com 30</text><text x=\"525\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">props.session.minutes += 5</text><text x=\"525\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">permitido: 35 nos dois</text></svg>", "caption": "O objeto das props é somente leitura num nível só; o objeto para onde uma prop aponta continua sendo do pai."}
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
