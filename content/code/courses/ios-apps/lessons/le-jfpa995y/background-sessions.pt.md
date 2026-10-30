---
title: URL sessions de segundo plano, transferências que o sistema termina
version: 1
---

**Um `URLSession` de segundo plano entrega a transferência ao sistema, que segue com ela enquanto o app
está suspenso, ou mesmo depois de ele ter sido tirado da memória.** É o único jeito de um app mover um
arquivo grande sem estar acordado o tempo todo, e funciona de forma diferente de tudo na aula 12. Esta
seção foi escrita a partir da documentação da Apple para `URLSessionConfiguration.background(withIdentifier:)`
e *Downloading files in the background*, e **não foi executada**: sessões de segundo plano pertencem à
implementação própria da Apple, não ao Foundation do Linux.

## O que muda

Uma sessão de segundo plano é feita a partir de uma configuração com identificador próprio, e as
transferências dela são **tarefas com um delegate**, não chamadas com `await`:

```swift
// Exporter.swift
import Foundation

final class Exporter: NSObject, URLSessionDownloadDelegate {
    static let sessionID = "com.example.planner.export"

    lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionID)
        config.isDiscretionary = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    func download(_ url: URL) {
        session.downloadTask(with: url).resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        // Move the file out of `location` now: the system deletes it when this returns.
    }
}
```

**Os métodos `async` da aula 12 não são a interface aqui.** Um `await` mantém uma função esperando na
memória do app, e uma sessão de segundo plano existe justamente para o caso em que o app não está mais
na memória. Então o sistema termina a transferência, abre o app em segundo plano se precisar, e chama o
delegate. O `isDiscretionary` deixa o sistema escolher um bom momento, Wi-Fi e energia, para uma
transferência que não é urgente.

O SwiftUI tem um tipo de tarefa para essa reabertura, `.backgroundTask(.urlSession(Exporter.sessionID))`,
em que o app recria a sessão com o mesmo identificador para o sistema conseguir entregar os eventos que
guardou.

## Se o planner precisa de uma

**Não para as sessões dele.** Cada uma tem algumas dezenas de bytes, uma sessão de segundo plano é
feita para arquivos, e os pedidos comuns da seção 07 dentro de uma tarefa de atualização têm o tamanho
certo para o trabalho. A exportação da seção 04 é onde um planner usaria uma: o app pede ao servidor um
ano de estudo como arquivo, a pessoa fecha o app, e o arquivo está lá quando ela volta.
