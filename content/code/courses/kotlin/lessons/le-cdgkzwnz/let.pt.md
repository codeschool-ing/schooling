---
title: let, para o valor que pode ser null
version: 1
---

O `let` passa o objeto como `it` e devolve o resultado do bloco. Sozinho, isso é pouco mais que dar
nome a um valor. **O uso de verdade dele é atrás de uma chamada segura**: `x?.let { … }` roda o bloco
só quando `x` não é null, com o `it` já convertido por smart cast para o tipo não nulo, e dá `null`
caso contrário.

```kotlin
// Let.kt
fun main() {
    val input: String? = "45"
    val seconds = input?.toIntOrNull()?.let { it * 60 }
    println(seconds)

    val missing: String? = null
    missing?.let { println("never printed: $it") }
    println(missing?.let { it.length } ?: 0)

    val note: String? = "read chapter 3"
    note?.let { text ->
        val words = text.split(" ").size
        println("note of $words words")
    }
}
```

```
ana@vm:~/kt/l06$ kotlinc Let.kt -include-runtime -d let.jar && java -jar let.jar
2700
0
note of 3 words
```

Três usos num arquivo. O primeiro transforma um número que pode faltar em outro número que pode
faltar, e a corrente para no primeiro `null`, como as chamadas seguras da lição 2. O segundo roda um
bloco pelo efeito só quando há algo sobre o que agir. O terceiro mostra um nome para o `it`, `text`,
que é a escolha certa quando o bloco passa de uma linha.

## Um `let` que só renomeia é ruído

`val n = minutes.let { it * 2 }` é `val n = minutes * 2` com mais pontuação. **O `let` se justifica
quando o valor é anulável, ou quando ele é o fim de uma corrente** que você não quer quebrar num `val`
com nome:

```kotlin
// LetChain.kt
fun main() {
    val sessions = listOf("Kotlin" to 45, "Android" to 30, "Kotlin" to 60)
    sessions.filter { it.first == "Kotlin" }
        .sumOf { it.second }
        .let { "Kotlin this week: ${it / 60} h ${it % 60} min" }
        .let(::println)
}
```

```
ana@vm:~/kt/l06$ kotlinc LetChain.kt -include-runtime -d letchain.jar && java -jar letchain.jar
Kotlin this week: 1 h 45 min
```

O total é usado duas vezes dentro do template, então precisa de nome, e o `let` dá um sem interromper
a corrente. O último `let` recebe uma referência a função, que a lição 4 mostrou ser permitida onde
quer que caiba uma lambda do mesmo tipo.

## `?.let` contra `if`

`if (note != null) { … }` faz o mesmo que `note?.let { … }` para um `val` local, e muitas vezes é mais
claro. Os dois diferem para uma propriedade `var`, em que a lição 2 mostrou que o `if` não faz smart
cast: o `?.let` lê a propriedade uma vez e trabalha sobre esse valor, então é a forma curta do "copie
para um `val` antes" da lição 2.
