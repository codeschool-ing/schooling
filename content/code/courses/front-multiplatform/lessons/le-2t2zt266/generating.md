---
title: Generating the plugin
version: 1
---

**Capacitor's generator writes a whole plugin project**: the TypeScript side, an Android library, an
iOS Swift package, a demonstration app and the scripts to build them. It lives beside the planner, in
a folder of its own, because a plugin is its own package with its own version, and the planner will
install it like any other. Every question the generator would ask is answered on the line:

```
ana@dev:~$ npm init @capacitor/plugin@0.22.0 keep-awake -- --name capacitor-keep-awake --package-id com.example.keepawake --class-name KeepAwake --repo https://example.org/keep-awake --author "Ana Lima <ana@example.org>" --license MIT --description "Keep the screen on while a study session runs" --android-lang kotlin > /dev/null
npm warn deprecated inflight@1.0.6: This module is not supported, and leaks memory. Do not use it. Check out lru-cache if you want a good and tested way to coalesce async requests by a key value, which is much more comprehensive and powerful.
npm warn deprecated @humanwhocodes/config-array@0.13.0: Use @eslint/config-array instead
npm warn deprecated rimraf@3.0.2: Rimraf versions prior to v4 are no longer supported
npm warn deprecated @humanwhocodes/object-schema@2.0.3: Use @eslint/object-schema instead
npm warn deprecated glob@7.2.3: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated eslint@8.57.1: This version is no longer supported. Please see https://eslint.org/version-support for other options.
npm warn deprecated uuid@7.0.3: uuid@10 and below is no longer supported.  For ESM codebases, update to uuid@latest.  For CommonJS codebases, use uuid@11 (but be aware this version will likely be deprecated in 2028).

dist/esm/index.js → dist/plugin.js, dist/plugin.cjs.js...
created dist/plugin.js, dist/plugin.cjs.js in 42ms
Switched to a new branch 'main'
ana@dev:~$ cd keep-awake
ana@dev:~/keep-awake$ git ls-files ':!example-app' ':!*/gradle/wrapper/*' ':!*.gitkeep'
.eslintignore
.gitignore
.prettierignore
CONTRIBUTING.md
CapacitorKeepAwake.podspec
Package.swift
README.md
android/.gitignore
android/build.gradle
android/gradle.properties
android/gradlew
android/gradlew.bat
android/proguard-rules.pro
android/settings.gradle
android/src/androidTest/kotlin/com/getcapacitor/android/ExampleInstrumentedTest.kt
android/src/main/AndroidManifest.xml
android/src/main/kotlin/com/example/keepawake/KeepAwake.kt
android/src/main/kotlin/com/example/keepawake/KeepAwakePlugin.kt
android/src/test/kotlin/com/getcapacitor/ExampleUnitTest.kt
ios/.gitignore
ios/Sources/KeepAwakePlugin/KeepAwake.swift
ios/Sources/KeepAwakePlugin/KeepAwakePlugin.swift
ios/Tests/KeepAwakePluginTests/KeepAwakeTests.swift
package.json
rollup.config.mjs
src/definitions.ts
src/index.ts
src/web.ts
tsconfig.json
```

- **`--name`** is the npm package name, the one the planner will import. `capacitor-` in front is the
  convention that makes a plugin findable.
- **`--package-id`** is the Android package and the reverse-domain identity of the native code. Use
  a domain you control, as with the `appId`.
- **`--class-name`** is the name the three sides share, and the next section shows why that matters.
- **`--android-lang kotlin`**: the generator writes Java unless told otherwise. Kotlin is what Google's
  own documentation and Android Studio's templates use now, and the shorter of the two to read.

The generator also made the folder a git repository, with one commit, ran `npm install` in it and
built it once. Its own report went to `/dev/null`, because it ends with emoji this page cannot draw;
what still came through is what other programs wrote to the error stream, npm's warnings about old
packages among the generator's tools and Rollup's line about the build. None of them is a problem in
your plugin. What it made is the list of files, and three groups matter, the three implementations:

| folder | what it is |
|---|---|
| `src/` | the TypeScript: the interface, the web implementation, and the line that joins them |
| `android/` | an Android library, written in Kotlin, built by Gradle into the app that installs it |
| `ios/` | a Swift package, built by Xcode into the app that installs it |

`package.json`'s `capacitor` key tells the `cap` command where the two native folders are, and
`Package.swift` and the `.podspec` describe the iOS side to Swift Package Manager and to CocoaPods.
Its version ranges, `^8.0.0` and the like, are right **for a library**: they say which versions of
Capacitor the plugin works with, and the app that installs it is the one that pins.

## The join

`src/index.ts` is generated and stays as it is:

```
ana@dev:~/keep-awake$ cat src/index.ts
import { registerPlugin } from '@capacitor/core';

import type { KeepAwakePlugin } from './definitions';

const KeepAwake = registerPlugin<KeepAwakePlugin>('KeepAwake', {
  web: () => import('./web').then((m) => new m.KeepAwakeWeb()),
});

export * from './definitions';
export { KeepAwake };
```

**`registerPlugin` is where the three implementations meet**. On a phone, Capacitor finds the native
class registered under `'KeepAwake'` and sends every call to it. In a browser there is none, so it
runs the function given as `web`, which loads `src/web.ts` only when it is first needed.

## What the generator wrote that the planner does not need

The template is an `echo` method on all three sides, a demonstration app in `example-app/`, a sample
test on each platform, and a separate implementation class on each native side. This plugin is small
enough to keep everything in the plugin class itself, so the extra files go, and so does the test
target in `Package.swift` that pointed at the deleted iOS test:

```
ana@dev:~/keep-awake$ git rm -rq example-app ios/Tests android/src/test android/src/androidTest android/src/main/kotlin/com/example/keepawake/KeepAwake.kt ios/Sources/KeepAwakePlugin/KeepAwake.swift
ana@dev:~/keep-awake$ sed -n '/targets: \[/,$p' Package.swift
            targets: ["KeepAwakePlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "KeepAwakePlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/KeepAwakePlugin")
    ]
)
```

A plugin people depend on deserves tests on each platform, and the generator's structure is the one
to keep for that. **They need an Android SDK and Xcode to run**, which this course's recording machine
did not have.
