---
title: Rótulos de argumento, e chamadas que se leem como frases
version: 1
---

A maioria das linguagens dá um nome a cada parâmetro. **O Swift dá dois: um rótulo de argumento,
escrito na chamada, e um nome de parâmetro, usado dentro da função.** O objetivo é o lugar da chamada,
que é lido muito mais vezes do que a função é escrita:

```swift
// Labels.swift
func add(minutes: Int, to course: String) {
    print("\(minutes) minutes of \(course)")
}
func describe(_ course: String, for minutes: Int) -> String {
    "\(course): \(minutes) min"
}
add(minutes: 45, to: "Swift")
print(describe("Swift", for: 30))
```

```
ana@vm:~/sw/l03$ swift Labels.swift
45 minutes of Swift
Swift: 30 min
```

Em `to course: String`, `to` é o rótulo e `course` o nome. A chamada fica `add(minutes: 45, to:
"Swift")`, perto de uma frase em inglês, e o corpo lê `course`, que é o que o valor é. Escrever `to`
dentro do corpo não faria sentido, e escrever `course:` na chamada leria pior. Um parâmetro escrito
com uma palavra só, `minutes: Int`, usa essa palavra para as duas coisas.

O `_` como rótulo quer dizer **nenhum rótulo na chamada**: `describe("Swift", for: 30)`. Use quando o
nome da função já diz o que é o primeiro argumento, como `describe` faz aqui e `weekTotal` fez na
seção 02.

## Os rótulos fazem parte do nome

Uma chamada precisa escrever os rótulos que a função declarou, na ordem declarada:

```swift
// NoLabels.swift
func add(minutes: Int, to course: String) {
    print("\(minutes) minutes of \(course)")
}
add(45, "Swift")
```

```
ana@vm:~/sw/l03$ swiftc NoLabels.swift -o nolabels
NoLabels.swift:5:4: error: missing argument labels 'minutes:to:' in call
3 |     print("\(minutes) minutes of \(course)")
4 | }
5 | add(45, "Swift")
  |    `- error: missing argument labels 'minutes:to:' in call
6 | 
```

O compilador nomeia os rótulos que queria. Isso diz mais do que parece: **no Swift os rótulos fazem
parte da identidade da função.** O nome completo desta função é `add(minutes:to:)`, que é como a
documentação e o compilador se referem a ela, e duas funções chamadas `add` com rótulos diferentes são
duas funções diferentes. O `minutes(from:)` da aula 2 foi escrito assim de propósito.

## Escolhendo rótulos

As diretrizes de desenho de API da Apple, que a maior parte do código Swift segue, se resumem a
algumas regras:

- **nomeie a função pelo que ela faz, e deixe o primeiro rótulo continuar a frase**:
  `add(minutes:to:)`, `remove(at:)`, `index(of:)`;
- **tire um rótulo que só repete o tipo**: `print(total)`, não `print(value: total)`;
- **prefira clareza na chamada a brevidade na declaração**. Um rótulo custa uma palavra uma vez, na
  declaração, e poupa quem lê toda vez que a chamada é lida.

Um teste útil é ler a chamada em voz alta sem olhar a declaração. Se ela não diz o que acontece, falta
um rótulo ou ele tem o nome errado.
