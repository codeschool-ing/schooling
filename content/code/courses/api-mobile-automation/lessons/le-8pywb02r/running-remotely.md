---
title: Pointing the suites at a cloud
version: 1
---

**Moving a suite to a cloud changes where it connects and what it installs, and leaves the tests
themselves alone.** An Appium test connects to the cloud's server instead of `127.0.0.1:4723`; an
Espresso suite is two APKs uploaded instead of installed by Gradle. Everything a test checks stays as
lessons 15 and 16 wrote it.

**No device cloud was used for this course.** Each needs an account, and the recording machine had
none, so nothing below was run and no output, report or video from one is shown. The options and
commands are the ones the tools document; the details that differ from one vendor to the next are
pointed out rather than guessed.

## Appium, on a cloud's server

First the APK is uploaded, through the cloud's web page or its upload API, and the cloud answers
with an identifier for it, which the session then names instead of a path on your disk. The test
of lesson 15 changes only in its call to `remote()`:

```js
driver = await remote({
  protocol: 'https',
  hostname: process.env.CLOUD_HOST,
  port: 443,
  path: '/wd/hub',
  user: process.env.CLOUD_USER,
  key: process.env.CLOUD_KEY,
  logLevel: 'warn',
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'UiAutomator2',
    'appium:app': process.env.CLOUD_APP,
    'appium:deviceName': 'Galaxy A15',
    'appium:platformVersion': '14',
  },
});
```

- **`protocol`, `hostname`, `port` and `path`** are the cloud's server, which its documentation
  gives; `user` and `key` are your account's name and access key, read from the environment like
  every secret since lesson 3.
- **`appium:app`** is the identifier the upload returned, held in `CLOUD_APP`.
- **`appium:deviceName` and `appium:platformVersion`** pick one row of the matrix, the top model of
  section 03 on its version. Each cloud spells its models its own way, so the names come from its
  catalogue.
- Anything else a cloud offers, such as a name for the build or whether to record video, goes in an
  object of its own named with the vendor's prefix, `bstack:options` on BrowserStack and
  `sauce:options` on Sauce Labs, by the same W3C rule lesson 15 explained for `appium:`.

To run the matrix, the same test runs once per row with those two capabilities changed, several at a
time if the plan allows. And the line of the test that asked boxoffice for the seats must now ask the
copy of the server that the cloud's phone reaches, as section 05 said.

## Espresso, on Firebase Test Lab

Espresso needs no server: the cloud installs the app and the test APK and runs the instrumentation
itself, as Gradle did in lesson 16. Gradle builds both from the `tickets` folder, the test APK
landing beside the app's under `app/build/outputs/apk/androidTest/debug/`:

```sh
./gradlew assembleDebug assembleDebugAndroidTest
gcloud firebase test android models list
gcloud firebase test android run --type instrumentation \
  --app app/build/outputs/apk/debug/app-debug.apk \
  --test app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=MODEL_ID,version=34,locale=pt_BR,orientation=portrait \
  --device model=OTHER_MODEL_ID,version=33,locale=en,orientation=portrait
```

`gcloud` is Google Cloud's command-line tool, and it needs a Google Cloud project with Test Lab
switched on. `models list` prints the catalogue, with each model's id and the Android versions it
offers; `MODEL_ID` and `OTHER_MODEL_ID` stand for two of those ids. Each `--device` is one row of
the matrix: model, Android version, language and orientation, so section 04's twelve rows are twelve
such lines. The results, JUnit XML, a video and the device's log for each row, land in a Cloud
Storage bucket and in the Firebase console.

`--type robo` instead runs Test Lab's crawler, which opens the app and taps its way through the
screens with no test written at all. It is no replacement for a suite, since it checks little beyond
crashes, and it is a cheap first look at an app on many phones at once.

## Reading a result from far away

A cloud run fails for more reasons than a local one, so read it in order:

1. **Watch the video** at the failing step. A screen that never loaded, a system dialog over the app,
   a keyboard covering the button: each is visible in a second.
2. **Run the same row again.** A failure that does not repeat is the network or the cloud; one that
   does is the app on that phone.
3. **Compare the row with its neighbours.** If the same test passes on the other models of that
   version and fails on one maker's, it belongs in lesson 19's table as a device-only defect, and
   the report says which build it came from.
