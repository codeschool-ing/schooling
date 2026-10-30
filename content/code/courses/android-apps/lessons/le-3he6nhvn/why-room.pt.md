---
title: Um banco de dados no celular, e o que o Room acrescenta
version: 1
---

**Todo celular Android traz o SQLite, e o Room é uma camada sobre ele que confere o seu SQL enquanto
o app compila.** O SQLite é um banco relacional inteiro num arquivo, o motor que o `mobile-offline`,
o curso depois deste, compara com as alternativas na aula 3. O Android o oferece desde a primeira
versão, por uma API em que uma consulta é uma string e um erro nela é descoberto quando aquela linha
roda, num celular, na frente de um usuário. O Room mantém o SQLite e leva os erros para o build.

O Room é três tipos de coisa, cada um uma anotação:

| | o que é | no planner |
|---|---|---|
| **uma entidade** | uma classe que é uma tabela, uma linha por objeto | `CourseEntity`, `SessionEntity` |
| **um DAO** | uma interface de consultas, com o SQL escrito em cada método | `SessionDao` |
| **o banco** | uma classe abstrata que lista as entidades e entrega os DAOs | `PlannerDatabase` |

**O KSP lê os três e escreve o código que roda o SQL.** A seção 05 mostra um nome de tabela escrito
errado derrubando o build, que é o motivo inteiro de usar o Room em vez da API do próprio SQLite.

## O arquivo de build

O Room chega como um plugin do Gradle, um runtime e um compilador que roda no KSP. A única
configuração do plugin, `schemaDirectory`, é onde o Room escreve uma descrição em JSON de cada versão
do banco; a seção 07 precisa desses arquivos, e a linha `sourceSets` os entrega aos testes. Ela nomeia
o source set `debug`, e não `test`, porque o Robolectric lê os assets do build de debug; os schemas
viajam então dentro dos APKs de debug, e nunca dentro de um de release. Os testes rodam no
Robolectric porque um banco Room precisa de um `Context` do Android:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.ksp)
    alias(libs.plugins.room)
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

    sourceSets {
        getByName("debug").assets.srcDir("$projectDir/schemas")
    }

    testOptions {
        unitTests.isIncludeAndroidResources = true
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

room {
    schemaDirectory("$projectDir/schemas")
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(libs.coroutines.test)
    testImplementation(libs.room.testing)
}
```

O modelo é o mesmo de todas as aulas, e o banco vai guardá-lo:

```kotlin
// app/src/main/java/com/example/planner/data/Model.kt
package com.example.planner.data

import java.time.LocalDate

data class Course(val id: String, val name: String)

data class StudySession(
    val id: Long,
    val courseId: String,
    val date: LocalDate,
    val minutes: Int,
    val done: Boolean = false,
)
```

## Onde o arquivo mora

Num celular o banco é um arquivo no armazenamento privado do app, em
`/data/data/com.example.planner/databases/`, legível pelo app e por mais ninguém. **Não executado:**
não há celular aqui para olhá-lo; o App Inspection do Android Studio mostra as tabelas de um app
rodando, e `adb shell run-as com.example.planner` abre esse diretório num build de debug, segundo a
documentação do Google. Os testes desta aula usam um banco que o Room guarda na memória, que some
quando o teste termina, e a seção 07 um num arquivo que o Robolectric põe num diretório temporário.
