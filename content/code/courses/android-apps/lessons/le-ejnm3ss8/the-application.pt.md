---
title: A classe de aplicação, e o inicializador que você desliga
version: 1
---

**Alguém precisa dar ao WorkManager a sua fábrica antes de o primeiro worker ser construído**, e num
app esse alguém é a classe `Application`: o único objeto que o Android cria quando o processo começa,
antes de qualquer activity. O projeto da aula 1 não tem uma, porque nada precisava. Agora algo
precisa:

```kotlin
// app/src/main/java/com/example/planner/PlannerApp.kt
package com.example.planner

import android.app.Application
import androidx.work.Configuration
import androidx.work.WorkManager
import com.example.planner.data.Uploader
import com.example.planner.work.PlannerWorkerFactory
import com.example.planner.work.scheduleSync

class PlannerApp : Application(), Configuration.Provider {

    // Lesson 16's repository sends the sessions; until then nothing is sent.
    private val uploader = Uploader { 0 }

    override val workManagerConfiguration: Configuration
        get() = Configuration.Builder()
            .setWorkerFactory(PlannerWorkerFactory(uploader))
            .build()

    override fun onCreate() {
        super.onCreate()
        scheduleSync(WorkManager.getInstance(this))
    }
}
```

`Configuration.Provider` é o jeito de o WorkManager pedir a configuração à aplicação. A primeira
chamada a `WorkManager.getInstance` a encontra ali e se monta com a fábrica. E o `onCreate` agenda a
sincronização periódica a cada início, o que o `KEEP` da seção 04 torna inofensivo.

## O manifesto: nomeie a classe, e tire o padrão

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

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

        <provider
            android:name="androidx.startup.InitializationProvider"
            android:authorities="${applicationId}.androidx-startup"
            tools:node="merge">
            <meta-data
                android:name="androidx.work.WorkManagerInitializer"
                android:value="androidx.startup"
                tools:node="remove" />
        </provider>
    </application>

</manifest>
```

`android:name=".PlannerApp"` é o que faz o Android criar a sua classe em vez da `Application` comum.
O bloco `<provider>` é a parte que as pessoas esquecem. O manifesto do próprio WorkManager, combinado
com o seu como a seção 07 da aula 1 mostrou, registra um **inicializador** que monta o WorkManager com
uma configuração padrão quando o processo começa, antes de a sua `Application` ter voz. Deixe-o ali e
a sua fábrica nunca é usada: a padrão tenta construir o `SyncWorker` com dois parâmetros e falha.
`tools:node="remove"` é uma instrução para o combinador de manifestos, não para o celular: tire essa
única entrada do que as bibliotecas trouxeram.

## O que o combinador fez com isso

Compile, e veja o que o combinador produziu:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E -A1 "Warning:|^BUILD"
BUILD SUCCESSFUL in 24s
36 actionable tasks: 22 executed, 14 up-to-date
ana@vm:~/planner$ grep -c WorkManagerInitializer app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml
0
ana@vm:~/planner$ find ~/.gradle/caches -path "*work-runtime-2.12.0*" -name AndroidManifest.xml -exec grep -c WorkManagerInitializer {} \;
1
ana@vm:~/planner$ grep -o "uses-permission android:name=\"[^\"]*\"" app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml
uses-permission android:name="android.permission.WAKE_LOCK"
uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"
uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"
uses-permission android:name="android.permission.FOREGROUND_SERVICE"
uses-permission android:name="com.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
```

O build não diz nada sobre a remoção, então conte. **O manifesto da própria biblioteca, no cache do
Gradle, declara o inicializador uma vez, e o manifesto combinado não tem nenhum**: o combinador tirou a
entrada, e o WorkManager vai esperar a `PlannerApp` configurá-lo.

As permissões são a outra coisa a ler, como a aula 1 pediu sempre que chega uma biblioteca. A última é
a da aula 1, de `androidx.core`; você não escreveu nenhuma das outras quatro. `WAKE_LOCK` mantém o
processador acordado enquanto um worker roda, `ACCESS_NETWORK_STATE` deixa o WorkManager conferir a
restrição de rede, `RECEIVE_BOOT_COMPLETED` é como ele recoloca os jobs depois de uma reinicialização,
e `FOREGROUND_SERVICE` é para trabalho longo mostrado com uma notificação. Nenhuma delas pergunta nada
ao estudante: as quatro são concedidas na instalação, o que a aula 20 explica.
