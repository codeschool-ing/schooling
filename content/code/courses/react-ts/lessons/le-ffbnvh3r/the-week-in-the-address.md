---
title: The week in the address
version: 1
---

**A course has an address now; the week does not.** It is still state inside `useWeek`, so this address
names a week and the planner ignores it:

```
ana@dev:~/planner$ look 'http://localhost:5173/?week=2026-10-12' --today 2026-10-21 | grep -E 'Week of|minutes done'
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
```

The 12th of October was asked for, and the current week came. A link to a week someone wanted to show
you, or a reload of the week you were looking at, lands on today's. The fix is lesson 15's: the week goes
in the address as a **search parameter**, `?week=2026-10-12`, which in Next.js was `searchParams` and in
React Router is `useSearchParams`. `src/useWeek.ts`:

```ts
import { useCallback, useEffect } from 'react'
import { useSearchParams } from 'react-router'
import { addDays, formatWeek, mondayOf, today } from './week'

const DAY = /^\d{4}-\d\d-\d\d$/

// The week on screen lives in the address, as ?week=YYYY-MM-DD, so that a link,
// a bookmark or a reload shows the same week.
export function useWeek() {
  const [params, setParams] = useSearchParams()
  const asked = params.get('week')
  const monday = mondayOf(asked && DAY.test(asked) ? asked : today())
  const setMonday = useCallback((m: string) => setParams({ week: m }), [setParams])

  useEffect(() => {
    document.title = `Week of ${formatWeek(monday)} · Study planner`
  }, [monday])

  useEffect(() => {
    function onKey(event: KeyboardEvent) {
      if (event.target instanceof HTMLInputElement) return
      if (event.key === 'ArrowLeft') setMonday(addDays(monday, -7))
      if (event.key === 'ArrowRight') setMonday(addDays(monday, 7))
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [monday, setMonday])

  return [monday, setMonday] as const
}
```

- **The state is gone.** `monday` is worked out from the address on every render, with today's week when
  the address names none, or names something that is not a date.
- **`setMonday` writes the address.** `setParams({ week: m })` changes the search part of the URL, which
  re-renders everything that reads it, and adds an entry to the history, so Back returns to the week
  before.
- **Nothing that called `useWeek` changes.** It still returns `[monday, setMonday]`, so `WeekScreen` and
  `WeekNav` are untouched, which is what a custom hook was for, in lesson 7.

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 71ms on 27 files with 116 rules using 4 threads.
no errors
```

```
ana@dev:~/planner$ look 'http://localhost:5173/?week=2026-10-12' --today 2026-10-21 | grep -E 'Week of|minutes done'
    - paragraph: Week of 12 Oct 2026
    - paragraph: 60 of 60 minutes done
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowLeft' | grep -E 'Week of|minutes done'
    - paragraph: Week of 12 Oct 2026
    - paragraph: 60 of 60 minutes done
```

The address names the 12th, and the planner shows the 12th, with its 60 minutes of chemistry. The arrow
key from lesson 5 still works, now by writing the address.

**What belongs in the address** is what someone would want to share or come back to: which screen,
which course, which week. What does not is what is private to this moment: whether a dialog is open,
what is typed in a field. Those stay in state.
