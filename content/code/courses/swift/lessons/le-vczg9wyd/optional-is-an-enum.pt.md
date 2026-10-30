---
title: Um opcional é um enum
version: 1
---

A lição 2 tratou o `Int?` como um tipo à parte, com sintaxe própria: `if let`, `??`, `!`. **Por baixo
da sintaxe, `Int?` é `Optional<Int>`, um enum da biblioteca padrão com dois casos**: `.none`, que é o
que `nil` quer dizer, e `.some(Int)`, que carrega o valor. Tudo o que a lição 2 mostrou é açúcar para
padrões sobre esse enum, e o enum puro continua lá para ser usado:

```swift
// Optional.swift
func parse(_ typed: String) -> Optional<Int> {
    Int(typed)
}
for typed in ["45", "forty"] {
    let minutes = parse(typed)
    switch minutes {
    case .some(let value):
        print("\(typed): some(\(value))")
    case .none:
        print("\(typed): none")
    }
    switch minutes {
    case let value? where value > 30:
        print("  a long session")
    case let value?:
        print("  \(value) minutes")
    case nil:
        print("  nothing typed that is a number")
    }
}
let spelled: Optional<Int> = .some(30)
let sugared: Int? = 30
print(spelled == sugared)
```

```
ana@vm:~/sw/l07$ swift Optional.swift
45: some(45)
  a long session
forty: none
  nothing typed that is a number
true
```

O primeiro switch nomeia os dois casos com todas as letras. O segundo usa as formas que você vai
encontrar em código real: **`let value?` é um padrão que quer dizer `.some(let value)`**, e `nil`
num padrão quer dizer `.none`. Os dois switches são exaustivos com dois tipos de caso, porque o enum
tem exatamente dois.

`Optional<Int>` e `Int?` são o mesmo tipo escrito de dois jeitos, e `.some(30)` e `30` o mesmo valor;
a última linha os compara e imprime `true`. Escrever `30` onde se espera um `Int?` funciona porque o
compilador o embrulha em `.some` para você, a única conversão que o Swift faz sem ser pedido.

## Por que isso importa

Isso explica toda regra que a lição 2 precisou enunciar. Uma função que recebe um `Int` não pode
receber um `Int?`, porque são tipos diferentes: um é um número e o outro é um enum que pode guardar
um. O `!` é "suponha `.some` e quebre no `.none`". O `??` é um switch com um padrão para o `.none`.
**Não existe null especial no Swift**, só mais um enum, e toda ferramenta que esta lição lhe deu para
enums funciona nele.
