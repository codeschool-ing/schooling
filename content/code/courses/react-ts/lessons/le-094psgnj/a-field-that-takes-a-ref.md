---
title: A field that passes its ref on
version: 1
---

**In React 19, `ref` is a prop like any other.** A function component that receives one can hand it
to an element, and the element's node ends up wherever the ref points. Earlier versions treated `ref`
as special: it never reached the component, and passing one on needed a wrapper called
`forwardRef`. Code written before React 19 is full of it; new code does not need it.

The form inside the dialog has the same three lines twice: a label, an input with its accessibility
attributes, and an error paragraph. A component can say them once, `src/Field.tsx`:

```tsx
import { useId, type ComponentProps } from 'react'

type FieldProps = ComponentProps<'input'> & {
  label: string
  error?: string
}

export function Field({ label, error, ...input }: FieldProps) {
  const id = useId()
  return (
    <>
      <label htmlFor={id}>{label}</label>
      <input
        id={id}
        aria-invalid={error ? true : undefined}
        aria-describedby={error ? `${id}-error` : undefined}
        {...input}
      />
      {error && <p id={`${id}-error`}>{error}</p>}
    </>
  )
}
```

`ComponentProps<'input'>` is the type of every prop an `<input>` accepts, `ref` among them, and
`Field` adds two of its own, `label` and `error`. Everything else, `...input`, goes on to the input
unchanged. The form, `src/AddSessionForm.tsx`, now reads as a list of its fields:

```tsx
import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { Field } from './Field'
import { usePlannerContext } from './plannerContext'
import { sessionSchema, type SessionInput } from './sessionSchema'

type AddSessionFormProps = {
  course: string
  onAdded: (session: SessionInput) => void
}

export function AddSessionForm({ course, onAdded }: AddSessionFormProps) {
  const { addSession } = usePlannerContext()
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
    addSession(
      { course, ...values },
      {
        onSuccess: () => {
          reset()
          onAdded(values)
        },
      },
    )
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate>
      <Field label="Date" type="date" error={errors.date?.message} {...register('date')} />
      <Field
        label="Minutes"
        type="number"
        error={errors.minutes?.message}
        {...register('minutes', { valueAsNumber: true })}
      />
      <button type="submit">Add session</button>
    </form>
  )
}
```

`{...register('date')}` spreads four things into `Field`: `name`, `onChange`, `onBlur` and **`ref`**.
React Hook Form keeps the element it receives through that ref, reads the input's value from it, and
uses it to focus the first field with an error when a submit fails. The ref passes through `Field` to the `<input>` because, in
React 19, nothing stops it: it is one of the props in `...input`.

Two other changes. The heading went, because the dialog has one, and the form's caller learns when
a session has been saved: `addSession` is React Query's `mutate`, which takes a second argument of
callbacks **for this one call**, and `onSuccess` runs once the server has answered. Only then does
the form reset and tell its caller, which closes the dialog. A form that closed on submit would close
on a session the server then refused.

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session' --do 'click button Add session' | sed -n '/dialog/,$p'
  - dialog "Plan a session":
    - heading "Plan a session" [level=2]
    - text: Date
    - textbox "Date" [invalid]
    - paragraph: Choose the day of the session.
    - text: Minutes
    - spinbutton "Minutes": "30"
    - button "Add session"
    - button "Close"
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click button Plan a session' --do 'fill Date=2026-10-24' --do 'fill Minutes=45' --do 'click button Add session' | grep -E 'dialog|checkbox'
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - checkbox "Wed 21 Oct · 40 min"
      - checkbox "Sat 24 Oct · 45 min"
```

The first page submits the form empty: the dialog stays, `Date` is `[invalid]`, and the schema's
message is under it. The second fills both fields and submits: **the dialog has gone, and Saturday's
45 minutes is in the list.** The checkboxes are the course screen's, drawn again from the cache after
the invalidation lesson 11 set up.
