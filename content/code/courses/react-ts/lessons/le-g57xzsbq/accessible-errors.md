---
title: The form, with errors a screen reader can find
version: 1
---

**An error message is useful only if the person who made the error can find it.** For a sighted
user that means text beside the field. For a screen-reader user it means the field itself says it is
invalid, the message is attached to it, and focus goes to it. This is the form with React Hook Form,
the schema, and all three:

```tsx
import { zodResolver } from '@hookform/resolvers/zod'
import { useId } from 'react'
import { useForm } from 'react-hook-form'
import { usePlannerContext } from './plannerContext'
import { sessionSchema, type SessionInput } from './sessionSchema'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()
  const id = useId()
  const {
    register,
    handleSubmit,
    reset,
    formState: { errors },
  } = useForm<SessionInput>({
    resolver: zodResolver(sessionSchema),
    defaultValues: { date: '', minutes: 30 },
  })

  function submit(values: SessionInput) {
    addSession({ course, ...values })
    reset()
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate>
      <h2>Add a session</h2>
      <label htmlFor={`${id}-date`}>Date</label>
      <input
        id={`${id}-date`}
        type="date"
        aria-invalid={errors.date ? true : undefined}
        aria-describedby={errors.date ? `${id}-date-error` : undefined}
        {...register('date')}
      />
      {errors.date && <p id={`${id}-date-error`}>{errors.date.message}</p>}
      <label htmlFor={`${id}-minutes`}>Minutes</label>
      <input
        id={`${id}-minutes`}
        type="number"
        aria-invalid={errors.minutes ? true : undefined}
        aria-describedby={errors.minutes ? `${id}-minutes-error` : undefined}
        {...register('minutes', { valueAsNumber: true })}
      />
      {errors.minutes && <p id={`${id}-minutes-error`}>{errors.minutes.message}</p>}
      <button type="submit">Add session</button>
    </form>
  )
}
```

- **`useForm` with `zodResolver(sessionSchema)`** runs the schema on submit and fills `errors` with
  its messages. `defaultValues` gives the starting values, and `reset()` returns to them.
- **`{...register('date')}`** spreads the props the library needs, `name`, `ref`, `onChange` and
  `onBlur`, onto the input; `valueAsNumber` hands the schema a number for the minutes, as it expects.
- **`handleSubmit(submit)`** calls `submit` only with values the schema accepted, already typed as
  `SessionInput`.
- **`noValidate`** turns off the browser's bubbles, because the form now shows its own messages; the
  `min` and `max` attributes went with them, since the schema holds those rules.
- **`useId`** makes ids unique per form, so two forms on one page cannot collide; React writes them like
  `_r_0_`, as the transcript shows.

Submit with no date and 500 minutes:

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 82ms on 17 files with 116 rules using 4 threads.
no errors
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Minutes=500' --do 'click button Add session' | sed -n '/heading "Add/,$p'
  - heading "Add a session" [level=2]
  - text: Date
  - textbox "Date" [invalid]
  - paragraph: Choose the day of the session.
  - text: Minutes
  - spinbutton "Minutes" [invalid]: "500"
  - paragraph: A session is at most 240 minutes.
  - button "Add session"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Minutes=500' --do 'click button Add session' --quiet --html ':focus'
-- click button Statistics
-- fill Minutes=500
-- click button Add session
<input id="_r_0_-date" type="date" name="date" aria-invalid="true" aria-describedby="_r_0_-date-error">
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Minutes=500' --do 'click button Add session' --quiet --html 'input[aria-invalid]'
-- click button Statistics
-- fill Minutes=500
-- click button Add session
<input id="_r_0_-date" type="date" name="date" aria-invalid="true" aria-describedby="_r_0_-date-error">
```

Both fields are marked `[invalid]` in the snapshot, which is `aria-invalid="true"`, and each message is
a paragraph under its field. **Focus went to the first invalid field**, the date, because React Hook
Form focuses it by default; the field's `aria-describedby` points at its message, so a screen reader
announces the field, that it is invalid, and "Choose the day of the session." The user lands on
the problem and hears what it is.

Correct both and the messages go as the fields change, because after a failed submit the library checks
again on every change; submit, and the session is added and the form empties:

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Minutes=500' --do 'click button Add session' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' | sed -n '/heading "Add/,$p'
  - heading "Add a session" [level=2]
  - text: Date
  - textbox "Date": 2026-10-24
  - text: Minutes
  - spinbutton "Minutes": "45"
  - button "Add session"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | sed -n '/list:/,$p'
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
    - listitem:
      - checkbox "Sat 24 Oct · 45 min"
      - text: Sat 24 Oct · 45 min
  - heading "Add a session" [level=2]
  - text: Date
  - textbox "Date"
  - text: Minutes
  - spinbutton "Minutes": "30"
  - button "Add session"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' --do 'click button Back to courses' | grep minutes
    - paragraph: 80 of 240 minutes done
```

240 minutes planned now, 195 plus 45. This is the form the planner keeps.

| what makes it findable | how |
|---|---|
| the field has a name | a `<label>` tied to it with `htmlFor` |
| the field says it is wrong | `aria-invalid` |
| the message belongs to the field | `aria-describedby` pointing at the message's `id` |
| the user is taken to it | focus on the first invalid field |
| the message says what to do | "Choose the day of the session", not "Invalid" |
