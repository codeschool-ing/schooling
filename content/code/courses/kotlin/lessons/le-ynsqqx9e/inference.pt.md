---
title: Inferência de tipo, e as conversões que o Kotlin não faz por você
version: 1
---

Nenhum dos programas até aqui escreveu um tipo, e todos os nomes deles têm um. **O Kotlin é
estaticamente tipado: o compilador conhece o tipo de cada nome antes de o programa rodar**,
exatamente como o do Java. Ele só deduz a maioria deles pelo valor à direita, o que se chama
inferência de tipo. Um tipo não escrito não é uma verificação a menos.

```kotlin
// Types.kt
fun main() {
    val minutes = 45
    val big = 3_000_000_000
    val hours = minutes / 60.0
    val done = false
    val course = "Kotlin"
    println(minutes::class.simpleName)
    println(big::class.simpleName)
    println(hours::class.simpleName)
    println(done::class.simpleName)
    println(course::class.simpleName)
    println(minutes / 60)
    println(hours)
}
```

```
ana@vm:~/kt/l01$ kotlinc Types.kt -include-runtime -d types.jar && java -jar types.jar
Int
Long
Double
Boolean
String
0
0.75
```

Cinco valores, cinco tipos, nenhum escrito. O `::class.simpleName` pergunta a um valor o nome da
classe dele em tempo de execução, e imprime o que o compilador já tinha decidido:

| literal | tipo | por quê |
|---|---|---|
| `45` | `Int` | um número inteiro que cabe em 32 bits |
| `3_000_000_000` | `Long` | não cabe num `Int`, então o compilador escolhe 64 bits; os sublinhados são só para os seus olhos |
| `minutes / 60.0` | `Double` | um dos lados é `Double`, então o resultado também é |
| `false` | `Boolean` | |
| `"Kotlin"` | `String` | |

**`minutes / 60` imprimiu `0`.** Dois `Int` dividem para um `Int`, e a fração é jogada fora em vez
de arredondada: 45 dividido por 60 dá 0, resto 45. A linha seguinte dividiu por `60.0` e deu `0.75`.
É a mesma regra do Java e do C, e é o número errado mais comum no programa de um iniciante.

## Escrevendo o tipo você mesmo

Um tipo vem depois do nome, atrás de dois-pontos. O compilador então verifica o valor contra ele em
vez de inferir:

```kotlin
// Declared.kt
fun main() {
    val minutes: Int = 45
    val total: Long = minutes
    println(total)
}
```

```
ana@vm:~/kt/l01$ kotlinc Declared.kt -include-runtime -d declared.jar
Declared.kt:4:21: error: initializer type mismatch: expected 'Long', actual 'Int'.
    val total: Long = minutes
                    ^
```

É aqui que o Kotlin difere do Java. **O Kotlin não alarga um número por você**: um `Int` não é um
`Long`, mesmo que todo valor `Int` caiba num, e o Java teria convertido sem dizer nada. A conversão
precisa ser escrita, e é uma função do número:

```kotlin
// Converted.kt
fun main() {
    val minutes: Int = 45
    val total: Long = minutes.toLong()
    val ratio: Double = minutes.toDouble() / 60
    println(total)
    println(ratio)
}
```

```
ana@vm:~/kt/l01$ kotlinc Converted.kt -include-runtime -d converted.jar && java -jar converted.jar
45
0.75
```

`toLong()`, `toInt()`, `toDouble()` e as irmãs existem em todo tipo numérico. As que estreitam, como
`toInt()` num `Long`, guardam os bits baixos e descartam o resto, então um valor que não cabe sai
como outro número em vez de um erro. Escrever a conversão é o que torna isso visível no código.

## Quando escrever o tipo mesmo assim

Inferir é o padrão, e um tipo declarado vale a pena em três lugares:

- **quando o valor à direita não diz o bastante**, como em `val total: Long = 0`, em que o literal
  sozinho daria um `Int`;
- **no tipo de retorno de uma função pública**, que a aula 3 transforma em hábito, porque é uma
  promessa a quem chama e não deve mudar porque alguém editou o corpo;
- **quando você não tem certeza do que o compilador inferiu.** Escrever o tipo que você espera e
  compilar é o jeito mais rápido de descobrir se acertou.
