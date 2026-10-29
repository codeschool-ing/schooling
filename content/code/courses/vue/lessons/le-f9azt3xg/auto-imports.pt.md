---
title: Importações automáticas, e as peças do planner trazidas para cá
version: 1
---

**Num projeto Nuxt, um componente em `app/components/` pode ser usado por qualquer template, e uma
função exportada de `app/composables/`, `app/utils/` ou `shared/utils/` pode ser chamada por qualquer
script, tudo sem `import`.** As funções do próprio Nuxt, `useRoute`, `useFetch`, `navigateTo`, e as do
Vue, `ref`, `computed`, `watch`, são importadas do mesmo jeito. As peças do planner vêm agora, e perdem
linhas em vez de ganhar.

O `planner.ts`, as regras que a aula 3 escreveu e a aula 16 tipou, vai para `shared/utils/`, a pasta
cujos exports tanto a aplicação quanto o servidor recebem, porque o servidor vai precisar do `toggleDone`
na próxima seção. A primeira linha dele cita o lugar antigo, então o `sed` corrige. A folha de estilo e
os dados vêm também:

```
ana@dev:~/vue/planner-nuxt$ mkdir -p shared/utils app/components app/assets server/data
ana@dev:~/vue/planner-nuxt$ cp ../planner/src/planner.ts shared/utils/planner.ts
ana@dev:~/vue/planner-nuxt$ sed -i '1s#src/planner.ts#shared/utils/planner.ts#' shared/utils/planner.ts
ana@dev:~/vue/planner-nuxt$ cp ../planner/src/main.css app/assets/main.css
ana@dev:~/vue/planner-nuxt$ cp ../planner/public/courses.json server/data/courses.json
```

Nada no `planner.ts` muda: as funções dele recebem valores simples e não sabem nada do Vue, que era o
motivo de escrevê-las assim na aula 3.

## Três componentes, com menos linhas

O `PlannerPanel` vem como está, com o primeiro comentário dizendo onde ele mora agora:

```html
<!-- app/components/PlannerPanel.vue -->
<script setup lang="ts">
defineProps({ title: { type: String, required: true } })
</script>

<template>
  <section class="panel">
    <header class="panel-head">
      <h2>{{ title }}</h2>
      <slot name="actions" />
    </header>
    <slot>
      <p>Nothing here yet.</p>
    </slot>
    <footer v-if="$slots.footer" class="panel-foot">
      <slot name="footer" />
    </footer>
  </section>
</template>

<style scoped>
.panel {
  border: 1px solid #c9d8cf;
  border-radius: 6px;
  margin: 1rem 0;
  padding: 0 1rem 1rem;
}
.panel-head {
  align-items: center;
  display: flex;
  gap: 1rem;
  justify-content: space-between;
}
.panel-foot {
  border-top: 1px solid #c9d8cf;
  color: #2f6f4e;
  padding-top: 0.5rem;
}
</style>
```

O `CourseCard` perde as duas linhas de `import`, e o `RouterLink` vira `NuxtLink`:

```html
<!-- app/components/CourseCard.vue -->
<script setup lang="ts">
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
    <h3><NuxtLink :to="`/courses/${id}`">{{ title }}</NuxtLink></h3>
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

O `SessionRow` muda mais, porque lia os títulos dos cursos da store Pinia da aula 13, e este projeto não
tem store. O título vira uma prop, passada pela página que tem os dados:

```html
<!-- app/components/SessionRow.vue -->
<script setup lang="ts">
const { session, title, today = false } = defineProps<{
  session: Session
  title: string
  today?: boolean
}>()
const emit = defineEmits<{
  toggle: [id: string]
}>()
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

O `Session`, um tipo, e o `formatDay`, uma função, vêm os dois de `shared/utils/planner.ts` sem serem
nomeados em lugar nenhum do arquivo.

## De onde vêm os nomes

Um import que você não escreve ainda precisa existir em algum lugar, e o Nuxt o escreve, em `.nuxt`, a
pasta de arquivos gerados que ele mantém atualizada enquanto o servidor de desenvolvimento roda:

