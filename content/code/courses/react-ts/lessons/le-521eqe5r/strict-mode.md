---
title: Strict mode renders twice on purpose
version: 1
---

**Every line was printed twice because `<StrictMode>` calls each component twice in development.**
It is the template's choice and a good one, and this section takes it out for a moment to show what
it is doing. The `sed` replaces `<StrictMode>` with a fragment and removes its import:

```
ana@dev:~/planner$ sed -i 's/<StrictMode>/<>/; s/<\/StrictMode>/<\/>/; /^import { StrictMode }/d' src/main.tsx
ana@dev:~/planner$ cat src/main.tsx
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

createRoot(document.getElementById('root')!).render(
  <>
    <App />
  </>,
)
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --quiet
render App
render WeekNav
render WeekSummary
render CourseList
render CourseCard
render Card
render CourseCard
render Card
render CourseCard
render Card
```

One call per component. Nothing on the page changed: the screen is the same with strict mode and
without it, and that is the point. **Strict mode calls your component a second time and throws the
result away, to find components that are not pure.** A pure component, called twice with the same
props, returns the same tree twice and nobody can tell. The component from lesson 2 that capitalised
its course's name would have capitalised it twice: harmless there, and not harmless in a component
that adds a line to a list or increments a counter every time it runs.

It does two more things lesson 5 relies on. It runs every effect, then cleans it up, then runs it
again, to find effects that do not clean up after themselves. And it warns about a handful of
interfaces React has deprecated.

Three facts keep this from being alarming:

- **Only in development.** `npm run build` produces a version where strict mode does nothing, and a
  visitor's browser renders each component once.
- **Only inside the tag.** It applies to the components under `<StrictMode>`, which in this app is all
  of them, and you could wrap part of an app instead.
- **The logs are real calls.** React 19 prints the second call's `console.log` too, as you saw; some
  browsers' developer tools grey it out. React 17 hid it, which made the second call
  invisible and the double-counting it catches harder to understand.

Leave it on. The rest of this lesson keeps it off for one reason only: a transcript with each line
once is half as long to read. The last section puts it back.
