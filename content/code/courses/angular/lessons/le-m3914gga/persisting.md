---
title: Persisting it, with the effect lesson 6 promised
version: 1
---

**Keeping a value in the browser between visits means writing it outside the application, and an
effect is the tool for that.** Lesson 6 said the effects worth keeping in this course were few, and
that one here would save to `localStorage`, which is exactly the outside world an effect is for. A
`computed` derives a value inside the signal graph; an effect does something the graph cannot see,
every time the signals it reads change.

```schooling-example
{"language": "typescript", "file": "src/app/preferences.ts", "parts": [
 {"code": "// src/app/preferences.ts\nimport { Injectable, computed, effect, signal } from '@angular/core';\n\nconst KEY = 'planner.preferences';\n\ninterface Saved {\n  hideDone: boolean;\n}", "note": "One key for all the planner's preferences, in one JSON object, so a new preference is a new field and not a new key to clean up."},
 {"code": "function read(): Saved {\n  try {\n    const saved = JSON.parse(localStorage.getItem(KEY) ?? '{}');\n    return { hideDone: saved?.hideDone === true };\n  } catch {\n    return { hideDone: false };\n  }\n}", "note": "Reading is defensive twice over. The stored text may not be JSON, or may be from an older version of the planner, so each field is checked. And `localStorage` can throw: a browser blocking storage, or no browser at all, which lesson 23 runs this code in. A failed read is the default preferences, which is what a first visit has anyway."},
 {"code": "@Injectable({ providedIn: 'root' })\nexport class Preferences {\n  private readonly state = signal<Saved>(read());\n  readonly hideDone = computed(() => this.state().hideDone);\n\n  constructor() {\n    effect(() => {\n      const saved = JSON.stringify(this.state());\n      try {\n        localStorage.setItem(KEY, saved);\n      } catch (error) {\n        console.warn('Preferences will last this visit only:', error);\n      }\n    });\n  }\n\n  setHideDone(hide: boolean): void {\n    this.state.update((saved) => ({ ...saved, hideDone: hide }));\n  }\n}", "note": "The state starts from what was saved. The effect runs once at the start and again whenever `state` changes, and writes it out. A failed write is said in the console rather than swallowed, because it means the preference will not last."}
]}
```

The same look as the end of the last section:

```
ana@dev:~/planner$ look http://localhost:4200/courses/javascript --today 2026-10-23 --text app-course-sessions --do 'check Hide sessions that are done' --do 'go /courses/javascript'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
-- check Hide sessions that are done
-- go /courses/javascript
[vite] connecting...
Angular is running in development mode.
[vite] connected.
Hide sessions that are done
Sat 24 Oct, 50 minutes
```

The application loaded again, made a new `Preferences`, and the new one read what the old one had
written. The components did not change at all: `CourseSessions` still asks `hideDone()` and calls
`setHideDone`, and where the value lives between visits is the service's business.

**`localStorage` is the reader's, not yours.** It is per browser and per origin, the person can clear it,
and anything there can be read by any script on the page, so it is for preferences and drafts, never
for a password or a token. What must survive a change of computer belongs on the server, as the
sessions do.
