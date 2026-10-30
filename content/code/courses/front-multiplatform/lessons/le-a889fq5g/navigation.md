---
title: Navigation, as files
version: 1
---

**A phone app moves between screens, and the way back is part of the platform**: the back gesture on
Android and iOS, the title bar with its back arrow, the screen sliding in from the side. **Expo Router**
gives that to a React Native app with one rule: **every file in the `app/` folder is a screen, and its
path is its address**.

| file | address | screen |
|---|---|---|
| `app/_layout.tsx` | none | not a screen: what wraps every screen, here a stack |
| `app/index.tsx` | `/` | the list of courses |
| `app/course/[id].tsx` | `/course/statistics`, `/course/guitar`, … | one course; `[id]` is the part of the address that varies |

A **stack** is the navigation every phone app has: a new screen goes on top, back takes it off. On a
phone, Expo Router builds it from the platform's own navigation, so the title bar, the animation and the
back gesture are the system's. In a browser, each screen is a page with its own address, and the
browser's back button works.

Install it, with the four packages it needs, and let Expo pick their versions for SDK 58:

```
ana@dev:~/planner-native$ npx expo install expo-router react-native-screens react-native-safe-area-context expo-linking expo-constants
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 5 SDK 58.0.0 compatible native modules using npm
> npm install

added 50 packages, and audited 536 packages in 5s

5 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
› Added config plugin: expo-router
```

**The first two lines are the recording machine's**, not yours: it could not reach Expo's servers,
so Expo ran offline, without its check of which libraries work together. Then npm installed the five
packages at the versions SDK 58 lists. The last line is Expo editing `app.json` for you: a **config plugin** is a package's own instructions
for the native projects, applied when they are generated, which lesson 9 meets again. Then pin the five
versions it chose, as lesson 7 did, tell the project that its entry point is now the router, not
`index.ts`, and remove the two files lesson 7 had in its place:

```
ana@dev:~/planner-native$ npm install -E expo-router@58.0.26 react-native-screens@4.30.0 react-native-safe-area-context@5.10.1 expo-linking@58.0.14 expo-constants@58.0.13 > /dev/null
ana@dev:~/planner-native$ npm pkg set main=expo-router/entry
ana@dev:~/planner-native$ git rm -q App.tsx index.ts
ana@dev:~/planner-native$ grep -E "\"main\"|expo-router" package.json
  "main": "expo-router/entry",
    "expo-router": "58.0.26",
```

Moving from one screen to another is one call, `router.push("/course/statistics")`, and the screen at
the other end reads the varying part of its address with `useLocalSearchParams()`. **The address is
the only thing passed between screens**, and it is a string. The plan, which every screen needs, lives
above all of them, in the layout, which is the next section.
