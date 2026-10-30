---
title: Um tipo com uma lista fixa de valores
version: 1
---

Um dia da semana é uma de sete coisas, nunca uma oitava. Escrevê-lo como `String` deixa passar um
erro de digitação, `"Firday"`, e escrevê-lo como `Int` deixa todo leitor lembrando que 5 quer dizer
sexta. **Uma enumeração, `enum`, é um tipo cujos valores são uma lista que você escreve**, e nada fora
da lista pode ser um valor dela:

```swift
// Cases.swift
enum Weekday: String, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}
enum Level: Int {
    case easy = 1, medium, hard
}
let today = Weekday.friday
print(today, today.rawValue)
print(Weekday(rawValue: "friday") as Any, Weekday(rawValue: "Friday") as Any)
print(Weekday.allCases.count, Weekday.allCases.first!)
print(Level.medium.rawValue, Level(rawValue: 3) as Any)
var day: Weekday = .monday
day = .sunday
print(day)
```

```
ana@vm:~/sw/l07$ swiftc Cases.swift -o cases && ./cases
friday friday
Optional(cases.Weekday.friday) nil
7 monday
2 Optional(cases.Level.hard)
sunday
```

Cada `case` é um valor. Onde o tipo já é conhecido, como em `day = .sunday`, o nome do tipo pode ficar
de fora e só o ponto é escrito, e é por isso que código Swift é cheio de formas curtas como
`.monday`.

**Um raw value é uma segunda identidade para cada caso, de um tipo que você escolhe.** O `: String`
depois do nome do enum dá uma string a cada caso, e sem nada escrito a string é o próprio nome do
caso. O `: Int` dá números, e depois de `easy = 1` cada caso seguinte pega o próximo. O raw value é o
que você grava num arquivo ou manda pela rede, e a aula 13 faz exatamente isso.

**Voltar de um raw value pode falhar**, então `Weekday(rawValue:)` devolve um opcional: `"friday"`
achou o seu caso, e `"Friday"`, com maiúscula, não achou nenhum e deu `nil`. É o mesmo inicializador
que pode falhar que a aula 6 escreveu à mão, e este quem escreve é o compilador. O `as Any` cala o
aviso que a aula 1 encontrou ao imprimir um opcional; a saída ainda mostra o embrulho
`Optional(…)`, com o nome completo do tipo dentro, `cases.Weekday`, prefixado pelo módulo como a
aula 5 viu nas classes.

O `CaseIterable` pede ao compilador o `allCases`, um array com todos os casos na ordem em que foram
escritos. É assim que uma tela lista os sete dias sem ninguém digitá-los duas vezes.

## Um enum é um tipo de valor

Um enum é copiado como uma struct, pode ter métodos e propriedades computadas como uma struct, e não
tem propriedades armazenadas próprias: um caso é o valor inteiro. O que ele pode ter no lugar disso é
o assunto da próxima seção.
