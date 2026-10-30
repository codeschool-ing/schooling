---
title: Closures, funções sem nome
version: 1
---

Uma função no Swift é um valor, como um `Int` ou uma `String`. Tem tipo, pode ser guardada numa
constante, passada para outra função e devolvida por uma. **Uma closure é uma função escrita no lugar,
sem nome**, e é como a maior parte do código Swift passa comportamento adiante.

## Uma função é um valor

```swift
// FunctionValues.swift
func seconds(_ minutes: Int) -> Int {
    minutes * 60
}
let convert = seconds
print(convert(45))
print(type(of: convert))
func applyAll(_ f: (Int) -> Int, to values: [Int]) -> [Int] {
    var out: [Int] = []
    for value in values {
        out.append(f(value))
    }
    return out
}
print(applyAll(seconds, to: [45, 30]))
```

```
ana@vm:~/sw/l03$ swift FunctionValues.swift
2700
(Int) -> Int
[2700, 1800]
```

`let convert = seconds` guarda a própria função, sem chamá-la: não há parênteses depois de `seconds`.
O tipo dela é `(Int) -> Int`, lido como "recebe um `Int`, dá um `Int`", e esse é também o tipo do
parâmetro `f` de `applyAll`. Então `applyAll` consegue aplicar qualquer função desse formato a cada
valor de uma lista, sem saber qual.

## A mesma função, sem nome

Passar `seconds` exigiu declará-la antes, em outro lugar. Uma closure a escreve onde é usada, e o
Swift deixa escrevê-la em quatro níveis de brevidade:

```schooling-example
{"language": "swift", "file": "Shorthand.swift", "parts": [{"code": "// Shorthand.swift\nlet full: (Int) -> Int = { (minutes: Int) -> Int in\n    return minutes * 60\n}", "note": "A forma inteira: o parâmetro e seu tipo, o tipo do resultado, a palavra `in` e então o corpo. É uma função sem nome, e o tipo dela está escrito à esquerda: recebe um `Int` e dá um `Int`."}, {"code": "let inferred: (Int) -> Int = { minutes in\n    return minutes * 60\n}", "note": "O tipo à esquerda já diz `(Int) -> Int`, então a closure não precisa repeti-lo. Só o nome do parâmetro fica antes do `in`."}, {"code": "let implicit: (Int) -> Int = { minutes in minutes * 60 }", "note": "Um corpo de uma expressão só não precisa de `return`, como numa função."}, {"code": "let short: (Int) -> Int = { $0 * 60 }", "note": "Nome nenhum: `$0` é o primeiro parâmetro, `$1` o segundo. Serve para uma closure de uma linha curta, e fica difícil de ler numa mais longa."}, {"code": "print(full(45), inferred(45), implicit(45), short(45))\nprint(type(of: short))", "note": "Quatro grafias, uma função e um tipo."}]}
```

```
ana@vm:~/sw/l03$ swift Shorthand.swift
2700 2700 2700 2700
(Int) -> Int
```

**Toda forma é a mesma função**: as quatro chamadas imprimem o mesmo número e o tipo é o mesmo. O que
muda é quanto se diz a quem lê e quanto ele deduz. Duas regras cobrem a maior parte do código: use
`$0` numa closure que cabe com folga numa linha, e dê nomes aos parâmetros assim que houver mais de uma
linha ou mais de um parâmetro.

Os tipos podem ser omitidos porque o Swift **os infere do contexto**: aqui, o `(Int) -> Int` escrito à
esquerda. Quando uma closure é passada direto para uma função, como na seção 06, o tipo do parâmetro
da função é o contexto, e nada à esquerda é necessário.
