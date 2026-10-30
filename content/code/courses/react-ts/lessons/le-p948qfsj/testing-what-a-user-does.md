---
title: Testing what a person does
version: 1
---

**Most components are worth testing for what happens when someone uses them.** `WeekNav` has no text
to check; its whole job is to ask for the next or the previous Monday when a button is pressed.
`src/WeekNav.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, it, vi } from 'vitest'
import { WeekNav } from './WeekNav'

it('asks for the next and the previous Monday', async () => {
  const user = userEvent.setup()
  const onChange = vi.fn()
  render(<WeekNav monday="2026-10-19" onChange={onChange} />)

  await user.click(screen.getByRole('button', { name: 'Next week' }))
  await user.click(screen.getByRole('button', { name: 'Previous week' }))

  expect(onChange).toHaveBeenNthCalledWith(1, '2026-10-26')
  expect(onChange).toHaveBeenNthCalledWith(2, '2026-10-12')
})
```

- **`vi.fn()`** is a function that remembers how it was called. It stands in for `setMonday`, so the test
  can ask what `WeekNav` asked for.
- **`userEvent.setup()`** makes a user, and **`await user.click(…)`** presses a button as a person
  would: pointer down, focus, pointer up, click, each event in its order. The `await` is real, because
  the events are dispatched one after another.
- **`getByRole('button', { name: 'Next week' })`** finds the button by what a screen reader would
  announce, the same role and name `look` prints. A test written this way fails when the button stops
  being a button or loses its name, which are failures a user would notice too.

```schooling-figure
{"svg": "<svg data-fig=\"anatomy\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The four steps of a component test. Arrange: render the component into jsdom's document, with fake functions for what it calls. Act: a user, from user-event, clicks and types. Find: queries by role, label or text, as a person or a screen reader would. Assert: expect what is on the page, or what the fake functions were called with.\"><text x=\"94\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">arrange</text><rect x=\"14\" y=\"50\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"94.0\" y=\"75.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">render(…)</text><text x=\"94.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">vi.fn()</text><line x1=\"176\" y1=\"82\" x2=\"188\" y2=\"82\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,82.0 180.5,85.2 180.5,78.8\" fill=\"var(--wire)\"></polygon><text x=\"270\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">act</text><rect x=\"190\" y=\"50\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"75.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">user.click(…)</text><text x=\"270.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">user.type(…)</text><line x1=\"352\" y1=\"82\" x2=\"364\" y2=\"82\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"364.0,82.0 356.5,85.2 356.5,78.8\" fill=\"var(--wire)\"></polygon><text x=\"446\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">find</text><rect x=\"366\" y=\"50\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"75.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">getByRole(…)</text><text x=\"446.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">findByText(…)</text><line x1=\"528\" y1=\"82\" x2=\"540\" y2=\"82\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,82.0 532.5,85.2 532.5,78.8\" fill=\"var(--wire)\"></polygon><text x=\"622\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">assert</text><rect x=\"542\" y=\"50\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"75.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">toBeInTheDocument()</text><text x=\"622.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">toHaveBeenCalledWith</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">in jsdom: a document with no screen, inside Node.js</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">queries by role and name fail when a user would notice</text></svg>", "caption": "Draw it, use it, find what a person would see, check it."}
```

```
ana@dev:~/planner$ npm test -- WeekNav

> planner@0.0.0 test
> vitest run WeekNav


 RUN  v5.0.5 /home/ana/planner

 ✓ src/WeekNav.test.tsx (1 test) 214ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  23:16:05
   Duration  1.78s (environment 58%, transform 20%, tests 13%, setup 7%, import 2%)
```

The form from lessons 10 and 14 is the most interesting component to test, because it reads the
planner's context. **A test can provide a context of its own**, with fake actions in it,
`src/AddSessionForm.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { AddSessionForm } from './AddSessionForm'
import { PlannerContext, type Planner } from './plannerContext'

function renderForm() {
  const addSession = vi.fn()
  const planner: Planner = {
    status: 'ready',
    courses: [],
    sessions: [],
    toggleDone: vi.fn(),
    addSession,
  }
  render(
    <PlannerContext value={planner}>
      <AddSessionForm course="statistics" onAdded={vi.fn()} />
    </PlannerContext>,
  )
  return { addSession, user: userEvent.setup() }
}

describe('AddSessionForm', () => {
  it('says what is missing, and sends nothing', async () => {
    const { addSession, user } = renderForm()
    await user.click(screen.getByRole('button', { name: 'Add session' }))

    expect(await screen.findByText('Choose the day of the session.')).toBeInTheDocument()
    expect(screen.getByLabelText('Date')).toHaveAttribute('aria-invalid', 'true')
    expect(addSession).not.toHaveBeenCalled()
  })

  it('sends the session that was typed', async () => {
    const { addSession, user } = renderForm()
    await user.type(screen.getByLabelText('Date'), '2026-10-24')
    await user.clear(screen.getByLabelText('Minutes'))
    await user.type(screen.getByLabelText('Minutes'), '45')
    await user.click(screen.getByRole('button', { name: 'Add session' }))

    expect(addSession).toHaveBeenCalledWith(
      { course: 'statistics', date: '2026-10-24', minutes: 45 },
      expect.anything(),
    )
  })
})
```

- **`renderForm`** draws the form inside a `PlannerContext` holding a ready planner and a fake
  `addSession`, and returns what each test needs. TypeScript checks the fake against the real `Planner`
  type, so a fake missing a field does not compile.
- **The first test** submits an empty form and waits, with `findByText`, for the schema's message:
  React Hook Form validates asynchronously, and `find…` keeps looking until the text appears or a
  timeout passes. The date field is then marked invalid, and **nothing was sent**, which is the point.
- **The second** types a date and 45 minutes, and checks what `addSession` received: the session, and a
  second argument, the `onSuccess` lesson 14 passed, which `expect.anything()` accepts without caring
  about.

```
ana@dev:~/planner$ npm test -- AddSessionForm

> planner@0.0.0 test
> vitest run AddSessionForm


 RUN  v5.0.5 /home/ana/planner

 ✓ src/AddSessionForm.test.tsx (2 tests) 282ms

 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  23:16:07
   Duration  1.68s (environment 38%, transform 32%, tests 18%, setup 7%, import 5%)
```

And everything together, with the lint and the type check first, as a change should be checked:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && npm test

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 72ms on 36 files with 116 rules using 4 threads.

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/WeekSummary.test.tsx (1 test) 66ms
 ✓ src/WeekNav.test.tsx (1 test) 259ms
 ✓ src/AddSessionForm.test.tsx (2 tests) 288ms
 ✓ src/week.test.ts (4 tests) 5ms

 Test Files  4 passed (4)
      Tests  8 passed (8)
   Start at  23:16:13
   Duration  2.29s (environment 71%, tests 12%, setup 10%, import 4%, transform 2%)

Environment  jsdom was created 4 times · 3.61s total, 71% of tracked time
             create it once per worker with pool: 'vmThreads' (keeps per-file isolation) or isolate: false (shares it across files)
             learn more: https://vitest.dev/guide/improving-performance#test-environments
```

Eight tests in four files. The note at the end is Vitest's own advice: each test file gets a fresh
jsdom, which is most of the time spent, and it names two ways to share one. Four files do not need it.

**What is worth a test** is what would hurt if it broke quietly: the arithmetic every number on the
screen comes from, what a form sends, what the screen says for a given state. What is not is what the
library already tests, or the exact layout of the markup: a test that fails when a `<p>` becomes a
`<div>` is a test that will be deleted.
