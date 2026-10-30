---
title: The planner's first eight files
version: 1
---

**The app this course builds is a study planner**, the same one the `frontend` track builds for the
browser and the other two options of this track build for iOS and React Native. A student lists
courses, opens one, adds study sessions with a date and a duration, marks them done, and sees the
week's total. By lesson 22 it keeps its data in a database, talks to a server, works offline, sends a
reminder and goes out as a signed bundle. Today it is eight files and one line of text on a screen.

Android Studio writes these files for you from a template, and the template changes with every
release. **Writing them by hand once is the fastest way to know what each one is for**, and it is
what every later lesson starts from: lessons 2 to 22 each begin with a copy of the project exactly as
this section leaves it, and add the files that lesson shows. Make a directory for it:

```
ana@vm:~$ mkdir -p ~/planner && cd ~/planner
```

## The settings: what the build contains, and where it downloads from

```kotlin
// settings.gradle.kts
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "planner"
include(":app")
```

Gradle reads this file first. It names the **repositories**, the servers libraries come from:
`google()` is Google's Maven repository, where every `androidx` library and the Android Gradle
plugin live, and `mavenCentral()` is where most of the rest of the Java world publishes.
`include(":app")` says the build has one module, in the directory `app`. A larger app splits into
several, `:core:data` and `:feature:sessions` and so on, and each is a line here. One is enough for
this course, and lesson 22 says when that stops being true.

`FAIL_ON_PROJECT_REPOS` makes a module that declares its own repository an error. It keeps the
list of servers your build trusts in this one file, where somebody reviewing a change will see it.

## The catalogue: every version this course uses, in one place

```toml
# gradle/libs.versions.toml
[versions]
agp = "9.5.0"
kotlin = "2.4.21"
ksp = "2.3.12"
coroutines = "1.11.0"
serialization = "1.12.0"
core = "1.19.1"
activity = "1.13.0"
composeBom = "2026.09.00"
lifecycle = "2.11.0"
navigation = "2.10.2"
hilt = "2.60.1"
androidxHilt = "1.4.0"
room = "2.8.5"
work = "2.12.0"
retrofit = "3.0.0"
okhttp = "5.5.1"
moshi = "1.15.2"
coil = "3.6.3"
junit = "4.13.2"
robolectric = "4.17"
roborazzi = "1.77.0"
androidxTest = "1.7.0"

[libraries]
core-ktx = { module = "androidx.core:core-ktx", version.ref = "core" }
activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activity" }
compose-bom = { module = "androidx.compose:compose-bom", version.ref = "composeBom" }
compose-ui = { module = "androidx.compose.ui:ui" }
compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
compose-ui-test-junit4 = { module = "androidx.compose.ui:ui-test-junit4" }
compose-ui-test-manifest = { module = "androidx.compose.ui:ui-test-manifest" }
compose-material3 = { module = "androidx.compose.material3:material3" }
lifecycle-runtime-compose = { module = "androidx.lifecycle:lifecycle-runtime-compose", version.ref = "lifecycle" }
lifecycle-viewmodel-compose = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "lifecycle" }
navigation-compose = { module = "androidx.navigation:navigation-compose", version.ref = "navigation" }
navigation-testing = { module = "androidx.navigation:navigation-testing", version.ref = "navigation" }
hilt-android = { module = "com.google.dagger:hilt-android", version.ref = "hilt" }
hilt-compiler = { module = "com.google.dagger:hilt-compiler", version.ref = "hilt" }
hilt-android-testing = { module = "com.google.dagger:hilt-android-testing", version.ref = "hilt" }
hilt-lifecycle-viewmodel-compose = { module = "androidx.hilt:hilt-lifecycle-viewmodel-compose", version.ref = "androidxHilt" }
hilt-work = { module = "androidx.hilt:hilt-work", version.ref = "androidxHilt" }
hilt-work-compiler = { module = "androidx.hilt:hilt-compiler", version.ref = "androidxHilt" }
room-runtime = { module = "androidx.room:room-runtime", version.ref = "room" }
room-ktx = { module = "androidx.room:room-ktx", version.ref = "room" }
room-compiler = { module = "androidx.room:room-compiler", version.ref = "room" }
room-testing = { module = "androidx.room:room-testing", version.ref = "room" }
work-runtime-ktx = { module = "androidx.work:work-runtime-ktx", version.ref = "work" }
work-testing = { module = "androidx.work:work-testing", version.ref = "work" }
coroutines-android = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }
coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }
serialization-json = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "serialization" }
retrofit = { module = "com.squareup.retrofit2:retrofit", version.ref = "retrofit" }
retrofit-kotlinx-serialization = { module = "com.squareup.retrofit2:converter-kotlinx-serialization", version.ref = "retrofit" }
retrofit-moshi = { module = "com.squareup.retrofit2:converter-moshi", version.ref = "retrofit" }
okhttp = { module = "com.squareup.okhttp3:okhttp", version.ref = "okhttp" }
okhttp-logging = { module = "com.squareup.okhttp3:logging-interceptor", version.ref = "okhttp" }
okhttp-mockwebserver = { module = "com.squareup.okhttp3:mockwebserver3-junit4", version.ref = "okhttp" }
moshi = { module = "com.squareup.moshi:moshi", version.ref = "moshi" }
moshi-codegen = { module = "com.squareup.moshi:moshi-kotlin-codegen", version.ref = "moshi" }
coil-compose = { module = "io.coil-kt.coil3:coil-compose", version.ref = "coil" }
coil-network = { module = "io.coil-kt.coil3:coil-network-okhttp", version.ref = "coil" }
coil-test = { module = "io.coil-kt.coil3:coil-test", version.ref = "coil" }
junit = { module = "junit:junit", version.ref = "junit" }
robolectric = { module = "org.robolectric:robolectric", version.ref = "robolectric" }
androidx-test-core = { module = "androidx.test:core-ktx", version.ref = "androidxTest" }
roborazzi = { module = "io.github.takahirom.roborazzi:roborazzi", version.ref = "roborazzi" }
roborazzi-compose = { module = "io.github.takahirom.roborazzi:roborazzi-compose", version.ref = "roborazzi" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
room = { id = "androidx.room", version.ref = "room" }
roborazzi = { id = "io.github.takahirom.roborazzi", version.ref = "roborazzi" }
```

