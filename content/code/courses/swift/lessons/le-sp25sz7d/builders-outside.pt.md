---
title: Um bloco que monta um valor
version: 1
---

A outra metade de uma tela de SwiftUI se parece com isto. De novo, é a forma documentada pela Apple e
**não é rodada aqui**:

```swift
var body: some View {
    VStack {
        Text("This week")
        Text("135 of 300 minutes")
        if minutes > 300 {
            Text("Goal reached")
        }
    }
}
```

Olhe o que está dentro das chaves do `VStack`: três valores `Text` em linhas próprias, e um `if` com um
quarto. **Nada é devolvido, nada é acrescentado, e nenhuma vírgula os separa.** Numa closure comum da
lição 3, essas linhas criariam três valores e jogariam cada um fora. Aqui elas viram o conteúdo da
pilha, porque o parâmetro do `VStack` é marcado com um **result builder**: um atributo que manda o
compilador recolher o valor de cada linha do bloco e combiná-los num só.

## Um que você pode rodar hoje

O SwiftUI não está no Linux, mas o toolchain padrão do Swift traz outro result builder, no módulo
`RegexBuilder`, que monta uma expressão regular a partir de pedaços que se leem como uma descrição.
Aqui ele lê uma linha do registro do planner, uma data, um curso e alguns minutos:

```swift
// LogLine.swift
import RegexBuilder

let line = "2026-11-02 Swift 45"
let pattern = Regex {
    Capture {
        Repeat(.digit, count: 4)
        "-"
        Repeat(.digit, count: 2)
        "-"
        Repeat(.digit, count: 2)
    }
    " "
    Capture { OneOrMore(.word) }
    " "
    Capture { OneOrMore(.digit) }
}

if let match = line.wholeMatch(of: pattern) {
    print("date:", match.1)
    print("course:", match.2)
    print("minutes:", match.3)
}
```

```
ana@vm:~/sw/l16$ swift LogLine.swift
date: 2026-11-02
course: Swift
minutes: 45
```

**O mesmo formato do `VStack`**: um bloco de linhas, cada uma produzindo um pedaço, e nenhuma cola
entre elas. O `Regex { … }` recolhe os pedaços em ordem, uma captura, um espaço, uma captura, um
espaço, uma captura, e o `wholeMatch` confere a linha contra todos eles. As três capturas voltam como
`match.1` a `match.3`.

## O que o bloco está fazendo de verdade

Parece um tipo novo de sintaxe, e é Swift comum com uma reescrita. Para um bloco marcado com um
builder, o compilador pega o valor de cada linha e passa todos a uma função estática do builder
chamada `buildBlock`. Um `if` sem `else` vira uma chamada a `buildOptional`, um `if` com `else` a
`buildEither`, e um laço `for` a `buildArray`. Um builder que não define uma delas não suporta aquela
instrução, e o compilador diz isso. A seção 06 escreve um builder, e faz essa recusa acontecer.
