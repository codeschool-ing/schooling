---
title: lazy, and Suspense around it
version: 1
---

**`lazy` takes a function that imports a module, and returns a component that calls it the first time
it is rendered.** Until the module has arrived, the component is not ready, and React shows the
fallback of the nearest `Suspense` above it. The whole change is in `src/App.tsx`:

```tsx
import { lazy, Suspense, useState } from 'react'
import { CourseList } from './CourseList'
import { LoadFailed } from './LoadFailed'
import { usePlannerContext } from './plannerContext'
import { useWeek } from './useWeek'
import { inWeek } from './week'
import { WeekNav } from './WeekNav'
import { WeekSummary } from './WeekSummary'

const CourseScreen = lazy(() =>
  import('./CourseScreen').then((module) => ({ default: module.CourseScreen })),
)

function App() {
  const [monday, setMonday] = useWeek()
  const { status, courses, sessions } = usePlannerContext()
  const [openId, setOpenId] = useState<string | null>(null)

  if (status === 'loading') return <p>Loading the planner…</p>
  if (status === 'failed') return <LoadFailed />

  const open = courses.find((c) => c.id === openId)
  if (open) {
    return (
      <main>
        <Suspense fallback={<p>Loading the course…</p>}>
          <CourseScreen course={open} onBack={() => setOpenId(null)} />
        </Suspense>
      </main>
    )
  }

  const thisWeek = sessions.filter((s) => inWeek(s.date, monday))
  return (
    <main>
      <h1>Study planner</h1>
      <WeekNav monday={monday} onChange={setMonday} />
      <WeekSummary monday={monday} sessions={thisWeek} />
      <CourseList key={monday} courses={courses} sessions={thisWeek} onOpen={setOpenId} />
    </main>
  )
}

export default App
```

Three changes, and each one matters:

- **The static `import { CourseScreen }` is gone.** A static import at the top of a file is part of
  that file, and while one remains anywhere, the bundler keeps the module in the main file.
- **`import('./CourseScreen')` is the dynamic form**, a function call that returns a promise of the
  module. Bundlers treat it as a place to cut, and put the module in a file of its own. `lazy` expects
  the module to have a **default** export, and `CourseScreen.tsx` exports a named one, so `.then`
  hands `lazy` an object whose `default` is the named export.
- **`Suspense` around the place it is drawn**, with the sentence to show while the code loads. It
  goes inside `<main>`, so only the content is replaced, never the page's landmark.

```
ana@dev:~/planner$ npm run lint

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 48ms on 20 files with 116 rules using 4 threads.
```

Build again:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 175 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                         0.45 kB │ gzip:  0.29 kB
dist/assets/index-C0qAAZg_.css          0.43 kB │ gzip:  0.25 kB
dist/assets/CourseScreen-rKGK0gfi.js  111.03 kB │ gzip: 34.52 kB
dist/assets/index-BDKi8Zd8.js         261.51 kB │ gzip: 81.53 kB

✓ built in 609ms
```

```schooling-figure
{"svg": "<svg data-fig=\"split\" viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Two builds side by side. Before: one JavaScript file of 371 kB, loaded before the first screen. After: a main file of 262 kB, loaded at once, and a CourseScreen file of 111 kB holding the course screen, React Hook Form and Zod, loaded when a course is opened.\"><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">before</text><rect x=\"20\" y=\"36\" width=\"260\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">index-CkcBpHKM.js</text><text x=\"150.0\" y=\"103.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">371 kB</text><text x=\"150\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">all of it before the first screen</text><text x=\"520\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">after</text><rect x=\"360\" y=\"36\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"88.75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">index-BDKi8Zd8.js</text><text x=\"455.0\" y=\"103.25\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">262 kB</text><rect x=\"570\" y=\"36\" width=\"130\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">CourseScreen-…js</text><text x=\"635.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">111 kB</text><text x=\"635\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the course screen,</text><text x=\"635\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">react-hook-form, zod</text><text x=\"455\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">at once</text><text x=\"635\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">on the first click</text></svg>", "caption": "The form's libraries leave the first download."}
```

**Two JavaScript files now.** `index-BDKi8Zd8.js` is 110 kB smaller, and the difference sits in
`CourseScreen-rKGK0gfi.js`: the course screen, the form, React Hook Form and Zod, everything that only
the course screen reaches. The bundler named the new file after the module it starts from.

To see when each file is fetched, serve the build. `npm run preview` serves `dist/` as a small
production server would, on port 4173, with the same proxy to the API as the development server; leave
it running in a terminal of its own:

```

> planner@0.0.0 preview
> vite preview

  ➜  Local:   http://localhost:4173/
  ➜  Network: use --host to expose
```

```
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --network | grep -E 'assets|api'
net  GET /assets/index-C0qAAZg_.css  200
net  GET /assets/index-BDKi8Zd8.js  200
net  GET /api/planner  200
ana@dev:~/planner$ look http://localhost:4173/ --today 2026-10-21 --network --do 'click button Statistics' | grep -E 'assets|api|^-- |heading'
net  GET /assets/index-C0qAAZg_.css  200
net  GET /assets/index-BDKi8Zd8.js  200
net  GET /api/planner  200
-- click button Statistics
net  GET /assets/CourseScreen-rKGK0gfi.js  200
  - heading "Statistics" [level=1]
  - heading "Add a session" [level=2]
```

The first page loads the stylesheet, the main file and the planner, and **nothing of the course
screen**. The second clicks a course: only then does `CourseScreen-rKGK0gfi.js` arrive, and the screen
is drawn with its heading and its form. In between, for as long as that file took to come, the page
showed *Loading the course…*. On a fast connection it is too brief to see; on a slow phone network it
is what the student sees instead of a frozen page.
