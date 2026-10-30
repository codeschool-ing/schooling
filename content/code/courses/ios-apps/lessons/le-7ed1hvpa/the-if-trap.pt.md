---
title: A armadilha do if: um modificador aplicado só às vezes
version: 1
---

**Uma função auxiliar que aplica um modificador só quando uma condição vale é um dos trechos de
SwiftUI mais comuns na internet, e ela custa à view a identidade, em silêncio.** Ela é assim:

```swift
extension View {
    @ViewBuilder
    func when<Modified: View>(_ condition: Bool, modify: (Self) -> Modified) -> some View {
        if condition {
            modify(self)
        } else {
            self
        }
    }
}

Text("50 min")
    .when(session.done) { $0.foregroundStyle(.green) }
```

Ela se lê bem e compila. **O `if` dentro dela é o `if` da aula 3 seção 07**: dois ramos, duas vagas no
tipo, e virar a condição remove a view de uma vaga e cria uma nova na outra. Para um `Text` isso é um
desperdício pequeno. Para uma view com estado dentro, um campo de texto ou uma posição de rolagem, é um
reinício: o campo perde o que foi digitado quando a sessão é marcada como feita. A aula 11 mostra o
outro sintoma, uma animação que esmaece uma view e faz aparecer outra em vez de mudar uma cor.

## A mesma coisa sem SwiftUI

Swift puro mostra o que a auxiliar constrói. `Words` faz o papel de uma view e `Highlighted` o do
embrulho de um modificador; `when` é a auxiliar, e `Highlight` é a alternativa, um embrulho que está
sempre lá e cujo efeito é um valor. Salve isto como `iftrap.swift` em `~/l05`:

```schooling-example
{"language": "swift", "file": "iftrap.swift", "parts": [{"code": "// iftrap.swift: a modifier inside an if, and the identity it costs\nstruct Words { let text: String }\nstruct Highlighted<Content> { let content: Content }\nenum Either<First, Second> { case first(First), second(Second) }\n", "note": "Uma view, o embrulho de um modificador, e o formato de dois ramos que um builder faz de um `if`."}, {"code": "/// The helper people write: apply a modifier only when a condition holds.\nfunc when<V, T>(_ condition: Bool, _ view: V, _ modify: (V) -> T) -> Either<T, V> {\n    condition ? .first(modify(view)) : .second(view)\n}\n", "note": "A auxiliar, sem a sintaxe do builder: a view modificada no primeiro ramo, a simples no segundo. O tipo dela tem os dois, então compila; o valor dela é um ou outro."}, {"code": "/// The alternative: one wrapper, always there, whose effect is a value.\nstruct Highlight<Content> { let content: Content; let on: Bool }\n", "note": "A correção: o embrulho é aplicado sempre, e se ele faz alguma coisa é um `Bool` dentro dele."}, {"code": "for done in [true, false] {\n    let branched = when(done, Words(text: \"50 min\")) { Highlighted(content: $0) }\n    let valued = Highlight(content: Words(text: \"50 min\"), on: done)\n    print(\"done: \\(done)\")\n    print(\"  if:    \\(branched)\")\n    print(\"  value: \\(valued)\")\n}\n", "note": "Os dois jeitos, para uma sessão feita e não feita."}]}
```

```
ana@vm:~/l05$ swift iftrap.swift
done: true
  if:    first(iftrap.Highlighted<iftrap.Words>(content: iftrap.Words(text: "50 min")))
  value: Highlight<Words>(content: iftrap.Words(text: "50 min"), on: true)
done: false
  if:    second(iftrap.Words(text: "50 min"))
  value: Highlight<Words>(content: iftrap.Words(text: "50 min"), on: false)
```

**Com o `if`, o texto mora em `first` quando está feito e em `second` quando não**: dois lugares
diferentes, então para o SwiftUI duas views diferentes. **Com o valor, o texto fica no mesmo lugar nas
duas vezes**, e só o `on` mudou. Essa é a diferença inteira entre um reinício e uma atualização.

## O que escrever no lugar

A maioria dos modificadores aceita um valor que pode querer dizer "nenhum efeito", então a condição vai
dentro do valor:

```swift
Text("50 min")
    .foregroundStyle(session.done ? .green : .primary)
    .opacity(session.done ? 0.6 : 1)
```

Uma view, sempre na mesma vaga, com valores que mudam. Use uma view condicional só quando as views
forem de fato coisas diferentes, um sinal de concluído contra um número, como a aula 3 seção 07 fez de
propósito. Nada nesta seção rodou o SwiftUI; o `iftrap.swift` rodou no Linux.
