---
title: React
version: 1
---

**React is a library for drawing user interfaces, and its components are functions that return
what to draw.** It has no command-line tool of its own; a project is usually made with Vite, the
build tool whose dev server is also the one under `ng serve`, which is why this course's pages
printed `[vite] connecting...`. Its project generator, `create-vite`, is run at a fixed version:

```
ana@dev:~/compare$ npm create vite@9.3.1 -- react --template react-ts --no-immediate

> npx
> cva react --template react-ts --no-immediate


create-vite v9.3.1

│
◇  Scaffolding project in /home/ana/compare/react...
│
└  Done. Now run:

  cd react
  npm install
  npm run dev
```

`--no-immediate` stops it from installing and starting on its own. Install, pin every package to
the version that was installed, as the planner's are, and remove the template's example:

```
ana@dev:~/compare/react$ npm install

added 27 packages, and audited 28 packages in 3s

found 0 vulnerabilities
```

```
ana@dev:~/compare/react$ npm install --save-exact react@19.3.1 react-dom@19.3.1 @types/node@22.20.5 @types/react@19.3.0 @types/react-dom@19.3.0 @vitejs/plugin-react@6.1.2 oxlint@1.90.0 typescript@6.0.3 vite@8.3.5

added 3 packages, changed 2 packages, and audited 31 packages in 3s

found 0 vulnerabilities
```

```
ana@dev:~/compare/react$ rm src/App.tsx src/App.css src/index.css
```

The template wrote carets, `^19.3.0` and the like; installing each package again with
`--save-exact` writes the version itself, and `@types/node` is set to the Node.js this track runs on.

The card:

```schooling-example
{"language": "typescript", "file": "src/WeekCard.tsx", "parts": [
 {"code": "// src/WeekCard.tsx: one course's week, the React way\nimport { useState } from 'react';\n\nconst start = [\n  { id: 3, date: 'Tue 20 Oct', minutes: 60, done: true },\n  { id: 5, date: 'Sat 24 Oct', minutes: 50, done: false },\n];\n", "note": "A React component is a function, and the file is TSX: TypeScript with HTML-like tags inside it."},
 {"code": "export function WeekCard() {\n  console.log('React: WeekCard runs');\n  const [sessions, setSessions] = useState(start);\n  const planned = sessions.reduce((sum, s) => sum + s.minutes, 0);\n  const done = sessions.filter((s) => s.done).reduce((sum, s) => sum + s.minutes, 0);\n", "note": "The function runs again every time the state changes: that is how React finds out what to draw. `useState` hands back the current value and a function to replace it, and React keeps the value between runs. The totals are plain `const`s, computed afresh on every run."},
 {"code": "  function toggle(id: number) {\n    setSessions(sessions.map((s) => (s.id === id ? { ...s, done: !s.done } : s)));\n  }\n", "note": "The tick builds a new list and hands it to `setSessions`, as the planner's store replaces its state rather than changing it."},
 {"code": "  return (\n    <section>\n      <h2>JavaScript</h2>\n      <ul>\n        {sessions.map((s) => (\n          <li key={s.id}>\n            <label>\n              <input type=\"checkbox\" checked={s.done} onChange={() => toggle(s.id)} /> {s.date}, {s.minutes} minutes\n            </label>\n          </li>\n        ))}\n      </ul>\n      <p>\n        {done} of {planned} minutes done\n      </p>\n    </section>\n  );\n}", "note": "What to draw is the function's return value. `{ }` holds an expression; `map` over the list is React's `@for`, with `key` as its `track`."}
]}
```

```typescript
// src/main.tsx: the card, and nothing else, in the page's #root
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { WeekCard } from './WeekCard';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <WeekCard />
  </StrictMode>,
);
```

Start it with `npm run dev`, which serves on port 5173, and tick the same session:

```
ana@dev:~/compare/react$ look http://localhost:5173/ --do 'check Sat 24 Oct, 50 minutes' --text body
[vite] connecting...
[vite] connected.
%cDownload the React DevTools for a better development experience: https://react.dev/link/react-devtools font-weight:bold
React: WeekCard runs
React: WeekCard runs
-- check Sat 24 Oct, 50 minutes
React: WeekCard runs
React: WeekCard runs
JavaScript
 Tue 20 Oct, 60 minutes
 Sat 24 Oct, 50 minutes

110 of 110 minutes done
```

The first line is React suggesting its browser extension, printed with a style the terminal does
not draw. Then the same 110 of 110, and **the function ran four times**: twice for the first drawing, and twice
more for the tick. Once per drawing is how React works; the second of each pair is `StrictMode`,
which in development runs each component twice on purpose, so that code with a side effect it
should not have, a request or a counter, shows up as doing it twice. A production build runs it once
per drawing. Stop the dev server.
