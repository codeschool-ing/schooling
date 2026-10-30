---
title: Tipos que você não escreveu
version: 1
---

Nenhum dos programas até aqui escreveu um tipo, e todo nome neles tem um. **O Swift infere o tipo a
partir do valor**, na compilação, e daí em diante o nome tem esse tipo para sempre. Nada é decidido
enquanto o programa roda. O `type(of:)` pergunta o tipo de um valor, o que torna a inferência
visível:

```swift
// Inference.swift
let course = "Swift"
let minutes = 45
let hours = 1.5
let done = false
let pace: Double = 45
print(type(of: course), type(of: minutes), type(of: hours), type(of: done), type(of: pace))
print(minutes / 60, Double(minutes) / 60, Int(hours))
print(Int.max, Int8.max, Int8.min)
```

```
ana@vm:~/sw/l01$ swift Inference.swift
String Int Double Bool Double
0 0.75 1
9223372036854775807 127 -128
```

Quatro regras produziram a primeira linha:

| um literal como | é inferido como |
|---|---|
| `"Swift"` | `String` |
| `45` | `Int` |
| `1.5` | `Double` |
| `false` | `Bool` |

O quinto nome, `pace`, tem uma **anotação**: o `: Double` depois do nome diz que tipo você quer. O
literal `45` sozinho seria um `Int`, e a anotação o transformou num `Double`. Isso funciona porque um
literal não tem tipo até ser usado; um literal inteiro pode virar qualquer tipo numérico que o
contexto pedir. A seção 07 mostra que um valor que já tem tipo não ganha esse favor.

## Inteiros dividem como inteiros

`minutes / 60` imprimiu `0`. Os dois lados são `Int`, então a divisão é inteira: 45 dividido por 60
dá 0, com resto 45, e o resto é descartado. `Double(minutes) / 60` converte primeiro, e dá `0.75`.
**O tipo dos operandos decide a aritmética**, e nada avisa. Quando um resultado sai menor do que você
esperava, olhe os tipos antes dos números. `Int(hours)` vai no sentido contrário e corta `1.5` para
`1`, em direção a zero.

## Inteiros têm tamanhos

O `Int` tem 64 bits em todo computador e celular para o qual o Swift sai hoje, e a terceira linha
imprime o maior valor dele. `Int8`, `Int16`, `Int32` e `Int64` existem, com versões sem sinal como
`UInt8`, para formatos de arquivo e protocolos de rede em que o tamanho faz parte do contrato.
**Use `Int` a menos que um formato diga outra coisa**; misturar tamanhos custa conversões em toda
parte, pelo motivo que a seção 07 mostra. `Double` é o tipo de ponto flutuante para usar, e `Float`
tem metade do tamanho.

## Quando escrever o tipo mesmo assim

Uma anotação que só repete o que o literal diz, `let minutes: Int = 45`, não acrescenta nada.
Escreva uma quando o literal inferiria o tipo errado, como em `pace`, ou quando não há literal nenhum
e quem lê teria de procurar em outro lugar para saber. Uma anotação também é verificada. Ela nunca é
uma conversão:

```swift
// Annotated.swift
let minutes: Int = 1.5
print(minutes)
```

```
ana@vm:~/sw/l01$ swiftc Annotated.swift -o annotated
Annotated.swift:2:20: error: cannot convert value of type 'Double' to specified type 'Int'
1 | // Annotated.swift
2 | let minutes: Int = 1.5
  |                    `- error: cannot convert value of type 'Double' to specified type 'Int'
3 | print(minutes)
4 | 
```

Um literal `Double` não vira `Int` sem perder o `.5`, e o compilador não faz isso em silêncio.
