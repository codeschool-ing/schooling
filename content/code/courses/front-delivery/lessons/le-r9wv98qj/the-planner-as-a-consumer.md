---
title: The planner, installing its own components
version: 1
---

**The planner now installs `@planner/ui` like any other dependency, and deletes its own copies.** If
everything was moved faithfully, every check the planner has passes without a change to a test, which is
the strongest evidence a refactor can offer.

Point the planner's `@planner` scope at the registry, with the same line the library uses, and install the
exact version:

```
ana@dev:~/planner$ cp ../planner-ui/.npmrc .
ana@dev:~/planner$ npm install --save-exact @planner/ui@0.1.0 2>&1 | tail -1
found 0 vulnerabilities
ana@dev:~/planner$ grep -A1 '"dependencies"' package.json
  "dependencies": {
    "@planner/ui": "0.1.0"
```

## Switching the imports

Three files imported the components from `./components`, and the stylesheet imported the generated tokens.
Each now names the package instead:

```
ana@dev:~/planner$ sed -i 's#"./components"#"@planner/ui"#' src/view.ts src/session-row.stories.ts src/week-summary.stories.ts
ana@dev:~/planner$ sed -i 's#@import "./tokens.css";#@import "@planner/ui/tokens.css";#' src/style.css
ana@dev:~/planner$ grep -n "@planner/ui" src/*.ts src/style.css
src/session-row.stories.ts:4:import { sessionRow } from "@planner/ui";
src/view.ts:2:import { actionButton, sessionRow, weekSummary } from "@planner/ui";
src/week-summary.stories.ts:3:import { weekSummary } from "@planner/ui";
src/style.css:2:@import "@planner/ui/tokens.css";
```

Then delete what the package now provides, and the two scripts that generated and checked it:

```
ana@dev:~/planner$ git rm -q src/components.ts src/format.ts src/tokens.css tokens.json tokens.mjs contrast.mjs
ana@dev:~/planner$ npm pkg delete scripts.tokens scripts.contrast
```

## Every check, unchanged

The type check, the unit tests, the build, and the workshop with its pictures and its audits:

```
ana@dev:~/planner$ npx tsc && npm test 2>&1 | grep Tests
      Tests  5 passed (5)
ana@dev:~/planner$ npm run build 2>&1 | grep css
dist/assets/index-BU4yu1tj.css  2.11 kB │ gzip: 0.64 kB
ana@dev:~/planner$ npm run build-storybook > /dev/null 2>&1
ana@dev:~/planner$ npx playwright test 2>&1 | tail -1
  10 passed (15.0s)
```

**The stylesheet's name, `index-BU4yu1tj.css`, is the one lesson 5's build wrote**: the tokens arrive
through a package now and the CSS is byte for byte what it was. The ten visual tests pass against pictures
approved before the move, so not a pixel of any story changed.

Commit the switch:

```
ana@dev:~/planner$ git add -A && git commit -qm "Use @planner/ui 0.1.0 instead of local copies"
```

From now on a change to a token or a component happens in `~/planner-ui`, becomes a version, and reaches
the planner only when the planner installs that version. One practical consequence of a registry on your
own computer: **it has to be running whenever the planner installs**, or `npm install` cannot find
`@planner/ui`. A company's registry is a server that is always up, which is most of what it is paid for.
