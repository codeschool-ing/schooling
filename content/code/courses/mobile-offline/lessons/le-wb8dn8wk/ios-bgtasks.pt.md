---
title: "iOS: BGTaskScheduler, e o upload que sobrevive ao app"
version: 1
---

**No iOS você registra uma tarefa por nome, pede que ela rode não antes de algum horário e termina
antes do prazo do sistema; o sistema escolhe o momento.** O framework é o `BackgroundTasks`, e ele
tem os dois tipos de tarefa da primeira seção: `BGAppRefreshTask`, com uns trinta segundos, e
`BGProcessingTask`, para trabalho mais longo que o sistema roda quando o celular está ocioso.

*As listagens desta seção não foram rodadas para este curso: o Xcode e o simulador do iOS só rodam
num Mac, e o curso foi gravado em Linux. Elas seguem a documentação da Apple para o
`BackgroundTasks` e o `URLSession`.*

## Declare

O nome da tarefa vai no `Info.plist` do app, e o modo de atualização nos modos de segundo plano
dele; o sistema se recusa a agendar um nome que não encontra ali:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>org.example.planner.refresh</string>
</array>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
</array>
```

## Registrar, pedir, terminar

```swift
import BackgroundTasks

// In application(_:didFinishLaunchingWithOptions:), before it returns.
BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.example.planner.refresh", using: nil) { task in
    handleRefresh(task as! BGAppRefreshTask)
}

func scheduleRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "org.example.planner.refresh")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("could not schedule the refresh: \(error)")
    }
}

func handleRefresh(_ task: BGAppRefreshTask) {
    scheduleRefresh()
    let sync = Task { await Planner.sync() }
    task.expirationHandler = { sync.cancel() }
    Task {
        await sync.value
        task.setTaskCompleted(success: !sync.isCancelled)
    }
}
```

Três coisas no `handleRefresh` não são opcionais.

- **Ele pede a próxima execução primeiro.** Um pedido de atualização é usado uma vez; um app que
  esquece de mandar outro não ganha mais atualizações.
- **O `expirationHandler` é o sistema dizendo que o tempo acabou.** Aqui ele cancela a
  sincronização, e `Planner.sync` precisa perceber o cancelamento entre os passos e parar com o
  progresso salvo.
- **O `setTaskCompleted` tem de ser chamado**, cedo ou tarde. O sistema mede como um app se comporta
  em segundo plano, e um que passa do tempo ou nunca avisa ganha menos chances.

Um app SwiftUI pode escrever o mesmo tratamento como um modificador de cena,
`.backgroundTask(.appRefresh(...))`, cujo fecho é cancelado quando o tempo acaba.

## Uploads que sobrevivem ao app

Trinta segundos é pouco para mandar uma foto anexada a uma sessão. Para isso, o iOS tem o
**`URLSession` em segundo plano**: o app entrega uma transferência ao sistema, e o sistema a leva
adiante enquanto o app está suspenso ou até depois de ele ter sido encerrado, e então acorda o app
para dizer como foi.

```swift
let config = URLSessionConfiguration.background(withIdentifier: "org.example.planner.uploads")
let session = URLSession(configuration: config, delegate: uploader, delegateQueue: nil)
session.uploadTask(with: request, fromFile: photoURL).resume()
```

O upload precisa vir de um arquivo, porque o app pode não estar vivo para entregar bytes, e os
resultados chegam pelo `delegate`. A exceção é a da primeira seção: quem arrasta o app para fora
cancelou também as transferências em segundo plano dele.
