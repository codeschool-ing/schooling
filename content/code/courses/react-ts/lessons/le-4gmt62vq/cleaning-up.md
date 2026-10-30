---
title: Cleaning up after yourself
version: 1
---

**Whatever an effect starts, it has to be able to stop.** The third effect in `App` listens for the
arrow keys anywhere on the page, so that the left and right arrows move between weeks:

```tsx
useEffect(() => {
  function onKey(event: KeyboardEvent) {
    if (event.target instanceof HTMLInputElement) return
    if (event.key === 'ArrowLeft') setMonday((m) => addDays(m, -7))
    if (event.key === 'ArrowRight') setMonday((m) => addDays(m, 7))
  }
  window.addEventListener('keydown', onKey)
  return () => window.removeEventListener('keydown', onKey)
}, [])
```

The listener ignores keys pressed in an input, where the arrows move the cursor, and it uses the
updater form from lesson 4 because the effect runs once and its own `monday` would be stuck at the
first week forever. The cleanup removes exactly the function it added, which is why `onKey` is a
named function and not an anonymous one written twice.

```
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowRight' | grep 'Week of'
    - paragraph: Week of 26 Oct 2026
```

One press, one week. **Now take the cleanup out**, the line that returns `removeEventListener`:

```
ana@dev:~/planner$ sed -i '/return () => window.removeEventListener/d' src/App.tsx
ana@dev:~/planner$ grep -n "addEventListener\|removeEventListener" src/App.tsx
51:    window.addEventListener('keydown', onKey)
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowRight' | grep 'Week of'
    - paragraph: Week of 2 Nov 2026
ana@dev:~/planner$ sed -i 's|^    window.addEventListener(.keydown., onKey)$|&\n    return () => window.removeEventListener('"'"'keydown'"'"', onKey)|' src/App.tsx
ana@dev:~/planner$ grep -n "addEventListener\|removeEventListener" src/App.tsx
51:    window.addEventListener('keydown', onKey)
52:    return () => window.removeEventListener('keydown', onKey)
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'press ArrowRight' | grep 'Week of'
    - paragraph: Week of 26 Oct 2026
```

**One press, two weeks: 2 November.** Strict mode ran the effect, ran its cleanup, which no longer
existed, and ran the effect again, so two listeners were attached to the window and both moved the
week. With the cleanup back, one press moves one week again.

```schooling-figure
{"svg": "<svg data-fig=\"strict-effects\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Strict mode on the first load: effect, cleanup, effect. With a cleanup, the listener count goes 1, 0, 1, and one key press moves one week. Without one, the cleanup step does nothing and the count goes 1, 1, 2, so one key press moves two weeks.\"><text x=\"20\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">with the cleanup</text><rect x=\"20\" y=\"40\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">effect</text><text x=\"80\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">listeners: 1</text><line x1=\"142\" y1=\"57\" x2=\"168\" y2=\"57\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,57.0 160.5,60.2 160.5,53.8\" fill=\"var(--wire)\"></polygon><rect x=\"170\" y=\"40\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cleanup</text><text x=\"230\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">listeners: 0</text><line x1=\"292\" y1=\"57\" x2=\"318\" y2=\"57\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,57.0 310.5,60.2 310.5,53.8\" fill=\"var(--wire)\"></polygon><rect x=\"320\" y=\"40\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">effect</text><text x=\"380\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">listeners: 1</text><text x=\"480\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">→ one week per press</text><text x=\"20\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">without it</text><rect x=\"20\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">effect</text><text x=\"80\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">listeners: 1</text><line x1=\"142\" y1=\"147\" x2=\"168\" y2=\"147\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"168.0,147.0 160.5,150.2 160.5,143.8\" fill=\"var(--wire)\"></polygon><rect x=\"170\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"230.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">cleanup</text><text x=\"230\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">listeners: 1</text><line x1=\"292\" y1=\"147\" x2=\"318\" y2=\"147\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"318.0,147.0 310.5,150.2 310.5,143.8\" fill=\"var(--wire)\"></polygon><rect x=\"320\" y=\"130\" width=\"120\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"147.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">effect</text><text x=\"380\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">listeners: 2</text><text x=\"480\" y=\"147\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">→ two weeks per press</text></svg>", "caption": "Strict mode's second run makes a missing cleanup show on the first load."}
```

That is what strict mode's second run is for. It cannot see your listener, but it can make a missing
cleanup visible on the first load, in development, instead of the day a user opens and closes the
course screen thirty times and every arrow press moves thirty weeks. **An effect that behaves the
same when run, cleaned up and run again is an effect that cleans up correctly**, and that is the only
kind worth shipping.

A note on the keys themselves. Arrow keys are not printable characters, so WCAG's rule about
single-character shortcuts does not apply to them; the planner still offers the same action on two
buttons, which is the version every user can reach. A shortcut is an extra, never the only way.
