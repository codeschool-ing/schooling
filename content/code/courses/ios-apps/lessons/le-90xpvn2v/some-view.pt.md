---
title: some View: um tipo, que só o compilador precisa conhecer
version: 1
---

**`some View` quer dizer "exatamente um tipo concreto que obedece a `View`", escolhido pelo body e
escondido de quem o lê.** O compilador conhece o tipo e o confere; você não precisa escrevê-lo, o que
importa porque o tipo de um body de verdade é comprido. A crença a trocar é a de que `some View` quer
dizer "qualquer view", de modo que um body pudesse devolver um tipo de view numa chamada e outro na
seguinte. Não pode, e Swift puro mostra o porquê sem SwiftUI.

Aqui está a mesma regra num protocolo nosso. `Card` faz o papel de `View`, e dois tipos obedecem a
ele. Salve isto como `opaque.swift` num diretório para esta aula, `~/l03`:

```swift
// opaque.swift
protocol Card {
    func render() -> String
}
struct Title: Card {
    let text: String
    func render() -> String { "# \(text)" }
}
struct Minutes: Card {
    let value: Int
    func render() -> String { "\(value) min" }
}

func header(short: Bool) -> some Card {
    if short { return Minutes(value: 50) }
    return Title(text: "SQL Databases")
}
print(header(short: false).render())
```

O `swift opaque.swift` compila um arquivo sozinho e o roda, como a aula 1 seção 08 fez com o
`check.swift`:

```
ana@vm:~/l03$ swift opaque.swift; echo $?
opaque.swift:14:6: error: function declares an opaque return type 'some Card', but the return statements in its body do not have matching underlying types [#OpaqueTypeInference]
12 | }
13 | 
14 | func header(short: Bool) -> some Card {
   |      `- error: function declares an opaque return type 'some Card', but the return statements in its body do not have matching underlying types [#OpaqueTypeInference]
15 |     if short { return Minutes(value: 50) }
   |                       `- note: return statement has underlying type 'Minutes'
16 |     return Title(text: "SQL Databases")
   |            `- note: return statement has underlying type 'Title'
17 | }
18 | print(header(short: false).render())

[#OpaqueTypeInference]: <https://docs.swift.org/compiler/documentation/diagnostics/opaque-type-inference>
1
```

**O compilador recusa, e a nota dele cita os dois tipos.** `some Card` prometeu um tipo por baixo, e
os dois `return` dão dois. Nada rodou: o código de saída é 1 e o `print` nunca aconteceu. Um body é o
mesmo tipo de função, então um body SwiftUI que devolvesse um `Text` num ramo e uma `Image` em outro
seria recusado com esta mensagem.

## Por que o SwiftUI quer um tipo só

**Porque o tipo é o formato da tela.** O tipo de um body registra quais views ele contém, em que ordem
e em qual ramo, para que o SwiftUI compare uma descrição antiga com uma nova pela estrutura, sem
adivinhar. A seção 07 mostra esse formato com um tipo nosso.

Há dois jeitos de devolver views diferentes de um body, e o SwiftUI usa o primeiro:

- **um result builder**, que transforma um `if` e um `else` num tipo só com uma vaga para cada ramo.
  O `body` é marcado com um, e a seção 06 constrói um builder pequeno nosso;
- **apagamento de tipo**, o `AnyView` do SwiftUI, que embrulha qualquer view e esconde o tipo dela.
  Ele compila, e esconde justamente a estrutura pela qual o SwiftUI compara: a documentação da Apple
  para o `AnyView` diz que, sempre que o tipo embrulhado muda, a hierarquia antiga é destruída e uma
  nova é criada.
