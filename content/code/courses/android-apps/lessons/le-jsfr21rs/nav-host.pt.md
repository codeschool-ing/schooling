---
title: Um NavHost, três rotas e um controlador
version: 1
---

**Um app com uma activity só continua tendo muitas telas**, e alguma coisa precisa saber qual está
aparecendo, qual veio antes e o que o botão voltar deve fazer. No Compose essa coisa é um
`NavHostController`, e as telas entre as quais ele se move são declaradas num `NavHost`. A aula 2
defendeu uma activity por app; esta aula é o que a preenche.

O planner tem três telas por enquanto: a lista de cursos, um curso e um formulário para acrescentar
uma sessão àquele curso. Cada uma é uma **rota**, e desde a versão 2.8 do Navigation Compose uma
rota pode ser um tipo Kotlin em vez de uma string:

```kotlin
// app/src/main/java/com/example/planner/Routes.kt
package com.example.planner

import kotlinx.serialization.Serializable

@Serializable
object Courses

@Serializable
data class CourseDetail(val courseId: String)

@Serializable
data class AddSession(val courseId: String)
```

`Courses` não recebe nada, então é um `object`. `CourseDetail` e `AddSession` precisam saber qual
curso, então são data classes com um `courseId`. **`@Serializable` é o que deixa o Navigation
transformar uma rota na string que ele guarda e de volta**, e essa anotação precisa do plugin de
serialização do Kotlin, que é a primeira mudança no arquivo de build do módulo desde a aula 1:

```kotlin
// app/build.gradle.kts
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
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
    implementation(libs.navigation.compose)
    implementation(libs.serialization.json)
    debugImplementation(libs.compose.ui.tooling)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.navigation.testing)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

Três linhas diferem das da aula 1: o plugin `kotlin.serialization` e as bibliotecas
`navigation-compose` e `serialization-json`; uma quarta, `navigation-testing`, é para os testes da
seção 04. As quatro já estavam no catálogo da aula 1, então só este arquivo muda.

As telas em si não sabem nada de navegação. Cada uma recebe os dados que mostra e uma função para
cada coisa que o usuário pode fazer:

```kotlin
// app/src/main/java/com/example/planner/Screens.kt
package com.example.planner

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

val courseNames = mapOf("kotlin" to "Kotlin", "android" to "Android Apps", "sql" to "SQL Databases")

@Composable
fun CoursesScreen(onOpen: (String) -> Unit) {
    Column(Modifier.padding(16.dp)) {
        Text("Courses", style = MaterialTheme.typography.headlineSmall)
        courseNames.forEach { (id, name) ->
            Text(name, Modifier.fillMaxWidth().clickable { onOpen(id) }.padding(vertical = 12.dp))
        }
    }
}

@Composable
fun CourseDetailScreen(courseId: String, onAdd: () -> Unit, onBack: () -> Unit) {
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(courseNames.getValue(courseId), style = MaterialTheme.typography.headlineSmall)
        Button(onClick = onAdd) { Text("Add session") }
        TextButton(onClick = onBack) { Text("Back") }
    }
}

@Composable
fun AddSessionScreen(courseId: String, onSaved: () -> Unit) {
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text("New session for ${courseNames.getValue(courseId)}", style = MaterialTheme.typography.titleMedium)
        Button(onClick = onSaved) { Text("Save") }
    }
}
```

O `CoursesScreen` não navega quando um curso é tocado; ele chama `onOpen` com o id do curso e deixa
quem chamou decidir o que isso significa. **Uma tela que recebe um `NavController` só pode ser
mostrada dentro daquele grafo de navegação**, e não pode ser vista em prévia nem testada sozinha;
uma que recebe funções pode as duas coisas. A aula 10 tira os dados das telas também.

E o grafo que as une:

```kotlin
// app/src/main/java/com/example/planner/PlannerNavHost.kt
package com.example.planner

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute

@Composable
fun PlannerNavHost(navController: NavHostController = rememberNavController()) {
    NavHost(navController, startDestination = Courses) {
        composable<Courses> {
            CoursesScreen(onOpen = { id -> navController.navigate(CourseDetail(id)) })
        }
        composable<CourseDetail> { entry ->
            val route = entry.toRoute<CourseDetail>()
            CourseDetailScreen(
                courseId = route.courseId,
                onAdd = { navController.navigate(AddSession(route.courseId)) },
                onBack = { navController.popBackStack() },
            )
        }
        composable<AddSession> { entry ->
            val route = entry.toRoute<AddSession>()
            AddSessionScreen(
                courseId = route.courseId,
                onSaved = { navController.popBackStack() },
            )
        }
    }
}
```

O `NavHost` recebe o controlador e a rota de partida, e dentro dele cada `composable<Route>` diz o que
desenhar quando aquela rota está no topo. **`navigate(route)` empilha; `popBackStack()` desempilha**;
a seção 04 vê os dois acontecerem. `rememberNavController()` é o padrão, então o app chama
`PlannerNavHost()` sem nada, e um teste passa um controlador que ele pode inspecionar.
