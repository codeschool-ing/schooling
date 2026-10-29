---
title: TypeScript, added to the planner
version: 1
---

**TypeScript checks the planner's code before it runs, against types you write down: that a session has
a `minutes` that is a number, that `toggle` is given an id, that a prop marked required is passed.** Vue
3 is written in TypeScript, and `create-vue`'s default project, which lesson 1 stepped round, is a
TypeScript one. This lesson converts the planner, file by file, and reads what the checker finds.

The common wrong picture is that TypeScript makes the code run differently. It does not: **Vite strips
the types and runs the JavaScript underneath**, exactly as before. What changes is that a separate
program, `vue-tsc`, reads the whole project and reports every place where the code contradicts the
types. The dev server does not run it; the last but one section of this lesson is about where it runs.

## Three packages and a configuration

Stop the dev server and install the compiler, Vue's checker for `.vue` files, and Vue's recommended
settings, pinned to the versions `create-vue` 3.24.0 chooses. `--save-dev` files them under
`devDependencies`, beside Vite, because they are used to build the planner and never reach a browser:

```
ana@dev:~/vue/planner$ npm install --save-dev --save-exact typescript@6.0.3 vue-tsc@3.3.13 @vue/tsconfig@0.9.1

added 10 packages, and audited 92 packages in 1s

24 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
```

`tsconfig.json` says which files are checked and how strictly:

```json
{
  "extends": "@vue/tsconfig/tsconfig.dom.json",
  "include": ["env.d.ts", "src/**/*.ts", "src/**/*.vue"],
  "compilerOptions": {
    "lib": ["ES2023", "DOM", "DOM.Iterable"],
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

`extends` takes Vue's settings, which turn on `strict`, the mode in which a value whose type cannot be
worked out is an error rather than a silent `any`. `lib` adds ES2023, because the planner uses
`toSorted`, which lesson 3 chose and which arrived in that edition; without it the checker would not know
the method exists. And `env.d.ts`, one line, tells the checker about what Vite adds to JavaScript, such
as `import.meta.env` (lesson 17):

```
ana@dev:~/vue/planner$ echo '/// <reference types="vite/client" />' > env.d.ts
```

Last, a script in `package.json`, beside `dev` and `build`, that runs the checker without writing any
files:

```
ana@dev:~/vue/planner$ npm pkg set scripts.type-check='vue-tsc --noEmit'
```

## Every file, renamed

TypeScript reads `.ts` files and `<script setup lang="ts">` blocks. Rename every `.js` file in `src`,
point `index.html` at `main.ts`, and mark every component's script:

```
ana@dev:~/vue/planner$ for f in $(find src -name '*.js'); do mv "$f" "${f%.js}.ts"; done
ana@dev:~/vue/planner$ sed -i 's#/src/main.js#/src/main.ts#' index.html
ana@dev:~/vue/planner$ sed -i 's/<script setup>/<script setup lang="ts">/' $(find src -name '*.vue')
```

The imports keep their `.js` endings, `import { toggleDone } from '../planner.js'`, and that is not a
mistake: it is how TypeScript writes imports for modules that will run as JavaScript, and Vite finds
`planner.ts` for an import of `planner.js` from a TypeScript file. Then the checker:

```
ana@dev:~/vue/planner$ npm run type-check 2>&1 | grep -c 'error TS'
59
```

**Nothing was changed but names, and the checker found that many problems**, every one of them a place
where TypeScript cannot tell what a value is. Counted by kind, with the code TypeScript gives each:

```
ana@dev:~/vue/planner$ npm run type-check 2>&1 | grep -o 'error TS[0-9]*' | sort | uniq -c | sort -rn
     27 error TS7006
     20 error TS2339
      5 error TS18047
      3 error TS7031
      1 error TS7034
      1 error TS7005
      1 error TS2698
      1 error TS2322
```

Three codes account for almost all of them. **TS7006, `implicitly has an 'any' type`**: a function's
parameter that nothing describes, most of them in `planner.ts`, which the next section types. **TS2339,
`does not exist on type 'never'`**: `ref([])` was taken to be an array of nothing, so every session read
from it has no properties at all (three more say `on type '{}'`, in `SessionForm`). **TS18047, `is
possibly 'null'`**: a template ref used as if its element were always there. The section on typed refs
fixes the last two. The app still runs in the browser meanwhile, exactly as it did: none of this is
about what the code does.
