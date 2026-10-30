---
title: if let, para um valor que pode estar lá
version: 1
---

A primeira resposta para "e se for nil?" é a que você vai escrever mais: **verificar e, dentro da
verificação, usar um valor simples.** `if let minutes = Int(typed)` faz as duas coisas de uma vez. Se
`Int(typed)` tem um número, `minutes` é esse número, um `Int` e não um `Int?`, no corpo do `if`. Se é
`nil`, o corpo é pulado e o `else` roda no lugar.

Uma estudante digitou três durações no planner, e uma delas é uma palavra:

```swift
// IfLet.swift
let entries = ["45", "forty", "30"]
var total = 0
for typed in entries {
    if let minutes = Int(typed) {
        total += minutes
        print("added \(minutes)")
    } else {
        print("skipped \(typed)")
    }
}
print("total \(total)")
```

```
ana@vm:~/sw/l02$ swift IfLet.swift
added 45
skipped forty
added 30
total 75
```

`for typed in entries` roda o corpo uma vez para cada string do array, com `typed` valendo cada uma
por vez; a aula 4 é sobre arrays. Dentro do `if`, `total += minutes` compila porque `minutes` é um
`Int`. Escreva `total += Int(typed)` no lugar e o compilador recusa, pelo motivo que a seção 02 deu:
um `Int?` não tem `+=` com um `Int`.

**O nome desempacotado só existe dentro das chaves.** Depois da chave que fecha, `minutes` some, e só
`typed` e `total` ficam. É essa propriedade que torna o `if let` seguro: não há linha nenhuma do
programa em que `minutes` possa ser `nil`.

## A forma curta

Muitas vezes o opcional já tem um bom nome, e inventar um segundo não acrescenta nada. **`if let note`
desempacota `note` num valor simples com o mesmo nome**, durante as chaves:

```swift
// Shorthand.swift
let note: String? = "read chapter 3"
if let note {
    print("note has \(note.count) characters")
}
let goal: Int? = nil
if let goal {
    print("goal is \(goal)")
} else {
    print("no goal set")
}
```

```
ana@vm:~/sw/l02$ swift Shorthand.swift
note has 14 characters
no goal set
```

Dentro do primeiro `if`, `note` é uma `String`, e `note.count` compila. Fora dele, o mesmo nome é a
`String?` que sempre foi. A forma curta chegou no Swift 5.7, então código mais antigo que você ler a
escreve por extenso, `if let note = note`, que quer dizer exatamente o mesmo.

## Vários de uma vez

Uma sessão precisa de um início e de um fim que sejam números, e do fim depois do início. Vírgulas
juntam as condições, e **todas precisam dar certo** para o corpo rodar:

```swift
// Several.swift
func duration(start: String, end: String) {
    if let from = Int(start), let to = Int(end), to > from {
        print("\(to - from) minutes")
    } else {
        print("cannot read \(start)-\(end)")
    }
}
duration(start: "600", end: "645")
duration(start: "600", end: "noon")
duration(start: "645", end: "600")
```

```
ana@vm:~/sw/l02$ swift Several.swift
45 minutes
cannot read 600-noon
cannot read 645-600
```

As condições são lidas da esquerda para a direita, e cada uma pode usar os nomes desempacotados antes
dela: `to > from` compara dois `Int` porque os dois `let` já deram certo. A primeira que falha manda o
`if` inteiro para o `else`. A função recebe os rótulos `start:` e `end:` na chamada, que a aula 3
explica.
