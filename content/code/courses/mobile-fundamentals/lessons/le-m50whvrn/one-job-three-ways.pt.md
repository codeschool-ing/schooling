---
title: A sincronização diária do planner, escrita de três jeitos
version: 1
---

**O planner tem um trabalho que não precisa de a aluna estar olhando: mandar ao servidor as sessões
marcadas como concluídas hoje, e trazer de volta qualquer mudança feita em outro aparelho.** Ninguém
espera por ele, algumas horas de atraso não custam nada, e ele sai mais barato no Wi-Fi com o
celular no carregador. É exatamente o trabalho para o qual os sistemas da etapa anterior foram
feitos. Deve ser um job agrupado por dia, com restrições, e não um cronômetro.

Abaixo está esse job nas palavras de cada plataforma. Os três trechos foram adaptados do guia do
Android sobre definir trabalho com o WorkManager, do artigo da Apple sobre usar tarefas em segundo
plano para atualizar um app, e da documentação do `expo-background-task` da Expo, e **não foram
compilados nem executados para este curso**. `syncWeek` representa o código do próprio app que faz o
envio; ele é o mesmo nos três e não aparece.

## Android, com o WorkManager

```kotlin
class SyncWeekWorker(context: Context, params: WorkerParameters) :
    CoroutineWorker(context, params) {
    override suspend fun doWork(): Result =
        if (syncWeek()) Result.success() else Result.retry()
}

val constraints = Constraints.Builder()
    .setRequiredNetworkType(NetworkType.UNMETERED)
    .setRequiresCharging(true)
    .build()
val daily = PeriodicWorkRequestBuilder<SyncWeekWorker>(1, TimeUnit.DAYS)
    .setConstraints(constraints)
    .build()
WorkManager.getInstance(context)
    .enqueueUniquePeriodicWork("sync-week", ExistingPeriodicWorkPolicy.KEEP, daily)
```

**As restrições dizem quando sai barato, e o intervalo diz com que frequência, no máximo.** Se o
celular passa um dia fora do carregador, a execução atrasa, ou é pulada, e a documentação diz isso.
O `retry()` devolve uma tentativa que falhou ao WorkManager, que tenta de novo mais tarde com um
backoff próprio, a mesma ideia que a aula 14 escreveu à mão. O `enqueueUniquePeriodicWork` com um
nome faz com que chamá-lo a cada abertura do app mantenha um job só, em vez de empilhar um novo a
cada vez.

## iOS, com o BGTaskScheduler

```swift
// Registered while the app launches, for an identifier listed in Info.plist
BGTaskScheduler.shared.register(forTaskWithIdentifier: "app.planner.sync", using: nil) { task in
    scheduleSync() // ask for the next one first
    let work = Task { task.setTaskCompleted(success: await syncWeek()) }
    task.expirationHandler = { work.cancel() }
}

func scheduleSync() {
    let request = BGProcessingTaskRequest(identifier: "app.planner.sync")
    request.requiresExternalPower = true
    request.requiresNetworkConnectivity = true
    request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
    try? BGTaskScheduler.shared.submit(request)
}
```

**O iOS não tem pedido periódico: cada execução pede a próxima.** O handler agenda a próxima
sincronização antes de começar esta, então uma execução interrompida no meio ainda deixa uma
esperando. O `expirationHandler` é o sistema dizendo que o tempo concedido acabou; a tarefa precisa
parar, e o `setTaskCompleted` conta ao sistema como foi. O `earliestBeginDate` fica a um dia de
distância, que é o mais cedo em que o sistema pode rodá-la, não a hora em que vai rodar.

## React Native, com o expo-background-task

```tsx
import * as BackgroundTask from "expo-background-task";
import * as TaskManager from "expo-task-manager";

// Defined at the top level of the app, not inside a component
TaskManager.defineTask("sync-week", async () => {
  const ok = await syncWeek();
  return ok
    ? BackgroundTask.BackgroundTaskResult.Success
    : BackgroundTask.BackgroundTaskResult.Failed;
});

await BackgroundTask.registerTaskAsync("sync-week", { minimumInterval: 24 * 60 }); // minutes
```

**O JavaScript é curto porque a metade nativa é da biblioteca.** No Android ele vira um job do
WorkManager, no iOS uma tarefa do `BGTaskScheduler`, e as regras de cada um valem sem mudança. A
documentação da Expo sobre o `minimumInterval`, lida em 30 de outubro de 2026, diz que o valor é em
minutos, com um padrão de 12 horas e um mínimo de 15 minutos. No iOS, acrescenta, intervalos curtos
muitas vezes são ignorados, e as tarefas tendem a rodar em janelas como a madrugada.

## O que os três têm em comum

| | Android | iOS | React Native |
|---|---|---|---|
| o trabalho | um `Worker` | um handler de abertura | uma tarefa definida com o `TaskManager` |
| o momento barato | `setRequiresCharging`, `NetworkType.UNMETERED` | `requiresExternalPower`, `requiresNetworkConnectivity` | bateria e rede, decididas pela biblioteca |
| com que frequência | no máximo uma vez por intervalo | uma vez, e o handler pede de novo | no máximo uma vez por `minimumInterval` |
| quando exatamente | quando as restrições e o sistema permitem | quando o sistema escolhe | um dos dois |

**Nenhum dos três consegue dizer "às 08:00".** Essa é a lição da etapa inteira: trabalho em segundo
plano num celular é um pedido, e o sistema o atende quando convém à bateria. Algo que precisa
chegar à aluna num momento certo, como um lembrete de que uma sessão começa em quinze minutos, é uma
notificação, e a aula 17 é sobre elas. O curso `mobile-offline` constrói a sincronização completa
sobre esses jobs na aula 16; o curso `android-apps` ensina o WorkManager na aula 18 e o `ios-apps`
as tarefas em segundo plano na aula 16, conforme o caminho que você seguir.
