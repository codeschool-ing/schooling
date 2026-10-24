---
title: What the build writes
version: 1
---

**`npm run build` turns the project into the folder a host serves, and nothing else is deployed.**
The script in `package.json` is `tsc && vite build`: first the TypeScript compiler checks every type
and writes nothing, then Vite bundles. The `&&` means the second only runs if the first succeeded, so a
type error stops the build before a single file is written.

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 7 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                 0.48 kB │ gzip: 0.31 kB
dist/assets/index-DXSNtWuR.css  0.18 kB │ gzip: 0.15 kB
dist/assets/index-BVi82VJx.js   3.04 kB │ gzip: 1.41 kB

✓ built in 240ms
```

Vite printed each file it wrote, its size, and its size compressed with gzip, which is closer to what
travels over the network, since every host compresses text before sending it. The whole app is about
3 kB of JavaScript.

## Four files

```
ana@dev:~/planner$ find dist -type f | sort
dist/assets/index-BVi82VJx.js
dist/assets/index-DXSNtWuR.css
dist/courses.json
dist/favicon.svg
dist/index.html
```

`courses.json` and `favicon.svg` came from `public/`, copied as they were. The script and the
stylesheet are new: every module the app imports, `main.ts`, `planner.ts`, `view.ts` and the CSS,
went into one JavaScript file and one CSS file. And `index.html` is not the one you wrote:

```
ana@dev:~/planner$ cat dist/index.html
<!-- index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-BVi82VJx.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-DXSNtWuR.css">
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

The `<script>` that pointed at `/src/main.ts` now points at the bundle, and a `<link>` for the
stylesheet was added. **The page names the files by their new names**, so it has to be built with them
and served with them; copying a `dist/index.html` from one build next to the assets of another gives a
page that asks for files that are not there.

## The name changes when the content does

The eight characters before `.js` are a hash of the file's content. Build twice without changing
anything and the names are the same; change one word of the code, and only the script's name moves,
while the stylesheet keeps its own:

```
ana@dev:~/planner$ ls dist/assets
index-BVi82VJx.js
index-DXSNtWuR.css
ana@dev:~/planner$ npm run build > /dev/null && ls dist/assets
index-BVi82VJx.js
index-DXSNtWuR.css
ana@dev:~/planner$ sed -i 's/All courses/Every course/' src/view.ts
ana@dev:~/planner$ npm run build > /dev/null && ls dist/assets
index-DXSNtWuR.css
index-j59TGUSA.js
ana@dev:~/planner$ git checkout src/view.ts
Updated 1 path from the index
```

That is what lets a host tell browsers to keep a file for a year: a new version is a new name, so an
old copy is never mistaken for the current one. Which headers say so, and why `index.html` gets the
opposite treatment, is front-performance lesson 9. What this lesson needs from it is the consequence for
a deploy: **a release is the whole folder at once**, never one file of it.

## A type error stops it

The type check is the first step for a reason. Change one type in `planner.ts`, say a session's
`minutes` to a `string`, and build:

```
ana@dev:~/planner$ sed -i 's/minutes: number;/minutes: string;/' src/planner.ts
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc && vite build

src/planner.ts(17,11): error TS2322: Type 'Session | { id: number; course: string; date: string; minutes: number; done: false; }' is not assignable to type 'Session'.
  Type '{ id: number; course: string; date: string; minutes: number; done: false; }' is not assignable to type 'Session'.
    Types of property 'minutes' are incompatible.
      Type 'number' is not assignable to type 'string'.
src/planner.ts(17,44): error TS2322: Type 'string | number' is not assignable to type 'string'.
  Type 'number' is not assignable to type 'string'.
src/planner.ts(35,58): error TS2769: No overload matches this call.
  Overload 1 of 3, '(callbackfn: (previousValue: Session, currentValue: Session, currentIndex: number, array: Session[]) => Session, initialValue: Session): Session', gave the following error.
    Type 'string' is not assignable to type 'Session'.
  Overload 2 of 3, '(callbackfn: (previousValue: number, currentValue: Session, currentIndex: number, array: Session[]) => number, initialValue: number): number', gave the following error.
    Type 'string' is not assignable to type 'number'.
src/planner.ts(36,12): error TS2322: Type 'Session' is not assignable to type 'number'.
src/planner.ts(36,32): error TS2322: Type 'Session' is not assignable to type 'number'.
ana@dev:~/planner$ git checkout src/planner.ts
Updated 1 path from the index
```

`tsc` found five errors, in the three lines that build or add up a session's minutes, and exited with
an error, so `vite build` never ran and `dist/` still holds the last good build. **That is the behaviour you want from every machine
that builds your site**: a broken commit produces no deploy, rather than a deploy that is broken. Lesson
3 makes the same check run on every push, on a machine that is not yours.

`vite build` on its own does not check types. It removes them and bundles what is left, which is why a
project whose script is only `vite build` can publish code that its editor underlines in red.
