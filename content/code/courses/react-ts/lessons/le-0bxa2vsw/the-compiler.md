---
title: The compiler does it for you
version: 1
---

**React Compiler adds the memoisation at build time, so that the code does not have to carry it.**
Lesson 7 introduced it; here it goes on. First the hand-written `memo` comes off `SessionRow`, so that
what the compiler does is not mixed up with what the code does, and then the compiler goes in:

```
ana@dev:~/planner$ sed -i 's/^export const SessionRow = memo(function SessionRow(/export function SessionRow(/; s/^import { memo, Profiler } from .react./import { Profiler } from '\''react'\''/' src/SessionRow.tsx && sed -i '$s/^})$/}/' src/SessionRow.tsx && grep -c memo src/SessionRow.tsx
0
ana@dev:~/planner$ npm install --save-dev @rolldown/plugin-babel@0.2.4 @babel/core@8.0.7 babel-plugin-react-compiler@1.0.0

added 42 packages, and audited 82 packages in 2s

21 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

Three packages, pinned like everything else. `babel-plugin-react-compiler` is the compiler itself,
1.0.0, the stable release. It is a Babel plugin, and Vite 8 does not use Babel, so
`@rolldown/plugin-babel` runs Babel inside Vite's bundler for this one job, with `@babel/core`. The
plugin for React exports a ready-made preset, and `vite.config.ts` puts it on:

```ts
import babel from '@rolldown/plugin-babel'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), babel({ presets: [reactCompilerPreset()] })],
  server: {
    proxy: {
      '/api': 'http://localhost:3001',
    },
  },
})
```

```
ana@dev:~/planner$ npm run lint && npx tsc -b && echo no errors

> planner@0.0.0 lint
> oxlint

Found 0 warnings and 0 errors.
Finished in 91ms on 31 files with 116 rules using 4 threads.
no errors
```

To check that it is on, ask the development server for `SessionRow` as the browser gets it:

```
ana@dev:~/planner$ curl -s http://localhost:5173/src/SessionRow.tsx | grep -o 'react_compiler-runtime\.js\|_c([0-9]*)' | sort -u
_c(16)
react_compiler-runtime.js
```

**`_c(16)`** is the compiler's work: a cache of sixteen slots that the compiled component keeps between
renders, from React's `compiler-runtime`. The component you wrote has no `memo`, no `useMemo` and no
`useCallback`; the one the browser runs has a cache for every value worth keeping. The same two
interactions as before:

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
```

```
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click checkbox Wed 21 Oct · 40 min'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click checkbox Wed 21 Oct · 40 min
drawn: row s2 (update)
```

**The same result as the hand-written `memo`**: nothing redrawn when the dialog opens, one row when a
session changes. The compiled `SessionRow` returns the very same element as last time when its props
are the same, and React skips what is underneath, `Profiler` included.

The compiler holds two conditions over the code, both from earlier lessons. **Components have to be
pure and follow the rules of hooks**, lessons 3 and 6: it caches what a pure function would return, and
a component that reads something it was not given gets cached wrong, or skipped by the compiler. And it
only compiles your code: a component from a library that was published without it gets no cache from
yours. The inline arrow from the last section, in this project, is now a different story:

```
ana@dev:~/planner$ sed -i 's|onToggle={toggleDone} />}|onToggle={(id) => toggleDone(id)} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx
34:        render={(s) => <SessionRow session={s} onToggle={(id) => toggleDone(id)} />}
ana@dev:~/planner$ look http://localhost:5173/courses/statistics --today 2026-10-21 --quiet --do 'click button Plan a session'
drawn: row s1 (mount)
drawn: row s2 (mount)
-- click button Plan a session
ana@dev:~/planner$ sed -i 's|onToggle={(id) => toggleDone(id)} />}|onToggle={toggleDone} />}|' src/CourseScreen.tsx && grep -n 'onToggle=' src/CourseScreen.tsx
34:        render={(s) => <SessionRow session={s} onToggle={toggleDone} />}
```

**Nothing redrawn**, with the inline arrow in place: the compiler cached the arrow itself, as
`useCallback` would have. That is the point of it. Stability no longer depends on everyone remembering.

**What to do with a slow screen, in order**: measure it with the profiler, or the Profiler tab of
React's developer tools in the browser; find the render that is slow, not the one that is frequent;
and only then change the code. With the compiler on, far fewer of those places need `memo` by hand.
