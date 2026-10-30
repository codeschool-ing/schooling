---
title: Modos de linguagem, e como ligar as verificações
version: 1
---

Tudo o que esta aula recusou, recusou no **modo de linguagem Swift 6**. O mesmo compilador tem um
**modo Swift 5**, e a seção 02 mostrou quanto isso custa: o `Race.swift` compilou sem uma palavra e
contou errado. **O modo de linguagem é uma configuração do compilador, não uma versão dele.** O Swift
6.4.2 compila os dois, e qual vale é decidido por módulo.

| como você compila | modo de linguagem, se você não disser outro |
|---|---|
| `swift File.swift` ou `swiftc File.swift` | Swift 5 |
| `swiftc -swift-version 6 File.swift` | Swift 6 |
| um pacote cujo manifesto começa com `// swift-tools-version: 6.0` ou mais | Swift 6, em todo target |
| um pacote com tools version 5.x | Swift 5 |

Os modos existem porque as verificações do Swift 6 recusariam muito código escrito antes delas, e um
projeto de milhares de arquivos não se conserta numa tarde. Então um projeto muda quando está pronto,
um módulo por vez.

## Um pacote decide por você

A aula 19 é sobre pacotes; aqui está o menor deles, com o código do `Race.swift` como `main.swift`.
O manifesto declara tools version 6.0:

```swift
// swift-tools-version: 6.0
// Package.swift
import PackageDescription

let package = Package(
    name: "Race",
    targets: [
        .executableTarget(name: "Race")
    ]
)
```

```swift
// Sources/Race/main.swift
final class WeekTotal {
    var minutes = 0
    func add(_ m: Int) { minutes += m }
}

func countWeek() async -> Int {
    let week = WeekTotal()
    await withTaskGroup(of: Void.self) { group in
        for _ in 1...8 {
            group.addTask {
                for _ in 1...100_000 {
                    week.add(1)
                }
            }
        }
    }
    return week.minutes
}

for _ in 1...3 {
    print("expected 800000, got \(await countWeek())")
}
```

```
ana@vm:~/sw/l15/race$ swift build 2>&1 | grep -E '^/[^ ]+[.]swift:|^error: Build|^Build'
Building for debugging...
/home/ana/sw/l15/race/Sources/Race/main.swift:11:19: error: passing closure as a 'sending' parameter risks causing data races between code in the current isolation context and concurrent execution of the closure [#RegionIsolation::SendingClosureRisksDataRace]
error: Build failed
```

O `swift build` imprime muita coisa, inclusive a linha de comando inteira do compilador que falhou,
então o `grep` guarda os dois tipos de linha que valem a leitura: as que começam com o caminho de um
arquivo `.swift`, que são diagnósticos, e o veredito. **O mesmo erro da seção 02, sem ninguém pedir**,
porque tools version 6.0 quer dizer modo Swift 6.

Um target que não está pronto pode ser segurado, no manifesto, onde todo mundo vê:

```swift
// swift-tools-version: 6.0
// Package.swift
import PackageDescription

let package = Package(
    name: "Race",
    targets: [
        .executableTarget(
            name: "Race",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
```

```
ana@vm:~/sw/l15/race$ swift build 2>&1 | grep -E '^/[^ ]+[.]swift:|^error: Build|^Build'
Building for debugging...
Build complete! (1.51 secs)
ana@vm:~/sw/l15/race$ swift run Race 2>/dev/null
expected 800000, got 547351
expected 800000, got 431104
expected 800000, got 719980
```

Compila, roda, e erra de novo. **O `.swiftLanguageMode(.v5)` é uma dívida escrita**: um target que
diz que ainda não foi verificado. Passá-lo para Swift 6 significa remover a linha e consertar o que o
compilador então apontar, que é o trabalho que esta aula vem mostrando.

## O que o `swift package init` liga

O `swift package init`, o comando com que a aula 19 começa todo pacote, escreve um manifesto próprio,
e ele traz uma configuração a mais que os manifestos acima:

```
ana@vm:~/sw/l15/week$ swift package init --type library --name Week
Creating library package: Week
Creating Package.swift
Creating .gitignore
Creating Sources
Creating Sources/Week/Week.swift
Creating Tests/
Creating Tests/WeekTests/
Creating Tests/WeekTests/WeekTests.swift
ana@vm:~/sw/l15/week$ grep -n -A2 swiftSettings Package.swift
20:            swiftSettings: [
21-                .enableUpcomingFeature("ApproachableConcurrency"),
22-            ],
--
27:            swiftSettings: [
28-                .enableUpcomingFeature("ApproachableConcurrency"),
29-            ],
ana@vm:~/sw/l15/week$ head -1 Package.swift
// swift-tools-version: 6.4
```

O manifesto está em tools version 6.4, então os targets dele estão no modo Swift 6, e cada target tem
também `.enableUpcomingFeature("ApproachableConcurrency")`. Uma **upcoming feature** é uma mudança
planejada para um modo de linguagem futuro que um módulo pode adotar antes, um nome por vez. A
`ApproachableConcurrency` é um pacote de várias delas, acrescentado no Swift 6.2, que muda alguns
padrões para que código que roda num único ator precise de menos anotações. Ela não desliga nenhuma
verificação: uma corrida continua sendo erro. Quando um manifesto seu a traz, a linguagem é o modo
Swift 6 com esses padrões, e a documentação do Swift sobre concorrência lista o que cada uma dessas
features faz.

**O que fazer com tudo isso.** Escreva código novo no modo Swift 6, que um pacote em tools version 6
ou mais lhe dá sem pedir. Mantenha o `-swift-version 6` na linha de comando quando experimentar um
programa concorrente com o `swiftc`. E leia um erro de concorrência do Swift 6 como esta aula leu:
ele diz o que atravessa, de onde para onde, e o que mais ainda o alcança.
