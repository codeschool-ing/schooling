---
title: O formulário do planner, inteiro
version: 1
---

**A página da semana do planner ganha um terceiro painel, *Add a session*, com o formulário que esta aula
construiu em partes.** São dois componentes: o campo da seção do contrato, agora em `src/components` do
planner, e o formulário que o usa.

## FormField, com um slot para um select

A versão do campo no planner acrescenta uma coisa à do sandbox: um slot com escopo, da aula 7, para que um
campo que não é um `<input>`, como o `<select>` de curso, possa ser envolvido com o mesmo rótulo e o mesmo
erro. O slot entrega ao conteúdo o seu `id`, se ele está inválido, e o id da sua mensagem:

```html
<!-- src/components/FormField.vue -->
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
    <slot :id="id" :invalid="Boolean(error)" :described-by="error ? `${id}-error` : undefined">
      <input
        :id="id"
        v-model="model"
        v-bind="$attrs"
        :aria-invalid="error ? 'true' : undefined"
        :aria-describedby="error ? `${id}-error` : undefined"
      />
    </slot>
    <p v-if="error" :id="`${id}-error`" class="error">{{ error }}</p>
  </div>
</template>

<style scoped>
.field {
  margin-bottom: 0.75rem;
}
label {
  display: block;
  font-weight: 600;
}
.error {
  color: #a3261b;
  margin: 0.25rem 0 0;
}
</style>
```

## SessionForm

```html
<!-- src/components/SessionForm.vue -->
<script setup>
import { reactive, ref, computed, useTemplateRef } from 'vue'
import FormField from './FormField.vue'
import { usePlannerStore } from '../stores/planner.js'
import { formatDay } from '../planner.js'

const { date: firstDate } = defineProps({ date: { type: String, required: true } })
const planner = usePlannerStore()

// The fields travel together, so they are one reactive object (lesson 2).
const draft = reactive({ course: '', date: firstDate, minutes: 30 })
const tried = ref(false)
const saved = ref('')
const courseField = useTemplateRef('course')

const errors = computed(() => ({
  course: draft.course ? '' : 'Choose a course.',
  date: draft.date ? '' : 'Choose a date.',
  minutes:
    Number.isInteger(draft.minutes) && draft.minutes >= 5 && draft.minutes <= 240
      ? ''
      : 'Between 5 and 240 whole minutes.',
}))
const valid = computed(() => Object.values(errors.value).every((e) => e === ''))
// Errors are shown only once the student has tried to submit.
const shown = computed(() => (tried.value ? errors.value : {}))

function submit() {
  tried.value = true
  if (!valid.value) {
    saved.value = ''
    return
  }
  planner.add({ ...draft })
  saved.value = `Added ${draft.minutes} minutes of ${planner.titles[draft.course]} on ${formatDay(draft.date)}.`
  Object.assign(draft, { course: '', minutes: 30 })
  tried.value = false
  courseField.value.focus()
}
</script>

<template>
  <form novalidate @submit.prevent="submit">
    <FormField label="Course" :error="shown.course">
      <template #default="{ id, invalid, describedBy }">
        <select
          :id="id"
          ref="course"
          v-model="draft.course"
          :aria-invalid="invalid ? 'true' : undefined"
          :aria-describedby="describedBy"
        >
          <option value="" disabled>Choose…</option>
          <option v-for="c in planner.courses" :key="c.id" :value="c.id">{{ c.title }}</option>
        </select>
      </template>
    </FormField>
    <FormField v-model="draft.date" label="Date" type="date" :error="shown.date" />
    <FormField v-model.number="draft.minutes" label="Minutes" type="number" min="5" max="240" :error="shown.minutes" />
    <button>Add the session</button>
    <p role="status" class="saved">{{ saved }}</p>
  </form>
</template>
```

O campo de curso preenche o slot com um `<select>` e o conecta com os três valores que o slot passa; os
campos de data e de minutos usam o `<input>` padrão. O formulário recebe como prop a data de onde o aluno
começa, `date`, que é copiada para o draft uma vez: o "valor inicial que o filho passa a ter" da aula 6.

## Na página

O `HomeView.vue` o importa, `import SessionForm from '../components/SessionForm.vue'`, e adiciona um
painel depois do da semana:

```html
<PlannerPanel title="Add a session">
  <SessionForm :date="today" />
</PlannerPanel>
```

Hoje é a data inicial, porque é quando um aluno mais planeja a próxima sessão. Apertado vazio, o
formulário diz o que falta:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Add the session' --text form
[vite] connecting...
[vite] connected.
-- click text=Add the session
== the text of form
Course
Choose…
Statistics
Spanish
Guitar

Choose a course.

Date
Minutes
Add the session
```

**Só o curso falta**: a data começou como hoje, e os minutos como 30, o que está dentro da regra. O texto
do formulário mostra todas as opções do select, porque as opções de um `<select>` são o seu texto; a tela
mostra a escolhida.

O planner agora consegue adicionar sessões, além de marcá-las, e o watcher da aula 4 salva cada nova no
navegador, sem ninguém ter de lembrar disso. A aula 16 tipa este formulário, a aula 21 o testa.
