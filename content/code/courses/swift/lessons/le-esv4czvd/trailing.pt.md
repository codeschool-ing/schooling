---
title: Closures no fim da chamada
version: 1
---

Quando o último argumento de uma chamada é uma closure, o Swift deixa você **fechar os parênteses
antes e escrever a closure depois deles**. Isso se chama trailing closure, e é o motivo de a maior
parte do código Swift que passa uma função parecer um bloco de código em vez de uma lista de
argumentos.

```swift
// Trailing.swift
func repeatTwice(_ action: () -> Void) {
    action()
    action()
}
func applyAll(_ values: [Int], _ f: (Int) -> Int) -> [Int] {
    var out: [Int] = []
    for value in values {
        out.append(f(value))
    }
    return out
}
repeatTwice({ print("review chapter 3") })
repeatTwice {
    print("review chapter 4")
}
let doubled = applyAll([45, 30]) { $0 * 2 }
print(doubled)
```

```
ana@vm:~/sw/l03$ swift Trailing.swift
review chapter 3
review chapter 3
review chapter 4
review chapter 4
[90, 60]
```

`repeatTwice({ … })` e `repeatTwice { … }` são a mesma chamada. Quando a closure é o único argumento,
os parênteses somem de vez. `applyAll([45, 30]) { $0 * 2 }` mantém os parênteses para o primeiro
argumento e escreve a closure depois deles. `() -> Void` é o tipo de uma função que não recebe nada e
não devolve nada, que é o que uma ação é.

**Leia uma trailing closure como o último argumento**, não como um bloco que roda na hora. Se ela roda
agora, duas vezes, depois ou nunca, quem decide é a função que a recebeu. O `repeatTwice` a roda duas
vezes. O `map`, o `filter` e o `sorted` da aula 4 recebem closures escritas exatamente assim, e é
naquela aula que a forma se paga.

## Mais de uma

Uma função que recebe várias closures pode ter todas no fim. A primeira é escrita sem rótulo, e as
outras com os delas:

```swift
// TwoClosures.swift
func load(course: String, onSuccess: (Int) -> Void, onFailure: (String) -> Void) {
    if course == "Swift" {
        onSuccess(135)
    } else {
        onFailure("no sessions for \(course)")
    }
}
load(course: "Swift") { minutes in
    print("loaded \(minutes) minutes")
} onFailure: { message in
    print("failed: \(message)")
}
load(course: "Kotlin") { minutes in
    print("loaded \(minutes) minutes")
} onFailure: { message in
    print("failed: \(message)")
}
```

```
ana@vm:~/sw/l03$ swift TwoClosures.swift
loaded 135 minutes
failed: no sessions for Kotlin
```

A forma, uma closure para o sucesso e uma para a falha, é a que o código de rede mais antigo usava antes
de existir `async`/`await`, e a aula 14 parte dela. É também exatamente como os botões e as listas do
SwiftUI são escritos no `ios-apps`: `Button("Add") { … }` é uma chamada cujo último argumento é uma
trailing closure.
