---
title: Kotlin tested on the JVM
version: 1
---

**The Kotlin rule can run without a phone**, because it is plain Kotlin and Java's calendar exists on any
JVM. Android projects keep such tests in `src/test/`, and Gradle runs them on the computer, with JUnit. The
module's `build.gradle` needs JUnit added for its tests. Replace
`modules/week-start/android/build.gradle`:

```java
// modules/week-start/android/build.gradle: the template's, with JUnit added for the tests that run on
// the computer's JVM.
plugins {
  id 'com.android.library'
  id 'expo-module-gradle-plugin'
}

group = 'org.example.weekstart'
version = '0.1.0'

android {
  namespace "org.example.weekstart"
  defaultConfig {
    versionCode 1
    versionName "0.1.0"
  }
  lintOptions {
    abortOnError false
  }
}

dependencies {
  testImplementation 'junit:junit:4.13.2'
}
```

Then three cases, written as the author believed them. Save
`modules/week-start/android/src/test/java/org/example/weekstart/FirstWeekdayTest.kt`:

```kotlin
// modules/week-start/android/src/test/java/org/example/weekstart/FirstWeekdayTest.kt
// The rule, run on the computer's JVM, without a phone.
package org.example.weekstart

import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test

class FirstWeekdayTest {
  @Test fun brazilStartsOnSunday() = assertEquals(0, firstWeekday(Locale.forLanguageTag("pt-BR")))

  @Test fun theUnitedKingdomStartsOnMonday() = assertEquals(1, firstWeekday(Locale.forLanguageTag("en-GB")))

  @Test fun portugalStartsOnMonday() = assertEquals(1, firstWeekday(Locale.forLanguageTag("pt-PT")))
}
```

Gradle can only build the module inside an Android project, so generate one with prebuild, and run the
module's tests from `android/`. `:week-start` is the name autolinking gave the module's Gradle project:

```
ana@dev:~/planner$ npx expo prebuild --platform android --clean --no-install > /dev/null 2>&1
ana@dev:~/planner/android$ ./gradlew :week-start:testDebugUnitTest --console=plain 2>&1 | grep -E "FAILED|AssertionError|tests completed"
> Task :week-start:testDebugUnitTest FAILED
FirstWeekdayTest > portugalStartsOnMonday FAILED
    java.lang.AssertionError at FirstWeekdayTest.kt:14
3 tests completed, 1 failed
BUILD FAILED in 59s
```

**Brazil and the United Kingdom passed, and Portugal did not.** The author expected Monday; the JVM says
Sunday. Neither the Kotlin nor the test is broken: the calendar data, the **CLDR** that Java, Android, iOS
and the browsers take their week rules from, says Portugal's week starts on Sunday. The browser in the
last section says so too.

**That is the point of a test against the platform's own data**: the module's job is to return what the
phone's calendar says, and the author's belief about it is exactly what should not be in the code. The test
is corrected to what the data says, with a comment so that the next reader does not "fix" it back:

```kotlin
// modules/week-start/android/src/test/java/org/example/weekstart/FirstWeekdayTest.kt
// The rule, run on the computer's JVM, without a phone.
package org.example.weekstart

import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test

class FirstWeekdayTest {
  @Test fun brazilStartsOnSunday() = assertEquals(0, firstWeekday(Locale.forLanguageTag("pt-BR")))

  @Test fun theUnitedKingdomStartsOnMonday() = assertEquals(1, firstWeekday(Locale.forLanguageTag("en-GB")))

  // not what the author expected: the calendar data says Sunday, and Chromium agrees
  @Test fun portugalStartsOnSundayToo() = assertEquals(0, firstWeekday(Locale.forLanguageTag("pt-PT")))
}
```

```
ana@dev:~/planner/android$ ./gradlew :week-start:testDebugUnitTest --console=plain 2>&1 | grep -E "FAILED|BUILD"
BUILD SUCCESSFUL in 27s
```
