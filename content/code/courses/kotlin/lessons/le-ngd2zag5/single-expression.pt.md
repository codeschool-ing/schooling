---
title: Corpo de expressão única, e o if como valor
version: 1
---

Quando o corpo de uma função é uma expressão só, as chaves e o `return` saem, e um `=` entra no lugar
deles. **O valor da expressão é o valor da função**, e o tipo de retorno então pode ser inferido dele:

```kotlin
// Format.kt
fun format(minutes: Int): String = "${minutes / 60} h ${minutes % 60} min"

fun isLong(minutes: Int) = minutes >= 60

fun label(minutes: Int) = if (minutes >= 60) "long" else "short"

fun main() {
    println(format(135))
    println(isLong(45))
    println(label(90))
}
```

```
ana@vm:~/kt/l03$ kotlinc Format.kt -include-runtime -d format.jar && java -jar format.jar
2 h 15 min
false
long
```

`isLong` não tem tipo de retorno escrito, e é `Boolean` porque `>=` dá um. Essa inferência é cômoda e
tem um custo: **mude a expressão, e o tipo da função muda junto**, em silêncio, para todo chamador.
Escreva o tipo numa função da qual outro código depende, como `format` faz, e deixe-o de fora num
pequeno ajudante privado em que o corpo conta a história inteira.

## O `if` é uma expressão

`label` usa o `if` do jeito que outras linguagens usam o operador ternário, o `?:` do Java, que o
Kotlin não tem porque não precisa. `if (…) a else b` tem valor, e o valor é o do ramo que rodou. Um
`if` usado como valor precisa do `else`: sem ele não haveria valor quando a condição fosse falsa.

```kotlin
// NoElse.kt
fun label(minutes: Int) = if (minutes >= 60) "long"

fun main() {
    println(label(90))
}
```

```
ana@vm:~/kt/l03$ kotlinc NoElse.kt -include-runtime -d noelse.jar
NoElse.kt:2:27: error: 'if' must have both main and 'else' branches when used as an expression.
fun label(minutes: Int) = if (minutes >= 60) "long"
                          ^^
```

O mesmo vale para `when` e `try`, que as aulas 9 e 13 usam como valores do mesmo jeito. Isso é boa
parte do motivo de código Kotlin ter menos `var` que Java: um nome que antes era declarado vazio e
preenchido por dois ramos agora é declarado uma vez, com o `if` à direita.

## Corpo de bloco ou corpo de expressão

A escolha é sobre leitura, não sobre o que a função consegue fazer:

| forma | use quando |
|---|---|
| `fun f(…): T = expressão` | o resultado é uma expressão, e cabe numa linha ou duas |
| `fun f(…): T { … return … }` | há passos, um laço ou um `return` antecipado |

Um corpo de expressão única que cresce para quinze linhas de `if` aninhados é legal e difícil de ler.
Quando um corpo precisa de um nome para um valor intermediário, ele já não cabe no `=`.
