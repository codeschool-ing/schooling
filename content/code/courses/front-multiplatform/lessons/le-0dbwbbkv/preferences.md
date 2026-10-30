---
title: Preferences, so a reload keeps the plan
version: 1
---

**Lesson 1 ended with a plan that forgot every change on reload.** `savePlan` now runs after each one,
and `loadPlan` runs before the JSON file is fetched, so the file only supplies the plan the very first
time. Mark the Spanish session of 22 October done, reload, and look at what the browser kept:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:5173/?today=2026-10-21' --click 'Spanish A2' --click 'Mark done' --reload --eval 'Object.keys(localStorage)' --eval 'localStorage.length'
console.debug: [vite] connecting...
console.debug: [vite] connected.
console.debug: [vite] connecting...
console.debug: [vite] connected.
Object.keys(localStorage) = CapacitorStorage.plan
localStorage.length = 1
- main:
  - heading "Study planner" [level=1]
  - paragraph: "This week: 105 of 125 minutes done"
  - list:
    - listitem:
      - button "Spanish A2"
    - listitem:
      - button "Statistics"
    - listitem:
      - button "Guitar"
  - button "Export plan"
  - button "Where am I?"
  - status
```

**The week now reads 105 of 125 after a reload**, where it read 75 before: the session marked done
was saved, and the page loaded the saved plan instead of `courses.json`. The two `--eval` lines show
where it went on the web, one key in `localStorage`, named `CapacitorStorage.plan`.

## Why not `localStorage` directly

On the web, Preferences is a thin layer over `localStorage`, so it is fair to ask what it adds. The
answer is on the phone. **A mobile system may clear a WebView's `localStorage`**, which it treats
much like a cache, and the plugin's own documentation says so in its first lines. On iOS
Preferences writes to `UserDefaults` and on Android to `SharedPreferences`, the stores each system
keeps for an app's settings and never clears behind its back. Same call, three stores, and only one of
them can vanish.

**Preferences is for small values**, settings and a plan of a few hundred characters. It writes the
whole value every time and reads it whole, so a list that grows into thousands of sessions belongs in
a file, the next section, or in a database: the community plugins for SQLite are the usual choice, and
none is official.

## Two rules worth keeping

- **Save after the change, not before the screen.** `change()` in `main.ts` redraws at once and saves
  in the background, so a slow write never holds up a tap. If the save fails, the status line says so
  rather than the change silently not surviving.
- **Version what you store.** The day `Session` gains a field, a plan saved by the old app comes back
  without it. A `version` key beside the plan, checked in `loadPlan`, is what lets a later release
  convert an old plan instead of breaking on it. The planner does not need one yet; your app may.
