---
title: EAS Build, and iOS without a Mac
version: 1
---

**EAS Build is Expo's build service**: the project is uploaded, built on Expo's machines, Linux for Android
and macOS for iOS, and the result is a signed app you can download, install or send to the stores with
`eas submit`. It is the answer to "I have no Mac" for iOS, and to "the release depends on one person's
laptop" for both.

It is driven by `eas.json`, at the top of the project, which names **build profiles**. Save `eas.json`:

```json
{
  "cli": { "version": ">= 27.0.0", "appVersionSource": "remote" },
  "build": {
    "development": { "developmentClient": true, "distribution": "internal" },
    "preview": {
      "distribution": "internal",
      "android": { "buildType": "apk" },
      "env": { "EXPO_PUBLIC_API_URL": "https://staging.planner.example.org" }
    },
    "production": {
      "autoIncrement": true,
      "env": { "EXPO_PUBLIC_API_URL": "https://planner.example.org" }
    }
  },
  "submit": { "production": {} }
}
```

- **`development`** is a development build, lesson 3's, with `expo-dev-client`, for the team's phones.
  `internal` distribution gives a link to install from instead of a store.
- **`preview`** is a release build for testers: an APK on Android, which installs directly, against a
  staging server.
- **`production`** is what goes to the stores: an AAB on Android, and an iOS build signed for the App Store.
- **`env` sets the variables for each build**, so `EXPO_PUBLIC_API_URL` has its value where the release is
  built, which is the habit lesson 18 asked for.
- **`appVersionSource: "remote"` and `autoIncrement`** let EAS keep Android's `versionCode` and iOS's
  `buildNumber`, the numbers every upload must raise, so nobody has to remember the last one.

```
ana@dev:~/planner$ node -e "const e = require(\"./eas.json\"); console.log(Object.keys(e.build))"
[ 'development', 'preview', 'production' ]
```

That check is all this course ran: three profiles in a file that parses. *The rest was not run, because
Expo's servers refused the machine that recorded this course.* What follows is the workflow from Expo's
documentation:

- **`npx eas-cli@27.2.0 login`** and **`npx eas-cli@27.2.0 init`** connect the project to an Expo account and
  write its `projectId` into `app.json`, the id lesson 16's push token asked for.
- **`eas build --platform android --profile production`** uploads the project and builds it. The first time,
  EAS offers to generate an upload key and keep it; or `eas credentials` uploads the one you made.
- **`eas build --platform ios --profile production`** asks for your Apple Developer account, creates the
  distribution certificate and the provisioning profile there, and keeps them. No Mac is involved at any
  point, on your side.
- **`eas submit`** sends the result to Google Play or to App Store Connect, from where TestFlight hands it to
  testers.

**Keeping credentials on Expo's servers is a decision, not a default you must accept**: it means a second
place your signing key lives. The alternative, `credentialsSource: "local"`, keeps them in a file you
manage, as this lesson's keystore is.
