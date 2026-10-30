---
title: Um arquivo para todas as versões
version: 1
---

O build do planejador nomeia `2.4.21` e `1.11.0` dentro de strings, e o `1.11.0` duas vezes. Com um
projeto isso é tolerável. Com vários, a mesma versão é escrita em cada um, e uma atualização que esquece
um deixa dois módulos em duas versões de uma biblioteca. **Um catálogo de versões é um arquivo,
`gradle/libs.versions.toml`, que nomeia cada versão e cada biblioteca uma vez**, e o Gradle o lê
sozinho:

```toml
# gradle/libs.versions.toml
[versions]
kotlin = "2.4.21"
coroutines = "1.11.0"

[libraries]
kotlinx-coroutines-core = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-core", version.ref = "coroutines" }
kotlinx-coroutines-test = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-test", version.ref = "coroutines" }

[plugins]
kotlin-jvm = { id = "org.jetbrains.kotlin.jvm", version.ref = "kotlin" }
```

O Gradle transforma cada nome num acessor em `libs`, com os hifens virando pontos, e o script de build
se refere a eles em vez de a strings:

```kotlin
// build.gradle.kts
import org.gradle.api.tasks.testing.logging.TestExceptionFormat

plugins {
    alias(libs.plugins.kotlin.jvm)
    application
}

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.kotlinx.coroutines.core)
    testImplementation(kotlin("test"))
    testImplementation(libs.kotlinx.coroutines.test)
}

kotlin {
    jvmToolchain(21)
}

application {
    mainClass = providers.gradleProperty("main").orElse("HelloKt")
}

tasks.test {
    useJUnitPlatform()
    testLogging {
        events("passed", "failed")
        exceptionFormat = TestExceptionFormat.FULL
        showStackTraces = false
    }
}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=WeekModelKt
loading…
2 sessions, 75 min
3 sessions, 135 min
```

O programa imprimiu o que imprimiu na lição 17, e esse é o teste de uma mudança assim: **o build quer
dizer a mesma coisa, e as versões agora moram num lugar só**. O `kotlin("test")` fica como estava,
porque já pega a versão do plugin do Kotlin.

Um erro de digitação é pego onde é cometido. `libs.kotlinx.corutines.core` não é uma propriedade de
`libs`, então o script de build não compila, apontando a linha, antes de qualquer download. Uma string
digitada errado, do jeito antigo, falha depois e mais longe, como uma dependência que o Maven Central
não tem.

O catálogo também é o que o `android-apps` lê: um projeto Android novo vem com um
`gradle/libs.versions.toml` já escrito, exatamente nesta forma.
