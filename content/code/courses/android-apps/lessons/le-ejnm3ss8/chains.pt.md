---
title: Cadeias, e o que uma nova tentativa segura
version: 1
---

**Uma cadeia é uma sequência de pedidos em que cada um só começa quando o anterior deu certo**, e
recebe a saída dele como entrada. O planner usa uma quando o estudante aperta "sincronizar agora":
enviar as sessões, depois montar a frase que a tela mostra sobre isso. O segundo passo precisa do
número que o primeiro produziu, e não tem o que fazer se o primeiro não aconteceu.

O segundo worker lê a saída do primeiro:

```kotlin
// app/src/main/java/com/example/planner/work/SummaryWorker.kt
package com.example.planner.work

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf

class SummaryWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val sent = inputData.getInt(SyncWorker.KEY_SENT, -1)
        if (sent < 0) return Result.failure()
        return Result.success(workDataOf(KEY_MESSAGE to "$sent sessions synced"))
    }

    companion object {
        const val KEY_MESSAGE = "message"
    }
}
```

Ele só tem os dois parâmetros padrão, então a `PlannerWorkerFactory` devolve `null` para ele e o
WorkManager o constrói por reflexão, como a seção 03 disse. `Data` serve para valores pequenos,
alguns números ou uma frase curta: o WorkManager o guarda no banco e o limita a 10 KB. Uma lista de
sessões não vai em `Data`; o worker a lê de onde as sessões ficam guardadas.

## Pedidos únicos numa cadeia única

```kotlin
// app/src/test/java/com/example/planner/work/ChainTest.kt
package com.example.planner.work

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.Configuration
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.testing.SynchronousExecutor
import androidx.work.testing.WorkManagerTestInitHelper
import java.io.IOException
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ChainTest {
    private val context = ApplicationProvider.getApplicationContext<Context>()
    private var serverUp = true

    @Before fun setUp() {
        val config = Configuration.Builder()
            .setExecutor(SynchronousExecutor())
            .setWorkerFactory(PlannerWorkerFactory {
                if (serverUp) 3 else throw IOException("no route to host")
            })
            .build()
        WorkManagerTestInitHelper.initializeTestWorkManager(context, config)
    }

    private fun syncThenSummarise(): Pair<String, String> {
        val wm = WorkManager.getInstance(context)
        val sync = OneTimeWorkRequestBuilder<SyncWorker>().build()
        val summary = OneTimeWorkRequestBuilder<SummaryWorker>().build()
        wm.beginUniqueWork("sync-now", ExistingWorkPolicy.REPLACE, sync).then(summary).enqueue()
        val s = wm.getWorkInfoById(sync.id).get()!!
        val m = wm.getWorkInfoById(summary.id).get()!!
        return "sync ${s.state} (attempts ${s.runAttemptCount})" to
            "summary ${m.state} ${m.outputData.getString(SummaryWorker.KEY_MESSAGE) ?: ""}"
    }

    @Test fun theOutputOfOneIsTheInputOfTheNext() {
        println(syncThenSummarise())
    }

    @Test fun aRetryHoldsEverythingAfterIt() {
        serverUp = false
        println(syncThenSummarise())
    }
}
```

`beginUniqueWork` dá nome à cadeia, como a seção 04 deu ao pedido periódico, e `REPLACE` é a política
que um botão quer: um segundo toque cancela a cadeia que ainda espera e começa uma nova, então dois
toques nunca enviam duas vezes. Estes pedidos não têm restrições, então, com o executor síncrono, eles
rodam no momento em que são enfileirados:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ChainTest' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    (sync SUCCEEDED (attempts 1), summary SUCCEEDED 3 sessions synced)
ChainTest > theOutputOfOneIsTheInputOfTheNext PASSED
    (sync ENQUEUED (attempts 1), summary BLOCKED )
ChainTest > aRetryHoldsEverythingAfterIt PASSED
BUILD SUCCESSFUL in 17s
```

Com o servidor no ar, a sincronização rodou uma vez e deu certo, e o resumo recebeu `sent` como
entrada e produziu a frase. **Com o servidor fora, o resumo fica `BLOCKED`**: ele espera o pedido
anterior, que pediu nova tentativa e está `ENQUEUED` de novo depois da primeira. Quando o atraso de
espera passa e a nova tentativa dá certo, o resumo roda. Se a sincronização tivesse respondido
`failure`, o WorkManager marcaria como falho tudo o que vem depois, sem rodar.

## Os estados, todos eles

Um pedido passa por seis estados, e os testes desta aula já mostraram três:

| estado | o que significa |
|---|---|
| `ENQUEUED` | esperando as restrições, o atraso ou o próximo período |
| `BLOCKED` | esperando o pedido anterior numa cadeia |
| `RUNNING` | `doWork` está executando agora |
| `SUCCEEDED` | terminou com sucesso; só pedidos únicos |
| `FAILED` | terminou com falha, ou um pedido anterior falhou |
| `CANCELLED` | cancelado pelo app, ou substituído por `REPLACE` |

O app lê esses estados com `getWorkInfosForUniqueWorkFlow`, um `Flow` que o
`collectAsStateWithLifecycle` da aula 11 transforma em estado na tela: uma linha pequena de
"sincronizando" enquanto a cadeia está `RUNNING`, e a frase do resumo depois que ela chega a
`SUCCEEDED`.
