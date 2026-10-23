---
title: Less motion, and the planner's dialog
version: 1
---

**Some people get dizzy, or lose their place, when things on a screen slide and fade, and every system
lets them ask for less motion. A page that respects the request turns its transitions off when the
`prefers-reduced-motion` media query says `reduce`.** It costs one block of CSS per transition. WCAG 2.2
only requires it at its highest level, AAA, for motion a click sets off, so the AA this course aims at
does not demand it; it is cheap enough that the planner does it anyway.

The fade demo of two sections back already has that block, at the end of its style. `look` can make
the browser report the preference:

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

**The same enter transition took about 0 milliseconds**, and the paragraph ends with no class left on
it. With `transition: none`, Vue found no duration in the computed style, so it finished the
transition at once, ran the hooks, and the element appeared. The student who asked for less motion gets
the same information with none of the movement.

`--reduced-motion` is an option of `look` from lesson 1. In your own system the setting is in the
accessibility settings, under a name like *Reduce motion* (macOS and iOS) or *Animation effects*
(Windows, turned off), and the browser passes it to every page.

## The planner, with a dialog and a moving list

The planner's form leaves its panel and moves into a dialog, opened by a button beside the week's, and
the week's list becomes a `<TransitionGroup>`. First the dialog, the native `<dialog>` of the dialog
section, in a component with a title and a close button, teleported to the body:

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

`defineExpose`, lesson 9, is how the parent calls `open()` and `close()` through a template ref, and the
only two things the dialog lets it reach. Then the transitions, added to the end of the shared
stylesheet with their reduced-motion block beside them:

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

`SessionForm` tells its parent when a session was added, with one new line after the store is set up,
`const emit = defineEmits(['added'])`, and one at the end of `submit`, `emit('added', saved.value)`. And
the week page puts it together:

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

Open the dialog, fill it in, and add the session:

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

**The dialog closed on its own, the session slid into its place on the 24th, and the status line under
the list says what was added**, so a screen-reader user, whose focus returned to the *Add a session*
button when the dialog closed, hears it too.
