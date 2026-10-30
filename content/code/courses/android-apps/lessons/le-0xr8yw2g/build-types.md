---
title: Build types: one project, a debug app and a release app
version: 1
---

**Every Android build is a variant: a build type crossed with a product flavour.** Lesson 1 built
only `debug`, the build type made for development: debuggable, signed with a key everybody has, and
optimised for compiling fast. A release needs the opposite on each count, and the Android Gradle
plugin has had a second build type, `release`, waiting in every project since lesson 1. This
lesson configures it, adds two flavours, signs the result with a key of your own, shrinks it, and
packages it the way Google Play wants it.

Start from lesson 1's project. This is the build file the whole lesson uses; the sections after
this one explain the parts it points at:

```schooling-example
{"language": "kotlin", "file": "app/build.gradle.kts", "parts": [{"code": "// app/build.gradle.kts\nplugins {\n    alias(libs.plugins.android.application)\n    alias(libs.plugins.kotlin.compose)\n    alias(libs.plugins.roborazzi)\n}\n\nandroid {\n    namespace = \"com.example.planner\"\n    compileSdk = 37\n\n    defaultConfig {\n        applicationId = \"com.example.planner\"\n        minSdk = 26\n        targetSdk = 36\n        versionCode = 1\n        versionName = \"0.1.0\"\n    }\n", "note": "Lesson 1's file down to `defaultConfig`, unchanged. `versionCode` is the number Google Play compares, and it must grow with every upload; `versionName` is what people read."}, {"code": "    signingConfigs {\n        create(\"upload\") {\n            storeFile = file(System.getProperty(\"user.home\") + \"/keys/planner-upload.jks\")\n            storePassword = providers.environmentVariable(\"PLANNER_UPLOAD_PASSWORD\").orNull\n            keyAlias = \"upload\"\n            keyPassword = providers.environmentVariable(\"PLANNER_UPLOAD_PASSWORD\").orNull\n        }\n    }\n", "note": "**The upload key, section 04.** The path is outside the project, so the key never sits in a folder that goes into version control, and the password comes from the environment, so it is in no file at all."}, {"code": "    buildTypes {\n        debug {\n            applicationIdSuffix = \".debug\"\n            versionNameSuffix = \"-debug\"\n        }\n        release {\n            isMinifyEnabled = true\n            isShrinkResources = true\n            proguardFiles(getDefaultProguardFile(\"proguard-android-optimize.txt\"), \"proguard-rules.pro\")\n            signingConfig = signingConfigs.getByName(\"upload\")\n        }\n    }\n", "note": "**The two build types.** `debug` gets a suffix so that it installs beside the release. `release` turns on R8 and resource shrinking, section 05, and is signed with the upload key."}, {"code": "    flavorDimensions += \"distribution\"\n    productFlavors {\n        create(\"play\") {\n            dimension = \"distribution\"\n            buildConfigField(\"String\", \"UPDATES_FROM\", \"\\\"Google Play\\\"\")\n        }\n        create(\"direct\") {\n            dimension = \"distribution\"\n            applicationIdSuffix = \".direct\"\n            buildConfigField(\"String\", \"UPDATES_FROM\", \"\\\"the planner's website\\\"\")\n        }\n    }\n", "note": "**One dimension, two flavours**, section 03. `direct` is the planner handed out as a file from its own website; it gets its own application id and its own value of `UPDATES_FROM`."}, {"code": "    buildFeatures {\n        compose = true\n        buildConfig = true\n    }\n\n    testOptions {\n        unitTests.isIncludeAndroidResources = true\n    }\n}\n", "note": "`buildConfig = true` asks the plugin to generate the `BuildConfig` class that carries the fields above; since AGP 8 it is off by default."}, {"code": "dependencies {\n    implementation(libs.core.ktx)\n    implementation(libs.activity.compose)\n    implementation(platform(libs.compose.bom))\n    implementation(libs.compose.ui)\n    implementation(libs.compose.material3)\n    implementation(libs.compose.ui.tooling.preview)\n    debugImplementation(libs.compose.ui.tooling)\n    debugImplementation(libs.compose.ui.test.manifest)\n\n    testImplementation(libs.junit)\n    testImplementation(libs.robolectric)\n    testImplementation(libs.androidx.test.core)\n    testImplementation(platform(libs.compose.bom))\n    testImplementation(libs.compose.ui.test.junit4)\n    testImplementation(libs.roborazzi)\n    testImplementation(libs.roborazzi.compose)\n}", "note": "The dependencies are lesson 1's."}]}
```

And the rules file the release build type names. The planner needs no rule of its own yet; section 05
says when a project does:

```properties
# app/proguard-rules.pro
# The planner keeps no class by reflection yet, so R8 needs no rule of ours.
```

## Two builds that can live on one phone

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E '^BUILD'
BUILD SUCCESSFUL in 15s
ana@vm:~/planner$ find app/build/outputs/apk -name "*.apk" | sort
app/build/outputs/apk/direct/debug/app-direct-debug.apk
app/build/outputs/apk/play/debug/app-play-debug.apk
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/aapt2 dump badging app/build/outputs/apk/play/debug/app-play-debug.apk | grep -o "name='[^']*' versionCode='[^']*' versionName='[^']*'"
name='com.example.planner.debug' versionCode='1' versionName='0.1.0-debug'
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/aapt2 dump badging app/build/outputs/apk/direct/debug/app-direct-debug.apk | grep -o "name='[^']*' versionCode='[^']*' versionName='[^']*'"
name='com.example.planner.direct.debug' versionCode='1' versionName='0.1.0-debug'
```

`assembleDebug` built the debug build type of **both flavours**, and each is a separate app as far as
a phone is concerned: `com.example.planner.debug` and `com.example.planner.direct.debug`. **That is
what `applicationIdSuffix` is for.** A developer's phone can then hold the debug build next to the
version from the store, each with its own data, instead of one replacing the other on every install.
`versionNameSuffix` puts `-debug` in the version, so a screenshot of the settings page says which build
it came from.

## What a build type changes

| | `debug` | `release` |
|---|---|---|
| a debugger can attach | yes | no |
| signed with | the shared debug key of lesson 1 section 08 | your upload key, section 04 |
| R8 shrinks and obfuscates | no | yes, section 05 |
| unused resources removed | no | yes, `isShrinkResources` |
| how long it took here | 15 s, two APKs | 1 min 16 s, two APKs and a bundle, section 04 |

A build type should change **how** the app is built and never **what** it does. A feature that
only works in `debug` is a feature nobody tested in the build that ships.
