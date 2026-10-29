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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 235\" role=\"img\" aria-label=\"A demo FieldContract depois de 1.5 ser digitado no campo das horas. O FormField das horas emite update:modelValue com 1.5. O computed gravável hours roda o seu setter, que escreve minutes como 1.5 vezes 60, arredondado: 90. O ref minutes agora é 90. A partir dele, o campo dos minutos mostra 90, e o computed error, que só tem mensagem acima de 240 minutos, fica vazio, então o erro do campo dos minutos some. O getter de hours, 90 dividido por 60, devolve 1.5.\"><text x=\"95\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">FormField</text><rect x=\"20\" y=\"34\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o campo Minutes</text><text x=\"95\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">90</text><rect x=\"20\" y=\"140\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"95\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o campo Hours</text><text x=\"95\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1.5 digitado</text><rect x=\"290\" y=\"34\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">minutes</text><text x=\"375\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ref: 300 → 90</text><rect x=\"290\" y=\"140\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"375\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">hours</text><text x=\"375\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">computed gravável</text><rect x=\"540\" y=\"34\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">error</text><text x=\"620\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">vazio: 90 não passa de 240</text><line x1=\"172\" y1=\"168\" x2=\"286\" y2=\"168\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"286.0,168.0 278.6,171.1 278.6,164.9\" fill=\"var(--amber)\"></polygon><text x=\"230\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">update:modelValue</text><line x1=\"375\" y1=\"138\" x2=\"375\" y2=\"94\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"375.0,94.0 378.1,101.4 371.9,101.4\" fill=\"var(--amber)\"></polygon><text x=\"385\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">set: × 60, arredondado</text><line x1=\"288\" y1=\"62\" x2=\"174\" y2=\"62\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"174.0,62.0 181.4,58.9 181.4,65.1\" fill=\"var(--phosphor)\"></polygon><text x=\"230\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">:model-value</text><line x1=\"462\" y1=\"62\" x2=\"536\" y2=\"62\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"536.0,62.0 528.6,65.1 528.6,58.9\" fill=\"var(--wire)\"></polygon><text x=\"375\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">get: 90 / 60 = 1.5, de volta no campo Hours</text></svg>", "caption": "Uma escrita sobe pelo contrato, e tudo o que lê minutes a acompanha."}
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
