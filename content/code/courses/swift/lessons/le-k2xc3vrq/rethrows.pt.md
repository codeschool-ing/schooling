---
title: rethrows, e defer para a saída
version: 1
---

Algumas funções só lançam porque uma closure que receberam lança. O `map` é uma delas: mapear com uma
closure que não falha não falha, e mapear com uma que pode, pode. **O `rethrows` diz exatamente
isso**: esta função só lança se a closure argumento lançar, e só os erros que a closure lança.

```swift
// Rethrows.swift
enum PlannerError: Error {
    case notANumber(String)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}

func total(_ texts: [String], reading read: (String) throws -> Int) rethrows -> Int {
    print("total: start")
    defer { print("total: leaving") }
    var sum = 0
    for text in texts {
        sum += try read(text)
    }
    return sum
}

print(total(["45", "30"], reading: { Int($0) ?? 0 }))
do {
    print(try total(["45", "forty", "30"], reading: parseMinutes))
} catch {
    print("caught:", error)
}
```

```
ana@vm:~/sw/l12$ swift Rethrows.swift
total: start
total: leaving
75
total: start
total: leaving
caught: notANumber("forty")
```

A primeira chamada passa `{ Int($0) ?? 0 }`, uma closure que não lança, e é escrita **sem `try`**,
porque o `rethrows` deixa o compilador ver que nada pode falhar. Ela imprimiu 75. A segunda passa
`parseMinutes`, uma função que lança, como closure, e precisa de `try` e de um `catch`: `"forty"`
lançou no meio do laço, e o erro pego é o que a `parseMinutes` lançou, sem mudança. `map`, `filter`,
`compactMap` e `sorted(by:)` são todas declaradas `rethrows`, e é por isso que o
`compactMap { try? … }` da seção 03 dispensou um `try` de fora, e um `map` com um `try` puro dentro
precisaria dele.

## O defer roda em toda saída

A `total` imprime `total: leaving` nas duas execuções, uma depois de um `return` normal e outra depois
do erro. **Um bloco `defer` roda quando o escopo em que está termina, seja como for**: um `return`, o
fim do bloco, ou um erro lançado através dele. É onde vai a limpeza, fechar um arquivo ou parar um
timer, para que um erro no meio do caminho não consiga pulá-la.

Dois detalhes valem saber. Um `defer` roda no fim do seu **escopo**, não da função, então um `defer`
dentro do corpo de um laço roda uma vez por volta. E vários blocos `defer` num escopo rodam em **ordem
inversa**, o último escrito primeiro, para que as coisas abertas por último sejam fechadas primeiro.
