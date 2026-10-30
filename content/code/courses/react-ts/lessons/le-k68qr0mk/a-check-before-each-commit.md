---
title: A check before each commit
version: 1
---

**Every check in this course is a command, and a command someone has to remember to run.** The way to
stop depending on memory is to make the commands one, and have git run it. Two scripts in
`package.json`:

```
ana@dev:~/planner$ npm pkg set scripts.format="prettier --write ." scripts.check="prettier --check . && npm run lint && tsc -b && npm test" && grep -A 9 "\"scripts\"" package.json
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "lint": "oxlint",
    "preview": "vite preview",
    "test": "vitest run",
    "format": "prettier --write .",
    "check": "prettier --check . && npm run lint && tsc -b && npm test"
  },
  "dependencies": {
ana@dev:~/planner$ chmod +x .git/hooks/pre-commit
```

- **`format`** rewrites everything in Prettier's layout.
- **`check`** is every check in the course, in order of speed: the layout, the linter, the types, the
  tests. `&&` stops at the first one that fails.

```schooling-figure
{"svg": "<svg data-fig=\"check\" viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"npm run check runs four steps in order, each stopping the rest when it fails: prettier --check for layout, oxlint for likely mistakes, tsc -b for types, vitest run for behaviour. Git's pre-commit hook runs it before every commit, and CI runs the same command for every push.\"><rect x=\"14\" y=\"40\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"94.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">prettier --check</text><text x=\"94\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">layout</text><line x1=\"176\" y1=\"65\" x2=\"188\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"188.0,65.0 180.5,68.2 180.5,61.8\" fill=\"var(--wire)\"></polygon><text x=\"182\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&amp;&amp;</text><rect x=\"190\" y=\"40\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">oxlint</text><text x=\"270\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">likely mistakes</text><line x1=\"352\" y1=\"65\" x2=\"364\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"364.0,65.0 356.5,68.2 356.5,61.8\" fill=\"var(--wire)\"></polygon><text x=\"358\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&amp;&amp;</text><rect x=\"366\" y=\"40\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">tsc -b</text><text x=\"446\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">types</text><line x1=\"528\" y1=\"65\" x2=\"540\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></line><polygon points=\"540.0,65.0 532.5,68.2 532.5,61.8\" fill=\"var(--wire)\"></polygon><text x=\"534\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">&amp;&amp;</text><rect x=\"542\" y=\"40\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"622.0\" y=\"65.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">vitest run</text><text x=\"622\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">behaviour</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">npm run check</text><text x=\"200\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">before every commit: .git/hooks/pre-commit</text><text x=\"540\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">on every push: CI, which nobody can skip</text></svg>", "caption": "Fastest first; the first failure stops the rest."}
```

Git runs a **hook** at certain moments, if a script with the right name is in `.git/hooks` and is
executable. `pre-commit` runs before a commit is made, and a failure stops the commit.
`.git/hooks/pre-commit`:

```sh
#!/bin/sh
# Runs before every `git commit`; a failure stops the commit.
exec npm run check
```

`chmod +x` made it executable. Now try to commit a file written carelessly:

```
ana@dev:~/planner$ printf 'export const late    =   true\n' > src/late.ts && git add -A && git commit -q -m 'Format the code' 2>&1 | tail -n 6
> planner@0.0.0 check
> prettier --check . && npm run lint && tsc -b && npm test

Checking formatting...
[warn] src/late.ts
[warn] Code style issues found in the above file. Run Prettier with --write to fix.
```

**The commit was stopped** at the first check: Prettier found the new file unformatted. Nothing was
committed. Format, and commit again:

```
ana@dev:~/planner$ npm run format > /dev/null && git add -A && git commit -q -m "Format the code" 2> /dev/null && git log --format=%s
Format the code
Add ESLint and Prettier
The planner, as lesson 22 left it
ana@dev:~/planner$ git rm -q src/late.ts && git commit -q -m "Remove an example" 2> /dev/null && git log --format=%s | head -n 1
Remove an example
```

The hook ran every check again and they all passed, so this time the commit was made. The example file
then goes, through the same hook.

Three things to know about hooks:

- **They are not shared.** `.git/hooks` is not part of what `git push` sends, so a teammate's clone has
  none of yours. Tools such as Husky and Lefthook keep the hook in the repository and install it on
  `npm install`.
- **They can be skipped**, with `git commit --no-verify`, by anyone in a hurry. A hook is a convenience
  for the person committing, not a guarantee.
- **The guarantee is CI**: the same `npm run check`, run on a server for every push, where nobody can
  skip it. The hook catches problems a minute after they are made; CI makes sure none of them reach the
  main branch.
