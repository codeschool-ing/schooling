---
title: A first app with Expo
version: 1
---

**Expo is the way React Native's own documentation recommends starting a new app.** It is a set of tools and libraries around React Native: it runs the app on a phone without building it first, builds it in the
cloud when you need a real package, and gives the native features as packages. Lesson 9 is about Expo
itself. This section uses the least of it: a new project, and the app in a browser.

**The project is separate from the planner**, in `~/planner-native`, because it has no Vite, no
`index.html` and no `src/view.ts`. Create it from Expo's TypeScript template, at the version this course
was recorded with, without installing yet:

```
ana@dev:~$ npx create-expo-app@5.0.0 planner-native --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1
ana@dev:~$ cd planner-native
ana@dev:~/planner-native$ ls
AGENTS.md
App.tsx
LICENSE
app.json
assets
index.ts
package.json
tsconfig.json
```

`@sdk-58` asks for the template of Expo's SDK 58, the release this course uses; without it,
`create-expo-app` takes the newest template, which follows Expo's own releases and not this course.
Its report went to `/dev/null` because it draws a spinner and emoji this page cannot show; `ls` shows
what it wrote. `App.tsx` is the
app, `index.ts` registers it, and `app.json` holds its name, icons and settings for each platform.

Then install, with every version written exactly, as in lesson 1, plus the three packages that let the
same app run in a browser: `react-dom` and `react-native-web`, which turn React Native's components into
HTML, and `@expo/metro-runtime`. And Playwright, at the same version as the planner's:

```
ana@dev:~/planner-native$ npm install -E expo@58.0.17 expo-status-bar@58.0.4 react@19.3.0 react-native@0.88.0 react-dom@19.3.0 react-native-web@0.21.4 @expo/metro-runtime@58.0.15

added 481 packages, and audited 482 packages in 15s

5 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner-native$ npm install -E -D typescript@6.0.3 @types/react@19.3.0 playwright@1.63.0

added 4 packages, and audited 486 packages in 2s

5 high severity vulnerabilities

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
ana@dev:~/planner-native$ grep -A12 '"dependencies"' package.json
  "dependencies": {
    "@expo/metro-runtime": "58.0.15",
    "expo": "58.0.17",
    "expo-status-bar": "58.0.4",
    "react": "19.3.0",
    "react-dom": "19.3.0",
    "react-native": "0.88.0",
    "react-native-web": "0.21.4"
  },
  "devDependencies": {
    "@types/react": "19.3.0",
    "playwright": "1.63.0",
    "typescript": "6.0.3"
```

The five high-severity advisories are, on the day this was recorded, in packages Expo's own tools
depend on; `npm audit` names them. As in lesson 2, **do not reach for `npm audit fix --force`**, which
may move `expo` itself to another SDK.

Expo's own command for adding a package, `npx expo install`, picks the version of each package that
matches the SDK, and writes it with a `~`. Running it first and pinning after with `npm install -E` is
the way to get both the right version and an exact one.

## Where to run it

| where | how | what it shows |
|---|---|---|
| a browser | `npx expo start --web`, or export and serve, as below | the app, drawn with HTML by `react-native-web` |
| a phone, with Expo Go | `npx expo start`, then scan the QR code it prints with the Expo Go app | the app, with real native views, without building it |
| an emulator | `npx expo start`, then `a` for Android or `i` for the iOS simulator on a Mac | the same, on the computer |

**The browser is the only one of the three this course could run**, for the reasons lesson 3 gave, so
the transcripts show the web build. *Expo Go on a phone was not run.* It is the quickest of the three to
set up, an app from either store and a phone on the same network as the computer, and it is where the
native views of the next section stop being a description.
