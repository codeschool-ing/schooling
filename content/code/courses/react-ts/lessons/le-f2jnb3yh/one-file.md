---
title: Everything in one file
version: 1
---

**`npm run build` turns the project into the files a web server hands to a browser**, and until now
that has been one JavaScript file with everything in it. The development server you have used so far
sends each module separately and compiles it on request; a build is what a real deployment serves.
Run it:

```
ana@dev:~/planner$ npm run build

> planner@0.0.0 build
> tsc -b && vite build

vite v8.3.5 building client environment for production...
transforming...
✓ 174 modules transformed.
rendering chunks...
computing gzip size...
dist/index.html                   0.45 kB │ gzip:   0.29 kB
dist/assets/index-C0qAAZg_.css    0.43 kB │ gzip:   0.25 kB
dist/assets/index-CkcBpHKM.js   371.14 kB │ gzip: 115.09 kB

✓ built in 558ms
```

`tsc -b` checked the types first, and only then did Vite build, so a type error stops a build before
anything is written. Then three files in `dist/`:

- `index.html`, the page, which loads the other two.
- `index-C0qAAZg_.css`, the stylesheet.
- **`index-CkcBpHKM.js`, 371 kB of JavaScript**, 115 kB once compressed with gzip, which is about what
  travels over the network. It holds React, React DOM, TanStack Query, React Hook Form, Zod, and the
  planner's own code.

The odd part of each name is a **hash**, worked out from the file's content. Change one character of
the code and the JavaScript file gets a new name. That lets a server tell browsers to keep a file for
as long as they like: a new version is a new name, so a browser can never be stuck with an old one.

Look at what is in that file from the student's side. Somebody opening the planner to see their week
downloads all of it before the first screen can be drawn, including **React Hook Form and Zod, which
only the course screen uses**, for the form at its foot. Somebody who never opens a course pays for
the form anyway.

The fix is to cut the file in two: the code the first screen needs, loaded at once, and the code of
the course screen, loaded when somebody opens one. That is **code splitting**, and in React it takes
two pieces: `lazy`, which loads a component's code the first time it is drawn, and `Suspense`, which
says what to show while that code is on its way.
