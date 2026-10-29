---
title: One component, four times
version: 1
---

**Lesson 1 placed React among the alternatives with words. This lesson does it with code.** The track
offers four options for the same job, and the fairest way to compare them is to write one small thing in
each and watch what it does. Not the planner: a single component, small enough to read whole in every
version, with the three things every interface needs. It holds **state**, it **derives** a value from
that state, and it **changes** when somebody clicks.

The component is a week of three study sessions. Each one is a button that marks it done, and above them
a sentence adds up the minutes. It also writes `Sessions ran` to the console from its own code, which is
how this lesson will see the biggest difference between the four.

Each version lives in a project of its own beside `~/planner`, made by that framework's own tool and
pinned the way lesson 1 pinned the planner. React's first, with the command lesson 1 used:

```
ana@dev:~$ npm create vite@9.3.1 sessions-react -- --template react-ts --no-interactive > /dev/null && cd sessions-react && npm config set save-exact true --location=project && npm install --silent react@19.3.1 react-dom@19.3.1 && npm install --silent --save-dev typescript@6.0.3 vite@8.3.5 @vitejs/plugin-react@6.1.2 @types/react@19.3.0 @types/react-dom@19.3.0 @types/node@22.20.5 oxlint@1.88.0 && ls src
App.css
App.tsx
assets
index.css
main.tsx
```

The template's `App.tsx` gives way to the component. `src/Sessions.tsx`:

```tsx
import { useState } from 'react'

type Session = { id: string; course: string; minutes: number; done: boolean }

const week: Session[] = [
  { id: 's1', course: 'Statistics', minutes: 40, done: true },
  { id: 's2', course: 'Python', minutes: 35, done: false },
  { id: 's3', course: 'Statistics', minutes: 45, done: false },
]

export function Sessions() {
  const [sessions, setSessions] = useState(week)
  const done = sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0)
  const total = sessions.reduce((sum, s) => sum + s.minutes, 0)
  console.log('Sessions ran')

  function toggle(id: string) {
    setSessions(sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

  return (
    <section>
      <h1>This week</h1>
      <p>
        {done} of {total} minutes done
      </p>
      <ul>
        {sessions.map((s) => (
          <li key={s.id}>
            <button aria-pressed={s.done} onClick={() => toggle(s.id)}>
              {s.course} · {s.minutes} min
            </button>
          </li>
        ))}
      </ul>
    </section>
  )
}
```

Nothing in it is new. `useState` holds the sessions, and `done` and `total` are plain constants computed
on every render, as lesson 4 recommended for anything that can be worked out from state. `toggle` builds
a new array rather than changing the old one, because React decides whether to render again by comparing
the old state with the new, and a changed object is still the same object. `src/App.tsx` only draws it:

```tsx
import { Sessions } from './Sessions'

export default function App() {
  return <Sessions />
}
```

Then a production build, served by `vite preview` as in lesson 13, and two clicks:

```
ana@dev:~/sessions-react$ rm src/App.css && npm run build

> sessions-react@0.0.0 build
> tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 17 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.46 kB │ gzip:  0.29 kB
dist/assets/index-DGNrK5qb.css    1.78 kB │ gzip:  0.81 kB
dist/assets/index-CyOvCvN4.js   220.20 kB │ gzip: 68.88 kB

✓ built in 388ms
ana@dev:~/sessions-react$ look http://localhost:4173/ --do 'click button Python · 35 min' --do 'click button Statistics · 45 min'
Sessions ran
-- click button Python · 35 min
Sessions ran
-- click button Statistics · 45 min
Sessions ran
- heading "This week" [level=1]
- paragraph: 120 of 120 minutes done
- list:
  - listitem:
    - button "Statistics · 40 min" [pressed]
  - listitem:
    - button "Python · 35 min" [pressed]
  - listitem:
    - button "Statistics · 45 min" [pressed]
```

**`Sessions ran` three times**: once when the page loaded, and once after each click. That is React's
model, the one this whole course has used: a change of state calls the component again, all of it, and
React compares what it returned with what it returned last time. The build is `npm run build` and not the
dev server for a reason: in development, strict mode would call the component twice each time, as lesson
3 showed, and every line of the count would
appear twice.

Keep the number in mind, and the size of that `.js` file. The other three versions are compared with both.
