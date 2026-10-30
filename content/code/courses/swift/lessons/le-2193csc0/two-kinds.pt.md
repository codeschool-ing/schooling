---
title: Dois jeitos de definir um tipo
version: 1
---

Todo programa até aqui usou tipos que outra pessoa escreveu: `Int`, `String`, `Double`. O Swift lhe
dá duas palavras-chave para escrever o seu próprio tipo com campos armazenados, `struct` e `class`,
e **as duas parecem quase idênticas na página**. A diferença é o que acontece quando um valor é
atribuído, passado ou guardado, e o resto desta lição é essa diferença. Esta seção mostra o que cada
uma pede de você antes de você conseguir criar uma.

Uma sessão de estudo tem um curso e um número de minutos. Aqui está ela escrita dos dois jeitos, lado
a lado:

```swift
// Kinds.swift
struct SessionValue {
    var course: String
    var minutes: Int
}
class SessionRef {
    var course: String
    var minutes: Int
}
let first = SessionValue(course: "Swift", minutes: 45)
print(first)
```

```
ana@vm:~/sw/l05$ swiftc Kinds.swift -o kinds
Kinds.swift:6:7: error: class 'SessionRef' has no initializers
 4 |     var minutes: Int
 5 | }
 6 | class SessionRef {
   |       `- error: class 'SessionRef' has no initializers
 7 |     var course: String
   |         `- note: stored property 'course' without initial value prevents synthesized initializers
 8 |     var minutes: Int
   |         `- note: stored property 'minutes' without initial value prevents synthesized initializers
 9 | }
10 | let first = SessionValue(course: "Swift", minutes: 45)
```

**A struct compilou e a classe não.** O compilador nomeia a classe, diz que ela não tem
inicializador e acrescenta uma nota sob cada propriedade armazenada: uma propriedade sem valor
inicial impede o compilador de escrever um. Uma struct na mesma situação ganha um **inicializador
memberwise** de graça, `SessionValue(course:minutes:)`, e é por isso que a linha 10 não deu erro. Uma
classe não ganha esse presente, e você escreve o `init`:

```swift
// KindsFixed.swift
struct SessionValue {
    var course: String
    var minutes: Int
}
final class SessionRef {
    var course: String
    var minutes: Int
    init(course: String, minutes: Int) {
        self.course = course
        self.minutes = minutes
    }
}
let first = SessionValue(course: "Swift", minutes: 45)
let second = SessionRef(course: "Swift", minutes: 45)
print(first)
print(second)
```

```
ana@vm:~/sw/l05$ swiftc KindsFixed.swift -o kindsfixed && ./kindsfixed
SessionValue(course: "Swift", minutes: 45)
kindsfixed.SessionRef
```

`self.course = course` atribui o parâmetro `course` à propriedade de mesmo nome; `self` é a instância
sendo construída, e a lição 6 tem mais a dizer sobre inicializadores. `final` diz que nenhuma outra
classe pode herdar desta, o que é o padrão certo para uma classe que ninguém desenhou para ser
estendida; a lição 10 é sobre herança e sobre quando ela vale a pena.

As duas linhas do `print` também diferem. **Uma struct imprime o seu conteúdo**, campo a campo,
porque o Swift consegue descrever um valor pelo que há nele. Uma classe imprime só o nome, prefixado
pelo módulo em que o programa foi compilado, `kindsfixed`, que o `swiftc` nomeou a partir do arquivo
de saída, porque o que identifica uma instância não é o conteúdo, e sim qual instância ela é. A seção
06 torna essa distinção exata.

## O que mais muda

| | `struct` | `class` |
|---|---|---|
| atribuir, ou passar para uma função | copia o valor | copia uma referência à mesma instância |
| um inicializador | escrito pelo compilador, um argumento por propriedade | você escreve o `init` |
| mudar uma propriedade a partir de um método | o método precisa ser `mutating` | sempre permitido |
| herança | nenhuma | uma superclasse, a menos que seja `final` |
| `===`, "é a mesma instância?" | não existe | existe |
| `deinit`, código que roda quando ela some | nenhum | sim, lição 11 |

A maior parte da biblioteca padrão está do lado esquerdo. `Int`, `String`, `Array`, `Dictionary` e
`Optional` são todos structs ou enums, assim como a maioria dos tipos que você vai escrever na camada
de modelo de um app de iPhone. Essa foi uma decisão proposital de quem desenhou o Swift, e a seção 08
dá os motivos.
