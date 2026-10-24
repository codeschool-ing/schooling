---
title: O componente genérico
version: 1
---

**Um componente genérico é aquele cujas props, eventos e slots são tipados por um parâmetro de tipo,
`T`, que o uso no pai decide.** Uma lista que aceita qualquer tipo de item e o devolve num slot e num
evento, tipado como o que foi passado, é o caso para o qual ele existe: sem um genérico, a lista teria
de dizer que os seus itens são "qualquer coisa", e todo pai perderia os seus tipos na borda da lista.

O sandbox também ganha TypeScript, para as demos desta seção, com os mesmos três pacotes e uma
configuração que confere só os arquivos cujo nome começa com `Typed`:

```
ana@dev:~/vue/sandbox$ npm install --save-dev --save-exact typescript@6.0.3 vue-tsc@3.3.13 @vue/tsconfig@0.9.1

added 11 packages, and audited 58 packages in 3s

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

```json
{
  "extends": "@vue/tsconfig/tsconfig.dom.json",
  "include": ["env.d.ts", "src/demos/Typed*.vue"],
  "compilerOptions": {
    "lib": ["ES2023", "DOM", "DOM.Iterable"]
  }
}
```

e o mesmo `env.d.ts` de uma linha do planner. A lista:

```html
<!-- src/demos/TypedList.vue -->
<script setup lang="ts" generic="T extends { id: string }">
// T is whatever kind of item the parent passes; all this component needs is an id.
const { items } = defineProps<{ items: T[] }>()
const emit = defineEmits<{ pick: [item: T] }>()
</script>

<template>
  <ul>
    <li v-for="item in items" :key="item.id">
      <button @click="emit('pick', item)">
        <slot :item="item">{{ item.id }}</slot>
      </button>
    </li>
  </ul>
</template>
```

**`generic="T extends { id: string }"`** na tag `<script setup>` declara o parâmetro de tipo, com uma
restrição: seja o que for `T`, ele tem um `id` string, de que o `:key` precisa. `items: T[]`, o
evento `pick: [item: T]` e o `item` do slot são todos o mesmo `T`. Um pai que a usa com cursos:

```html
<!-- src/demos/TypedPicker.vue -->
<script setup lang="ts">
import { ref } from 'vue'
import TypedList from './TypedList.vue'

interface Course {
  id: string
  title: string
  goal: number
}

const courses: Course[] = [
  { id: 'statistics', title: 'Statistics', goal: 180 },
  { id: 'spanish', title: 'Spanish', goal: 120 },
]
const chosen = ref<Course | null>(null)
</script>

<template>
  <TypedList :items="courses" @pick="(course) => (chosen = course)">
    <template #default="{ item }">{{ item.title }}, {{ item.goal }} minutes</template>
  </TypedList>
  <p id="chosen">{{ chosen ? `${chosen.title}: goal ${chosen.goal}` : 'Nothing chosen' }}</p>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TypedPicker' --do 'click text=Spanish' --text '#chosen'
[vite] connecting...
[vite] connected.
-- click text=Spanish
== the text of #chosen
Spanish: goal 120
```

Nada no picker diz o que são `item` e `course`: **`T` virou `Course` porque `:items` recebeu um
`Course[]`**, então o `item.title` do slot e o `course.goal` do evento são conferidos contra
`Course`.

## Dois usos que o verificador recusa

```html
<!-- src/demos/TypedMistakes.vue -->
<script setup lang="ts">
import TypedList from './TypedList.vue'

const sessions = [{ id: 's2', minutes: 45 }]
const labels = ['statistics', 'spanish']
</script>

<template>
  <TypedList :items="sessions">
    <template #default="{ item }">{{ item.title }}</template>
  </TypedList>
  <TypedList :items="labels" />
</template>
```

No navegador, a página não mostra nada útil e não diz nada:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=TypedMistakes'
[vite] connecting...
[vite] connected.
== the text of #app
```

O verificador é específico:

```
ana@dev:~/vue/sandbox$ npx vue-tsc --noEmit
src/demos/TypedMistakes.vue(11,43): error TS2339: Property 'title' does not exist on type '{ id: string; minutes: number; }'.
src/demos/TypedMistakes.vue(13,15): error TS2322: Type 'string[]' is not assignable to type '{ id: string; }[]'.
  Type 'string' is not assignable to type '{ id: string; }'.
```

**`title` não existe** numa sessão, porque `T` virou a forma da sessão; e **uma lista de strings é
recusada** pela restrição, porque uma string não tem `id`. Os dois, de outro modo, chegariam a um
estudante como um botão vazio.
