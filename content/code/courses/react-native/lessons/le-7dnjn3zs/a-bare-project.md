---
title: A bare project: the native folders are yours
version: 1
---

**React Native on its own starts by writing two native projects into your repository**, and from that
day they are source code you maintain. The tool that does it is the React Native community CLI, and
the clearest way to see what *bare* means is to run it and look:

```
ana@dev:~$ npx @react-native-community/cli@20.2.0 init Bare --version 0.88.1 --skip-install --skip-git-init > /dev/null 2>&1
ana@dev:~$ ls Bare
App.tsx
Gemfile
README.md
__tests__
android
app.json
babel.config.js
index.js
ios
jest.config.js
metro.config.js
package.json
tsconfig.json
ana@dev:~$ ls Bare/android Bare/ios
Bare/android:
app
build.gradle
gradle
gradle.properties
gradlew
gradlew.bat
settings.gradle

Bare/ios:
Bare
Bare.xcodeproj
Podfile
ana@dev:~$ find Bare/android Bare/ios -type f | wc -l
37
```

`--version 0.88.1` asks for the same React Native that Expo's SDK 58 uses, so the two projects in
this lesson differ in nothing but the approach. `--skip-install` and `--skip-git-init` keep it from
installing packages and making a commit, because this project is for looking at.

## What you are now responsible for

**`android/` is a Gradle project** and **`ios/` is an Xcode project** with a `Podfile` for CocoaPods,
the dependency manager iOS libraries use. Between them, 37 files, and every one is yours: the Android
manifest, the Gradle settings, the Xcode project file, the iOS app delegate. The JavaScript in
`App.tsx` is the part that looks like the rest of this course; the native folders are the part that
makes this a bare project.

Three things follow from owning them, and each is a real cost:

- **A configuration change is an edit in two languages.** A new permission is a line in
  `AndroidManifest.xml` and a key in `Info.plist`; a new app name, two more places. Nothing checks
  that the two platforms agree.
- **An upgrade is a diff to apply by hand.** When React Native moves from one version to the next,
  the template for these folders moves too. The community publishes the *upgrade helper*, a page
  that shows the template's diff between two versions, and you apply it to files you may have edited
  since. On a project a few versions behind, that is days of work.
- **A library with native code may need hands in both folders.** Most link themselves now, through
  autolinking, but some still ask you to paste lines into the manifest or the app delegate.

## What you gain

**Nothing stands between you and the native project.** Any Android or iOS code, any build setting,
any tool that expects a normal Gradle or Xcode project works as it would anywhere. A team that already
has native developers and native code, or an app that is mostly native with React Native in a few
screens, starts from here, and React Native's documentation has a section on adding it to an existing
native app for exactly that case.

**The next sections show that an Expo project can get the same folders**, written out on demand, and
then decide whether to keep them. The choice this lesson ends with is therefore not *native folders or
none*: it is *native folders you edit, or native folders you generate*.
