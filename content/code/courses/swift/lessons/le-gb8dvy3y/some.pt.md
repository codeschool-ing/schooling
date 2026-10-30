---
title: some, um tipo que quem chama não precisa conhecer
version: 1
---

Uma função que devolve uma sequência preguiçosa das sessões longas da semana tem um tipo de retorno
que ninguém quer escrever: `LazyFilterSequence<LazyMapSequence<Array<StudySession>, Int>>`, e ele muda
sempre que o corpo muda. **`some Protocolo` como tipo de retorno diz: um tipo específico, escolhido por
esta função, que conforma ao protocolo, e que quem chama não precisa conhecer.**

```swift
// Some.swift
struct StudySession {
    var course: String
    var minutes: Int
}

let week = [StudySession(course: "Swift", minutes: 45),
            StudySession(course: "SQL", minutes: 90),
            StudySession(course: "Swift", minutes: 60)]

func longMinutes(_ sessions: [StudySession]) -> some Sequence<Int> {
    sessions.lazy.map(\.minutes).filter { $0 >= 60 }
}

let long = longMinutes(week)
print(Array(long))
print(type(of: long))
```

```
ana@vm:~/sw/l09$ swift Some.swift
[90, 60]
LazyFilterSequence<LazyMapSequence<Array<StudySession>, Int>>
```

Quem chama vê `some Sequence<Int>`: algo que dá para percorrer e que produz inteiros. O `Array(long)`
funciona porque é só disso que um array precisa. A segunda linha imprime o tipo real, que a função
escolheu e a assinatura escondeu. O `<Int>` depois do protocolo fixa o tipo associado dele,
`Element`, para quem chama saber o que sai. `\.minutes` é um **key path**, um jeito curto de escrever
`{ $0.minutes }`.

## Um tipo, fixo

**`some` continua sendo exatamente um tipo.** O compilador sabe qual, verifica cada uso dele e gera o
mesmo código rápido que geraria com o nome completo escrito. O que ele recusa é uma função que devolve
tipos diferentes em caminhos diferentes:

```swift
// TwoTypes.swift
protocol Describable { var title: String { get } }
struct Course: Describable { var title: String }
struct StudySession: Describable { var title: String; var minutes: Int }

func pick(_ long: Bool) -> some Describable {
    if long { return Course(title: "Swift") }
    return StudySession(title: "Optionals", minutes: 45)
}
```

```
ana@vm:~/sw/l09$ swiftc TwoTypes.swift -o twotypes
TwoTypes.swift:6:6: error: function declares an opaque return type 'some Describable', but the return statements in its body do not have matching underlying types [#OpaqueTypeInference]
 4 | struct StudySession: Describable { var title: String; var minutes: Int }
 5 | 
 6 | func pick(_ long: Bool) -> some Describable {
   |      `- error: function declares an opaque return type 'some Describable', but the return statements in its body do not have matching underlying types [#OpaqueTypeInference]
 7 |     if long { return Course(title: "Swift") }
   |                      `- note: return statement has underlying type 'Course'
 8 |     return StudySession(title: "Optionals", minutes: 45)
   |            `- note: return statement has underlying type 'StudySession'
 9 | }
10 | 

[#OpaqueTypeInference]: <https://docs.swift.org/compiler/documentation/diagnostics/opaque-type-inference>
```

As duas notas nomeiam os dois tipos que os returns tinham. Um retorno `some` é a promessa de um tipo
que quem chama não consegue nomear; dois tipos quebrariam a promessa. Quando caminhos diferentes
precisam mesmo de tipos diferentes, o tipo de retorno é `any Describable`, e a seção 07 é sobre quanto
isso custa.

## some num parâmetro

`some` também funciona num parâmetro, `func show(_ item: some Describable)`, e ali é atalho para uma
função genérica: quer dizer exatamente `func show<T: Describable>(_ item: T)`, com o parâmetro de tipo
sem nome. O SwiftUI é construído com os dois usos; toda view diz que seu corpo é `some View`, um tipo
que ninguém conseguiria escrever à mão. O SwiftUI em si só existe nas plataformas da Apple e não roda
neste curso, mas a regra do `some` é a mesma que você acabou de ver o compilador impor.
