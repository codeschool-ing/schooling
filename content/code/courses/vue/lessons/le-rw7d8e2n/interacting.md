---
title: Interacting, the way a student does
version: 1
---

**A form is tested by filling it in and sending it, and then reading what a student would read.**
`SessionForm`, from lesson 14, checks three fields, says what is wrong only after the first try, and
on success adds the session to the store and announces it. Its tests:

```typescript
// src/components/SessionForm.test.ts: the form, filled in the way a student fills it.
import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import SessionForm from './SessionForm.vue'
import { usePlannerStore } from '../stores/planner.js'

describe('SessionForm', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    usePlannerStore().courses = [{ id: 'guitar', title: 'Guitar', goal: 90 }]
  })

  it('says nothing is wrong before the first try', () => {
    const form = mount(SessionForm, { props: { date: '' } })
    expect(form.findAll('.error')).toHaveLength(0)
  })

  it('names every field that is wrong once the student tries', async () => {
    const form = mount(SessionForm, { props: { date: '' } })
    await form.get('form').trigger('submit')
    expect(form.findAll('.error').map((e) => e.text())).toEqual(['Choose a course.', 'Choose a date.'])
    expect(usePlannerStore().sessions).toEqual([])
  })

  it('adds a valid session to the store and says what it added', async () => {
    const form = mount(SessionForm, { props: { date: '2026-10-24' } })
    await form.get('select').setValue('guitar')
    await form.get('input[type=number]').setValue('25')
    await form.get('form').trigger('submit')
    expect(usePlannerStore().sessions).toEqual([
      { id: 's1', course: 'guitar', date: '2026-10-24', minutes: 25, done: false },
    ])
    expect(form.emitted('added')).toEqual([['Added 25 minutes of Guitar on 24 October 2026.']])
  })
})
```

`setValue` sets a field and fires the events `v-model` listens to, so `'25'` typed into the number field
reaches the form as the number `25`, through the `v-model.number` of lesson 14. `trigger('submit')`
sends the form. Every one of them returns a promise, and the `await` in front matters: Vue redraws after
a change on its next tick, lesson 2's update queue, and the promise settles once it has. Without the
`await`, the next line would read the page from before the change.

```
ana@dev:~/vue/planner$ npx vitest run src/components/SessionForm.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/components/SessionForm.test.ts (3 tests) 86ms

 Test Files  1 passed (1)
      Tests  3 passed (3)
   Start at  22:07:16
   Duration  1.05s (environment 60%, transform 18%, import 12%, tests 9%)
```

**The second test checks the store as well as the screen**: an invalid form must not only show its
errors, it must not have added anything. The third checks what the student is told, the same sentence
lesson 14's status line announced, and, through `emitted`, what the page around the form is told.

## Finding an element

The tests find elements by what they are, `select`, `input[type=number]`, `form`, and by the class
of an error. Lesson 14 gave every field a `<label>` tied to it, so a test could also find a field
by its label, which is how a screen reader user finds it. Vue Test Utils does not do that itself,
and the companion library *Testing Library* (`@testing-library/vue`) is built around exactly that
idea. For a form this small, selectors are clear enough, and they break only when the markup does.
