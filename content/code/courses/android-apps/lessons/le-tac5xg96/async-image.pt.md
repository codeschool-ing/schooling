---
title: AsyncImage, e tudo o que ele faz por uma imagem
version: 1
---

**Mostrar uma imagem da rede são seis tarefas, e o `AsyncImage` faz todas.** Baixar os bytes fora da
thread principal. Decodificá-los num bitmap no tamanho de que a tela precisa, não no tamanho que o
arquivo tem. Guardar o bitmap na memória para a próxima vez, e os bytes no disco para a vez seguinte.
Mostrar algo enquanto carrega e outra coisa se falhar. E cancelar tudo se o composable sair da tela
antes. O Coil é a biblioteca que faz essas tarefas para o Compose, e o **Coil 3**, a versão que este
curso usa, é escrito em Kotlin com corrotinas do começo ao fim.

O planner ganha uma imagem por curso: uma capa no alto do cartão de cada curso. O Coil chega como
duas bibliotecas, a integração com o Compose e um fetcher de rede montado sobre o OkHttp da aula 13.
O arquivo de build também traz o que os testes desta aula precisam, o `coil-test` e o Roborazzi entre
eles:

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
        unitTests.all {
            it.testLogging {
                events("passed", "failed")
                showStandardStreams = true
            }
        }
    }
}

dependencies {
    implementation(libs.core.ktx)
    implementation(libs.activity.compose)
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.ui)
    implementation(libs.compose.material3)
    implementation(libs.coil.compose)
    implementation(libs.coil.network)
    debugImplementation(libs.compose.ui.test.manifest)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(libs.okhttp.mockwebserver)
    testImplementation(libs.coil.test)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
}
```

Uma imagem da rede precisa da permissão `INTERNET`, que a aula 13 acrescentou e que o manifesto
desta aula declara de novo, já que cada aula parte do da aula 1:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:name=".PlannerApp"
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

`android:name=".PlannerApp"` nomeia a classe de aplicação da seção 04, onde o carregador de imagens é
configurado uma vez para o app inteiro.

## O cartão

```kotlin
// app/src/main/java/com/example/planner/ui/CourseCard.kt
package com.example.planner.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.painter.ColorPainter
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage

@Composable
fun CourseCard(name: String, coverUrl: String?, modifier: Modifier = Modifier) {
    Card(modifier.fillMaxWidth()) {
        Column {
            AsyncImage(
                model = coverUrl,
                contentDescription = null,
                contentScale = ContentScale.Crop,
                placeholder = ColorPainter(Color(0xFFE0E0E0)),
                error = ColorPainter(Color(0xFFB00020)),
                fallback = ColorPainter(Color(0xFF9E9E9E)),
                modifier = Modifier.fillMaxWidth().height(120.dp),
            )
            Text(name, style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(16.dp))
        }
    }
}
```

**`model` é a URL; todo o resto é sobre o que o usuário vê.** `contentScale = Crop` preenche a faixa
de 120 dp e corta o que sobra, o que combina com uma capa. Os três painters são o que aparece enquanto
a imagem carrega, quando ela falha e quando `coverUrl` é `null`; a seção 05 desenha os três. A capa é
decoração, já que o nome do curso está escrito embaixo, então `contentDescription = null` diz a um
leitor de tela para pulá-la; uma imagem que levasse informação a descreveria ali.

**O que o `AsyncImage` não mostra é o tamanho que ele pediu.** Ele mediu a faixa de 120 dp e pediu a
imagem nesse tamanho, em pixels. A seção 03 é o motivo de essa decisão importar mais do que todo o
resto desta página.
