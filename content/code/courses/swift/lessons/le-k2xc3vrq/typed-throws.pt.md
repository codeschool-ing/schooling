---
title: Throws com tipo
version: 1
---

O `throws` sozinho quer dizer "pode lançar qualquer erro". Por isso a seção 02 precisou de um `catch`
puro no fim, e por isso quem chama uma função que lança não sabe, pela declaração, para quais falhas
se preparar. **Desde o Swift 6, uma função pode nomear o único tipo que lança**, entre parênteses
depois da palavra: `throws(PlannerError)`. O compilador então cobra isso dos dois lados.

```swift
// Typed.swift
enum PlannerError: Error {
    case notANumber(String)
    case tooLong(minutes: Int)
}

func parseMinutes(_ text: String) throws(PlannerError) -> Int {
    guard let minutes = Int(text) else { throw .notANumber(text) }
    guard minutes <= 240 else { throw .tooLong(minutes: minutes) }
    return minutes
}

do {
    print(try parseMinutes("300"))
} catch {
    switch error {
    case .notANumber(let text): print("not a number: \(text)")
    case .tooLong(let minutes): print("\(minutes) minutes is longer than a study block")
    }
}
```

```
ana@vm:~/sw/l12$ swift Typed.swift
300 minutes is longer than a study block
```

Três coisas mudaram em relação à seção 02, e cada uma é o compilador usando o tipo que recebeu:

- **`throw .notANumber(text)`** dispensa o nome do tipo, porque o único tipo possível é
  `PlannerError`, como num `switch` sobre um enum;
- no `catch`, **`error` é um `PlannerError`**, não um `any Error`, então um `switch` pode listar os
  casos dele;
- **o `switch` não tem `default` e o `do` não tem segundo `catch`.** Os dois casos estão cobertos e o
  compilador sabe que não há mais nada, então a recusa da seção 02 não acontece.

A promessa vale no outro sentido também. Uma função que declara `PlannerError` e lança outra coisa não
compila:

```swift
// TypedWrong.swift
enum PlannerError: Error { case notANumber(String) }
struct NetworkDown: Error {}

func parseMinutes(_ text: String) throws(PlannerError) -> Int {
    guard let minutes = Int(text) else { throw NetworkDown() }
    return minutes
}
```

```
ana@vm:~/sw/l12$ swiftc TypedWrong.swift -o typedwrong
TypedWrong.swift:6:48: error: thrown expression type 'NetworkDown' cannot be converted to error type 'PlannerError'
4 | 
5 | func parseMinutes(_ text: String) throws(PlannerError) -> Int {
6 |     guard let minutes = Int(text) else { throw NetworkDown() }
  |                                                `- error: thrown expression type 'NetworkDown' cannot be converted to error type 'PlannerError'
7 |     return minutes
8 | }
```

## Quando nomear o tipo

Throws com tipo fazem um contrato com todo chamador, e um contrato é difícil de mudar: acrescente um
caso a `PlannerError`, ou comece a lançar um erro de rede da mesma função, e todo `switch` que listava
os casos para de compilar. **Nomeie o tipo quando o conjunto de falhas é fechado e pertence à
função**, como ler um número de minutos. Deixe o `throws` puro onde as falhas vêm de baixo e podem
crescer, como ler um arquivo ou chamar um servidor, que podem falhar de jeitos que nenhum enum seu vai
listar. A SE-0413, a proposta do Swift que introduziu throws com tipo, diz o mesmo: o `throws` sem
tipo continua sendo o melhor padrão para a maior parte do código.
