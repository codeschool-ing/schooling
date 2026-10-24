---
title: defineStore, the setup way
version: 1
---

**`defineStore(id, setup)` defines a store with a function written exactly like `<script setup>`: refs
are its state, computed values are its getters, functions are its actions, and whatever it returns is
the store.** That form is called a *setup store*, and it is the one this course uses, because it is the
Composition API you already know with nothing new to learn.

The planner's store, which the last section of this lesson puts in place:

```schooling-example
{"language": "javascript", "file": "src/stores/planner.js", "parts": [
 {"code": "// src/stores/planner.js: the planner's data, in one place for every page.\nimport { ref, computed, watch } from 'vue'\nimport { defineStore } from 'pinia'\nimport { toggleDone } from '../planner.js'\n\nconst STORAGE_KEY = 'planner.sessions'", "note": "A store lives in `src/stores`, one file each, named after what it holds. The `planner.js` it imports is lesson 3's file of rules."},
 {"code": "export const usePlannerStore = defineStore('planner', () => {", "note": "`'planner'` is the store's id: unique in the application, and the name the developer tools show. `usePlannerStore` follows the composable naming of lesson 10."},
 {"code": "  // State\n  const courses = ref([])\n  const sessions = ref([])\n  const error = ref('')\n  const source = ref('')", "note": "State: four refs, the same four `usePlannerData` had."},
 {"code": "  // Getters\n  const titles = computed(() => Object.fromEntries(courses.value.map((c) => [c.id, c.title])))\n  const hasCourse = computed(() => (id) => courses.value.some((c) => c.id === id))", "note": "Getters: computed values. `hasCourse` returns a function, which is how a getter takes an argument."},
 {"code": "  // Actions\n  let loading = null\n  function load() {\n    // One request, however many pages and guards ask for the data.\n    loading ??= fetch('/courses.json')\n      .then((response) => {\n        if (!response.ok) throw new Error(`${response.status} ${response.statusText}`)\n        return response.json()\n      })\n      .then((data) => {\n        courses.value = data.courses\n        const saved = localStorage.getItem(STORAGE_KEY)\n        sessions.value = saved ? JSON.parse(saved) : data.sessions\n        source.value = saved ? 'this browser' : 'courses.json'\n      })\n      .catch((e) => {\n        error.value = `Could not load the courses: ${e.message}`\n      })\n    return loading\n  }", "note": "An action that loads the data once. `??=` assigns only if `loading` is still `null`, so every later caller gets the same promise, and only one request is ever sent."},
 {"code": "  function toggle(id) {\n    sessions.value = toggleDone(sessions.value, id)\n  }", "note": "An action that changes state, through lesson 3's rule."},
 {"code": "  // The store keeps its own copy in this browser, whoever changes the sessions.\n  watch(sessions, (list) => {\n    localStorage.setItem(STORAGE_KEY, JSON.stringify(list))\n  })", "note": "A watcher inside the store saves the sessions, whoever changed them."},
 {"code": "  return { courses, sessions, error, source, titles, hasCourse, load, toggle }\n})", "note": "Only what is returned is part of the store. A ref left out would be private, and Pinia's tools could not see it."}
]}
```

## Three words, mapped

| Pinia | in a setup store | read from a component as |
|---|---|---|
| state | `ref()` | `planner.sessions`, unwrapped |
| getter | `computed()` | `planner.titles` |
| action | a function | `planner.toggle('s4')` |

**A store is a `reactive` object**: its refs are unwrapped when read through it, so a component writes
`planner.sessions`, never `planner.sessions.value`, and the template reads `planner.courses.length`.
Lesson 2's rule about destructuring a `reactive` object applies too, and the fourth section of this
lesson is about it.

## Rules a setup store keeps

- **Return all the state.** Pinia can only save, inspect and reset what it can see. A ref kept private
  works, and is invisible to the developer tools and to server rendering.
- **Watchers and computed values work as in a component.** Lifecycle hooks do not belong in one: a store
  outlives every component, yet an `onMounted` inside it attaches to whichever component happened to
  create the store, and stops with it. And if the store is first created where no component is being
  set up, a guard for instance, the hook attaches to nothing and Vue warns, as lesson 10 showed.
- **Call `usePlannerStore()` inside setup, or after Pinia is installed.** The store needs to find the
  application's container, and before `app.use(createPinia())` there is none.
