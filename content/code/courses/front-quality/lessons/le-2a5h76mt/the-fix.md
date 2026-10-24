---
title: Text stays text
version: 1
---

**The fix is to write the note as text and let CSS keep the line breaks**, which is a property CSS has
had for a long time: `white-space: pre-line` shows a `\n` as a new line and collapses other spaces as
usual.

```
ana@dev:~/planner$ git diff
diff --git a/src/style.css b/src/style.css
index 184ff39..d3d4775 100644
--- a/src/style.css
+++ b/src/style.css
@@ -11,3 +11,4 @@ button:focus { outline: none; }
 .add { display: flex; gap: 0.5rem; margin: 1rem 0; }
 .week { font-weight: bold; animation: pulse 1s ease-in-out 3; }
 @keyframes pulse { 50% { transform: scale(1.06); } }
+.note { white-space: pre-line; margin: 0.2rem 0 0; }
diff --git a/src/view.ts b/src/view.ts
index 52e94e0..0a81f3f 100644
--- a/src/view.ts
+++ b/src/view.ts
@@ -35,7 +35,7 @@ export function render(root: HTMLElement, plan: Plan, day: string, route: string
     }
     if (s.note) {
       const note = el("p", "", "note");
-      note.innerHTML = s.note.replace(/\n/g, "<br>");
+      note.textContent = s.note;
       item.append(note);
     }
     list.append(item);
```

`textContent` puts the characters into the paragraph as they are, so `<b>` is two angle brackets and a
letter, and there is nothing to build. The style goes in `src/style.css`, beside the other rules.

```
ana@dev:~/planner$ npx vitest run src/view.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  4 passed (4)
   Start at  20:41:55
   Duration  1.33s (environment 52%, tests 34%, import 9%, transform 4%)
```

And the whole suite, with the browser tests, since the course page changed:

```
ana@dev:~/planner$ npm run check 2>&1 | grep -E "Tests |[0-9] (passed|failed)"
 Test Files  5 passed (5)
      Tests  33 passed (33)
  8 passed (6.3s)
```

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "Write the note as text"
```

## The rule behind it

**Every value goes into the page through the method that matches what it is.** Text through
`textContent` or `createElement`, an attribute through `setAttribute` with a name that is not an event
handler, a URL through a check of its scheme. Markup is written with `innerHTML` only when the markup is
the site's own, a fixed template, never when any part of it came from a person or a server. The
planner's `view.ts` did this for every value since lesson 1, through its `el()` helper; the note was the
one line that broke the habit, which is how it usually happens.
