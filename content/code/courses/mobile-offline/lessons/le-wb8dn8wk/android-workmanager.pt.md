---
title: "Android: WorkManager"
version: 1
---

**No Android, a sincronização em segundo plano é um trabalho que você entrega ao WorkManager, com as
condições de que ele precisa para rodar; você nunca abre uma thread e torce.** O WorkManager é a
biblioteca do Jetpack que o Google recomenda para trabalho que precisa acontecer em algum momento
mesmo que o app esteja fechado ou o celular reinicie. Ele guarda cada pedido num banco próprio,
então uma reinicialização não o perde, e roda o trabalho pelo agendador de tarefas do sistema, que é
o que respeita o Doze e os baldes da seção anterior.

*As listagens desta seção não foram rodadas para este curso: a máquina em que ele foi gravado não
conseguia instalar o SDK do Android. Elas seguem o guia do WorkManager em developer.android.com.*

## O worker

Um worker é uma classe com uma função. Devolver `Result.retry()` entrega a falha de volta ao
WorkManager, que espera e roda de novo; `Result.success()` encerra esta execução. `Planner.sync`
representa a sincronização do seu próprio app, a caixa de saída da aula 8 seguida da puxada da aula
11:

```kotlin
class SyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result =
        try {
            Planner.sync(applicationContext)
            Result.success()
        } catch (e: IOException) {
            Result.retry()
        }
}
```

## O pedido

```kotlin
val request = PeriodicWorkRequestBuilder<SyncWorker>(15, TimeUnit.MINUTES)
    .setConstraints(
        Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()
    )
    .setBackoffCriteria(BackoffPolicy.EXPONENTIAL, 30, TimeUnit.SECONDS)
    .build()

WorkManager.getInstance(context)
    .enqueueUniquePeriodicWork("planner-sync", ExistingPeriodicWorkPolicy.KEEP, request)
```

Quatro decisões estão escritas nessas linhas.

- **Quinze minutos é o menor período que o WorkManager aceita** para trabalho periódico, e é um
  mínimo: o Doze e os baldes decidem o intervalo real, que pode ser de horas.
- **A restrição de rede** faz o trabalho não começar sem conexão. Uma sincronização que rodasse
  offline falharia, tentaria de novo e gastaria bateria para descobrir o que o sistema já sabia.
- **O recuo** é o recuo exponencial da aula 9, feito pelo WorkManager entre as tentativas, começando
  em trinta segundos.
- **Trabalho único com `KEEP`** quer dizer que chamar isto a cada abertura, que é o lugar mais
  simples para fazê-lo, agenda um trabalho e não um por abertura. `REPLACE` reiniciaria o período a
  cada vez.

## Sincronizar agora, quando a rede volta

Quem salva uma sessão offline não deveria esperar o próximo período. Enfileire um pedido único com a
mesma restrição, e o WorkManager o roda assim que o celular estiver online:

```kotlin
val now = OneTimeWorkRequestBuilder<SyncWorker>()
    .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
    .build()
WorkManager.getInstance(context).enqueueUniqueWork("planner-sync-now", ExistingWorkPolicy.KEEP, now)
```

**Um worker pode ser parado enquanto roda**: quando a restrição dele deixa de valer, ou depois dos
dez minutos que o WorkManager permite numa execução. Num `CoroutineWorker`, isso chega como uma
corrotina cancelada, então `Planner.sync` precisa salvar o progresso conforme avança. A última seção
desta aula é exatamente isso, rodado no Node.
