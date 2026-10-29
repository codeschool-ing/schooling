---
title: Menos movimento, e o dialog do planner
version: 1
---

**Algumas pessoas ficam tontas, ou se perdem, quando coisas deslizam e somem na tela, e todo sistema
deixa que elas peçam menos movimento. Uma página que respeita o pedido desliga as transições quando a
media query `prefers-reduced-motion` diz `reduce`.** Custa um bloco de CSS por transição. A WCAG 2.2
só exige isso no nível mais alto, AAA, para o movimento que um clique dispara, então o AA que este curso
busca não o pede; é barato o bastante para que o planner o faça mesmo assim.

A demo do fade de duas seções atrás já tem esse bloco, no fim do estilo dela. O `look` consegue fazer o
navegador informar a preferência:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=FadeDemo' --reduced-motion --do 'click button' --do 'wait 1000' --html '#note' --text -
[vite] connecting...
[vite] connected.
-- click button
the enter transition took about 0 ms
-- wait 1000
== the HTML of #note
<p id="note" class="">Saved in this browser.</p>
```

**A mesma transição de entrada levou cerca de 0 milissegundo**, e o parágrafo termina sem classe
nenhuma. Com `transition: none`, o Vue não achou duração no estilo computado, então terminou a
transição na hora, rodou os hooks, e o elemento apareceu. O estudante que pediu menos movimento recebe a
mesma informação sem movimento nenhum.

`--reduced-motion` é uma opção do `look` da aula 1. No seu próprio sistema, a configuração fica nas
opções de acessibilidade, com um nome como *Reduzir movimento* (macOS e iOS) ou *Efeitos de animação*
(Windows, desligada), e o navegador a repassa para todas as páginas.

## O planner, com um dialog e uma lista que se move

O formulário do planner sai do painel e vai para um dialog, aberto por um botão ao lado dos da semana,
e a lista da semana vira um `<TransitionGroup>`. Primeiro o dialog, o `<dialog>` nativo da seção do
dialog, num componente com título e botão de fechar, teleportado para o body:

```html
<!-- src/components/PlannerDialog.vue -->
<script setup>
import { useTemplateRef, useId } from 'vue'

const { title } = defineProps({ title: { type: String, required: true } })
const dialog = useTemplateRef('dialog')
const titleId = useId()

// The parent opens and closes it; nothing else of the dialog is its business.
defineExpose({
  open: () => dialog.value.showModal(),
  close: () => dialog.value.close(),
})
</script>

<template>
  <Teleport to="body">
    <dialog ref="dialog" class="dialog" :aria-labelledby="titleId">
      <header>
        <h2 :id="titleId">{{ title }}</h2>
        <form method="dialog"><button aria-label="Close">×</button></form>
      </header>
      <slot />
    </dialog>
  </Teleport>
</template>

<style scoped>
.dialog {
  border: 1px solid #c9d8cf;
  border-radius: 6px;
  max-width: 28rem;
}
.dialog::backdrop {
  background: rgb(0 0 0 / 0.4);
}
header {
  align-items: center;
  display: flex;
  justify-content: space-between;
}
</style>
```

O `defineExpose`, da aula 9, é como o pai chama `open()` e `close()` por uma template ref, e são as
únicas duas coisas que o dialog o deixa alcançar. Depois as transições, acrescentadas ao fim da folha
de estilo compartilhada, com o bloco de movimento reduzido ao lado:

```css
/* src/main.css: the planner's look, shared by every component. */
body {
  color: #1d2b24;
  font-family: system-ui, sans-serif;
  line-height: 1.5;
  margin: 0 auto;
  max-width: 40rem;
  padding: 0 1rem;
}
ul {
  list-style: none;
  padding: 0;
}
button {
  font: inherit;
}

/* A session joining the week slides in, and the ones after it make room. */
.row-enter-active,
.row-move {
  transition: all 0.3s ease;
}
.row-enter-from {
  opacity: 0;
  transform: translateX(-1rem);
}

