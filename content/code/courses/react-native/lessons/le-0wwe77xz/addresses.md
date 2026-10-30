---
title: Every screen an address
version: 1
---

**A deep link is an address that opens a particular screen**: `planner://course/guitar` from a
notification, another app or a web page, or `https://…/course/guitar` in a browser. React Navigation
turns addresses into navigation state and back with the `linking` object at the end of
`src/navigation.tsx`:

| part | meaning |
|---|---|
| `prefixes: ["planner://"]` | the scheme the phone hands to this app |
| `Courses: ""` | the empty path is the *Courses* tab |
| `Week: "week"` | `/week` is the *This week* tab |
| `Course: "course/:id"` | `/course/guitar` is the Course screen, with `id` set to `guitar` |

The second test of the last section asked React Navigation's own `getStateFromPath` what
`course/statistics` means, and got the Course route with `{ id: "statistics" }`: an address checked
with no screen at all.

## Opening addresses in the browser

On the web the address bar is the link. **A single-page app needs a server that answers every path with
`index.html`**, so that `/course/guitar` loads the app, which then reads the path. `npx expo serve`
answers unknown paths with *404*, which is what the first recording of this section got, so the export
is served here with `serve`, a small static server whose `--single` option does exactly that:

```
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/course/guitar?today=2026-10-21'
- heading "Guitar" [level=1]
- heading "2026-10-21" [level=2]
- text: 20 min
- heading "2026-10-28" [level=2]
- text: 20 min
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/week?today=2026-10-21'
- heading "This week" [level=1]
- heading "2026-10-19" [level=2]
- text: 30 min, done
- heading "2026-10-20" [level=2]
- text: 45 min, done
- heading "2026-10-21" [level=2]
- text: 20 min
- heading "2026-10-22" [level=2]
- text: 30 min
- tablist:
  - tab "Courses"
  - tab "This week" [selected]
ana@dev:~/planner$ node look.mjs 'http://localhost:8082/course/chemistry'
- heading "Not found" [level=1]
- text: There is no course called chemistry.
```

**Three addresses, three screens, no pressing.** `/course/guitar` opened the course, with its title in
the header as a level-1 heading and its days below. `/week` opened the second tab, marked `selected`.
`/course/chemistry` named a course that does not exist and got the screen's plain answer, with *Not
found* as its title.

The course opened at its address has no back link: nothing was under it. React Navigation can be told to
put the tabs underneath a deep-linked screen, which is usually right for an app opened from a
notification, and its documentation calls this `initialRouteName` in the linking configuration.

## On a phone

The scheme comes from `app.json`: Expo uses the `"scheme"` field, and the template has none yet, so add
`"scheme": "planner"` inside `"expo"`. Prebuild then writes the intent filter into the Android manifest and
the URL type into `Info.plist`. *Opening `planner://course/guitar` on a device was not run for this
course.* With the development build installed, `adb shell am start -a android.intent.action.VIEW -d
planner://course/guitar` opens it on Android, and `npx uri-scheme open planner://course/guitar --ios`
on the iOS simulator.

**A custom scheme is not a secure link.** Any app can claim `planner://`. Links that must reach only your
app, from email or the web, are Android App Links and iOS Universal Links, which tie an `https` address to
the app through a file on your own domain; `mobile-delivery` covers publishing them.
