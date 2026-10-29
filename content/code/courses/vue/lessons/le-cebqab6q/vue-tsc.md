---
title: vue-tsc, and where the checking happens
version: 1
---

**The dev server does not check types, and the build does not either, unless you ask it to.** Vite
removes the types from each file it serves and checks nothing, which is why the planner ran in
the browser all through this lesson while `vue-tsc` was reporting dozens of errors. So the check has to be
put somewhere it cannot be skipped.

## In the build

`package.json`'s `build` script becomes two steps, checker first:

```
ana@dev:~/vue/planner$ npm pkg set scripts.build='vue-tsc --noEmit && vite build'
```

`&&` runs the second command only if the first succeeded, so **a type error now stops the build**. Show
it with the slip of the typed-emits section, and the `sed` that puts it back:

```
ana@dev:~/vue/planner$ sed -i "s/emit('toggle'/emit('toggel'/" src/components/SessionRow.vue
ana@dev:~/vue/planner$ npm run build

> planner@0.0.0 build
> vue-tsc --noEmit && vite build

src/components/SessionRow.vue(23,68): error TS2345: Argument of type '"toggel"' is not assignable to parameter of type '"toggle"'.
ana@dev:~/vue/planner$ sed -i "s/emit('toggel'/emit('toggle'/" src/components/SessionRow.vue
```

The build stopped at the checker, and `vite build` never ran. `create-vue`'s TypeScript projects run the
two in parallel with a helper package and fail if either does; the planner runs them one after the other,
which is a few seconds slower and needs nothing installed.

## While you work

Three places to see type errors as you type, in order of how soon they tell you:

- **The editor.** VS Code with the *Vue (Official)* extension runs the same checker in the background
  and underlines the error as you type it. This is where most type errors are met and fixed.
- **`npm run type-check`**, before a commit. A few seconds for a project this size.
- **CI**, the pipeline `front-delivery` lesson 3 builds, which runs the checker on every pull
  request so that an error nobody saw locally cannot be merged.

`vite-plugin-checker` puts the checker inside the dev server, with its errors in the terminal and over
the page. It costs startup time on large projects and the course does not use it; the editor gives the
same answer sooner.

## The dev server, unchanged

```
ana@dev:~/vue/planner$ look http://localhost:5173/ --clock 2026-10-21T10:00 --text main
[vite] connecting...
[vite] connected.
== the text of main
This week
Courses
Statistics

45 of 105 minutes done, goal 180

 25% of the weekly goal

Spanish

30 of 70 minutes done, goal 120

 25% of the weekly goal

Guitar

0 of 20 minutes done, goal 90

 0% of the weekly goal

Week of 19 October 2026
Previous weekNext week
Add a session
 19 October 2026, Statistics, 45 minutes
 19 October 2026, Spanish, 30 minutes
 21 October 2026, Statistics, 60 minutes (today)
 22 October 2026, Guitar, 20 minutes
 23 October 2026, Spanish, 40 minutes

75 of 195 minutes done
```

The planner in TypeScript is the planner: the same screen, the same numbers. What changed is that the
next wrong property, missing prop or misspelt event will be found by a program before it is found by a
person.
