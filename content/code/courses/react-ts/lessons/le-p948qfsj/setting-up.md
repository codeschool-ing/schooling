---
title: A test runner that already knows the project
version: 1
---

**Every check in this course so far has been a person looking**: `look`, `curl`, the compiler. They
find a mistake on the day someone runs them. A test is a check that runs again on every change,
written once, and says in one line whether the planner still does what it did.

**Vitest** is the test runner built on Vite: it reads the same `vite.config.ts`, so TypeScript, JSX,
the React plugin and the compiler all work in tests exactly as in the app, with nothing to configure
twice. **React Testing Library** draws components in a test and finds things in them the way a person
would, by their role and their name. Install both, with three companions:

```
ana@dev:~/planner$ npm install --save-dev vitest@5.0.5 jsdom@29.1.1 @testing-library/react@16.3.3 @testing-library/dom@10.4.2 @testing-library/user-event@14.6.8 @testing-library/jest-dom@7.0.1

added 78 packages, and audited 160 packages in 6s

33 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm pkg set scripts.test="vitest run" && grep "\"test\"" package.json
    "test": "vitest run"
```

- **`jsdom`** is a browser's document, written in JavaScript: elements, events and the DOM API, inside
  Node.js, with no window on a screen. It is what the components draw into. Version 29 is the one this
  course pins, because version 30 asks for a newer Node.js 22 than lesson 1 installed.
- **`@testing-library/user-event`** types and clicks the way a person does, key by key, with every
  event a browser would fire.
- **`@testing-library/jest-dom`** adds assertions about elements, such as `toBeInTheDocument`.

`npm pkg set` added a `test` script, so `npm test` runs every test once and stops. Vitest's options go
in `vite.config.ts`, under `test`:

```ts
/// <reference types="vitest/config" />
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
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
  },
})
```

The first line tells TypeScript about the `test` key. **`environment: 'jsdom'`** gives every test a
document, and **`setupFiles`** names a file that runs before each test file, `src/test/setup.ts`:

```ts
import '@testing-library/jest-dom/vitest'
import { cleanup } from '@testing-library/react'
import { afterEach } from 'vitest'

// Every test draws into the same document: empty it after each one.
afterEach(cleanup)
```

It loads `jest-dom`'s assertions into Vitest's `expect`, and after each test it removes what the test
drew, so the next one starts from an empty page. Testing Library does that by itself only when the test
functions are global, which this project does not turn on: every test file imports `describe`, `it` and
`expect` from `vitest`, so it is always clear where they come from.
