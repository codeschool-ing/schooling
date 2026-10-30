---
title: Trying it, and what a phone would show
version: 1
---

Serve the export as in lesson 7 and open it. The router renders a page as soon as it knows which screen
the address names, so the first run waits a moment for it:

```
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --wait 1000
- heading "Study planner" [level=1]
- main:
  - text: "This week: 75 of 125 minutes done"
  - button "Spanish A2"
  - button "Statistics"
  - button "Guitar"
```

**The title bar is a heading, "Study planner"**, drawn by the stack from the `title` the screen set,
above the screen itself, the `main`. Now the course, a new session for 23 October, and one with a date
the planner cannot read:

```
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --click Statistics --fill Date=2026-10-23 --fill Minutes=25 --click 'Add session'
- link "Study planner, back":
  - /url: /?today=2026-10-21
- heading "Statistics" [level=1]
- main:
  - text: "This week: 75 of 150 minutes done 2026-10-20, 45 min done 2026-10-26, 60 min"
  - button "Mark done"
  - text: 2026-10-23, 25 min
  - button "Mark done"
  - textbox "Date":
    - /placeholder: YYYY-MM-DD
  - textbox "Minutes"
  - button "Add session"
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --click Statistics --fill Date=23/10 --fill Minutes=25 --click 'Add session' | tail -n 3
  - textbox "Minutes": "25"
  - button "Add session"
  - alert: "not a date: 23/10"
```

The new session is in the list and the week went from 125 to 150, the same arithmetic as lesson 1
section 06, from the same `addSession`. The second run typed `23/10`: `addSession` refused it with its
own message, `not a date: 23/10`, and the screen showed that as an alert instead of adding a session
nobody could total. On the course screen the stack also drew a **link back**, named after the screen it
returns to; on a phone that is the title bar's back arrow, and the system's back gesture does the same.

## What the phone shows instead

*Expo Go and the emulators were not run for this course, as lesson 7 said; this is what the same code
does there, by Expo's and React Native's documentation.* The title bar is the platform's: centred on
iOS, at the left on Android. The course screen slides in from the right, and on iOS a swipe from the
left edge takes it away. The fields are native, and the minutes field opens the digit keyboard.
**Nothing in the code above says any of that**: it is what native views and a native stack give, and it
is the part of lesson 7's "what it buys" that a browser cannot show you.