**This is a version catalogue**, and Gradle reads it on its own because of where it sits. Each library
gets a short name, `room-runtime`, which build files then write as `libs.room.runtime`. Every version
the course uses is listed here, from lesson 1 to lesson 22, so you write this file once. **Listing a
library downloads nothing**: Gradle fetches a library only when a module's build file asks for it.

The `[versions]` table is the part to look at when something breaks. Twenty-two libraries, each
pinned to one exact number, all released before 30 October 2026, when this course was recorded. Three
deserve a sentence now:

- `agp` is the **Android Gradle plugin**, the part of the build that knows what an Android app is.
  Its version decides which Gradle it accepts and which `compileSdk` it understands.
- `composeBom` is a **bill of materials**: one number that fixes the versions of a dozen Compose
  libraries together. That is why the Compose lines under `[libraries]` have no version of their
  own.
- `kotlin` matches the compiler the `kotlin` course installed, 2.4.21. Two plugins carry it: the
  Compose compiler and the serialization plugin of lesson 14.

## The root build file, and the properties beside it

```kotlin
// build.gradle.kts
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.hilt) apply false
    alias(libs.plugins.room) apply false
    alias(libs.plugins.roborazzi) apply false
}
```

```properties
# gradle.properties
org.gradle.jvmargs=-Xmx2g -Dfile.encoding=UTF-8
android.useAndroidX=true
```

The root build file declares every plugin the project may use, with `apply false`: loaded once, at the
version in the catalogue, and applied by no one here. A module then applies the ones it needs by
name. `gradle.properties` gives the Gradle process two gigabytes of memory and says the project uses
the `androidx` libraries rather than the support library they replaced in 2018.

## The module: what the app is

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.roborazzi)
}

android {
    namespace = "com.example.planner"
    compileSdk = 37

    defaultConfig {
        applicationId = "com.example.planner"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
    }

    buildFeatures {
        compose = true
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.compose.ui.tooling.preview)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

Three numbers in `defaultConfig` are easy to confuse, and section 06 gives each its own paragraph.
In one line each: **`compileSdk`** is the Android version whose API the compiler checks your code
against, **`minSdk`** is the oldest Android that may install the app, and **`targetSdk`** is the
version whose behaviour the app has been tested with and opts into. `applicationId` is the app's
identity on a phone and in the Play Store, and it can never change once the app is published.

The second half of the dependencies is for tests. They run on your computer's JVM, not on a phone:
**Robolectric** stands in for the Android framework, and **Roborazzi** saves what a composable drew
as a PNG. That is how this course shows you a screen without an emulator, and section 02 of this
lesson says why there is no emulator in it.

```properties
# app/src/test/resources/robolectric.properties
sdk=35
```

This file tells Robolectric which Android version to pretend to be. It is 35 and not 36 because
Robolectric 4.17 could not start Android 36 on the JDK this course uses: every test failed at start-up
with `Failed to interact with raw FileDescriptor internals`. The app still targets 36; only the
stand-in used in tests is a version older.

## The manifest, one string, and one screen

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
</resources>
```

```kotlin
// app/src/main/java/com/example/planner/MainActivity.kt
package com.example.planner

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.ui.res.stringResource

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface {
                    Text(stringResource(R.string.welcome))
                }
            }
        }
    }
}
```

Section 07 reads the manifest and the strings properly. The activity is lesson 2's subject and
`setContent` is where Compose begins, which is lesson 3's. For now it is enough that the app has one
screen and that the screen says one sentence.

## The wrapper: the Gradle the project brings with it

You have Gradle 9.8.2 on your `PATH` from the `kotlin` course. A project should not depend on that:
somebody else cloning it may have another version, or none. So you run Gradle once to write a
**wrapper**, a small script and a jar that download the exact Gradle the project names and run it.
From then on, inside the project, you type `./gradlew` and never `gradle`:

```
ana@vm:~/planner$ gradle wrapper --gradle-version 9.8.2 -q
ana@vm:~/planner$ find . -type f -not -path "./.gradle/*" | sort
./app/build.gradle.kts
./app/src/main/AndroidManifest.xml
./app/src/main/java/com/example/planner/MainActivity.kt
./app/src/main/res/values/strings.xml
./app/src/test/resources/robolectric.properties
./build.gradle.kts
./gradle.properties
./gradle/libs.versions.toml
./gradle/wrapper/gradle-wrapper.jar
./gradle/wrapper/gradle-wrapper.properties
./gradlew
./gradlew.bat
./settings.gradle.kts
ana@vm:~/planner$ cat gradle/wrapper/gradle-wrapper.properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-9.8.2-bin.zip
networkTimeout=10000
retries=0
retryBackOffMs=500
validateDistributionUrl=true
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
```

The `find` leaves out `.gradle/`, a directory of Gradle's own bookkeeping that it creates in every
project it touches and that never goes into version control. `gradlew` and `gradlew.bat` are the scripts for Linux and macOS and for Windows. **All four wrapper
files go into version control**; a teammate who clones the project types `./gradlew build` and gets
the same Gradle you have, checked against the `distributionSha256Sum` if you add one.
