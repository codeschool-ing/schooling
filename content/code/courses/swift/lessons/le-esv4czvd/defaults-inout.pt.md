---
title: Valores padrão, parâmetros variádicos e inout
version: 1
---

Mais três coisas que um parâmetro pode ser, cada uma resolvendo um problema.

## Um padrão para o caso comum

A maioria das sessões do planner tem 30 minutos e é planejada para segunda-feira. Um **valor padrão**
deixa a chamada omitir o que é comum:

```swift
// Defaults.swift
func plan(_ course: String, minutes: Int = 30, on day: String = "Monday") {
    print("\(day): \(course) for \(minutes) min")
}
plan("Swift")
plan("Swift", minutes: 45)
plan("Swift", on: "Friday")
plan("Swift", minutes: 60, on: "Sunday")
```

```
ana@vm:~/sw/l03$ swift Defaults.swift
Monday: Swift for 30 min
Monday: Swift for 45 min
Friday: Swift for 30 min
Sunday: Swift for 60 min
```

Quatro chamadas, uma função. Como cada argumento tem rótulo, a chamada pode pular `minutes:` e ainda
dar `on:` sem ninguém se confundir sobre qual número foi para onde. **Ponha os parâmetros com padrão
depois dos que não têm**, para os argumentos obrigatórios virem sempre primeiro na chamada.

## Qualquer número de argumentos

Um parâmetro **variádico**, escrito com `...` depois do tipo, aceita zero ou mais valores e os vê como
um array:

```swift
// Variadic.swift
func total(_ sessions: Int...) -> Int {
    var sum = 0
    for minutes in sessions {
        sum += minutes
    }
    return sum
}
print(total())
print(total(45))
print(total(45, 30, 60))
```

```
ana@vm:~/sw/l03$ swift Variadic.swift
0
45
135
```

O próprio `print` é variádico, e é por isso que `print(total, hours(total))` na seção 02 imprimiu dois
valores com um espaço entre eles.

## Parâmetros são constantes

Dentro da função, todo parâmetro é um `let`. Tentar mudar um é erro:

```swift
// ParamLet.swift
func extend(_ minutes: Int) -> Int {
    minutes += 5
    return minutes
}
print(extend(45))
```

```
ana@vm:~/sw/l03$ swiftc ParamLet.swift -o paramlet
ParamLet.swift:3:13: error: left side of mutating operator isn't mutable: 'minutes' is a 'let' constant
1 | // ParamLet.swift
2 | func extend(_ minutes: Int) -> Int {
3 |     minutes += 5
  |             `- error: left side of mutating operator isn't mutable: 'minutes' is a 'let' constant
4 |     return minutes
5 | }
```

**O compilador está protegendo quem chama.** Quem chama passou um valor, e nada do que a função faz
volta para mudar a cópia dele. Quando uma função precisa de uma cópia de trabalho, ela escreve `var
longer = minutes` e muda essa.

## inout, quando mudar a variável de quem chama é o objetivo

Às vezes quem chama quer sua variável mudada. O `inout` marca esse parâmetro, e **a chamada precisa
escrever `&`**, para que ler só a chamada já diga que a variável pode voltar diferente:

```swift
// Inout.swift
func addSession(_ minutes: Int, to total: inout Int) {
    total += minutes
}
var week = 0
addSession(45, to: &week)
addSession(30, to: &week)
print(week)
```

```
ana@vm:~/sw/l03$ swift Inout.swift
75
```

`week` entrou valendo 0 e voltou valendo 75. Por baixo, o valor é copiado para dentro, mudado e
copiado de volta quando a função termina. O `inout` é útil e raro: uma função que devolve um valor
novo, `week = week + 45`, é mais fácil de acompanhar, e a maior parte do código Swift faz isso.
