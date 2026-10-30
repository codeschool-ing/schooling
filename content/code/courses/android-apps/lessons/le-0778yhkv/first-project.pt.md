---
title: Os oito primeiros arquivos do planner
version: 1
---

**O app que este curso constrói é um planner de estudos**, o mesmo que a trilha `frontend` constrói
para o navegador e que as outras duas opções desta trilha constroem para iOS e para React Native. Um
estudante lista cursos, abre um, acrescenta sessões de estudo com data e duração, marca como feitas
e vê o total da semana. Na aula 22 ele guarda os dados num banco, conversa com um servidor, funciona
offline, manda um lembrete e sai como um bundle assinado. Hoje são oito arquivos e uma linha de
texto numa tela.

O Android Studio escreve estes arquivos para você a partir de um modelo, e o modelo muda a cada
versão. **Escrevê-los à mão uma vez é o jeito mais rápido de saber para que serve cada um.** É também daqui que toda aula seguinte parte: as aulas 2 a 22 começam, cada uma, de uma cópia do projeto exatamente como esta seção o deixa, e acrescentam os arquivos que a aula mostra. Crie um diretório
para ele:

```
ana@vm:~$ mkdir -p ~/planner && cd ~/planner
```

## O settings: o que o build contém e de onde ele baixa

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

O Gradle lê este arquivo primeiro. Ele nomeia os **repositórios**, os servidores de onde vêm as
bibliotecas: `google()` é o repositório Maven do Google, onde moram todas as bibliotecas `androidx`
e o plugin Android do Gradle, e `mavenCentral()` é onde publica a maior parte do resto do mundo
Java. `include(":app")` diz que o build tem um módulo, no diretório `app`. Um app maior se divide em
vários, `:core:data`, `:feature:sessions` e assim por diante, e cada um é uma linha aqui. Um basta
para este curso, e a aula 22 diz quando isso deixa de ser verdade.

`FAIL_ON_PROJECT_REPOS` transforma em erro um módulo que declare o próprio repositório. Assim a
lista de servidores em que o seu build confia fica neste único arquivo, onde quem revisar uma
mudança vai vê-la.

## O catálogo: todas as versões que este curso usa, num só lugar

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

**Isto é um catálogo de versões**, e o Gradle o lê sozinho por causa de onde ele está. Cada
biblioteca ganha um nome curto, `room-runtime`, que os arquivos de build escrevem como
`libs.room.runtime`. Todas as versões que o curso usa estão aqui, da aula 1 à aula 22, então você
escreve este arquivo uma vez. **Listar uma biblioteca não baixa nada**: o Gradle só busca uma
biblioteca quando o arquivo de build de um módulo a pede.

A tabela `[versions]` é a parte para olhar quando algo quebra. Vinte e duas bibliotecas, cada uma
fixada num número exato, todas lançadas antes de 30 de outubro de 2026, quando este curso foi
gravado. Três merecem uma frase agora:

- `agp` é o **plugin Android do Gradle**, a parte do build que sabe o que é um app Android. A versão
  dele decide qual Gradle ele aceita e qual `compileSdk` ele entende.
- `composeBom` é uma **lista de materiais** (*bill of materials*): um número que fixa juntas as
  versões de uma dúzia de bibliotecas do Compose. É por isso que as linhas do Compose em
  `[libraries]` não têm versão própria.
- `kotlin` bate com o compilador que o curso `kotlin` instalou, 2.4.21. Dois plugins o carregam: o
  compilador do Compose e o plugin de serialização da aula 14.

## O arquivo de build da raiz, e as propriedades ao lado

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

O arquivo de build da raiz declara todos os plugins que o projeto pode usar, com `apply false`:
carregados uma vez, na versão do catálogo, e aplicados por ninguém aqui. Um módulo aplica então os
que precisa pelo nome. O `gradle.properties` dá ao processo do Gradle dois gigabytes de memória e diz
que o projeto usa as bibliotecas `androidx`, e não a support library que elas substituíram em 2018.

## O módulo: o que o app é

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

Três números em `defaultConfig` são fáceis de confundir, e a seção 06 dá a cada um o seu parágrafo.
Numa linha cada: **`compileSdk`** é a versão do Android cuja API o compilador usa para conferir o
seu código, **`minSdk`** é o Android mais antigo que pode instalar o app, e **`targetSdk`** é a
versão cujo comportamento o app testou e adota. `applicationId` é a identidade do app num celular e
na Play Store, e nunca pode mudar depois que o app é publicado.

A segunda metade das dependências é para testes. Eles rodam na JVM do seu computador, não num
celular: o **Robolectric** faz o papel do framework do Android, e o **Roborazzi** salva o que um
composable desenhou como PNG. É assim que este curso mostra uma tela sem emulador, e a seção 02
desta aula diz por que não há emulador nele.

```properties
# app/src/test/resources/robolectric.properties
sdk=35
```

Este arquivo diz ao Robolectric qual versão do Android imitar. É 35, e não 36, porque o Robolectric
4.17 não conseguiu iniciar o Android 36 no JDK que este curso usa: todo teste falhava na partida com
`Failed to interact with raw FileDescriptor internals`. O app continua mirando o 36; só o substituto
usado nos testes é uma versão mais antiga.

## O manifesto, uma string e uma tela

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

A seção 07 lê o manifesto e as strings com calma. A activity é o assunto da aula 2, e `setContent` é
onde o Compose começa, que é o da aula 3. Por ora basta que o app tem uma tela e que a tela diz uma
frase.

## O wrapper: o Gradle que o projeto traz consigo

Você tem o Gradle 9.8.2 no `PATH`, do curso `kotlin`. Um projeto não deveria depender disso: outra
pessoa que o clonar pode ter outra versão, ou nenhuma. Então você roda o Gradle uma vez para
escrever um **wrapper**, um script pequeno e um jar que baixam o Gradle exato que o projeto nomeia e o
executam. Daí em diante, dentro do projeto, você digita `./gradlew` e nunca `gradle`:

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

O `find` deixa de fora `.gradle/`, um diretório de controle interno que o Gradle cria em todo
projeto em que toca e que nunca vai para o controle de versão. `gradlew` e `gradlew.bat` são os
scripts para Linux e macOS e para Windows. **Os quatro arquivos do wrapper vão para o controle de
versão**; alguém que clonar o projeto digita `./gradlew build` e recebe o mesmo Gradle que você, conferido
contra o `distributionSha256Sum` se você acrescentar um.
