---
title: Replace, never change in place
version: 1
---

**An update to an object or array in state is a new object or array.** React decides whether
anything changed by comparing the old value with the new one using `Object.is`, which for objects
asks one question: is it the same object? Change an array in place and hand back the same array, and
the answer is yes, so nothing re-renders. This is `toggleDone` written the way most people try first:

```
ana@dev:~/planner$ cp src/App.tsx /tmp/App.tsx
ana@dev:~/planner$ sed -n 14,20p src/App.tsx
  function toggleDone(id: string) {
    setSessions((all) => {
      const session = all.find((s) => s.id === id)!
      session.done = !session.done
      return all
    })
  }
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min'
-- click button Statistics
-- click checkbox Wed 21 Oct · 40 min
- main:
  - button "Back to courses"
  - heading "Statistics" [level=1]
  - list:
    - listitem:
      - checkbox "Mon 19 Oct · 50 min" [checked]
      - text: Mon 19 Oct · 50 min
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 9,11p
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
ana@dev:~/planner$ cp src/main.tsx /tmp/main.tsx
ana@dev:~/planner$ sed -i 's/<StrictMode>/<>/; s/<\/StrictMode>/<\/>/; /^import { StrictMode }/d' src/main.tsx
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' | tail -n 3
    - listitem:
      - checkbox "Wed 21 Oct · 40 min"
      - text: Wed 21 Oct · 40 min
ana@dev:~/planner$ look http://localhost:5173/ --today 2026-10-21 --do 'click button Statistics' --do 'click checkbox Wed 21 Oct · 40 min' --do 'click button Back to courses' | sed -n 9,11p
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 120 of 195 minutes done
ana@dev:~/planner$ cp /tmp/App.tsx src/App.tsx && cp /tmp/main.tsx src/main.tsx
```

Four transcripts, and each says something:

1. **The box did not tick.** The updater returned `all`, the same array it was given, so React saw no
   change and did not render. The checkbox shows the state, and as far as React knows the state is the
   same.
2. **Going back, the total is still 80.** Under strict mode React runs an updater function twice, to
   find impure ones, and this one flipped `done` to true and then back to false. Strict mode caught the
   mutation by making it cancel itself out.
3. **Without strict mode, the box still did not tick.**
4. **But going back, the total says 120.** The session's `done` had become true in memory, behind
   React's back, and the summary picked it up the next time something else caused a render. A screen
   that shows the change somewhere and not where you made it is the signature of a mutation.

The fix is the line `App` had before: `all.map((s) => (s.id === id ? { ...s, done: !s.done } : s))`.

```schooling-figure
{"svg": "<svg data-fig=\"replace\" viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"On the left, changing in place: one array before and after, the same object, with s2's done flipped inside it, and Object.is says unchanged. On the right, map: a new array, with a new object for s2 and the same objects s1, s3, s4, s5 and s6 as before, and Object.is says changed.\"><text x=\"170\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">in place</text><rect x=\"40\" y=\"36\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"48\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"66.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s1</text><rect x=\"90\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s2</text><rect x=\"132\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s3</text><rect x=\"174\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"192.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s4</text><rect x=\"216\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"234.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s5</text><rect x=\"258\" y=\"44\" width=\"36\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s6</text><text x=\"170\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the same array, s2 changed inside</text><text x=\"170\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">Object.is(old, new) → true</text><text x=\"170\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">no render</text><text x=\"540\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">map: a new array</text><rect x=\"400\" y=\"36\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"56\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">old</text><rect x=\"400\" y=\"116\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"136\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">new</text><rect x=\"408\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"427.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s1</text><rect x=\"408\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"427.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s1</text><line x1=\"427\" y1=\"68\" x2=\"427\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><rect x=\"453\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s2</text><rect x=\"453\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"472.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">s2'</text><rect x=\"498\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"517.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s3</text><rect x=\"498\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"517.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s3</text><line x1=\"517\" y1=\"68\" x2=\"517\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><rect x=\"543\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"562.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s4</text><rect x=\"543\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"562.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s4</text><line x1=\"562\" y1=\"68\" x2=\"562\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><rect x=\"588\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"607.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s5</text><rect x=\"588\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"607.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s5</text><line x1=\"607\" y1=\"68\" x2=\"607\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><rect x=\"633\" y=\"44\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"652.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s6</text><rect x=\"633\" y=\"124\" width=\"38\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"652.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">s6</text><line x1=\"652\" y1=\"68\" x2=\"652\" y2=\"124\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"540\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">Object.is(old, new) → false</text><text x=\"540\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">dashed: the same object, reused</text></svg>", "caption": "React compares identities. A new array with one new object is a change it can see."}
```

`map` returns a new array, so React sees a change. The session that changed is a new object, `{ ...s,
done: !s.done }`, copied from the old with one field replaced. **Every other session is the same
object as before**, which costs nothing and lets lesson 21's `memo` skip the cards whose data did not
change. The original stays untouched, so the updater gives the same answer however many times strict
mode calls it.

The same goes for adding and removing, which lesson 10 needs:

| change | in place: wrong | a new array: right |
|---|---|---|
| add | `all.push(s)` | `[...all, s]` |
| remove | `all.splice(i, 1)` | `all.filter((x) => x.id !== id)` |
| change one | `all[i].done = true` | `all.map((x) => (x.id === id ? { ...x, done: true } : x))` |
| sort | `all.sort(byDate)` | `[...all].sort(byDate)`, or `all.toSorted(byDate)` |

The last command of the transcript puts back the correct `App` and strict mode.
