---
title: Refreshing, and when the request fails
version: 1
---

**`refresh()` runs the fetch again and replaces `data` with the new answer, and `error` holds what
went wrong when there is no answer to give.** The planner has used `refresh` since lesson 18: tick a
session, `$fetch` sends the `PATCH`, and `refresh()` reads the planner again so the page shows what the
server now holds. That is two requests per tick, and it is a choice: the `PATCH` already answers with
the changed session, and a page could put that one session into `data` itself. Asking again is
simpler and cannot go wrong when somebody else changed something too.

The planner's server never fails, which is the reason to make it. The week's endpoint, for a moment,
answers like a server under maintenance:

```
ana@dev:~/vue/planner-nuxt$ sed -i "s#=> planner)#=> {\n  throw createError({ statusCode: 503, statusMessage: 'Down for maintenance' })\n})#" server/api/courses.get.ts
```

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text main
[vite] connecting...
[vite] connected.
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main
This week
Courses
Week of 19 October 2026
Previous weekNext week

Nothing here yet.

0 of 0 minutes done
```

**The page drew, with zeros and an empty week, and said nothing about why.** `useFetch` does not
throw: it puts the failure in `error`, leaves `data` as it was, `undefined` here, and the page goes on
with what it has. Every `computed` of the week page falls back to `[]`, so the result looks like a
planner with no sessions, which is a lie told calmly. The week page gets a line for it, above the
heading:

```html
<p v-if="error" role="alert">The planner could not load its data: {{ error.statusMessage }}</p>
```

and `error` beside `data` and `refresh` in its `useFetch`. The whole file:

```html
<!-- app/pages/index.vue: the week, at / -->
<script setup lang="ts">
const { data, error, refresh } = await useFetch('/api/courses')
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
  <p v-if="error" role="alert">The planner could not load its data: {{ error.statusMessage }}</p>
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

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/ --text main
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main
The planner could not load its data: Down for maintenance

This week
Courses
Week of 19 October 2026
Previous weekNext week

Nothing here yet.

0 of 0 minutes done
```

**Now the page says what happened**, in a paragraph with `role="alert"`, which a screen reader reads
out as soon as it appears. The layout's count fails the same way and stays empty, which a footer can
afford. Put the endpoint back as lesson 18 wrote it:

```typescript
// server/api/courses.get.ts: GET /api/courses, every course and every session.
export default defineEventHandler(() => planner)
```

## An error that should stop the page

The week can be drawn without its data, badly; a course page cannot be drawn without its course. So
the course page of the keys section does the other thing with `error`: it throws it on, with
`createError`, and Nuxt draws `error.vue` with the status the server route gave:

```
ana@dev:~/vue/planner-nuxt$ look http://localhost:3000/courses/piano --text main
[error] Failed to load resource: the server responded with a status of 404 (No course called piano)
[vite] connecting...
[vite] connected.
<Suspense> is an experimental feature and its API will likely change.
== the text of main
Nothing here

No course called piano

Back to this week
```

**The route's own message, `No course called piano`, on a `404`**, passed from the server route
through `useFetch` to the page and out as the page's status. Which of the two a page should do is the
question to ask of every fetch: is the page still worth showing without this data? A week without
sessions, with a sentence saying why, is; a course page without its course is not.
