---
title: O slot padrão
version: 1
---

**Um slot é um buraco no template de um componente que o pai preenche com marcação própria.** Props
passam valores para baixo; um slot passa *conteúdo* para baixo, já escrito, para que um componente
possa ser uma moldura em volta de algo de que ele não sabe nada. Um card, um painel, um diálogo, um
botão com ícone: cada um decide onde o conteúdo vai e como ele é emoldurado, e o pai decide qual é o
conteúdo.

```html
<!-- src/demos/InfoCard.vue -->
<script setup>
const secret = 'the card'
</script>

<template>
  <div class="card">
    <slot>Nothing to show.</slot>
  </div>
</template>
```

```html
<!-- src/demos/DefaultSlot.vue -->
<script setup>
import InfoCard from './InfoCard.vue'

const course = 'Statistics'
</script>

<template>
  <InfoCard>
    <strong>{{ course }}</strong>: 45 of 180 minutes
  </InfoCard>
  <InfoCard />
  <InfoCard>The card's own variable is {{ typeof secret }} here.</InfoCard>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=DefaultSlot'
[vite] connecting...
[vite] connected.
[warn] [Vue warn]: Property "secret" was accessed during render but is not defined on instance. 
  at <InfoCard> 
  at <DefaultSlot>
== the text of #app
Statistics: 45 of 180 minutes
Nothing to show.
The card's own variable is undefined here.
```

Três cards, três lições:

- **O primeiro card desenhou a marcação do pai**, com negrito e tudo, dentro do próprio
  `<div class="card">`. O elemento `<slot>` foi substituído pelo que o pai escreveu entre `<InfoCard>` e
  `</InfoCard>`.
- **O segundo card não recebeu nada**, e desenhou o conteúdo reserva do slot, o texto escrito dentro de
  `<slot>…</slot>`. O conteúdo reserva é como um componente diz o que mostra quando o pai não tem nada a
  dizer.
- **O terceiro card tentou ler `secret`, a variável do próprio card, e não conseguiu.** O Vue avisou que
  `secret` não está definida, e o `typeof` deu `undefined`.

## As variáveis de quem

O terceiro card é a regra para guardar: **o conteúdo de um slot é compilado no escopo do pai.** Ele é
escrito no template do pai, então enxerga as variáveis do pai, `course` no primeiro card, e nenhuma
do filho, por mais perto que pareça na página. O filho posiciona o conteúdo; ele não empresta nada a
ele.

É uma fronteira de propósito, a mesma que o contrato de props da aula 6 traça. Quando um filho *quer*
entregar algo ao conteúdo, um valor que ele calculou, um item de uma lista que ele está percorrendo,
ele precisa dizer isso em voz alta, e um slot com escopo (duas seções adiante) é o jeito.

## Para que serve um slot

| o pai quer passar | use |
|---|---|
| um valor: um número, um título, uma sessão | uma prop |
| um pedaço de marcação: um título com um link dentro, uma lista, um formulário | um slot |
| uma escolha entre poucas aparências fixas | uma prop que nomeia a variante, não um slot |

A última linha importa porque slots são tentadores. Um botão que recebe o rótulo como slot pode
receber qualquer coisa, inclusive um segundo botão dentro dele, o que é HTML inválido e inutilizável
pelo teclado. Um slot dá liberdade ao pai; dê essa liberdade onde ela é necessária.
