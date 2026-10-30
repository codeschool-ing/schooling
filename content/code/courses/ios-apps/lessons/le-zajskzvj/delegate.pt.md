---
title: O delegate, para os dois momentos em que o app participa
version: 1
---

**Na maior parte do tempo o sistema mostra uma notificação sem o app; há dois momentos em que ele
pergunta ao app.** Um é uma notificação chegando enquanto o app já está aberto na tela. O outro é a
pessoa tocando numa notificação. Os dois são métodos de `UNUserNotificationCenterDelegate`, e um app que
nunca define um delegate recebe o padrão do sistema para cada um. Nada nesta seção foi executado; ela
segue a documentação da Apple para esse protocolo e para o `UIApplicationDelegateAdaptor`, lida em 30 de
outubro de 2026.

## Onde um delegate mora num app SwiftUI

Um app SwiftUI não tem app delegate a não ser que peça um. O `UIApplicationDelegateAdaptor` é como ele
pede: o SwiftUI cria o delegate e chama os métodos dele. A documentação da Apple diz para declará-lo uma
vez, no `App`, e que declará-lo mais de uma vez é um erro em tempo de execução. O delegate do planner se
põe como delegate da central de notificações na abertura, o que tem de acontecer antes de o app terminar
de abrir para que um toque que abriu o app chegue até ele:

```swift
// AppDelegate.swift
import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var openSession: (String) -> Void = { _ in }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // The app is on screen: show the banner anyway, without the sound
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }

    // The person tapped it: open the session it is about
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let id = response.notification.request.identifier
        if id.hasPrefix("reminder-") {
            openSession(String(id.dropFirst("reminder-".count)))
        }
    }
}
```

```swift
// PlannerApp.swift, with the delegate
@main
struct PlannerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            CourseListView()
        }
    }
}
```

## Enquanto o app está aberto

A documentação da Apple para `userNotificationCenter(_:willPresent:)` é precisa sobre o padrão, e ele
surpreende: **se o delegate não implementa o método, o sistema age como se ele tivesse respondido
"nenhum"**, e um lembrete que chega com o planner aberto não aparece. O planner responde `.banner` e
`.list`: o banner aparece sobre o app e a notificação fica na Central de Notificações, sem som, porque o
estudante já está olhando o app de que o lembrete trata.

## Quando ela é tocada

O `userNotificationCenter(_:didReceive:)` recebe a resposta, que carrega a notificação original e o
pedido dela. **O identificador do pedido é o endereço**, e é por isso que a seção 03 o fez `reminder-` e
o id da sessão: o delegate lê o id de volta e abre o curso daquela sessão. O `openSession` é definido
pela view raiz do app, que é dona do caminho de navegação que a aula 9 construiu, então o delegate não
precisa saber de telas.

A documentação acrescenta que esse método também recebe as ações personalizadas, botões na notificação
como "Mark done", declarados com `UNNotificationCategory` e `UNNotificationAction`, e que um app que não
o implementa nunca responde a elas. O planner não tem nenhuma; um botão "Mark done" que mudasse o plano
sem abrir o app é um próximo passo razoável, e ele chegaria aqui.

## Uma string que também é um protocolo

O `hasPrefix("reminder-")` tira sentido de um identificador, o que este curso evita em outros lugares: o
identificador é uma convenção do próprio planner, escrita numa função e lida em outra. Se um segundo tipo
de notificação for acrescentado, a versão honesta é um pequeno enum com uma função que escreve o
identificador e uma que o interpreta, testadas no pacote como os deep links da aula 9.
