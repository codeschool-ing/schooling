---
title: Tarefas de processamento, e o trabalho que a pessoa acompanha
version: 1
---

**Uma atualização é curta e frequente. Uma tarefa de processamento é longa e rara.** A documentação da
Apple descreve a `BGProcessingTask` como uma tarefa que pode levar minutos, agendada para períodos de
pouca atividade, como a madrugada enquanto o aparelho carrega, e é para lá que vai o trabalho que
seria indelicado em qualquer outra hora: reconstruir um índice, limpar dados velhos, migrar um
armazenamento. **Não executado**, como tudo nesta aula que pede tempo ao sistema.

## Pedindo uma

O pedido traz duas condições que o pedido de atualização não tem:

```swift
// Maintenance.swift
import BackgroundTasks

let maintenanceID = "com.example.planner.maintenance"

func scheduleMaintenance() {
    let request = BGProcessingTaskRequest(identifier: maintenanceID)
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = true
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("could not schedule maintenance:", error)
    }
}
```

`requiresExternalPower` pede ao sistema que espere um carregador, o que na prática quer dizer de
madrugada. `requiresNetworkConnectivity` é falso porque o trabalho é no aparelho. O identificador vai
em `BGTaskSchedulerPermittedIdentifiers` ao lado do da seção 03, e a capacidade precisa de *Background
processing* marcado além de *Background fetch*; o valor no `Info.plist` para ele é `processing`.

**O planner tem pouco que mereça uma.** O armazenamento dele é um arquivo pequeno. Uma tarefa de
processamento faz sentido num app com um banco de dados de verdade a compactar, um índice de busca a
reconstruir ou um modelo a retreinar, e o armazenamento SwiftData da aula 13, migrado depois de uma
atualização, é o mais perto que o planner chega. Pedir tempo de que o app não precisa custa bateria à
pessoa à toa, e o sistema percebe quais apps usam o tempo que recebem.

## Trabalho que a pessoa começa e acompanha

O outro caso longo é o oposto da manutenção de madrugada: a pessoa aperta *Exportar meu ano de
estudo* e troca de app. Do iOS 26 em diante, a documentação da Apple descreve a
`BGContinuedProcessingTaskRequest` para exatamente isso: uma tarefa enviada do primeiro plano, **como
resultado de algo que a pessoa fez**, que o sistema deixa continuar em segundo plano enquanto mostra o
progresso dela, e que a pessoa pode cancelar a partir dessa exibição. A documentação diz também que o
sistema pode encerrá-la sob pressão e encerra primeiro as tarefas que informam pouco ou nenhum
progresso, então informar progresso é parte do contrato, e não enfeite.

O planner tem como alvo o iOS 17, então não pode contar com isso, e ainda não tem nada que demore o
bastante para precisar. **A regra que ela enuncia vale ser guardada de qualquer jeito: trabalho longo
que a pessoa pediu deve mostrar progresso, e trabalho longo que ela não pediu deve esperar o
carregador.**
