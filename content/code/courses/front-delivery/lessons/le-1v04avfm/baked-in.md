---
title: A variable that is gone before the page opens
version: 1
---

**In a front end, an environment variable is read once, by the build, and written into the JavaScript as
a value.** The browser that opens the page has no environment to read: no `process.env`, no shell, no
`.env` file. What it gets is the string the build put there, and changing the variable afterwards changes
nothing until somebody builds again.

That is the opposite of what the word means on a server, where `process.env.PORT` is looked up while the
program runs and a restart with a new value is enough. Most of the mistakes in this lesson come from
carrying the server's picture to the front end.

## Watching it happen

The planner gets one setting to show this with: the title on its front page. A build for a staging site
can say so in the heading, which stops anybody mistaking a test copy for the real one. Add a small file
for it:

```typescript
// src/env.ts
export const title = import.meta.env.VITE_TITLE ?? "Study planner";
```

`import.meta.env` is where Vite puts the variables it exposes. An unset one is `undefined`, so `??` falls
back to the planner's usual name. Then make the heading use it, with two edits to `view.ts` that `git
diff` shows:

```
ana@dev:~/planner$ sed -i '2i import { title } from "./env";' src/view.ts
ana@dev:~/planner$ sed -i 's/el("h1", "Study planner")/el("h1", title)/' src/view.ts
ana@dev:~/planner$ git diff
diff --git a/src/view.ts b/src/view.ts
index 735101b..d3a3143 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -1,4 +1,5 @@
 // src/view.ts
+import { title } from "./env";
 import type { Course, Session } from "./planner";
 
 export interface Actions {
@@ -23,7 +24,7 @@ export function courseList(courses: Course[], week: { planned: number; done: num
     list.append(el("li"));
     list.lastElementChild!.append(link);
   }
-  main.append(el("h1", "Study planner"), el("p", `This week: ${week.planned} min planned, ${week.done} min done`), list);
+  main.append(el("h1", title), el("p", `This week: ${week.planned} min planned, ${week.done} min done`), list);
   return main;
 }
 
```

Build once with nothing set, and once with the variable on the command line, and look for the title in
the bundle:

```
ana@dev:~/planner$ npm run build > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner
ana@dev:~/planner$ grep -c VITE_TITLE dist/assets/*.js
0
ana@dev:~/planner$ VITE_TITLE='Study planner (staging)' npm run build > /dev/null
ana@dev:~/planner$ grep -o 'Study planner[^`]*' dist/assets/*.js
Study planner (staging)
```

**The variable's name is not in the bundle at all, and its value is.** Vite replaced
`import.meta.env.VITE_TITLE` with the literal string while it bundled, and the minifier then folded the
`??` away, because a string is never `undefined`. The script that reaches the browser has no idea a
variable was ever involved.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Before the build, src/env.ts reads import.meta.env.VITE_TITLE with a fallback, and the shell or a .env file holds VITE_TITLE set to Study planner (staging). The build replaces the expression with the value. After the build, the bundle contains only the string Study planner (staging); the variable&#x27;s name is gone. The browser receives that string and has no environment of its own.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">before the build</text><rect x=\"20\" y=\"34\" width=\"300\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">src/env.ts</text><text x=\"32\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">import.meta.env.VITE_TITLE ?? …</text><rect x=\"20\" y=\"108\" width=\"300\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"32\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the shell, or .env.staging</text><text x=\"32\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">VITE_TITLE=Study planner (staging)</text><line x1=\"330\" y1=\"96\" x2=\"380\" y2=\"96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"380.0,96.0 372.6,99.1 372.6,92.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"355\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">build</text><text x=\"390\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">after the build</text><rect x=\"390\" y=\"34\" width=\"310\" height=\"62\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"402\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dist/assets/index-….js</text><text x=\"402\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">`Study planner (staging)`</text><text x=\"390\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the name VITE_TITLE: gone</text><text x=\"390\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the value: a string like any other</text><line x1=\"545\" y1=\"96\" x2=\"545\" y2=\"172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"545.0,172.0 541.9,164.6 548.1,164.6\" fill=\"var(--paper-dim)\"></polygon><rect x=\"450\" y=\"176\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the browser</text><text x=\"545\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">has no environment to read</text></svg>", "caption": "A front end's variable is read by the build and written into the bundle as a value; the page never sees the variable."}
```

## What follows from it

Three consequences, and the rest of the lesson takes them one at a time:

- **a different value is a different build.** A staging site and a production site that differ in one
  variable are two builds with two hashes, not one build configured twice. The section on one build or
  many weighs that.
- **the value is public.** It is a string in a file anybody can download, which is fine for a title and
  fatal for a password. Two sections from now you put a secret there on purpose.
- **the value is fixed at the moment of the build.** A host where you change a variable in a dashboard
  serves the old value until the next deploy, which is a support ticket waiting to happen if nobody knows.

Commit the change, so the planner carries it from here on:

```
ana@dev:~/planner$ git add src/env.ts src/view.ts
ana@dev:~/planner$ git commit -qm "Take the title from VITE_TITLE"
```
