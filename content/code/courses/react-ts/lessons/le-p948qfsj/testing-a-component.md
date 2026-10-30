---
title: A component, and the numbers from lesson 1
version: 1
---

**Lesson 1 opened the finished planner and read *80 of 195 minutes done* off the screen, and promised a
test that checks it.** This is that test, `src/WeekSummary.test.tsx`:

```tsx
import { render, screen } from '@testing-library/react'
import { expect, it } from 'vitest'
import type { Session } from './types'
import { WeekSummary } from './WeekSummary'

// The week of 19 October 2026 as public/courses.json has it.
const week: Session[] = [
  { id: 's1', course: 'statistics', date: '2026-10-19', minutes: 50, done: true },
  { id: 's2', course: 'statistics', date: '2026-10-21', minutes: 40, done: false },
  { id: 's3', course: 'spanish', date: '2026-10-20', minutes: 30, done: true },
  { id: 's4', course: 'spanish', date: '2026-10-23', minutes: 30, done: false },
  { id: 's6', course: 'chemistry', date: '2026-10-22', minutes: 45, done: false },
]

it('says how much of the week is done', () => {
  render(<WeekSummary monday="2026-10-19" sessions={week} />)
  expect(screen.getByText('Week of 19 Oct 2026')).toBeInTheDocument()
  expect(screen.getByText('80 of 195 minutes done')).toBeInTheDocument()
})
```

- **`render`** draws the component into jsdom's document, as `createRoot` draws it into a browser's.
- **`screen.getByText`** finds the element whose text is exactly that sentence, and throws if there is
  none, so a missing sentence fails the test even before `expect` runs.
- **The data is written out in the test**: the five sessions of that week, as the seed file has them.
  A test that read the file would break whenever somebody edited the seed, for a reason that has nothing
  to do with the summary.

`npm test -- WeekSummary` runs only the files whose name contains `WeekSummary`:

```
ana@dev:~/planner$ npm test -- WeekSummary

> planner@0.0.0 test
> vitest run WeekSummary


 RUN  v5.0.5 /home/ana/planner

 ✓ src/WeekSummary.test.tsx (1 test) 61ms

 Test Files  1 passed (1)
      Tests  1 passed (1)
   Start at  23:15:59
   Duration  1.27s (environment 53%, transform 32%, setup 9%, tests 5%, import 1%)
```

**A passing test says little until you have seen it fail.** Change the expected sentence to a wrong
number, and read what Vitest says:

```
ana@dev:~/planner$ sed -i 's/80 of 195 minutes done/85 of 195 minutes done/' src/WeekSummary.test.tsx && npm test -- WeekSummary

> planner@0.0.0 test
> vitest run WeekSummary


 RUN  v5.0.5 /home/ana/planner

 ❯ src/WeekSummary.test.tsx (1 test | 1 failed) 55ms
   × says how much of the week is done 53ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/WeekSummary.test.tsx > says how much of the week is done
TestingLibraryElementError: Unable to find an element with the text: 85 of 195 minutes done. This could be because the text is broken up by multiple elements. In this case, you can provide a function for your text matcher to make your matcher more flexible.

Ignored nodes: comments, script, style
<body>
  <div>
    <section
      aria-label="This week"
    >
      <p>
        Week of 
        19 Oct 2026
      </p>
      <p>
        80
         of 
        195
         minutes done
      </p>
    </section>
  </div>
</body>
 ❯ Object.getElementError node_modules/@testing-library/dom/dist/config.js:37:19
 ❯ node_modules/@testing-library/dom/dist/query-helpers.js:76:38
 ❯ node_modules/@testing-library/dom/dist/query-helpers.js:52:17
 ❯ node_modules/@testing-library/dom/dist/query-helpers.js:95:19
 ❯ src/WeekSummary.test.tsx:18:17
     16|   render(<WeekSummary monday="2026-10-19" sessions={week} />)
     17|   expect(screen.getByText('Week of 19 Oct 2026')).toBeInTheDocument()
     18|   expect(screen.getByText('85 of 195 minutes done')).toBeInTheDocument…
       |                 ^
     19| })
     20|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed (1)
      Tests  1 failed (1)
   Start at  23:16:01
   Duration  1.16s (environment 60%, transform 23%, setup 10%, tests 5%, import 1%)

ana@dev:~/planner$ sed -i 's/85 of 195 minutes done/80 of 195 minutes done/' src/WeekSummary.test.tsx && npm test -- WeekSummary | grep Tests
      Tests  1 passed (1)
```

Read it from the top:

- **`×` and the test's name**, under the file, and `FAIL` with both again: which test failed.
- **`Unable to find an element with the text: 85 of 195 minutes done`**: what went wrong, in Testing
  Library's words.
- **The document, as the test saw it.** The second paragraph is drawn as four pieces of text, `80`, `of`,
  `195` and `minutes done`, the four parts of the JSX expression; `getByText` matches their joined text,
  which is why the real sentence passes. Here it says `80`, and the test expected `85`.
- **The stack**, ending at line 18 of the test, with the line itself and a caret under the call.

The second command put the right number back. A wrong expectation and a wrong component fail the same
way, which is why the failure message shows what was really there: the reader decides which side is
wrong.
