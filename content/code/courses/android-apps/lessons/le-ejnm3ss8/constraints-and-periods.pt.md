---
title: Restrições, períodos, e pedir o mesmo trabalho duas vezes
version: 1
---

**Um pedido é o worker mais as condições em que ele pode rodar.** O worker da seção 03 diz o que
fazer; o pedido diz quando isso é permitido, com que frequência, e o que fazer com uma nova
tentativa. O planner quer as sessões enviadas a cada poucas horas, só com rede, e não quando a
bateria está quase no fim:

```kotlin
// app/src/main/java/com/example/planner/work/Sync.kt
package com.example.planner.work

import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

const val SYNC_WORK = "sync-sessions"

fun scheduleSync(workManager: WorkManager) {
    val constraints = Constraints.Builder()
        .setRequiredNetworkType(NetworkType.CONNECTED)
        .setRequiresBatteryNotLow(true)
        .build()
    val request = PeriodicWorkRequestBuilder<SyncWorker>(6, TimeUnit.HOURS)
        .setConstraints(constraints)
        .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
        .build()
    workManager.enqueueUniquePeriodicWork(SYNC_WORK, ExistingPeriodicWorkPolicy.KEEP, request)
}
```

Há três decisões nessa função, uma por chamada:

- **`Constraints`** são conferidas pelo sistema, não pelo seu código. `CONNECTED` quer dizer qualquer
  rede; `UNMETERED` esperaria pelo Wi-Fi, o que combina com um envio grande e é errado para algumas
  sessões. `setRequiresBatteryNotLow` deixa a bateria do estudante decidir antes do planner.
- **`PeriodicWorkRequestBuilder`** com seis horas repete o trabalho mais ou menos a cada seis horas,
  enquanto o app estiver instalado. "Mais ou menos" é literal: o sistema o roda uma vez em cada
  período, num momento que ele escolhe.
- **`setBackoffCriteria`** diz quanto uma nova tentativa espera: 30 segundos depois da primeira, e o
  dobro a cada vez, que é o que `EXPONENTIAL` quer dizer. A alternativa, `LINEAR`, soma 30 segundos a
  cada vez.

## Trabalho único, porque o `onCreate` roda mais de uma vez

`scheduleSync` vai ser chamada pelo `onCreate` da aplicação, na seção 06, e ele roda toda vez que o
processo começa. Um `enqueue` simples acrescentaria um pedido periódico a cada início, e depois de uma
semana o planner estaria enviando as sessões vinte vezes a cada seis horas. **O trabalho único dá um
nome ao pedido**, e a política diz o que faz um segundo pedido com o mesmo nome: `KEEP` deixa o
existente em paz, e `UPDATE` substitui a definição dele mantendo o agendamento.

## Testando tempo e condições sem esperar por nenhum dos dois

O `WorkManagerTestInitHelper` põe um WorkManager de teste no lugar do verdadeiro, com um
`SynchronousExecutor` para que o trabalho rode na própria thread do teste. O **test driver** dele é o
que torna o teste possível: ele avisa o WorkManager que as restrições foram atendidas, ou que um
período passou, sem esperar seis horas.

```kotlin
// app/src/test/java/com/example/planner/work/ScheduleTest.kt
package com.example.planner.work

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.work.Configuration
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkInfo
import androidx.work.WorkManager
import androidx.work.testing.SynchronousExecutor
import androidx.work.testing.WorkManagerTestInitHelper
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ScheduleTest {
    private val context = ApplicationProvider.getApplicationContext<Context>()
    private var uploads = 0

    @Before fun setUp() {
        val config = Configuration.Builder()
            .setExecutor(SynchronousExecutor())
            .setWorkerFactory(PlannerWorkerFactory { uploads++; 2 })
            .build()
        WorkManagerTestInitHelper.initializeTestWorkManager(context, config)
    }

    private fun info(wm: WorkManager): WorkInfo =
        wm.getWorkInfosForUniqueWork(SYNC_WORK).get().single()

    @Test fun waitsForItsConstraintsEveryPeriod() {
        val wm = WorkManager.getInstance(context)
        scheduleSync(wm)
        val id = info(wm).id
        val driver = WorkManagerTestInitHelper.getTestDriver(context)!!
        println("enqueued:              ${info(wm).state}, uploads = $uploads")
        driver.setAllConstraintsMet(id)
        println("network and battery:   ${info(wm).state}, uploads = $uploads")
        driver.setPeriodDelayMet(id)
        println("six hours later:       ${info(wm).state}, uploads = $uploads")
        driver.setAllConstraintsMet(id)
        println("network and battery:   ${info(wm).state}, uploads = $uploads")
        assertEquals(2, uploads)
    }

    @Test fun keepLeavesTheFirstRequestAlone() {
        val wm = WorkManager.getInstance(context)
        scheduleSync(wm)
        val first = info(wm).id
        scheduleSync(wm)
        scheduleSync(wm)
        val all = wm.getWorkInfosForUniqueWork(SYNC_WORK).get()
        println("after three calls: ${all.size} request, same id = ${all.single().id == first}")
    }

    @Test fun fifteenMinutesIsTheFloor() {
        val request = PeriodicWorkRequestBuilder<SyncWorker>(5, TimeUnit.MINUTES).build()
        println("asked for 5 minutes, got ${request.workSpec.intervalDuration / 60_000}")
    }
}
```

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ScheduleTest.waits*' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    enqueued:              ENQUEUED, uploads = 0
    network and battery:   ENQUEUED, uploads = 1
    six hours later:       ENQUEUED, uploads = 1
    network and battery:   ENQUEUED, uploads = 2
ScheduleTest > waitsForItsConstraintsEveryPeriod PASSED
BUILD SUCCESSFUL in 16s
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ScheduleTest.keep*' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    after three calls: 1 request, same id = true
ScheduleTest > keepLeavesTheFirstRequestAlone PASSED
BUILD SUCCESSFUL in 10s
```

Leia o primeiro teste linha a linha, porque ele traz a única coisa do trabalho periódico que costuma
surpreender. Enfileirado, nada roda: nenhuma rede foi declarada. Restrições atendidas, o envio roda
uma vez, e o estado volta a `ENQUEUED`, **porque um pedido periódico nunca chega a `SUCCEEDED`**; ele
dá certo e espera o próximo período. Seis horas depois, nada acontece sozinho. **Cada período espera
as suas restrições de novo**, e só quando o teste diz que a rede está lá o segundo envio roda.

O segundo teste é a política `KEEP`: três chamadas, um pedido, e é o primeiro.

## Quinze minutos é o mínimo

Um período não pode ser tão curto quanto você quiser. O terceiro teste pede cinco minutos e olha o
que foi construído:

```
ana@vm:~/planner$ ./gradlew --console=plain testDebugUnitTest --tests '*ScheduleTest.fifteen*' 2>&1 | grep -E '^    |PASSED|FAILED|^BUILD'
    asked for 5 minutes, got 15
ScheduleTest > fifteenMinutesIsTheFloor PASSED
BUILD SUCCESSFUL in 13s
```

**Quinze minutos é o período mais curto que o WorkManager agenda**, e ele aumenta um mais curto em
vez de recusá-lo. Qualquer coisa que precise acontecer com mais frequência do que isso com o app
fechado é sinal de que o desenho está errado: um servidor pode empurrar uma mensagem no lugar, que é o
assunto da aula 17 de `mobile-fundamentals`.
