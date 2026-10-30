---
title: Metro, the bundler, and the development server
version: 1
---

**Metro turns a project of hundreds of files into the one file Hermes runs.** It is React Native's
bundler, and both `npx expo start` and `npx expo export` drive it. Knowing its three steps explains
most of what you will see it do, including the errors.

| step | what Metro does | what can go wrong there |
|---|---|---|
| resolve | starting from `index.ts`, follow every `import` to a file, in your project or in `node_modules` | *Unable to resolve module*: a typo, or a package not installed |
| transform | run each file through Babel, which removes TypeScript and turns JSX into function calls | a syntax error, reported with the file and line |
| serialise | put the transformed files in one bundle, each wrapped as a module with a number | rarely anything; this is where the size comes from |

**The bundle is different per platform.** A file called `button.android.tsx` is chosen over
`button.tsx` when Metro bundles for Android, and lesson 6 is about that. So Metro is always asked for a
bundle *for* a platform, and the development server answers for whichever one asks.

## The development server

`npx expo start` starts Metro as a server, by default on port 8081, and leaves it running. A phone in
Expo Go, a development build or a browser connects to it and asks for the bundle; when you save a
file, Metro rebuilds only what changed and the app is told to reload that part. Start it in one
terminal and leave it there; the commands below are typed in a second one.

```
ana@dev:~/planner$ curl -s localhost:8081/status; echo
packager-status:running
ana@dev:~/planner$ curl -s 'localhost:8081/index.bundle?platform=android&dev=true' -o dev.js
ana@dev:~/planner$ ls -l dev.js
-rw-r--r-- 1 ana ana 4280118 Oct 30 15:25 dev.js
ana@dev:~/planner$ grep -c "Study planner" dev.js
1
ana@dev:~/planner$ grep -o "This week" dev.js | head -1
This week
```

That is exactly what a development build on a phone does when it starts: it asks this server for
`index.bundle` for its platform, in development mode, and runs what comes back. The first request
took a moment because Metro transformed every file; the next is quicker, because transformed files
are cached in the project's `.expo` and in the system's temporary folder. The text of `App.tsx` is in
the bundle as written, because a development bundle is JavaScript, not bytecode.

**A development bundle is large on purpose.** It keeps React's warnings and checks, carries the
names of every function for readable errors, and is neither minified nor compiled. Lesson 18 compares
it with the release bundle and finds the bugs that live in the difference.

## Fast Refresh

When a file is saved, the server pushes the changed modules to every connected app, and React
re-renders the components defined in them **while keeping their state**: a half-typed form stays half
typed. That is **Fast Refresh**, and it is on by default. Two cases fall back to a full reload, which
does lose state: an edit to a file that exports something other than components, and a syntax error
fixed after it broke the app.

*Fast Refresh on a phone or an emulator was not run for this course.* In the browser it behaves the
same way, through `npx expo start --web`, which opens the app and reloads it on every save.

## When the server misbehaves

Nearly every strange development-server problem has the same cure: **stop it and start it with
`--clear`**, which empties Metro's cache. A package installed while the server ran, a renamed file
Metro still resolves to its old name, an environment variable that did not change: each one is a
stale cache. `npx expo start --clear` costs one slow first bundle, and settles it.
