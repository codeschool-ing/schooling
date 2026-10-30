---
title: guard let, e a saída antecipada
version: 1
---

O `if let` põe o caso bom dentro de chaves. Quando uma função não consegue fazer nada útil sem o
valor, isso aninha a função inteira um nível a mais, e uma segunda verificação aninha de novo. **O
`guard let` inverte: trata o caso ruim primeiro, sai, e o nome desempacotado fica para o resto da
função.**

```swift
// GuardLet.swift
func minutes(from typed: String) -> Int {
    guard let value = Int(typed) else {
        print("not a number: \(typed)")
        return 0
    }
    guard value > 0 else {
        print("not positive: \(value)")
        return 0
    }
    return value
}
print(minutes(from: "45"))
print(minutes(from: "forty"))
print(minutes(from: "-5"))
```

```
ana@vm:~/sw/l02$ swift GuardLet.swift
45
not a number: forty
0
not positive: -5
0
```

Leia a função de cima para baixo e a forma é uma lista de condições, cada uma com sua saída, e depois o
trabalho. `value` foi desempacotado pelo primeiro `guard` e é usado pelo segundo e por `return value`,
**fora de qualquer chave própria**. Essa é a diferença para o `if let`, em que o nome termina na chave
que fecha.

## O else precisa sair

Um `guard` existe para impedir que o código abaixo dele rode com um valor ruim, então o compilador
confere que o `else` sai de verdade. Esqueça o `return` e ele recusa:

```swift
// FallThrough.swift
func minutes(from typed: String) -> Int {
    guard let value = Int(typed) else {
        print("not a number: \(typed)")
    }
    return value
}
print(minutes(from: "45"))
```

```
ana@vm:~/sw/l02$ swiftc FallThrough.swift -o fallthrough
FallThrough.swift:5:5: error: 'guard' body must not fall through, consider using a 'return' or 'throw' to exit the scope
3 |     guard let value = Int(typed) else {
4 |         print("not a number: \(typed)")
5 |     }
  |     `- error: 'guard' body must not fall through, consider using a 'return' or 'throw' to exit the scope
6 |     return value
7 | }
```

`return` é uma saída de uma função, e a mensagem cita `throw` como a outra, que a lição 12 explica.
Dentro de um laço, `continue` e `break` também contam. **O que não conta é imprimir uma mensagem e
seguir em frente**, porque aí `value` seria usado abaixo sem valor nenhum dentro, que é justamente o
bug que o `guard` existe para impedir.

## Qual usar

| quando | escreva |
|---|---|
| o valor é necessário por algumas linhas e depois não | `if let` |
| a função não consegue continuar sem ele | `guard let … else { return }` |
| os dois casos fazem trabalho de verdade | `if let … else` |

As três formas compilam para a mesma verificação. A escolha é sobre o que quem lê vê primeiro: com
`guard`, os jeitos de a função desistir estão no topo, um por linha, e o resto da função é o caso que
importa.
