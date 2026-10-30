---
title: Canais, e o interruptor que é do estudante
version: 1
---

**Um canal é uma categoria de notificação que o estudante pode aumentar, baixar ou desligar
sozinha.** Desde o Android 8.0, que é a API 26 e o `minSdk` deste projeto, uma notificação que não
nomeia um canal existente não aparece. O objetivo da regra é o controle: um estudante que quer
lembretes de estudo e não quer um resumo semanal desliga um canal e mantém o outro, em vez de
silenciar o app inteiro.

Então os canais do planner merecem ser desenhados como o estudante vai vê-los, nas configurações de
notificação do app: um nome, uma frase de descrição e um canal separado para cada tipo de notificação
que alguém poderia querer tratar de outro jeito. O planner tem um tipo hoje.

Parta do projeto da aula 1. O arquivo de build é o da aula 1 com um bloco a mais, `testLogging`, que imprime o que cada teste escreve para você ver as linhas que esta aula mostra. Notificações não precisam de biblioteca nova, porque o `androidx.core`, que já está lá, traz as versões compatíveis de
todas as classes usadas aqui:

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

As strings, todas desta aula de uma vez:

```xml
<!-- app/src/main/res/values/strings.xml -->
<resources>
    <string name="app_name">Planner</string>
    <string name="welcome">No courses yet. Add the first one.</string>
    <string name="channel_reminders">Study reminders</string>
    <string name="channel_reminders_description">A nudge on days with a session planned</string>
    <string name="reminder_title">%1$s today</string>
    <string name="reminder_text">%1$d minutes planned. Tap to open the course.</string>
</resources>
```

## Criando

```kotlin
// app/src/main/java/com/example/planner/notify/Channels.kt
package com.example.planner.notify

import android.content.Context
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationManagerCompat
import com.example.planner.R

const val CHANNEL_REMINDERS = "reminders"

fun createChannels(context: Context) {
    val reminders = NotificationChannelCompat.Builder(
        CHANNEL_REMINDERS,
        NotificationManagerCompat.IMPORTANCE_DEFAULT,
    )
        .setName(context.getString(R.string.channel_reminders))
        .setDescription(context.getString(R.string.channel_reminders_description))
        .build()
    NotificationManagerCompat.from(context).createNotificationChannel(reminders)
}
```

`NotificationChannelCompat` é o invólucro do `androidx.core`, que não faz nada num celular anterior à
API 26 e cria o canal de verdade em qualquer um mais novo; com `minSdk` 26 é sempre o segundo caso, e
o invólucro mantém o código igual de qualquer jeito. O id, `reminders`, é o que toda notificação
nomeia. O nome e a descrição são o que o estudante lê, então vêm do `strings.xml` e são traduzidos
como qualquer outro texto.

**Criar um canal que já existe não muda nada importante.** O sistema mantém a importância que o
estudante escolheu e ignora a do seu código, e atualiza só o nome e a descrição. Isso torna seguro
chamar `createChannels` toda vez que o processo começa, que é para isso que serve uma classe
`Application`:

```kotlin
// app/src/main/java/com/example/planner/PlannerApp.kt
package com.example.planner

import android.app.Application
import com.example.planner.notify.createChannels

class PlannerApp : Application() {
    override fun onCreate() {
        super.onCreate()
        createChannels(this)
    }
}
```

E o manifesto a nomeia. Ele também declara a permissão de que trata a seção 05:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

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

## Conferindo

O Robolectric cria a classe de aplicação nomeada no manifesto antes de cada teste, então um teste vê
o canal exatamente como um app recém-iniciado veria:

```kotlin
// app/src/test/java/com/example/planner/notify/ChannelTest.kt
package com.example.planner.notify

import android.app.Application
import android.app.NotificationManager
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ChannelTest {
    @Test fun theApplicationRegistersTheChannel() {
        val app = ApplicationProvider.getApplicationContext<Application>()
        val manager = app.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        println("application class: ${app.javaClass.simpleName}")
        for (c in manager.notificationChannels) {
            println("channel ${c.id}: \"${c.name}\", importance ${c.importance}")
            println("  ${c.description}")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ChannelTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    application class: PlannerApp
    channel reminders: "Study reminders", importance 3
      A nudge on days with a session planned
ChannelTest > theApplicationRegistersTheChannel PASSED
BUILD SUCCESSFUL in 14s
```

**Importância 3 é `IMPORTANCE_DEFAULT`**: a notificação vai para a gaveta e toca o som de notificação
do celular, e não aparece por cima do que o estudante está fazendo. A escala vai de 0, que é o canal
desligado, a 4, `IMPORTANCE_HIGH`, que é o banner por cima da tela que um app de mensagens usa. Um
lembrete de estudo não é urgente o bastante para 4, e escolher 4 ensinaria os estudantes a desligar o
canal, que é o contrário do que um lembrete quer.

**Um app não pode subir a importância de um canal que já existe.** Se você lança com 2 e depois
decide por 3, quem instalou a versão anterior fica com 2. A saída é um canal novo com outro id, e
apagar o antigo, que o estudante vê nas configurações como uma categoria que sumiu. Escolha a primeira
importância com cuidado.
