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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Como T é decidido na demo TypedPicker. À esquerda, o pai passa :items igual a courses, um array de Course. No meio, T vira Course. À direita, os três lugares onde o TypedList escreveu T: items, um array de T, é um array de Course; o evento pick, com um item do tipo T, entrega ao listener um Course, então course.goal é um number; e o item do slot é um Course, então item.title é uma string. Cada um é verificado contra Course.\"><text x=\"110\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o pai passa</text><rect x=\"20\" y=\"76\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">:items=\"courses\"</text><text x=\"110\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Course[]</text><line x1=\"202\" y1=\"106\" x2=\"256\" y2=\"106\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"256.0,106.0 248.6,109.1 248.6,102.9\" fill=\"var(--amber)\"></polygon><rect x=\"260\" y=\"82\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"330\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">T = Course</text><text x=\"585\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">onde o TypedList escreveu T</text><rect x=\"470\" y=\"30\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">items: T[]</text><text x=\"585\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Course[]</text><line x1=\"402\" y1=\"106\" x2=\"466\" y2=\"53\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"466.0,53.0 462.3,60.1 458.3,55.3\" fill=\"var(--phosphor)\"></polygon><rect x=\"470\" y=\"95\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pick: [item: T]</text><text x=\"585\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">course.goal: number</text><line x1=\"402\" y1=\"106\" x2=\"466\" y2=\"118\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"466.0,118.0 458.2,119.7 459.3,113.6\" fill=\"var(--phosphor)\"></polygon><rect x=\"470\" y=\"160\" width=\"230\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"585\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;slot :item=\"item\"&gt;</text><text x=\"585\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">item.title: string</text><line x1=\"402\" y1=\"106\" x2=\"466\" y2=\"183\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"466.0,183.0 458.9,179.3 463.7,175.3\" fill=\"var(--phosphor)\"></polygon></svg>", "caption": "Nada no picker nomeia um tipo; T é lido dos itens que ele recebeu."}
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
