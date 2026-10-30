---
title: Restrições dizem o que o tipo precisa saber fazer
version: 1
---

Uma **restrição** estreita um parâmetro de tipo aos tipos que conformam a um protocolo, e em troca o
corpo pode usar tudo o que esse protocolo exige. O `largest` precisa de `>`, que é o que o
`Comparable` oferece, então ele diz isso:

```swift
// Constrained.swift
func largest<T: Comparable>(_ items: [T]) -> T? {
    var best = items.first
    for item in items where item > best! {
        best = item
    }
    return best
}

print(largest([45, 30, 60, 90]) ?? 0)
print(largest(["Swift", "Kotlin", "SQL"]) ?? "")
print(largest([2.5, 0.75]) ?? 0)
```

```
ana@vm:~/sw/l09$ swift Constrained.swift
90
Swift
2.5
```

`<T: Comparable>` se lê "qualquer `T` que seja `Comparable`". O corpo compila agora, porque todo tipo
admitido tem um `>`. `Int`, `String` e `Double` conformam, e `"Swift"` é a maior string porque
strings se comparam letra a letra e o `W` vem depois do `Q`.

## A recusa muda para a chamada

A restrição não fez a verificação sumir. Ela a mudou do corpo para cada chamada, onde o tipo é
conhecido:

```swift
// NotComparable.swift
final class Note {
    var text = ""
}

func largest<T: Comparable>(_ items: [T]) -> T? { items.max() }

print(largest([Note(), Note()]) as Any)
```

```
ana@vm:~/sw/l09$ swiftc NotComparable.swift -o notcomparable
NotComparable.swift:8:7: error: global function 'largest' requires that 'Note' conform to 'Comparable'
4 | }
5 | 
6 | func largest<T: Comparable>(_ items: [T]) -> T? { items.max() }
  |      `- note: where 'T' = 'Note'
7 | 
8 | print(largest([Note(), Note()]) as Any)
  |       `- error: global function 'largest' requires that 'Note' conform to 'Comparable'
9 | 
```

**O erro nomeia o requisito e o tipo que não o cumpre**, e a nota mostra o que `T` foi inferido como.
Uma restrição é um contrato com dois lados: a função pode usar `>`, e quem chama precisa trazer um
tipo que o tenha. A conformidade a `Comparable` da aula 8 é como um tipo do planner entra.

## where, para contratos mais longos

Algumas condições são sobre tipos ligados ao parâmetro, e não sobre o próprio parâmetro. Um total da
semana deveria aceitar qualquer coleção de inteiros, um array, um conjunto ou um intervalo, e nada
mais:

```swift
// WeekTotal.swift
func weekTotal<C: Collection>(_ sessions: C) -> Int where C.Element == Int {
    sessions.reduce(0, +)
}

print(weekTotal([45, 30, 60, 90]))
print(weekTotal(Set([45, 30])))
print(weekTotal(1...4))
```

```
ana@vm:~/sw/l09$ swift WeekTotal.swift
225
75
10
```

`C: Collection` deixa a função percorrer o argumento; a cláusula `where` acrescenta que o `Element`
da coleção precisa ser `Int`. `Element` é um **tipo associado** de `Collection`, um tipo que cada
coleção decide para si, e a seção 05 escreve um protocolo com um deles. Uma cláusula `where` pode ter
várias condições separadas por vírgulas, e é também como as extensões condicionais da aula 8 foram
escritas.
