---
title: Asynchronous code, and a clock the test sets
version: 1
---

**A page that waits, for data, for a timer, for the next render, is tested by making the test wait
for exactly that, and never by sleeping.** The week page waits for all three: the store's data, the
next tick after it, and the minute timer of lesson 10's `useToday` that moves *today* at midnight.
Its test:

```typescript
// src/views/HomeView.test.ts: the week page, on a clock the test sets.
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import HomeView from './HomeView.vue'
import { usePlannerStore } from '../stores/planner.js'
import courses from '../../public/courses.json'

describe('the week page', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
    // Wednesday 21 October 2026, ten in the morning, for every date the page asks for.
    vi.useFakeTimers({ now: new Date(2026, 9, 21, 10, 0) })
    vi.stubGlobal('fetch', async () => new Response(JSON.stringify(courses)))
  })
  afterEach(() => {
    vi.useRealTimers()
    vi.unstubAllGlobals()
  })

  async function page() {
    await usePlannerStore().load()
    // Links need a router and the dialog a body to go to; neither is what this test is about.
    const week = mount(HomeView, { global: { stubs: { RouterLink: true, Teleport: true } } })
    await flushPromises()
    return week
  }

  it('shows the week of the day it is opened, with its totals', async () => {
    const week = await page()
    expect(week.get('section:nth-of-type(2) h2').text()).toBe('Week of 19 October 2026')
    expect(week.text()).toContain('75 of 195 minutes done')
  })

  it('moves today to the next day when midnight passes', async () => {
    const week = await page()
    expect(week.get('li.today').text()).toContain('21 October 2026')
    vi.setSystemTime(new Date(2026, 9, 22, 0, 0, 30))
    await vi.advanceTimersByTimeAsync(60_000)
    expect(week.get('li.today').text()).toContain('22 October 2026')
  })
})
```

Three tools, one per kind of waiting:

- **`flushPromises()`** waits until every promise already started has settled, the store's `load`
  and anything that followed it, and then lets Vue redraw. It is the general *wait for the
  asynchronous work to finish*, when there is no single promise to `await`.
- **`vi.useFakeTimers({ now })`** replaces the clock: `new Date()` says what the test says, and
  `setInterval` and `setTimeout` do not run until the test lets time pass. Both of the week page's
  dates, its Monday and its today, come from that clock.
- **`vi.advanceTimersByTimeAsync(60_000)`** lets a minute pass at once, running the timers that fall
  due in it and the promises they start. The second test moves the clock past midnight first, then
  lets the minute pass, and the page's *today* moves with it.

`stubs` replaces two components with empty stand-ins: `RouterLink`, which needs a router this test
has no use for, and `Teleport`, so lesson 15's dialog is drawn where it is written instead of being
sent to a `<body>` the wrapper does not look at.

```
ana@dev:~/vue/planner$ npx vitest run src/views/HomeView.test.ts

 RUN  v5.0.5 /home/ana/vue/planner

 ✓ src/views/HomeView.test.ts (2 tests) 114ms

 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  22:07:19
   Duration  1.12s (environment 57%, transform 19%, import 13%, tests 11%)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 222\" role=\"img\" aria-label=\"The second test of the week page, on the clock the test sets, from left to right. useFakeTimers sets the clock to 21 October 2026 at ten in the morning. flushPromises waits for the store&#x27;s load and the redraw after it, and li.today contains 21 October 2026. setSystemTime moves the clock to 00:00:30 on 22 October. advanceTimersByTimeAsync lets a minute pass at once, the page&#x27;s minute timer runs, and li.today contains 22 October 2026. The whole file ran in about a tenth of a second.\"><line x1=\"20\" y1=\"120\" x2=\"705\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"705.0,120.0 697.6,123.1 697.6,116.9\" fill=\"var(--wire)\"></polygon><rect x=\"25\" y=\"30\" width=\"165\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"107\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">useFakeTimers</text><text x=\"107\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">21 Oct 2026, 10:00</text><line x1=\"37\" y1=\"78\" x2=\"37\" y2=\"122\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><rect x=\"195\" y=\"150\" width=\"165\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"277\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">flushPromises()</text><text x=\"277\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">load done, page drawn</text><line x1=\"207\" y1=\"150\" x2=\"207\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><rect x=\"365\" y=\"30\" width=\"165\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"447\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">setSystemTime</text><text x=\"447\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">22 Oct, 00:00:30</text><line x1=\"377\" y1=\"78\" x2=\"377\" y2=\"122\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><rect x=\"535\" y=\"150\" width=\"165\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"617\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">advanceTimersByTimeAsync</text><text x=\"617\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a minute passes at once</text><line x1=\"547\" y1=\"150\" x2=\"547\" y2=\"118\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><text x=\"355\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">li.today: 21 October 2026</text><text x=\"702\" y=\"104\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">li.today: 22 October 2026</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the test's clock: midnight in about a tenth of a second</text></svg>", "caption": "The test sets the clock and lets time pass; every wait names what it waits for."}
```

**Midnight, tested in about a tenth of a second.** Without fake timers, the second test would either
wait a real minute, or reach into `useToday` to call its callback, which tests a function and not the
page. With them, it reads like what it checks: at 00:00:30 on the 22nd, a minute later, the
highlighted row is the 22nd.

## The rule underneath

Every one of those waits says what it is waiting for. A test that calls `setTimeout(…, 500)` and hopes
the page is ready by then passes on a fast computer and fails on a busy CI machine one run in twenty. A
test that fails sometimes is worse than none, because people learn to run it again until it passes. If a
test needs to wait and there is no tool that names what for, the code under test is the thing to change:
it should return its promise, as the store's `load` does.
