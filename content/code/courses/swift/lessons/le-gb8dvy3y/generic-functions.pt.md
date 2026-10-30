---
title: Uma função para todo tipo
version: 1
---

O planner precisa da primeira e da última sessão de uma semana, e do primeiro e do último curso de
uma trilha. Escrito do jeito simples, isso dá duas funções com o mesmo corpo e tipos diferentes na
assinatura, e uma terceira no dia em que alguém precisar dela para datas. **Uma função genérica é
escrita uma vez com um marcador no lugar do tipo, e o compilador preenche o marcador em cada
chamada.**

```swift
// Generic.swift
func firstAndLast<T>(_ items: [T]) -> (first: T, last: T)? {
    guard let first = items.first, let last = items.last else { return nil }
    return (first, last)
}

let minutes = [45, 30, 60, 90]
let courses = ["Swift", "Kotlin", "SQL"]

if let ends = firstAndLast(minutes) { print(ends.first, ends.last) }
if let ends = firstAndLast(courses) { print(ends.first, ends.last) }
print(firstAndLast([Double]()) as Any)
```

```
ana@vm:~/sw/l09$ swift Generic.swift
45 90
Swift SQL
nil
```

O `<T>` depois do nome declara um **parâmetro de tipo** chamado `T`. Dentro da função, `T` representa
um tipo, o mesmo em todo lugar em que aparece, então os elementos do array e os dois valores
devolvidos têm o mesmo tipo. Na primeira chamada `T` é `Int`, porque `minutes` é um `[Int]`; na
segunda é `String`. Ninguém escreveu nenhum dos dois: **o compilador infere o parâmetro de tipo a
partir dos argumentos**, do jeito que a lição 1 mostrou ele inferir o tipo de um `let`. A terceira
chamada passa um array vazio de `Double`, e a função devolve `nil`, como diz o `guard` da lição 2.

`T` é só uma convenção. A biblioteca padrão escreve `Element` para o que uma coleção guarda e
`Value` para o que um dicionário mapeia, e um nome que diz para que serve o tipo se lê melhor que uma
letra quando há mais de um.

## Genérica, e ainda verificada

Um marcador não é "qualquer tipo, decidido na execução". Cada chamada é verificada com o tipo real,
então `let n: Int = firstAndLast(courses)!.first` é recusado, já que o `T` dessa chamada é `String`.
**A segurança da lição 1 sobrevive**: um corpo, e cada uso dele com tipo exato.

## O que um marcador não sabe

Dentro da função, `T` pode ser qualquer coisa, então o corpo só pode fazer com um `T` o que se pode
fazer com todo tipo: guardar, repassar, devolver. Comparar dois deles não está nessa lista:

```swift
// Largest.swift
func largest<T>(_ items: [T]) -> T? {
    var best = items.first
    for item in items where item > best! {
        best = item
    }
    return best
}
```

```
ana@vm:~/sw/l09$ swiftc Largest.swift -o largest
Largest.swift:4:34: error: binary operator '>' cannot be applied to two 'T' operands
2 | func largest<T>(_ items: [T]) -> T? {
3 |     var best = items.first
4 |     for item in items where item > best! {
  |                                  `- error: binary operator '>' cannot be applied to two 'T' operands
5 |         best = item
6 |     }
```

O compilador não está dizendo que `>` é errado para números. Está dizendo que alguns tipos não têm
`>` nenhum, entre eles a classe `Note` de um planner, e esta função prometeu funcionar para todo
tipo. A seção 03 acrescenta a promessa que torna a comparação legal.
