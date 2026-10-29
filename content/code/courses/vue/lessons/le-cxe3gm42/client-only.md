---
title: Client-only, for what only the browser knows
version: 1
---

**The reader's day belongs to the browser, so the browser decides it, after hydration, and the
server draws the week without it.** In the week page the line of the mismatch becomes a ref that
starts empty and is set in `onMounted`, which runs only in the browser and only once the page is
hydrated:

```html
<!-- app/pages/index.vue: the week, at / -->
<script setup lang="ts">
const { data, refresh } = await useFetch('/api/courses')
const monday = ref(weekStart(new Date()))
// The reader's day, which only the reader's browser knows: empty on the
// server, and set once the page is running in the browser.
const today = ref('')
onMounted(() => {
  today.value = isoDate(new Date())
})

const sessions = computed(() => data.value?.sessions ?? [])
const titles = computed(() => Object.fromEntries((data.value?.courses ?? []).map((c) => [c.id, c.title])))
const thisWeek = computed(() =>
  sessionsInWeek(sessions.value, monday.value).toSorted((a, b) => a.date.localeCompare(b.date)),
)
const perCourse = computed(() =>
  (data.value?.courses ?? []).map((course) => ({
    ...course,
    ...weekTotal(
      sessions.value.filter((s) => s.course === course.id),
      monday.value,
    ),
  })),
)
const total = computed(() => weekTotal(sessions.value, monday.value))

async function toggle(id: string) {
  await $fetch(`/api/sessions/${id}`, { method: 'PATCH' })
  await refresh()
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
    </template>
    <ul v-if="thisWeek.length > 0">
      <SessionRow
        v-for="session in thisWeek"
        :key="session.id"
        :session="session"
        :title="titles[session.course] ?? session.course"
        :today="session.date === today"
        @toggle="toggle"
      />
    </ul>
    <template #footer>{{ total.done }} of {{ total.planned }} minutes done</template>
  </PlannerPanel>
</template>
```

On the server, and in the first render in the browser, `today` is `''`, no row matches it, and the two
drawings agree. Then `onMounted` sets it, and the change redraws the one row, as any change of a ref
would. The highlight appears a moment after the page, which is the honest price: until the browser
has run, nobody knows what day it is for the reader.

## `<ClientOnly>`, for a part that cannot be drawn on the server

When a whole piece of a page depends on the browser, Nuxt's `<ClientOnly>` leaves it out of the
server's render and draws it after hydration, with an optional `#fallback` for the server to send in
its place. The planner's footer says which zone the days are counted in, which is a fact about the
browser and nothing else:

```html
<!-- app/layouts/default.vue: the frame around every page. -->
<script setup lang="ts">
import { version } from 'vue'

// The reader's time zone, as their browser reports it. The server has its own.
const zone = () => Intl.DateTimeFormat().resolvedOptions().timeZone
</script>

<template>
  <header>
    <p class="brand"><NuxtLink to="/">Study planner</NuxtLink></p>
  </header>
  <main>
    <slot />
  </main>
  <footer>
    <p>Built with Vue {{ version }}, by Nuxt</p>
    <ClientOnly>
      <p>Days are counted in {{ zone() }}</p>
      <template #fallback>
        <p>Days are counted in your browser's time zone</p>
      </template>
    </ClientOnly>
  </footer>
</template>

<style scoped>
header {
  border-bottom: 2px solid #2f6f4e;
}
.brand {
  font-size: 1.5rem;
  font-weight: 700;
}
footer p {
  color: #666;
  font-size: 0.875rem;
}
</style>
```

The same moment as before, half past eleven in São Paulo, with the server in UTC:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text 'li.today'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of li.today
 21 October 2026, Statistics, 60 minutes (today)
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text '#__nuxt > footer'
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of #__nuxt > footer
Built with Vue 3.5.44, by Nuxt

Days are counted in America/Sao_Paulo
```

**No warning, the 21st highlighted, and the reader's zone in the footer.** And what the server sent:

```
ana@dev:~/vue/planner-nuxt$ curl -s http://localhost:3000/ | grep -o 'Days are counted in [^<]*'
Days are counted in your browser&#39;s time zone
```

The fallback, a sentence true for every reader, and no mention of UTC anywhere. A component that only
makes sense in the browser can also say so in its name: `Clock.client.vue` in `app/components` is
drawn only in the browser, as if every use of it were wrapped in `<ClientOnly>`. Inside a script,
`import.meta.client` and `import.meta.server` are `true` on one side only, for the rare line that must
run on one and not the other; `onMounted` is usually the clearer way to say *in the browser*.

One question is left open on purpose. `monday`, the start of the week shown, is still decided on the
server, and on a Sunday night the server's Monday is a week ahead of the reader's. The planner could
move it to `onMounted` too and draw no week at all on the server, or ask the reader's zone once and
keep it in a cookie the server reads. Both are reasonable, and the next section is about choosing.
