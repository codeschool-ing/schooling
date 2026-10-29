---
title: Tipos para as regras e para as props
version: 1
---

**Um tipo descreve a forma de um valor, e o planner tem duas formas das quais todo o resto depende: um
curso e uma sessão.** Escritas uma vez, no `planner.ts`, elas são usadas pelas regras, pela store e
pelos componentes, então uma propriedade com o nome errado ou um número passado onde cabe uma string é
encontrado pelo verificador, e não por um estudante.

## planner.ts

As regras da aula 3, as mesmas funções, com os parâmetros e os resultados descritos:

```typescript
// src/planner.ts: the planner's rules, as plain functions over plain data.
// Nothing here knows about Vue, the page or the clock, which is what makes
// every function testable on its own (lesson 21 does it).

export interface Course {
  id: string
  title: string
  goal: number // minutes a week
}

export interface Session {
  id: string
  course: string // a Course's id
  date: string // YYYY-MM-DD
  minutes: number
  done: boolean
}

export interface Totals {
  planned: number
  done: number
}

// A date as YYYY-MM-DD, in the computer's own time zone.
export function isoDate(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

// The date n days after a YYYY-MM-DD date (before it, if n is negative).
export function addDays(iso: string, n: number): string {
  const [y, m, d] = iso.split('-').map(Number)
  return isoDate(new Date(y, m - 1, d + n))
}

// The Monday of the week a date falls in, as YYYY-MM-DD.
export function weekStart(date: Date): string {
  const daysSinceMonday = (date.getDay() + 6) % 7
  return addDays(isoDate(date), -daysSinceMonday)
}

// "19 October 2026", for people.
export function formatDay(iso: string): string {
  const [y, m, d] = iso.split('-').map(Number)
  return new Date(y, m - 1, d).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
}

// The sessions from Monday to Sunday of the week that starts on monday.
export function sessionsInWeek(sessions: Session[], monday: string): Session[] {
  const sunday = addDays(monday, 6)
  return sessions.filter((s) => s.date >= monday && s.date <= sunday)
}

// Minutes planned and minutes done in that week.
export function weekTotal(sessions: Session[], monday: string): Totals {
  const week = sessionsInWeek(sessions, monday)
  return {
    planned: week.reduce((sum, s) => sum + s.minutes, 0),
    done: week.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0),
  }
}

// A new list with one more session in it. The id is one past the highest.
export function addSession(sessions: Session[], { course, date, minutes }: Omit<Session, 'id' | 'done'>): Session[] {
  const highest = Math.max(0, ...sessions.map((s) => Number(s.id.slice(1))))
  return [...sessions, { id: `s${highest + 1}`, course, date, minutes, done: false }]
}

// A new list in which one session's done flag is flipped.
export function toggleDone(sessions: Session[], id: string): Session[] {
  return sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s))
}
```

`interface Course` e `interface Session` são os dados do planner escritos como tipos, e todos os
campos do `courses.json` estão neles. Cada função agora diz o que recebe e o que devolve:
`weekTotal(sessions: Session[], monday: string): Totals`. Dois detalhes mostram para que servem os
tipos:

- **`Omit<Session, 'id' | 'done'>`**, o argumento de `addSession`, é "uma sessão sem os dois campos
  que a regra preenche", então quem chama não consegue passar um id próprio, e um campo novo
  acrescentado depois a `Session` passa a ser exigido aqui na hora.
- **`Totals`** dá nome ao que `weekTotal` devolve, então um componente que lê `total.planned` também
  é conferido, e um que lê `total.plan` fica sabendo do erro.

## Props, por tipo

A aula 6 declarou props com objetos que o Vue confere enquanto o app roda: `{ type: Number, required:
true }`. Com TypeScript, o `defineProps` pode receber um **tipo** no lugar, e o compilador o transforma
na mesma declaração de runtime por você. O `CourseCard`, com as props como um tipo:

```html
<!-- src/components/CourseCard.vue -->
<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

// Destructured, and still reactive: the compiler turns every use of `done`
// below into `props.done`.
const {
  id,
  title,
  goal,
  planned = 0,
  done = 0,
} = defineProps<{
  id: string
  title: string
  goal: number // minutes a week
  planned?: number
  done?: number
}>()

const percent = computed(() => Math.round((done / goal) * 100))
</script>

<template>
  <li class="card">
    <h3><RouterLink :to="`/courses/${id}`">{{ title }}</RouterLink></h3>
    <p>{{ done }} of {{ planned }} minutes done, goal {{ goal }}</p>
    <p>
      <progress :value="done" :max="goal">{{ percent }}%</progress>
      {{ percent }}% of the weekly goal
    </p>
  </li>
</template>

<style scoped>
.card {
  margin-bottom: 1rem;
}
p {
  color: #2f6f4e;
}
</style>
```

`planned?: number` é uma prop opcional; `planned = 0` na desestruturação é o seu valor padrão, a forma
do Vue 3.5 que a aula 6 usou. E o `SessionRow`, cuja prop `session` agora é uma `Session`, e não
apenas "um objeto":

```html
<!-- src/components/SessionRow.vue -->
<script setup lang="ts">
import { computed } from 'vue'
import { formatDay, type Session } from '../planner.js'
import { usePlannerStore } from '../stores/planner.js'

const { session, today = false } = defineProps<{
  session: Session
  today?: boolean
}>()
const emit = defineEmits<{
  toggle: [id: string]
}>()

// The course's title, from the store; its id until the courses have loaded.
const planner = usePlannerStore()
const title = computed(() => planner.titles[session.course] ?? session.course)
</script>

<template>
  <li :class="{ done: session.done, today }">
    <label>
      <input type="checkbox" :checked="session.done" @change="emit('toggle', session.id)" />
      {{ formatDay(session.date) }}, {{ title }}, {{ session.minutes }} minutes
      <strong v-if="today">(today)</strong>
    </label>
  </li>
</template>

<style scoped>
.done {
  text-decoration: line-through;
}
.today {
  background: #e6f0ea;
}
</style>
```

`session: Session` significa que o `session.minutes` e o `session.date` do template se sabem
existentes, e `session.minuets` seria um erro antes de a página sequer abrir. A conferência de runtime
que o Vue gera a partir do tipo é `Object`, porque um tipo como `Session` existe só para o
verificador: em tempo de execução, o Vue só consegue ver que recebeu um objeto.

Os dois estilos são TypeScript válido, e os outros componentes do planner mantêm as suas declarações de
runtime: o verificador também as lê, e deduz os tipos a partir delas. **A forma baseada em tipo é a que
se escreve em código TypeScript novo**, porque ela descreve o que uma declaração por objeto não
consegue, como a forma de uma `Session`.
