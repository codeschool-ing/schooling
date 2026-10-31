---
title: A first project, and what actually ships
version: 1
---

**The quickest way to believe the last three sections is to build something and look inside it.**
This section makes a throwaway project, asks Expo to produce what would go into an Android app, and
reads the file it writes. Lesson 3 starts the real project; this one goes in the bin afterwards.

## The tools answer

First, the three tools from the last section. Open a terminal and ask each for its version:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ npm --version
10.9.4
ana@dev:~$ git --version
git version 2.43.0
```

Any `git` from the last few years will do. Node.js and npm should be exactly these versions, because
every transcript in this course was recorded with them; if `node` is not found, the last section
says where it should have come from.

## A project from Expo's template

`create-expo-app` writes a new project from a template. `npx` downloads it and runs it without
installing it anywhere permanent. Two things in the command keep it from drifting away from this
course: `@5.0.0` pins the version of the tool, and `@sdk-58` asks for the template of Expo's SDK 58,
the release this course uses, rather than whatever is newest on the day you type it.

```
ana@dev:~$ npx create-expo-app@5.0.0 hello --template blank-typescript@sdk-58 --no-install > /dev/null 2>&1
ana@dev:~$ cd hello
ana@dev:~/hello$ ls
AGENTS.md
App.tsx
LICENSE
app.json
assets
index.ts
package.json
tsconfig.json
ana@dev:~/hello$ npm install

added 460 packages, and audited 461 packages in 31s

8 vulnerabilities (5 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

`--no-install` stopped it from installing straight away so that the installation could be its own
step. **`App.tsx` is the whole app for now**, and the rest are its settings; lesson 3 goes through
each file. The report `create-expo-app` prints went to `/dev/null` because it draws a spinner this
page cannot show. `ls` shows what it wrote instead.

## What an Android app would carry

`npx expo export` runs the same bundler a real build runs, called **Metro**, and writes what it
produces into `dist/`. With `--platform android` it produces exactly the file an Android build would
put inside the app:

```
ana@dev:~/hello$ npx expo export --platform android > /dev/null 2>&1
ana@dev:~/hello$ find dist -type f
dist/_expo/static/js/android/index-1f4759e666c47e0ac79e3ec24a99b026.hbc
dist/metadata.json
ana@dev:~/hello$ file dist/_expo/static/js/android/*.hbc
dist/_expo/static/js/android/index-1f4759e666c47e0ac79e3ec24a99b026.hbc: Hermes JavaScript bytecode, version 99
ana@dev:~/hello$ grep -c "Open up App.tsx" dist/_expo/static/js/android/*.hbc
1
```

**There are two files, and only one matters here.** `metadata.json` describes the export, and lesson
21 uses it. The `.hbc` file is your app: every component, every line of React and React Native, and
every library, gathered into one file and compiled. `file` recognises it, and the name it gives is
the point of this lesson: **Hermes JavaScript bytecode**. Not ARM machine code, not Kotlin: bytecode
for the engine that the app carries.

The last command searched the bytecode for the sentence the template's `App.tsx` displays, and
found it once. Strings survive compilation as they are; the logic around them became instructions for
Hermes. That is what Hermes was built for: the app loads bytecode that was compiled once, on the
computer that built it, instead of parsing JavaScript text on the phone at every launch.

## Throw it away

```sh
cd ~ && rm -rf hello
```

Nothing else on your computer changed: `npx` keeps its downloads in npm's cache, and the project was
the only thing written outside it.
