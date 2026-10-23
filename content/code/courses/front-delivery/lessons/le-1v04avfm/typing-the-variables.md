---
title: Typing the variables, so a misspelt one fails the build
version: 1
---

**By default, TypeScript lets you read any name from `import.meta.env`, and a misspelt name is simply
`undefined`.** That is the worst kind of mistake for a setting: nothing fails, the fallback quietly takes
over, and a staging site starts calling itself production. Vite's types allow a stricter mode in which
only the variables you declare exist, and a misspelling stops the build.

## The mistake, unchecked

Swap two letters in `env.ts` and build the staging mode:

```
ana@dev:~/planner$ sed -i 's/VITE_TITLE/VITE_TITEL/' src/env.ts
ana@dev:~/planner$ npm run build -- --mode staging 2>&1 | tail -1
✓ built in 85ms
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner
```

The build succeeded, and the staging heading is gone: `VITE_TITEL` is not set anywhere, so `??` fell back
to the default, and nothing said a word.

## Declaring them

Vite's own type file declares `import.meta.env` with an index signature, a catch-all that accepts any
name, unless a project opts out. Opting out and listing the planner's one variable is a short file:

```typescript
// src/vite-env.d.ts
interface ViteTypeOptions {
  strictImportMetaEnv: unknown;
}

interface ImportMetaEnv {
  readonly VITE_TITLE?: string;
}
```

`ViteTypeOptions` with `strictImportMetaEnv` in it is the switch, and it is written as a declaration
rather than an option because it changes types, not behaviour. `ImportMetaEnv` then lists what exists:
`VITE_TITLE`, optional and a string. The file needs no import, because both interfaces are global ones
that Vite's types leave open to be extended.

**The name matters.** Called `env.d.ts`, beside `env.ts`, the file would be read as the declarations *of*
`env.ts` and skipped, and the build would go on passing the misspelling without a word. `vite-env.d.ts`
is the name Vite's own templates have used for it, and it collides with nothing.

Build the misspelt version again:

```
ana@dev:~/planner$ npm run build -- --mode staging

> planner@0.0.0 build
> tsc && vite build --mode staging

src/env.ts(2,38): error TS2551: Property 'VITE_TITEL' does not exist on type 'ImportMetaEnv'. Did you mean 'VITE_TITLE'?
```

**The mistake is now a type error**, with the file, the line and the name, and `tsc` stops the build
before Vite runs. Put the name right and the build goes through:

```
ana@dev:~/planner$ git checkout src/env.ts
Updated 1 path from the index
ana@dev:~/planner$ npm run build -- --mode staging 2>&1 | tail -1
✓ built in 198ms
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (staging)
ana@dev:~/planner$ git add src/vite-env.d.ts
ana@dev:~/planner$ git commit -qm "Declare the variables the planner reads"
```

From here on, **adding a variable means adding a line to `vite-env.d.ts`**. Lesson 9 adds the address of a
GraphQL server and lesson 11 the name of a release, and each goes in this file before any code reads it.
