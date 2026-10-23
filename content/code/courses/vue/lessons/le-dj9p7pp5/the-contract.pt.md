---
title: Um componente de campo, e o contrato do v-model
version: 1
---

**Um componente de campo de formulário envolve um input com o seu rótulo e o seu erro, e se junta ao
`v-model` do pai com `defineModel()`.** A aula 6 construiu o menor deles; este vale a pena ter, porque põe
o rótulo e a mensagem de erro ao lado do input num lugar só, conectados para um leitor de tela, de modo que
nenhum formulário do planner pode esquecer nenhum dos dois.

```html
<!-- src/demos/FormField.vue -->
<script setup>
import { useId } from 'vue'

defineOptions({ inheritAttrs: false })
const model = defineModel()
const { label, error } = defineProps({ label: String, error: String })

// One id per field, unique on the page: the label and the error point at it.
const id = useId()
</script>

<template>
  <div class="field">
    <label :for="id">{{ label }}</label>
    <input
      :id="id"
      v-model="model"
      v-bind="$attrs"
      :aria-invalid="error ? 'true' : undefined"
      :aria-describedby="error ? `${id}-error` : undefined"
    />
    <p v-if="error" :id="`${id}-error`" class="error">{{ error }}</p>
  </div>
</template>
```

Três coisas nele são novas:

- **`useId()`**, do Vue 3.5, dá a cada cópia do componente um id único na página, para que o
  `<label for>` chegue ao seu próprio input, e o erro ao seu próprio campo. Dois campos do mesmo formulário
  não podem mais dividir um id por serem cópias de um componente.
- **`inheritAttrs: false` e `v-bind="$attrs"`** mandam os atributos que o pai escreve, `type`, `min`,
  `max`, para o `<input>` em vez da `<div>` em volta, que o fallthrough da aula 6 teria escolhido.
- **`aria-invalid` e `aria-describedby`** amarram o erro ao campo. A seção sobre erros que um leitor de
  tela consegue ouvir, duas seções adiante, explica por quê.

Uma demo com dois campos, o segundo ligado ao computed gravável da aula 3, que prometeu encontrar o
`v-model` aqui:

```html
<!-- src/demos/FieldContract.vue -->
<script setup>
import { ref, computed } from 'vue'
import FormField from './FormField.vue'

const minutes = ref(300)
const error = computed(() => (minutes.value > 240 ? 'At most 240 minutes in one session.' : ''))

// Lesson 3's writable computed: the same value, edited in hours.
const hours = computed({
  get: () => minutes.value / 60,
  set: (value) => {
    minutes.value = Math.round(value * 60)
  },
})
</script>

<template>
  <FormField v-model.number="minutes" label="Minutes" type="number" min="5" max="240" :error="error" />
  <FormField v-model.number="hours" label="Hours" type="number" step="0.25" />
  <p id="value">minutes = {{ minutes }} ({{ typeof minutes }}), hours = {{ hours }}</p>
</template>
```

Ao abrir, com 300 minutos:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FieldContract' --html '.field' --text '#value'
[vite] connecting...
[vite] connected.
== the HTML of .field
<div class="field"><label for="v-0">Minutes</label><input id="v-0" type="number" min="5" max="240" aria-invalid="true" aria-describedby="v-0-error"><p id="v-0-error" class="error">At most 240 minutes in one session.</p></div>
== the text of #value
minutes = 300 (number), hours = 5
```

E com uma hora e meia digitada no campo de horas:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FieldContract' --do 'fill input[step] 1.5' --text '#value'
[vite] connecting...
[vite] connected.
-- fill input[step] 1.5
== the text of #value
minutes = 90 (number), hours = 1.5
```

**O campo de horas gravou 1.5, o computed gravável o transformou em 90 minutos, e o campo de minutos e o
seu erro acompanharam.** O `v-model.number` num componente passa o modificador para o componente, e o Vue
aplica a conversão ao valor que o componente emite. O `--html` mostra o erro ligado ao seu campo pelo id:
`aria-describedby="v-0-error"` no input, `id="v-0-error"` na mensagem.

## O contrato, mais uma vez

`v-model="x"` num componente é `:model-value="x"` e `@update:model-value="v => (x = v)"`, como a aula 6
mostrou; `defineModel()` é as duas metades do lado do filho. Um componente de campo que respeita isso pode
ser usado com qualquer ref, a propriedade de um objeto `reactive`, o estado de uma store ou um computed
gravável, e o pai nunca sabe a diferença.
