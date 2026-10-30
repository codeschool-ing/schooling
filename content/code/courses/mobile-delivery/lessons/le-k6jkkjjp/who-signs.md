---
title: Who does the signing: Xcode, a tool, or a service
version: 1
---

**Most teams should not manage certificates and profiles by hand, and the question is only which
machine does it for them.** Three answers are common, one per kind of team. *None of them was run
for this course: they need a Mac, an Apple account or both.*

## Xcode's automatic signing

Tick **Automatically manage signing** in the target's *Signing & Capabilities* tab, choose the
team, and Xcode creates the certificate, registers the App ID and the device, and downloads a
profile. For one developer on one Mac, this is the right answer and needs nothing else.

It stops being the right answer the day there are two Macs or a pipeline. Each Mac makes its own
development certificate, the distribution certificate's private key lives in whichever keychain
created it, and a build server has no person to click *Fix Issue*.

## One shared set, kept somewhere else

**fastlane match** keeps the team's certificates and profiles encrypted in a private git
repository or a cloud bucket, and every machine, including the pipeline, fetches the same set
instead of making its own. One person creates them once; the others only read. Lesson 11 runs
Fastlane, and lesson 10 is where a pipeline needs this.

```
# Matchfile: one encrypted set of certificates and profiles for the whole team
git_url("https://git.example.com/planner-certificates.git")
type("appstore")
app_identifier("com.example.planner")
```

## A service that owns the credentials

**Expo's EAS** generates the distribution certificate and profiles itself, keeps them on its
servers, and signs in its own hosted Macs. For a React Native team without a Mac, it is the
workaround lesson 10 names. **Xcode Cloud**, Apple's own service, does the same for an Xcode
project. The price of both is the same: the credentials live with somebody else, and you trust
their access controls with your ability to ship.

```json
{
  "build": {
    "production": {
      "ios": { "credentialsSource": "remote" }
    }
  }
}
```

That is the part of `eas.json` that says "EAS holds the credentials"; `local` would mean you
supply them from a file instead.

## Android, for comparison

Android has the same split with less ceremony. Android Studio's *Generate Signed Bundle* wizard is
the "one developer" answer; the Gradle `signingConfigs` block reading a keystore path and its
passwords from the environment is the "pipeline" answer; and Play App Signing, from lesson 1, is
already a service holding the key that matters.

```kotlin
// build.gradle.kts: the release build reads its upload key from the environment
android {
    signingConfigs {
        create("release") {
            storeFile = file(System.getenv("UPLOAD_KEYSTORE") ?: "upload.jks")
            storePassword = System.getenv("UPLOAD_PASS")
            keyAlias = "upload"
            keyPassword = System.getenv("UPLOAD_PASS")
        }
    }
    buildTypes { getByName("release") { signingConfig = signingConfigs.getByName("release") } }
}
```
