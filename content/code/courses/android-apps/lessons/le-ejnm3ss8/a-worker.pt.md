---
title: Um worker, e as três respostas que ele pode dar
version: 1
---

**Um worker é uma classe com uma função, `doWork`, e essa função termina dizendo uma de três
coisas**: deu certo, falhou de vez, ou deve ser tentada de novo mais tarde. Todo o resto do
WorkManager, as condições, o agendamento e as novas tentativas, existe para decidir quando `doWork`
é chamada e o que fazer com a resposta.

Parta do projeto da aula 1 e acrescente o WorkManager ao módulo. Este é o arquivo de build inteiro,
com duas linhas a mais para a biblioteca e o seu auxiliar de testes, uma para testes de corrotinas, e
um bloco `testLogging` que imprime o que cada teste escreve, para você ver as mesmas linhas que esta
seção mostra:

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
    implementation(libs.work.runtime.ktx)

    testImplementation(libs.junit)
    testImplementation(libs.robolectric)
    testImplementation(libs.androidx.test.core)
    testImplementation(platform(libs.compose.bom))
    testImplementation(libs.compose.ui.test.junit4)
    testImplementation(libs.roborazzi)
    testImplementation(libs.roborazzi.compose)
    testImplementation(libs.work.testing)
    testImplementation(libs.coroutines.test)
}
```

## A coisa que o worker chama

O worker não deveria saber como as sessões chegam ao servidor; a aula 13 constrói isso com Retrofit,
e a aula 16 o põe atrás de um repositório. Ele precisa de uma função para chamar, então ganha uma:

```kotlin
// app/src/main/java/com/example/planner/data/Uploader.kt
package com.example.planner.data

import java.io.IOException

/** Sends the sessions the server has not seen yet, and says how many went. */
fun interface Uploader {
    @Throws(IOException::class)
    suspend fun upload(): Int
}
```

`IOException` é a família de falhas que uma tentativa posterior pode resolver: sem rede, um tempo
esgotado, uma conexão que o servidor derrubou. Essa distinção é toda a decisão do worker.

## O worker

```schooling-example
{"language": "kotlin", "file": "app/src/main/java/com/example/planner/work/SyncWorker.kt", "parts": [{"code": "// app/src/main/java/com/example/planner/work/SyncWorker.kt\npackage com.example.planner.work\n\nimport android.content.Context\nimport androidx.work.CoroutineWorker\nimport androidx.work.WorkerParameters\nimport androidx.work.workDataOf\nimport com.example.planner.data.Uploader\nimport java.io.IOException"}, {"code": "\nclass SyncWorker(\n    context: Context,\n    params: WorkerParameters,\n    private val uploader: Uploader,\n) : CoroutineWorker(context, params) {", "note": "`CoroutineWorker` faz de `doWork` uma função `suspend`, executada em `Dispatchers.Default`. Os dois primeiros parâmetros são do WorkManager; o terceiro é nosso, e a seção 06 mostra quem o passa."}, {"code": "\n    override suspend fun doWork(): Result {\n        return try {\n            val sent = uploader.upload()\n            Result.success(workDataOf(KEY_SENT to sent))", "note": "**Sucesso** carrega uma saída: um pequeno mapa `Data` de chaves e valores simples. O WorkManager o guarda junto com o resultado, e a seção 05 o entrega ao próximo worker."}, {"code": "        } catch (e: IOException) {\n            if (runAttemptCount < MAX_ATTEMPTS - 1) Result.retry() else Result.failure()\n        }\n    }", "note": "**Nova tentativa** devolve o trabalho à fila, para rodar de novo depois de um atraso de espera. `runAttemptCount` conta as execuções anteriores a esta, então três tentativas são 0, 1 e 2, e a terceira desiste com **falha**."}, {"code": "\n    companion object {\n        const val KEY_SENT = \"sent\"\n        const val MAX_ATTEMPTS = 3\n    }\n}", "note": "A chave é uma constante porque o worker que lê esta saída está em outro arquivo."}]}
```

Qualquer outra exceção que escape de `doWork` conta como falha. É o padrão certo: uma
`IllegalStateException` vai ser lançada do mesmo jeito na próxima tentativa, e tentar de novo só gasta
bateria.

## Quem constrói o worker

O WorkManager cria os workers sozinho, pelo nome da classe, e por padrão só conhece o construtor com
dois parâmetros. Um worker com uma dependência precisa de uma **fábrica**, que o WorkManager consulta
primeiro:

```kotlin
// app/src/main/java/com/example/planner/work/PlannerWorkerFactory.kt
package com.example.planner.work

import android.content.Context
import androidx.work.ListenableWorker
import androidx.work.WorkerFactory
import androidx.work.WorkerParameters
import com.example.planner.data.Uploader

class PlannerWorkerFactory(private val uploader: Uploader) : WorkerFactory() {
    override fun createWorker(
        appContext: Context,
        workerClassName: String,
        workerParameters: WorkerParameters,
    ): ListenableWorker? = when (workerClassName) {
        SyncWorker::class.java.name -> SyncWorker(appContext, workerParameters, uploader)
        else -> null
    }
}
```

**Devolver `null` não é erro**: diz ao WorkManager para cair na reflexão dele, e é assim que um worker
com os dois parâmetros padrão continua sendo criado. Com o Hilt, a biblioteca da aula 12, o
`@HiltWorker` e o artefato `hilt-work` do catálogo geram essa fábrica para você.

## Testando, uma tentativa de cada vez

O `TestListenableWorkerBuilder` constrói um worker como o WorkManager construiria, com o número de
tentativa que o teste pedir, e `doWork` vira uma chamada `suspend` comum:

```kotlin
// app/src/test/java/com/example/planner/work/SyncWorkerTest.kt
package com.example.planner.work

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.ListenableWorker.Result
import androidx.work.testing.TestListenableWorkerBuilder
import androidx.work.workDataOf
import com.example.planner.data.Uploader
import java.io.IOException
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class SyncWorkerTest {
    private val context = ApplicationProvider.getApplicationContext<Context>()

    private fun worker(attempt: Int, uploader: Uploader) =
        TestListenableWorkerBuilder<SyncWorker>(context)
            .setRunAttemptCount(attempt)
            .setWorkerFactory(PlannerWorkerFactory(uploader))
            .build()

    @Test fun sendsAndReportsHowMany() = runTest {
        val result = worker(0) { 4 }.doWork()
        println("attempt 0, server up: $result")
        assertEquals(Result.success(workDataOf(SyncWorker.KEY_SENT to 4)), result)
    }

    @Test fun retriesWhileAttemptsRemain() = runTest {
        for (attempt in 0..2) {
            val result = worker(attempt) { throw IOException("no route to host") }.doWork()
            println("attempt $attempt, server down: $result")
        }
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*SyncWorkerTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    attempt 0, server up: Success {mOutputData=Data {sent : 4}}
SyncWorkerTest > sendsAndReportsHowMany PASSED
    attempt 0, server down: Retry
    attempt 1, server down: Retry
    attempt 2, server down: Failure {mOutputData=Data {}}
SyncWorkerTest > retriesWhileAttemptsRemain PASSED
BUILD SUCCESSFUL in 20s
```

As três respostas, cada uma onde deveria. Com o servidor no ar, a saída traz `sent : 4`. Com o
servidor fora, as tentativas 0 e 1 pedem para tentar de novo e a tentativa 2 desiste. **Uma falha é
definitiva**: o WorkManager não roda aquele pedido de novo. Uma nova tentativa é o oposto, e a seção
05 mostra o que ela faz com o trabalho enfileirado atrás.
