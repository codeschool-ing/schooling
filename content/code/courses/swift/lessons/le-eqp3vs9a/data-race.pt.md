---
title: Uma corrida de dados, e um total errado
version: 1
---

A aula 14 rodou trabalho lado a lado e toda resposta saiu certa, porque cada tarefa ficava nos
próprios dados. **Uma corrida de dados é duas threads mexendo na mesma memória ao mesmo tempo, com
pelo menos uma delas escrevendo.** Em geral ela não quebra o programa nem se anuncia: produz um número
errado por uma quantidade que muda a cada execução.

Aqui está o total semanal do planner, uma classe da aula 5 com um `var`, somado por oito tarefas ao
mesmo tempo, cem mil minutos cada uma:

```swift
// Race.swift
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
ana@vm:~/sw/l15$ swiftc Race.swift -o race && ./race
expected 800000, got 677275
expected 800000, got 800000
expected 800000, got 800000
```

**Compilou sem uma palavra, e a primeira execução perdeu 122.725 minutos.** A máquina em que o curso
foi gravado tem quatro núcleos, então até quatro das oito tarefas rodaram no mesmo instante.
`minutes += m` parece um passo e são três: ler `minutes`, somar um, escrever de volta. Quando duas
threads leem 41, as duas somam um e as duas escrevem 42, um minuto se perde, e a primeira execução
perdeu esse tanto deles.

**As outras duas execuções saíram certas, e isso é o pior de uma corrida de dados.** O mesmo
programa, sem mudança nenhuma, deu uma resposta errada e depois duas certas, numa única execução do
programa. Rode na sua máquina e os números serão outros. Um teste deste programa poderia passar na
terça e falhar na quinta, e nada na saída aponta a linha responsável.

## O mesmo arquivo em Swift 6

A aula 1 mediu que o `swiftc` compila no **modo de linguagem Swift 5** a menos que se diga outra
coisa, e nesse modo o compilador verifica muito pouco sobre concorrência. O `-swift-version 6` liga o
modo Swift 6, e o modo Swift 6 trata uma corrida de dados como erro:

```
ana@vm:~/sw/l15$ swiftc -swift-version 6 Race.swift -o race
Race.swift:11:19: error: passing closure as a 'sending' parameter risks causing data races between code in the current isolation context and concurrent execution of the closure [#RegionIsolation::SendingClosureRisksDataRace]
 9 |     await withTaskGroup(of: Void.self) { group in
10 |         for _ in 1...8 {
11 |             group.addTask {
   |                   `- error: passing closure as a 'sending' parameter risks causing data races between code in the current isolation context and concurrent execution of the closure [#RegionIsolation::SendingClosureRisksDataRace]
12 |                 for _ in 1...100_000 {
13 |                     week.add(1)
   |                          `- note: closure captures 'week' which is accessible to code in the current isolation context
14 |                 }
15 |             }

[#RegionIsolation]: <https://docs.swift.org/compiler/documentation/diagnostics/region-isolation>
[#SendingClosureRisksDataRace]: <https://docs.swift.org/compiler/documentation/diagnostics/sending-closure-risks-data-race>
```

O erro está no vocabulário do resto desta aula, e vale lê-lo devagar. O `addTask` recebe a closure
como parâmetro **`sending`**: a closure sai do contexto atual e roda concorrentemente com ele. A nota
diz por que isso é inseguro aqui: a closure **captura `week`**, que o código fora da closure também
alcança. Dois lugares alcançam um mesmo `WeekTotal`, e `WeekTotal` tem um `var` e nenhuma proteção.
**O compilador achou a corrida lendo o programa**, algo que nenhum teste do `Race.swift` consegue
fazer com segurança.

As próximas três seções são as três saídas: entregar o estado a um **ator**, o que a seção 03 faz;
tornar `Sendable` o que passa entre tarefas, o que a seção 05 explica; ou manter o trabalho num único
ator, o **ator principal**, seção 06.
