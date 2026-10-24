---
title: React
version: 1
---

**React describes the page with a function: the component is called, it returns what to draw, and
it is called again whenever its state changes.** There are no templates; the markup is **JSX**,
HTML-like syntax inside JavaScript, which the build turns into function calls. Made the same way:

```
ana@dev:~/vue/compare$ npm create vite@9.3.1 -- react --template react-ts --no-immediate

> npx
> cva react --template react-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/vue/compare/react...
│
└  Done. Now run:

  cd react
  npm install
  npm run dev
```

```
ana@dev:~/vue/compare/react$ npm install

added 27 packages, and audited 28 packages in 3s

9 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/react$ npm install --save-exact react@19.3.1 react-dom@19.3.1

added 3 packages, and audited 31 packages in 858ms

10 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/vue/compare/react$ rm src/App.tsx src/App.css
```

The card:

```jsx
// src/WeekCard.tsx: one course's week, the React way.
import { useState } from 'react'

const start = [
  { id: 's3', date: '19 October', minutes: 30, done: true },
  { id: 's6', date: '23 October', minutes: 40, done: false },
]

export function WeekCard() {
  console.log('React: WeekCard runs')
  const [sessions, setSessions] = useState(start)
  // Worked out again on every render: the whole function runs each time.
  const planned = sessions.reduce((sum, s) => sum + s.minutes, 0)
  const done = sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0)

  function toggle(id: string) {
    setSessions(sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)))
  }

  return (
    <section>
      <h2>Spanish</h2>
      <ul>
        {sessions.map((s) => (
          <li key={s.id}>
            <label>
              <input type="checkbox" checked={s.done} onChange={() => toggle(s.id)} /> {s.date},{' '}
              {s.minutes} minutes
            </label>
          </li>
        ))}
      </ul>
      <p>
        {done} of {planned} minutes done
      </p>
    </section>
  )
}
```

and its entry, which renders it into the template's `#root`:

```jsx
// src/main.tsx: the card, and nothing else, in the page's #root.
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { WeekCard } from './WeekCard.tsx'

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <WeekCard />
  </StrictMode>,
)
```

The differences from the Vue card, line by line:

- **`useState(start)`** gives the current value and a function to replace it. There is no reactive
  object to change: `toggle` builds a new list with `map` and hands it to `setSessions`, the way
  lesson 3's `toggleDone` did, and React draws again because it was given a new value.
- **The totals are plain `const`s**, computed afresh each time the function runs; nothing caches them
  unless you ask with `useMemo`, and for a sum of two numbers nobody should.
- **The checkbox is controlled**: `checked={s.done}` draws the state and `onChange` asks for the
  change. There is no `v-model`; the two directions are always written out.
- **`{sessions.map(...)}`** is the `v-for`, plain JavaScript, with the same `key` for the same reason.

`npm run dev`, and the same tick:

```
ana@dev:~/vue/compare/react$ look http://localhost:5173/ --do 'check text=23 October' --text body
[vite] connecting...
%cDownload the React DevTools for a better development experience: https://react.dev/link/react-devtools font-weight:bold
React: WeekCard runs
React: WeekCard runs
[vite] connected.
-- check text=23 October
React: WeekCard runs
React: WeekCard runs
== the text of body
Spanish
 19 October, 30 minutes
 23 October, 40 minutes

70 of 70 minutes done
```

**The same card, and the function ran twice before the tick and twice after it.** Running again on
every change is React's model, and the comparison section comes back to it. Running *twice* is
`<StrictMode>`, in development only: React calls the component a second time on purpose, to bring
out code that is not safe to run more than once. The `%c` line is React's invitation to install its
developer tools, styled for a console that `look` prints as plain text.
