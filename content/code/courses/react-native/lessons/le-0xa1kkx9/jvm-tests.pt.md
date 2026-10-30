---
title: Kotlin testado na JVM
version: 1
---

**A regra em Kotlin roda sem um celular**, porque é Kotlin puro e o calendário do Java existe em qualquer
JVM. Projetos Android guardam esses testes em `src/test/`, e o Gradle os roda no computador, com o JUnit. O
`build.gradle` do módulo precisa do JUnit acrescentado para os testes dele. Troque o
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

Depois três casos, escritos como o autor acreditava que eram. Salve o
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

O Gradle só consegue construir o módulo dentro de um projeto Android, então gere um com o prebuild, e rode
os testes do módulo a partir do `android/`. `:week-start` é o nome que o autolinking deu ao projeto Gradle do
módulo:

```
ana@dev:~/planner$ npx expo prebuild --platform android --clean --no-install > /dev/null 2>&1
ana@dev:~/planner/android$ ./gradlew :week-start:testDebugUnitTest --console=plain 2>&1 | grep -E "FAILED|AssertionError|tests completed"
> Task :week-start:testDebugUnitTest FAILED
FirstWeekdayTest > portugalStartsOnMonday FAILED
    java.lang.AssertionError at FirstWeekdayTest.kt:14
3 tests completed, 1 failed
BUILD FAILED in 59s
```

**O Brasil e o Reino Unido passaram, e Portugal não.** O autor esperava segunda; a JVM diz domingo. Nem o
Kotlin nem o teste estão quebrados: os dados de calendário, o **CLDR** de onde o Java, o Android, o iOS e os
navegadores tiram as regras da semana, dizem que a semana de Portugal começa no domingo. O navegador da
última seção diz o mesmo.

**Esse é o sentido de um teste contra os dados da própria plataforma**: o trabalho do módulo é devolver o
que o calendário do celular diz, e a crença do autor sobre isso é exatamente o que não deve estar no código.
O teste é corrigido para o que os dados dizem, com um comentário para o próximo leitor não "consertá-lo" de
volta:

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
