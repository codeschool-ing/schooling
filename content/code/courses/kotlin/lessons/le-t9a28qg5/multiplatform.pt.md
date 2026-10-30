---
title: Uma função, dois back ends
version: 1
---

Um projeto Kotlin Multiplatform compila um conjunto de fontes para vários alvos. **O código em
`src/commonMain` é compilado para todo alvo e só pode usar o que todo alvo tem**; o código no diretório
próprio de um alvo, `src/jvmMain` ou `src/jsMain`, é compilado só para aquele alvo e pode usar tudo o que
ele oferece. Um build novo, `~/kt/shared`, com o wrapper copiado como antes:

```kotlin
// settings.gradle.kts
rootProject.name = "shared"

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }
}
```

```kotlin
// build.gradle.kts
plugins {
    kotlin("multiplatform") version "2.4.21"
}

kotlin {
    jvmToolchain(21)
    jvm {
        mainRun { mainClass = "MainKt" }
    }
    js {
        nodejs()
        binaries.executable()
    }
}
```

O plugin `multiplatform` substitui o `jvm`, e cada alvo é declarado dentro de `kotlin { }`: a JVM, com a
classe a rodar, e JavaScript para Node.js, construído como programa e não como biblioteca.

```kotlin
// src/commonMain/kotlin/Week.kt
data class Session(val course: String, val minutes: Int)

fun summary(sessions: List<Session>): String =
    "${sessions.size} sessions, ${sessions.sumOf { it.minutes }} min, on ${platform()}"

expect fun platform(): String
```

```kotlin
// src/commonMain/kotlin/Main.kt
fun main() {
    println(summary(listOf(Session("kotlin", 45), Session("android-apps", 30))))
}
```

**O `expect fun platform()` é a promessa de que todo alvo vai fornecer esta função.** O código comum a
chama sem saber como ela é escrita; cada alvo cumpre a promessa com uma declaração `actual` no próprio
diretório, e o build falha para qualquer alvo que não cumprir.

```kotlin
// src/jvmMain/kotlin/Platform.jvm.kt
actual fun platform(): String = "the JVM " + System.getProperty("java.version")
```

```kotlin
// src/jsMain/kotlin/Platform.js.kt
actual fun platform(): String = "JavaScript"
```

O `System.getProperty` é da JVM, então só pode morar no `jvmMain`; escrito no `commonMain`, não
compilaria. Rode o programa em cada back end:

```
ana@vm:~/kt/shared$ ./gradlew -q jvmRun
2 sessions, 75 min, on the JVM 21.0.12.1
```

```
ana@vm:~/kt/shared$ ./gradlew -q jsNodeDevelopmentRun
2 sessions, 75 min, on JavaScript
```

O primeiro `jsNodeDevelopmentRun` demora: o Gradle baixa o Node.js e os pacotes JavaScript que o build
Kotlin/JS usa para dentro de `~/.gradle`, uma vez. **O `summary` e o `Session` foram compilados duas
vezes, para bytecode e para JavaScript**, a partir de um arquivo, e deram a mesma resposta em dois
runtimes.

## Um alvo nativo

Um terceiro alvo transforma o mesmo código num executável Linux sem JVM nenhuma. São duas linhas no
`build.gradle.kts`, dentro de `kotlin { }`, e mais um `actual`:

```kotlin
    linuxX64 {
        binaries.executable()
    }
```

```kotlin
// src/linuxX64Main/kotlin/Platform.linuxX64.kt
actual fun platform(): String = "Linux, natively"
```

O `./gradlew runDebugExecutableLinuxX64` o constrói e roda, e num Mac o alvo é `macosArm64`. Este é o
único programa do curso sem transcrição. O compilador do Kotlin/Native vem do Maven Central, mas o
toolchain de C com que ele liga o programa é baixado de `download.jetbrains.com`, que a máquina em que
estas aulas foram gravadas não alcançava, como a aula 1 disse. Na sua máquina é mais um download na
primeira execução.

Esse é o mecanismo por trás do Compose Multiplatform e do código dividido entre Android e iOS: as regras
no `commonMain`, escritas uma vez, e a tela e o armazenamento de cada plataforma ao lado.
