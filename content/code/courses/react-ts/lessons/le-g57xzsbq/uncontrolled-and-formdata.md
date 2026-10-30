---
title: Letting the browser hold the values
version: 1
---

**An uncontrolled input keeps its own value, in the DOM, and React reads it once, when the form is
submitted.** No state per field, no `onChange`, no render per keystroke. The browser has always been
able to collect a form's values, and `FormData` is how a handler asks for them:

```tsx
import type { FormEvent } from 'react'
import { usePlannerContext } from './plannerContext'

export function AddSessionForm({ course }: { course: string }) {
  const { addSession } = usePlannerContext()

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    addSession({ course, date: String(form.get('date')), minutes: Number(form.get('minutes')) })
    event.currentTarget.reset()
  }

  return (
    <form onSubmit={submit}>
      <h2>Add a session</h2>
      <label>
        Date
        <input name="date" type="date" required />
      </label>
      <label>
        Minutes
        <input name="minutes" type="number" defaultValue={30} min={5} max={240} required />
      </label>
      <button type="submit">Add session</button>
    </form>
  )
}
```

```schooling-figure
{"svg": "<svg data-fig=\"controlled\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two ways a field's value travels. Controlled: the value lives in React state, flows into the input as the value prop, and every keystroke calls onChange, which sets the state, which renders the input again. Uncontrolled: the value lives in the DOM input itself, and React reads it once, on submit, through FormData.\"><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">controlled</text><rect x=\"40\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">useState</text><rect x=\"200\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;input&gt;</text><line x1=\"162\" y1=\"52\" x2=\"198\" y2=\"52\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"198.0,52.0 190.5,55.2 190.5,48.8\" fill=\"var(--phosphor)\"></polygon><text x=\"180\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">value</text><line x1=\"198\" y1=\"72\" x2=\"162\" y2=\"72\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"162.0,72.0 169.5,68.8 169.5,75.2\" fill=\"var(--amber)\"></polygon><text x=\"180\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">onChange</text><text x=\"180\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every keystroke renders</text><text x=\"180\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the screen can react at once</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">uncontrolled</text><rect x=\"400\" y=\"40\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;input name&gt;</text><rect x=\"560\" y=\"40\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">onSubmit</text><line x1=\"522\" y1=\"60\" x2=\"558\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,60.0 550.5,63.2 550.5,56.8\" fill=\"var(--amber)\"></polygon><text x=\"540\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">new FormData(form)</text><text x=\"540\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">typing renders nothing</text><text x=\"540\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">React reads the value once</text><line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line></svg>", "caption": "Controlled: React holds the value. Uncontrolled: the DOM holds it until submit."}
```

- **`name` on each input** is what `FormData` collects by: `form.get('date')` is the date field's
  text.
- **`defaultValue={30}`**, not `value`: it sets the starting value and then leaves the field alone. A
  `value` without an `onChange` would freeze the field, and React warns about exactly that.
- **`event.currentTarget.reset()`** empties the form after adding, the browser's own way, with no
  state to clear.
- **`required`, `min` and `max`** are the browser's validation, which the next section looks at.

Which to write? **Controlled when the screen has to react while the user types**: a character count,
a field that enables another, a search that filters as it goes. **Uncontrolled when the values matter
only on submit**, which is most forms, including this one. Both are React; neither is the old way.
The form libraries in the rest of this lesson are mostly uncontrolled underneath, and lesson 16 shows
React 19 handing a form's `FormData` straight to a function with no handler at all.
