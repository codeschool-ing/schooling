---
title: A ref is a box React does not watch
version: 1
---

**`useRef` gives a component an object with one property, `current`, that survives every render and
that React never looks at.** State is a value React watches: change it and the component renders
again. A ref is the opposite: change it and nothing happens, and the next render finds the value you
left there. That makes a ref the right place for anything a component needs to remember and does
not need to draw.

The smallest demonstration is a component that counts its own renders. It is temporary; save it as
`src/RenderCount.tsx`:

```tsx
import { useRef } from 'react'

// For lesson 7 only: a ref survives renders and changing it renders nothing.
export function RenderCount() {
  const renders = useRef(0)
  renders.current += 1
  console.log('RenderCount has rendered', renders.current, 'times')
  return null
}
```

It draws nothing, `return null`, and logs every time it is called. Put it under `WeekNav` in `App`,
and press "Next week" twice:

```
ana@dev:~/planner$ sed -i 's|^      <WeekNav .*|&\n      <RenderCount />|; 1a import { RenderCount } from "./RenderCount"' src/App.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet --do 'click button Next week' --do 'click button Next week'
RenderCount has rendered 1 times
RenderCount has rendered 2 times
-- click button Next week
RenderCount has rendered 3 times
RenderCount has rendered 4 times
-- click button Next week
RenderCount has rendered 5 times
RenderCount has rendered 6 times
ana@dev:~/planner$ sed -i '/RenderCount/d' src/App.tsx && rm src/RenderCount.tsx
```

Two lines per render, strict mode again, and the count carries on across them: 1 and 2 on load, 3 and
4 after the first click, 5 and 6 after the second. **The ref kept its value between renders, and
changing it did not cause one.** Had `renders` been state, `setRenders(renders + 1)` during the render
would have asked for another render, which would ask for another, and React would stop it with an
error about too many re-renders.

Changing `renders.current` during the render, as this does, breaks lesson 2's rule that a render
changes nothing, and strict mode's double count is the symptom: in a build, the number would be half.
That is acceptable for a throwaway counter and nowhere else. **Read and write a ref in effects and
event handlers, not while rendering**, and the next section does exactly that.

| | `useState` | `useRef` |
|---|---|---|
| survives between renders | yes | yes |
| changing it renders again | yes | no |
| read it while rendering | yes: that is what it is for | no: the value may be stale or half-changed |
| typical use | anything the screen shows | a DOM element, a timer's id, a value an effect needs and the screen does not |