/* Less motion for whoever has asked their system for it. */
@media (prefers-reduced-motion: reduce) {
  .row-enter-active,
  .row-move {
    transition: none;
  }
}
```

O `SessionForm` avisa o pai quando uma sessão foi adicionada, com uma linha nova depois de a store ser
configurada, `const emit = defineEmits(['added'])`, e uma no fim do `submit`, `emit('added', saved.value)`.
E a página da semana junta tudo:

```html
<!-- src/views/HomeView.vue -->
<script setup>
import { ref, computed, useTemplateRef } from 'vue'
import CourseCard from '../components/CourseCard.vue'
import SessionRow from '../components/SessionRow.vue'
import PlannerPanel from '../components/PlannerPanel.vue'
import SessionForm from '../components/SessionForm.vue'
import PlannerDialog from '../components/PlannerDialog.vue'
import { storeToRefs } from 'pinia'
import { usePlannerStore } from '../stores/planner.js'
import { useToday } from '../composables/useToday.js'
import { weekStart, addDays, formatDay, weekTotal, sessionsInWeek } from '../planner.js'

const planner = usePlannerStore()
const { courses, sessions } = storeToRefs(planner)
const { toggle } = planner
const today = useToday()
const monday = ref(weekStart(new Date()))

const thisWeek = computed(() =>
  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),
)
const perCourse = computed(() =>
  courses.value.map((course) => ({
    ...course,
    ...weekTotal(
      sessions.value.filter((s) => s.course === course.id),
      monday.value,
    ),
  })),
)
const total = computed(() => weekTotal(sessions.value, monday.value))

const adding = useTemplateRef('adding')
const added = ref('')
function onAdded(message) {
  added.value = message
  adding.value.close()
}
</script>

<template>
  <h1>This week</h1>
  <PlannerPanel title="Courses">
    <ul>
      <CourseCard
        v-for="course in perCourse"
        :key="course.id"
        :id="course.id"
        :title="course.title"
        :goal="course.goal"
        :planned="course.planned"
        :done="course.done"
      />
    </ul>
  </PlannerPanel>
  <PlannerPanel :title="`Week of ${formatDay(monday)}`">
    <template #actions>
      <nav aria-label="Weeks">
        <button @click="monday = addDays(monday, -7)">Previous week</button>
        <button @click="monday = addDays(monday, 7)">Next week</button>
      </nav>
      <button @click="adding.open()">Add a session</button>
    </template>
    <TransitionGroup v-if="thisWeek.length > 0" tag="ul" name="row">
      <SessionRow
        v-for="session in thisWeek"
        :key="session.id"
        :session="session"
        :today="session.date === today"
        @toggle="toggle"
      />
    </TransitionGroup>
    <p role="status">{{ added }}</p>
    <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>
  </PlannerPanel>
  <PlannerDialog ref="adding" title="Add a session">
    <SessionForm :date="today" @added="onAdded" />
  </PlannerDialog>
</template>
```

Abra o dialog, preencha e adicione a sessão:

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --do 'click text=Add a session' --do 'select select guitar' --do 'fill input[type=date] 2026-10-24' --do 'fill input[type=number] 25' --do 'click text=Add the session' --text 'main section:nth-child(3)'
[vite] connecting...
[vite] connected.
-- click text=Add a session
-- select select guitar
-- fill input[type=date] 2026-10-24
-- fill input[type=number] 25
-- click text=Add the session
== the text of main section:nth-child(3)
Week of 19 October 2026
Previous weekNext week
Add a session
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes
 24 October 2026, Guitar, 25 minutes

Added 25 minutes of Guitar on 24 October 2026.

75 of 220 minutes done
```

**O dialog fechou sozinho, a sessão deslizou até o lugar dela no dia 24, e a linha de status embaixo
da lista diz o que foi adicionado**, então quem usa leitor de tela, cujo foco voltou para o botão *Add a
session* quando o dialog fechou, também ouve.
