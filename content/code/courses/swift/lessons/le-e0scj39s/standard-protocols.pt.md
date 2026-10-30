---
title: Protocolos que a biblioteca padrão já tem
version: 1
---

A maioria dos protocolos a que um programa Swift conforma foi escrita por outra pessoa. Quatro deles
aparecem em quase todo tipo do planner, e o compilador escreve o código de três deles a menos que
você peça outra coisa:

| protocolo | o que dá | escrito por |
|---|---|---|
| `Equatable` | `==` e `!=` | o compilador, comparando toda propriedade armazenada |
| `Hashable` | um hash, para o valor poder ser elemento de um `Set` ou chave de dicionário | o compilador, a partir de toda propriedade armazenada |
| `Comparable` | `<`, e com ele `sorted()`, `min()`, `max()` | você: só você sabe o que "menor" quer dizer |
| `CustomStringConvertible` | o que o `print` mostra | você, por meio de `description` |

```swift
// Session.swift
struct StudySession: Hashable, Comparable, CustomStringConvertible {
    var course: String
    var minutes: Int

    static func < (a: StudySession, b: StudySession) -> Bool { a.minutes < b.minutes }
    var description: String { "\(course) \(minutes) min" }
}

let a = StudySession(course: "Swift", minutes: 45)
let b = StudySession(course: "Swift", minutes: 45)
let c = StudySession(course: "Kotlin", minutes: 30)
print(a == b, a == c, a < c)
print(Set([a, b, c]).count)
print([a, c].sorted())
print(a)
```

```
ana@vm:~/sw/l08$ swift Session.swift
true false false
2
[Kotlin 30 min, Swift 45 min]
Swift 45 min
```

`a == b` dá `true` embora ninguém tenha escrito `==`: **o `Equatable` sintetizado compara toda
propriedade armazenada**, e as duas batem. O `Hashable` foi sintetizado do mesmo jeito, então o
conjunto de três sessões guarda duas, já que `a` e `b` são iguais. O `Comparable` precisou de uma
função, `<`, escrita como `static func` porque um operador pertence ao tipo e não a um valor; o
`sorted()` então funciona sem argumento. O `description` decidiu o que o `print` mostrou, para a
sessão sozinha e para cada elemento do array.

## Quando o compilador não escreve

A síntese exige que toda propriedade armazenada já conforme. Uma propriedade cujo tipo não pode ser
comparado torna impossível escrever o `==` automaticamente, e o compilador diz qual propriedade é a
culpada:

```swift
// NoteRef.swift
final class Note {
    var text = ""
}

struct StudySession: Equatable {
    var minutes: Int
    var note: Note
}
```

```
ana@vm:~/sw/l08$ swiftc NoteRef.swift -o noteref 2>&1 | head -13
NoteRef.swift:6:8: error: type 'StudySession' does not conform to protocol 'Equatable'
 4 | }
 5 | 
 6 | struct StudySession: Equatable {
   |        |- error: type 'StudySession' does not conform to protocol 'Equatable'
   |        `- note: add stubs for conformance
 7 |     var minutes: Int
 8 |     var note: Note
   |         `- note: stored property type 'Note' does not conform to protocol 'Equatable', preventing synthesized conformance of 'StudySession' to 'Equatable'
 9 | }
10 | 

Swift.==:1:24: note: candidate would match if 'StudySession' conformed to 'RawRepresentable'
ana@vm:~/sw/l08$ swiftc NoteRef.swift -o noteref 2>&1 | wc -l
63
```

O compilador imprime muito mais do que isso, e o `head -13` guarda a parte que vale ler; o `wc -l`
conta a mensagem inteira. Depois das linhas mostradas vêm notas sobre todos os outros `==` da
biblioteca padrão que poderiam ter servido, uma por protocolo, e a última delas nomeia o próprio
requisito. A nota a ler é a que aponta para a linha 8: **a propriedade armazenada `note` é o que
impede a síntese.**

`Note` é uma classe sem `==`, e a aula 5 explica por que duas instâncias de classe não têm um
significado óbvio para "igual". A correção é fazer `Note` conformar, ou escrever você mesmo o `==` da
sessão e dizer o que igualdade significa para ela, por exemplo os mesmos minutos e o mesmo texto.

## Igual é decisão sua

O `==` sintetizado é um bom padrão e nem sempre a resposta certa. Duas sessões com o mesmo curso e os
mesmos minutos, em dias diferentes, são iguais para ele. **Se um tipo tem identidade, como um `id`,
a igualdade pode ser sobre isso e mais nada**, e aí você escreve `==` e `hash(into:)`, usando as mesmas
propriedades nos dois. Valores iguais precisam ter o mesmo hash, ou um `Set` perde a conta deles.