```
ana@dev:~/vue/planner-nuxt$ grep -n 'shared/utils/planner' .nuxt/imports.d.ts .nuxt/types/imports.d.ts | cut -c1-140
.nuxt/imports.d.ts:37:export { isoDate, addDays, weekStart, formatDay, sessionsInWeek, weekTotal, addSession, toggleDone, Course, Session, T
.nuxt/types/imports.d.ts:6:  const addDays: typeof import('../../shared/utils/planner').addDays
.nuxt/types/imports.d.ts:8:  const addSession: typeof import('../../shared/utils/planner').addSession
.nuxt/types/imports.d.ts:35:  const formatDay: typeof import('../../shared/utils/planner').formatDay
.nuxt/types/imports.d.ts:53:  const isoDate: typeof import('../../shared/utils/planner').isoDate
.nuxt/types/imports.d.ts:91:  const sessionsInWeek: typeof import('../../shared/utils/planner').sessionsInWeek
.nuxt/types/imports.d.ts:103:  const toggleDone: typeof import('../../shared/utils/planner').toggleDone
.nuxt/types/imports.d.ts:197:  const weekStart: typeof import('../../shared/utils/planner').weekStart
.nuxt/types/imports.d.ts:198:  const weekTotal: typeof import('../../shared/utils/planner').weekTotal
.nuxt/types/imports.d.ts:218:  export type { Course, Session, Totals } from '../../shared/utils/planner'
.nuxt/types/imports.d.ts:219:  import('../../shared/utils/planner')
.nuxt/types/imports.d.ts:227:    readonly addDays: UnwrapRef<typeof import('../../shared/utils/planner')['addDays']>
.nuxt/types/imports.d.ts:229:    readonly addSession: UnwrapRef<typeof import('../../shared/utils/planner')['addSession']>
.nuxt/types/imports.d.ts:256:    readonly formatDay: UnwrapRef<typeof import('../../shared/utils/planner')['formatDay']>
.nuxt/types/imports.d.ts:274:    readonly isoDate: UnwrapRef<typeof import('../../shared/utils/planner')['isoDate']>
.nuxt/types/imports.d.ts:312:    readonly sessionsInWeek: UnwrapRef<typeof import('../../shared/utils/planner')['sessionsInWeek']>
.nuxt/types/imports.d.ts:324:    readonly toggleDone: UnwrapRef<typeof import('../../shared/utils/planner')['toggleDone']>
.nuxt/types/imports.d.ts:418:    readonly weekStart: UnwrapRef<typeof import('../../shared/utils/planner')['weekStart']>
.nuxt/types/imports.d.ts:419:    readonly weekTotal: UnwrapRef<typeof import('../../shared/utils/planner')['weekTotal']>
```

**Todo export do `planner.ts` está listado, os tipos entre eles**, e esse arquivo é o que o editor e o
`vue-tsc` leem para saber o que é o `formatDay`. Os componentes são listados em `.nuxt/components.d.ts`
do mesmo jeito, cada um duas vezes:

```
ana@dev:~/vue/planner-nuxt$ grep -n '"../app/components' .nuxt/components.d.ts | cut -c1-120
17:export const CourseCard: typeof import("../app/components/CourseCard.vue")['default']
18:export const PlannerPanel: typeof import("../app/components/PlannerPanel.vue")['default']
19:export const SessionRow: typeof import("../app/components/SessionRow.vue")['default']
114:export const LazyCourseCard: LazyComponent<typeof import("../app/components/CourseCard.vue")['default']>
115:export const LazyPlannerPanel: LazyComponent<typeof import("../app/components/PlannerPanel.vue")['default']>
116:export const LazySessionRow: LazyComponent<typeof import("../app/components/SessionRow.vue")['default']>
```

O segundo nome de cada um é o primeiro com `Lazy` na frente. `<LazyCourseCard>` é o mesmo componente
carregado só quando é desenhado pela primeira vez, num chunk próprio, como as rotas sob demanda da aula
12; vale a pena para algo grande que a maioria das visitas nunca mostra, e o planner não tem nada assim.

Um componente numa subpasta leva a pasta no nome: `components/week/Row.vue` seria `<WeekRow>`. E o build
inclui só o que é usado: um componente que ninguém desenha, ou uma função que ninguém chama, está na
lista e não no bundle.

O custo é o de toda convenção. Ler um arquivo não diz mais de onde vem um nome, então uma função
chamada `formatDay` em `shared/utils` e outra `formatDay` em `app/utils` seriam uma colisão que o Nuxt
avisa ao iniciar, e um colega que encontra o `toggleDone` pela primeira vez precisa do *ir para a
definição* do editor, ou do arquivo gerado acima. Um `import { formatDay } from '#imports'` explícito
continua funcionando, onde quer que um arquivo fique mais legível com um.
