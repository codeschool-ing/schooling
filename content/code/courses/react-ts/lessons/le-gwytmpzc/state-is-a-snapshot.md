---
title: State is a snapshot
version: 1
---

**`useState` gives a component a value React keeps between renders, and a function that asks for a
different one next time.** That second half is the one people get wrong. Calling the setter does
not change the variable you are holding; it schedules a new render, and the new value arrives in
that render. Lesson 3 used `setMonday` as a trigger. This section looks at what it actually does.

```tsx
const [monday, setMonday] = useState(() => mondayOf(today()))
```

Three things are packed into that line:

- **The initial value**, used on the first render only. Here it is a function, `() => mondayOf(today())`,
  which React calls once; passing `mondayOf(today())` directly would work too, and would compute the
  date on every render only to throw it away.
- **`monday`**, the value for this render. It is a plain constant, and nothing can change it while this
  render's code runs.
- **`setMonday`**, which tells React: next time you render this component, `monday` is this.

## One click, two calls

A throwaway component makes the difference visible. It calls the setter twice in one click, as code
does that tries to move two weeks by moving one week twice, and logs `monday` afterwards. Save it as
`src/TwoWeeks.tsx`; it is for this lesson only:

```tsx
import type { Dispatch, SetStateAction } from 'react'
import { addDays } from './week'

type TwoWeeksProps = {
  monday: string
  setMonday: Dispatch<SetStateAction<string>>
}

// For lesson 4 only: one click, two calls to the setter.
export function TwoWeeks({ monday, setMonday }: TwoWeeksProps) {
  function jump() {
    setMonday(addDays(monday, 7))
    setMonday(addDays(monday, 7))
    console.log('after both calls, monday is', monday)
  }
  return (
    <button type="button" onClick={jump}>
      Two weeks on
    </button>
  )
}
```

Put it under `WeekNav` in `App`, and press it once:

```
ana@dev:~/planner$ sed -i 's|^      <WeekNav .*|&\n      <TwoWeeks monday={monday} setMonday={setMonday} />|; 1a import { TwoWeeks } from "./TwoWeeks"' src/App.tsx
ana@dev:~/planner$ grep -n TwoWeeks src/App.tsx
2:import { TwoWeeks } from "./TwoWeeks"
16:      <TwoWeeks monday={monday} setMonday={setMonday} />
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Two weeks on' | head -n 11
-- click button Two weeks on
after both calls, monday is 2026-10-19
- main:
  - heading "Study planner" [level=1]
  - navigation "Week":
    - button "Previous week"
    - button "Next week"
  - button "Two weeks on"
  - region "This week":
    - paragraph: Week of 26 Oct 2026
    - paragraph: 0 of 0 minutes done
```

Two things went wrong, and both are the same thing. **The log says `2026-10-19`**, after two calls
that each asked for the 26th: `monday` is this render's constant, and asking for a new value did not
reach back and change it. **And the week moved by one**, to the 26th, not two. Both calls computed
`addDays(monday, 7)` from the same snapshot, so both asked for the 26th, and asking twice for the same
value is asking once.

```schooling-figure
{"svg": "<svg data-fig=\"snapshot\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two rows, one click each. Top row, with values: the render has monday 19 Oct, the click handler calls set 26 Oct twice, both computed from the snapshot, and the next render has 26 Oct. Bottom row, with updater functions: the queue runs 19 to 26, then 26 to 2 Nov, and the next render has 2 Nov. In both rows the handler's own monday stays 19 Oct.\"><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">setMonday(value)</text><rect x=\"20\" y=\"40\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render</text><text x=\"85.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday = 19 Oct</text><line x1=\"152\" y1=\"68\" x2=\"188\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,68.0 180.5,71.2 180.5,64.8\" fill=\"var(--wire)\"></polygon><rect x=\"190\" y=\"40\" width=\"330\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"202\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">click handler, one event</text><rect x=\"202\" y=\"66\" width=\"146\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">set 26 Oct</text><rect x=\"360\" y=\"66\" width=\"146\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"433.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">set 26 Oct</text><line x1=\"522\" y1=\"68\" x2=\"558\" y2=\"68\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,68.0 550.5,71.2 550.5,64.8\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"40\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">next render</text><text x=\"630.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">monday = 26 Oct</text><text x=\"20\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">setMonday(function)</text><rect x=\"20\" y=\"150\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">render</text><text x=\"85.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monday = 19 Oct</text><line x1=\"152\" y1=\"178\" x2=\"188\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,178.0 180.5,181.2 180.5,174.8\" fill=\"var(--wire)\"></polygon><rect x=\"190\" y=\"150\" width=\"330\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"202\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">click handler, one event</text><rect x=\"202\" y=\"176\" width=\"146\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">19 → 26 Oct</text><rect x=\"360\" y=\"176\" width=\"146\" height=\"22\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"433.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">26 Oct → 2 Nov</text><line x1=\"522\" y1=\"178\" x2=\"558\" y2=\"178\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"558.0,178.0 550.5,181.2 550.5,174.8\" fill=\"var(--wire)\"></polygon><rect x=\"560\" y=\"150\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"171.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">next render</text><text x=\"630.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">monday = 2 Nov</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the handler's own monday is 19 Oct in both rows</text></svg>", "caption": "A value asks twice for the same thing; a function is handed what the last one returned."}
```

React also did not render twice. **Every setter called during one event is collected and applied
together**, and the component renders once afterwards. This is called batching, and it is why a
handler that sets three pieces of state produces one render rather than three intermediate screens.
