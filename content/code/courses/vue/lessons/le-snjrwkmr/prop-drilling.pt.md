---
title: Prop drilling
version: 1
---

**Prop drilling é passar um valor por componentes que não o usam, só para que um componente mais
abaixo possa usá-lo.** Cada camada no meio ganha uma prop com que não se importa, precisa nomeá-la,
repassá-la e mudar quando ela muda. Numa árvore de três níveis é um incômodo; numa de oito níveis é o
motivo de uma mudança simples mexer em oito arquivos.

Aqui está ele na forma mais curta: um pai quer que as folhas mostrem horas, e o componente do meio,
que desenha a lista, é obrigado a carregar a unidade junto.

```html
<!-- src/demos/DrillLeaf.vue -->
<script setup>
defineProps({ minutes: Number, unit: String })
</script>

<template>
  <li>{{ unit === 'hours' ? minutes / 60 : minutes }} {{ unit }}</li>
</template>
```

```html
<!-- src/demos/DrillMiddle.vue -->
<script setup>
import DrillLeaf from './DrillLeaf.vue'

// This component never uses `unit`. It only passes it on.
defineProps({ sessions: Array, unit: String })
</script>

<template>
  <ul>
    <DrillLeaf v-for="s in sessions" :key="s.id" :minutes="s.minutes" :unit="unit" />
  </ul>
</template>
```

```html
<!-- src/demos/PropDrilling.vue -->
<script setup>
import DrillMiddle from './DrillMiddle.vue'

const sessions = [
  { id: 's2', minutes: 45 },
  { id: 's4', minutes: 60 },
]
</script>

<template>
  <DrillMiddle :sessions="sessions" unit="hours" />
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=PropDrilling'
[vite] connecting...
[vite] connected.
== the text of #app
0.75 hours
1 hours
```

Funciona, e as folhas mostram 0.75 e 1 hours. **O custo está no `DrillMiddle`**: o comentário dele diz
que ele nunca usa `unit`, e mesmo assim `unit` está nas props e no template dele, e quem o lê precisa
descobrir que ele só está repassando. Acrescente uma segunda configuração de que as folhas precisam,
um formato de data, por exemplo, e o do meio ganha mais uma prop que não usa.

## Drilling muitas vezes não tem problema

A palavra soa como acusação, e na maior parte das vezes não é. Props são explícitas: lendo o
`DrillMiddle` você vê exatamente o que ele recebe e o que entrega para baixo, e um teste pode dar a ele
a unidade que quiser. Dois ou três níveis repassando um valor são o custo normal de um fluxo de dados
claro, e a aula 6 chamou esse fluxo de contrato.

Vira problema quando o valor é **ambiente**, necessário a muitos componentes em muitas profundidades e
definido num lugar só para todos eles:

- uma configuração que vale para uma parte inteira da árvore: uma unidade, um idioma, um tema, uma
  densidade;
- um serviço que todo componente de uma funcionalidade usa: o usuário atual, o estado de um formulário,
  um conjunto de consultas como os títulos dos cursos do planner;
- algo que os componentes de uma biblioteca compartilham entre si: um grupo de abas e as abas dele, um
  formulário e os campos dele.

Para esses, o Vue tem um jeito de pular as camadas do meio, que é a próxima seção.
