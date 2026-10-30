---
title: ESLint, the one with the plugins
version: 1
---

**ESLint is the linter most JavaScript projects use**, and the one most rules are written for first.
The React team publishes its hook rules as an ESLint plugin, and so does almost every library with
rules of its own. Install it, with the plugins the Vite template used to ship:

```
ana@dev:~/planner$ npm install --save-dev eslint@10.13.0 @eslint/js@10.0.1 typescript-eslint@8.72.0 eslint-plugin-react-hooks@7.1.1 eslint-plugin-react-refresh@0.5.7 globals@17.13.0

added 133 packages, and audited 293 packages in 6s

65 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

- **`@eslint/js`** is ESLint's own recommended rules, and **`typescript-eslint`** lets it read TypeScript
  and adds rules about types.
- **`eslint-plugin-react-hooks`** is the React team's: the rules of hooks, the dependency arrays, and
  the React Compiler's checks.
- **`eslint-plugin-react-refresh`** warns about exports that stop Vite's hot reload from keeping a
  component's state, the same thing Oxlint's `only-export-components` checks.
- **`globals`** tells ESLint which names exist in a browser, `window` and `document` among them.

ESLint reads `eslint.config.js`, a list of configuration objects:

```js
import js from '@eslint/js'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import { defineConfig, globalIgnores } from 'eslint/config'
import globals from 'globals'
import tseslint from 'typescript-eslint'

export default defineConfig([
  globalIgnores(['dist']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      globals: globals.browser,
    },
  },
])
```

`globalIgnores` keeps the build out; the second object applies to TypeScript files and extends four
ready-made configurations, one from each package. Run it over the project, with the same line still in
`CourseScreen`:

```
ana@dev:~/planner$ npx eslint .

/home/ana/planner/src/CourseScreen.tsx
  18:15  error  Error: Cannot access refs during render

React refs are values that are not needed for rendering. Refs should only be accessed outside of render, such as in event handlers or effects. Accessing a ref value (the `current` property) during render can cause your component not to update as expected (https://react.dev/reference/react/useRef).

/home/ana/planner/src/CourseScreen.tsx:18:15
  16 |   const [message, setMessage] = useState('')
  17 |   const heading = useRef<HTMLHeadingElement>(null)
> 18 |   console.log(heading.current)
     |               ^^^^^^^^^^^^^^^ Passing a ref to a function may read its value during render
  19 |   useEffect(() => {
  20 |     heading.current?.focus()
  21 |   }, [])  react-hooks/refs

✖ 1 problem (1 error, 0 warnings)
```

**The same finding**, worded the same way, because it is the same check: the plugin's `react-hooks/refs`
is where Oxlint's copy comes from. ESLint calls it an **error** and exits with a failure. The line goes,
and the two linters are timed on the clean project:

```
ana@dev:~/planner$ sed -i '/^  console.log(heading.current)$/d' src/CourseScreen.tsx && git status --short
 M package-lock.json
 M package.json
?? eslint.config.js
ana@dev:~/planner$ time npx eslint .

real	0m2.428s
user	0m3.069s
sys	0m0.321s
ana@dev:~/planner$ time npx oxlint
Found 0 warnings and 0 errors.
Finished in 109ms on 37 files with 116 rules using 4 threads.

real	0m0.510s
user	0m0.371s
sys	0m0.266s
```

**Both found nothing, and Oxlint did it several times faster**, most of its half second being `npx`
starting up: Oxlint itself reports about a tenth of a second for the whole project. On a project of
this size neither is slow; on one with thousands of files, that difference decides whether a linter runs
on every save or only in CI.

**So which one?** Oxlint covers the common rules, React's included, at a speed that makes it free to run
constantly. ESLint has every plugin ever written, and rules that need TypeScript's type information,
such as a promise nobody awaited. Many projects run both: Oxlint on every save and every commit, ESLint
in CI, where its extra seconds do not matter. The planner keeps that arrangement: `npm run lint` stays
Oxlint, and `npx eslint .` is there when you want the rest.
