---
title: The store, and a network the test controls
version: 1
---

**A test must not depend on a server being up, so where the code calls `fetch`, the test puts in a
`fetch` of its own that answers what the test chooses.** The planner store of lesson 13 loads the data
with `fetch(import.meta.env.VITE_DATA_URL)`, keeps one request however many callers ask, reports a
failure in `error`, and saves the sessions in `localStorage`. All four are worth a test:

```typescript
// src/stores/planner.test.ts: the store, with the network replaced by an answer the test chooses.
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { nextTick } from 'vue'
import { createPinia, setActivePinia } from 'pinia'
import { usePlannerStore } from './planner.js'

const data = {
  courses: [{ id: 'spanish', title: 'Spanish', goal: 120 }],
  sessions: [{ id: 's1', course: 'spanish', date: '2026-10-19', minutes: 30, done: false }],
}

// What fetch will answer, for the test that calls this.
function answer(body: unknown, status = 200, statusText = 'OK') {
  const fetch = vi.fn(async () => new Response(JSON.stringify(body), { status, statusText }))
  vi.stubGlobal('fetch', fetch)
  return fetch
}

describe('the planner store', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
  })
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('loads the courses and sessions from the data address', async () => {
    const fetch = answer(data)
    const planner = usePlannerStore()
    await planner.load()
    expect(fetch).toHaveBeenCalledWith('/courses.json')
    expect(planner.titles).toEqual({ spanish: 'Spanish' })
    expect(planner.source).toBe('courses.json')
  })

  it('asks once, however many times it is asked to load', async () => {
    const fetch = answer(data)
    const planner = usePlannerStore()
    await Promise.all([planner.load(), planner.load(), planner.load()])
    expect(fetch).toHaveBeenCalledTimes(1)
  })

  it('says what went wrong when the server fails', async () => {
    answer({}, 503, 'Service Unavailable')
    const planner = usePlannerStore()
    await planner.load()
    expect(planner.error).toBe('Could not load the courses: 503 Service Unavailable')
  })

  it('keeps a tick in this browser', async () => {
    answer(data)
    const planner = usePlannerStore()
    await planner.load()
    const saved = () => JSON.parse(localStorage.getItem('planner.sessions') ?? '[]')
    planner.toggle('s1')
    // The watcher that saves runs before the next render, not on the spot.
    expect(saved()[0].done).toBe(false)
    await nextTick()
    expect(saved()[0].done).toBe(true)
  })
})
```

`vi.fn` makes a function that records how it was called, and `vi.stubGlobal('fetch', …)` puts it
where the store will look for `fetch`; `vi.unstubAllGlobals()` after each test puts the real one back.
The fake answers with a real `Response`, the class `fetch` itself returns, so the store reads it with
`response.ok` and `response.json()` exactly as it reads a server's. `import.meta.env.VITE_DATA_URL` is
`/courses.json` in a test too, because Vitest reads `.env` as Vite does.

```
ana@dev:~/vue/planner$ npx vitest run src/stores/planner.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/stores/planner.test.ts (4 tests) 14ms

 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  22:07:18
   Duration  787ms (environment 82%, import 11%, transform 5%, tests 2%, worker 1%)
```

## Two of them are about time

**The second test is lesson 13's `loading ??=` held to its promise**: three calls, one request. A
change that lost the line would still pass the first test and fail this one, which is what the
first test could never say.

**The last one is about when, not what.** The store saves with a `watch`, and lesson 4 showed that a
watcher runs before the next render rather than on the spot. So right after `toggle`, the saved copy
in `localStorage` is still the one written at load, with the session not done, and after `nextTick()`
it is the new one. A test that read `localStorage` without waiting would fail, and one that waited
without checking the moment before would not notice if the save ever became synchronous. Writing both
lines makes the timing part of what is tested.

`localStorage` itself is jsdom's, empty for each test because `beforeEach` clears it, as the store is
new for each test because `setActivePinia(createPinia())` makes a new one. Pinia also publishes
`@pinia/testing`, whose `createTestingPinia` replaces every action with a recording one, for a test
of a component that should only check that it *called* the store. The planner's tests use the real
store, which is small and fast enough to be the cheaper choice.
