---
title: Mounting a component
version: 1
---

**`mount(Component, { props })` creates a component in jsdom, as the app would, and returns a
*wrapper*: an object to read what it drew and to act on it.** The first component to test is
`SessionRow`, one row of the week, because it is small and the planner draws it everywhere:

```typescript
// src/components/SessionRow.test.ts: one row of the week, mounted on its own.
import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import SessionRow from './SessionRow.vue'
import { usePlannerStore } from '../stores/planner.js'

const session = { id: 's4', course: 'statistics', date: '2026-10-21', minutes: 60, done: false }

describe('SessionRow', () => {
  // A store of its own for every test, so no test sees another's data.
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('shows the course id until the courses have loaded', () => {
    const row = mount(SessionRow, { props: { session } })
    expect(row.text()).toBe('21 October 2026, statistics, 60 minutes')
  })

  it('shows the course title once the store has it', () => {
    usePlannerStore().courses = [{ id: 'statistics', title: 'Statistics', goal: 180 }]
    const row = mount(SessionRow, { props: { session } })
    expect(row.text()).toBe('21 October 2026, Statistics, 60 minutes')
  })

  it('marks a done session and today', () => {
    const row = mount(SessionRow, { props: { session: { ...session, done: true }, today: true } })
    expect(row.classes()).toEqual(['done', 'today'])
    expect(row.get('strong').text()).toBe('(today)')
  })

  it('asks its parent to toggle it when the box is ticked', async () => {
    const row = mount(SessionRow, { props: { session } })
    await row.get('input').setValue(true)
    expect(row.emitted('toggle')).toEqual([['s4']])
  })
})
```

`SessionRow` reads the course titles from the store, so a test needs a Pinia, and `setActivePinia(
createPinia())` before each test gives it a fresh one, empty; without a fresh one, the second test's
title would still be in the third test's store. The wrapper's methods do the rest: `text()` is what a
reader sees, `classes()` the element's classes, `get(selector)` the first element that matches, and a
failure if there is none.

```
ana@dev:~/vue/planner$ npx vitest run src/components/SessionRow.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/components/SessionRow.test.ts (4 tests) 59ms

 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  22:07:14
   Duration  1.14s (environment 52%, transform 30%, import 12%, tests 6%)
```

## What the tests say, and what they leave out

**Each test names what the row does for its reader**, in words a reader would use: the course id
until the titles arrive, the title after, a struck-through session and today's mark. None of them
mentions a ref, a computed, or how the row decides; they would all still pass if the component were
written again another way and drew the same thing, which is the point. A test that reached into the
component, `row.vm.title`, would break on every refactoring and catch nothing a student could see.

The last test is the row's other half, what it tells its parent. `setValue(true)` ticks the box and
fires the `change` event, as a click would, and `emitted('toggle')` lists every `toggle` the row
emitted, each as the list of its arguments: one, carrying `s4`. The row does not toggle anything
itself; lesson 6 made that its parent's job, and the test holds it to that.
