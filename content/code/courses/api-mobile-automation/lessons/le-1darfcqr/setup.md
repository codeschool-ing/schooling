---
title: Setting up a React Native project with Detox
version: 1
---

**Detox is three things to install, and only one of them is an npm package.** The package goes into
the React Native project's `package.json`. The configuration file says which app and which device.
And the Android app itself has to carry Detox's library, which is a change to its Gradle files.
The first two ran on the recording machine and are shown as they ran. The third could not be
built there, and is described from Detox's own setup guide.

## The project

React Native's own command line creates a project from its template. In `~/boxoffice`:

```sh
npx --yes @react-native-community/cli@20.2.0 init TicketsRN --version 0.86.3 --directory tickets-rn --pm npm --skip-git-init
```

`TicketsRN` is the app's name, which React Native wants without dashes. `--directory` puts it in
`tickets-rn` beside the Kotlin Tickets. `--version` pins React Native, for the reason lesson 6 pins
everything. `--skip-git-init` leaves out a Git repository of its own, since the project lives
inside boxoffice's. The command downloads the template and installs its packages, several hundred of
them. It ends with instructions for running the app on Android. Its progress lines are drawn with
symbols this page cannot show, so its output is not reproduced. This is what it left:

```
ana@laptop:~/boxoffice$ ls tickets-rn
App.tsx    __tests__  babel.config.js  jest.config.js	package-lock.json
Gemfile    android    index.js	       metro.config.js	package.json
README.md  app.json   ios	       node_modules	tsconfig.json
ana@laptop:~/boxoffice$ ls tickets-rn/android/app/src/main/java/com/ticketsrn
MainActivity.kt  MainApplication.kt
```

`App.tsx` is the app, in TypeScript. `android` and `ios` are two native projects that wrap it, the
Android one with a `MainActivity.kt` like Tickets's. `__tests__` and `jest.config.js` are the
template's own unit test. It uses Jest, the test runner Detox runs on too.

## Detox

Into the React Native project, not boxoffice's, because Detox belongs to that app. Change into
`tickets-rn` first with `cd tickets-rn`. Every command from here on runs there:

```
ana@laptop:~/boxoffice/tickets-rn$ npm install --save-dev --save-exact detox@20.51.4
npm warn deprecated rimraf@2.4.5: Rimraf versions prior to v4 are no longer supported
npm warn deprecated glob@6.0.4: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me
npm warn deprecated glob@8.1.0: Old versions of glob are not supported, and contain widely publicized security vulnerabilities, which have been fixed in the current version. Please update. Support for old versions may be purchased (at exorbitant rates) by contacting i@izs.me

added 99 packages, and audited 965 packages in 11s

180 packages are looking for funding
  run `npm fund` for details

60 vulnerabilities (12 moderate, 48 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

```
ana@laptop:~/boxoffice/tickets-rn$ npx detox --version
20.51.4
```

`npx detox init` writes the three files a Detox project starts with:

```
ana@laptop:~/boxoffice/tickets-rn$ npx detox init
Created a file at path: .detoxrc.js
Created a file at path: e2e/jest.config.js
Created a file at path: e2e/starter.test.js
```

`e2e/jest.config.js` tells Jest where the specs are and to run them through Detox. They run one at
a time, with two minutes each, because a spec waits for an emulator to boot and an app to install.
`e2e/starter.test.js` is an example for an app this is not. Delete it, since section 05 writes the
real spec:

```
ana@laptop:~/boxoffice/tickets-rn$ rm e2e/starter.test.js
ana@laptop:~/boxoffice/tickets-rn$ ls e2e
jest.config.js	tickets.test.js
```

## The configuration

`.detoxrc.js` says how to build the app, where the built APK is, and which device to run it on.
`init` writes one for every combination: iOS and Android, debug and release, emulator and phone.
Keep the Android debug build on the emulator of lesson 14 and drop the rest. Replace the file;
save it as `tickets-rn/.detoxrc.js`:

```js
/** @type {Detox.DetoxConfig} */
module.exports = {
  testRunner: {
    args: {
      '$0': 'jest',
      config: 'e2e/jest.config.js'
    },
    jest: {
      setupTimeout: 120000
    }
  },
  apps: {
    'android.debug': {
      type: 'android.apk',
      binaryPath: 'android/app/build/outputs/apk/debug/app-debug.apk',
      build: 'cd android && ./gradlew assembleDebug assembleAndroidTest -DtestBuildType=debug',
      reversePorts: [
        8081
      ]
    }
  },
  devices: {
    emulator: {
      type: 'android.emulator',
      device: {
        avdName: 'Pixel_8_API_35'
      }
    }
  },
  configurations: {
    'android.emu.debug': {
      device: 'emulator',
      app: 'android.debug'
    }
  }
};
```

| part | what it says |
|---|---|
| `testRunner` | run the specs with Jest, using `e2e/jest.config.js` |
| `apps.android.debug` | the APK to install, and `build`, the Gradle command `npx detox build` runs to make it and the test APK beside it |
| `reversePorts: [8081]` | `adb reverse` for Metro, the server that sends a debug build its JavaScript, so the app on the emulator reaches it on your computer |
| `devices.emulator` | the AVD to boot, by name: `Pixel_8_API_35`, from lesson 14 |
| `configurations` | the pair a run asks for with `-c android.emu.debug` |

**A debug build loads its JavaScript from Metro on your computer.** `npx react-native start` has
to be running in another terminal while debug tests run. A release build carries its JavaScript
inside the APK and needs no Metro, which is one reason pipelines often test release builds.

## What the Android app needs, described

Detox's library for Android ships inside the npm package, and Gradle finds it there:

```
ana@laptop:~/boxoffice/tickets-rn$ ls node_modules/detox/Detox-android
com
```

Detox's setup guide lists the changes the Android project needs so that the app carries that
library and can be driven by it. None of them could be built on the recording machine, so they are
named here and not shown. Follow the guide for the version you installed, because these files are
where React Native's template changes most between releases:

1. in `android/build.gradle`, the folder above as a Maven repository, so Gradle can find the
   library;
2. in `android/app/build.gradle`, under `defaultConfig`, the instrumentation runner of lesson 16
   and the build type Detox tests against, and the library as an `androidTestImplementation`;
3. a small test class under `android/app/src/androidTest`, given in the guide, that starts Detox
   inside the instrumentation, the same mechanism Espresso used in lesson 16;
4. a network security configuration allowing plain HTTP to `10.0.2.2` and `localhost`, like the one
   Tickets has from lesson 14. The app talks to Metro and to boxoffice over plain HTTP.

Then `npx detox build -c android.emu.debug` runs the `build` command of the configuration, and
writes both APKs where `binaryPath` says.
