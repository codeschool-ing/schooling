---
title: Uma tarefa de atualização, do pedido ao handler
version: 1
---

**Uma tarefa de atualização tem três peças, e faltar qualquer uma falha sem mensagem.** O app declara
que pode atualizar em segundo plano, pede ao sistema para rodar uma tarefa com nome não antes de uma
data, e diz o que fazer quando a tarefa roda. Esta seção foi escrita a partir da documentação da Apple
para `BGAppRefreshTaskRequest`, `BGTaskScheduler` e o `backgroundTask(_:action:)` do SwiftUI, e **nada
dela foi executado**.

## A declaração

No Xcode, a aba *Signing & Capabilities* do target do app ganha a capacidade *Background Modes* com
*Background fetch* marcado, e o `Info.plist` lista todo identificador de tarefa que o app vai agendar,
em `BGTaskSchedulerPermittedIdentifiers`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Info.plist (the background keys only) -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>BGTaskSchedulerPermittedIdentifiers</key>
    <array>
        <string>com.example.planner.refresh</string>
    </array>
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
    </array>
</dict>
</plist>
```

O identificador é DNS invertido como o bundle identifier da aula 1, e por convenção começa por ele.
**Um identificador que não está nesta lista não pode ser agendado**: a documentação da Apple para o
erro `notPermitted` dá exatamente duas causas, um identificador faltando neste array e um modo de
segundo plano faltando no outro.

## O pedido

O app pede a próxima atualização sempre que o plano muda e quando vai para o segundo plano:

```swift
// Refresh.swift
import BackgroundTasks
import PlannerCore

let refreshID = "com.example.planner.refresh"

func scheduleRefresh(pending: Int) {
    let request = BGAppRefreshTaskRequest(identifier: refreshID)
    request.earliestBeginDate = nextRefresh(after: .now, pending: pending, calendar: .current)
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("could not schedule a refresh:", error)
    }
}
```

`nextRefresh` é a função da seção 06, do pacote do planner. **Um pedido não é uma promessa**: o
`earliestBeginDate` só diz que a tarefa não pode rodar antes disso. Enviar um pedido novo com o mesmo
identificador substitui o antigo, então pedir de novo sempre que algo muda é seguro.

## O handler

O SwiftUI prende o trabalho à cena do app, com o mesmo identificador:

```swift
// PlannerApp.swift
import SwiftUI
import PlannerCore

@main
struct PlannerApp: App {
    let repository: PlannerRepository
    @State private var model: PlannerModel

    init() {
        let api = APIClient(base: URL(string: "https://planner.example.com")!)
        let file = URL.applicationSupportDirectory.appending(path: "planner.json")
        let repository = try! PlannerRepository(source: api, store: FileStore(url: file))
        self.repository = repository
        _model = State(initialValue: PlannerModel(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            CourseListView(model: model)
        }
        .backgroundTask(.appRefresh(refreshID)) {
            _ = await repository.syncUntilCancelled()
            try? await repository.refresh()
            scheduleRefresh(pending: await repository.pendingCount)
        }
    }
}
```

**O handler é uma closure `async`, e a tarefa termina quando ela retorna.** A documentação da Apple
para o `backgroundTask(_:action:)` diz que o sistema cancela a tarefa se a closure não tiver retornado
quando o tempo dela acabar, e sugere `withTaskCancellationHandler` para perceber. Esse cancelamento é
o cancelamento comum de tarefas do Swift, e é por isso que a seção 07 consegue praticar a expiração
inteira no Linux: ela cancela uma tarefa e vê o que sobrevive.

O handler agenda a próxima atualização antes de retornar, porque uma tarefa de atualização roda uma
vez. Um app que esquece essa linha atualiza em segundo plano exatamente uma vez.

O modelo fica num `@State` para ser criado uma vez, e não a cada avaliação do `body`; a aula 6 trata
de por que isso importa. O `try!` no `init` é um atalho de rascunho: um planner que não consegue ler o
próprio arquivo ao abrir não tem nada para mostrar, e a aula 14 é onde essa falha é tratada direito.
