---
title: Apagamento, e parâmetros de tipo reificados
version: 1
---

Na JVM, **argumentos de tipo só existem na compilação**. Uma `List<Int>` e uma `List<String>` são as
duas apenas uma `List` enquanto o programa roda; o `<Int>` foi verificado pelo compilador e depois
jogado fora. Isso se chama apagamento de tipo, e explica uma recusa que você vai encontrar:

```kotlin
// Erased.kt
fun <T> isListOf(value: Any): Boolean = value is List<T>

fun main() {
    println(isListOf<Int>(listOf(45)))
}
```

```
ana@vm:~/kt/l12$ kotlinc Erased.kt -include-runtime -d erased.jar
Erased.kt:2:50: error: cannot check for instance of erased type 'List<T (of fun <T> isListOf)>'.
fun <T> isListOf(value: Any): Boolean = value is List<T>
                                                 ^^^^^^^
```

Em tempo de execução não há `T` com que comparar, então `is List<T>` não tem resposta e é recusado. É
também por isso que a aula 9 escreveu `is List<*>`: a estrela pergunta só "é uma lista", o que dá para
verificar.

## `reified`: guardando o T numa função inline

A aula 4 disse que havia um caso em que o `inline` é obrigatório e não uma otimização. **O corpo de uma
função inline é copiado em cada lugar de chamada, onde o argumento de tipo é conhecido**, então o
compilador consegue escrever o tipo real na cópia. Marcar o parâmetro como `reified` pede que ele faça
isso:

```kotlin
// Reified.kt
inline fun <reified T> List<Any>.only(): List<T> = filter { it is T }.map { it as T }

inline fun <reified T> typeName(): String? = T::class.simpleName

fun main() {
    val mixed: List<Any> = listOf(45, "read chapter 3", 30, 2.5)
    println(mixed.only<Int>())
    println(mixed.only<String>())
    println(typeName<Map<String, Int>>())
    println(mixed.filterIsInstance<Double>())
}
```

```
ana@vm:~/kt/l12$ kotlinc Reified.kt -include-runtime -d reified.jar && java -jar reified.jar
[45, 30]
[read chapter 3]
Map
[2.5]
```

`it is T` compila aqui, porque na cópia feita para `only<Int>()` ele se lê `it is Int`. `T::class` dá o
objeto de classe do tipo, o que um `T` não reificado não consegue. O `filterIsInstance` da biblioteca
padrão, na última linha, é exatamente esse padrão, assim como o `inject<T>()` ou o `viewModel<T>()` que
bibliotecas Android usam: **uma função que precisa saber em tempo de execução para qual tipo foi chamada
é uma função inline com um parâmetro reificado**.

## O preço

Uma função reificada precisa ser `inline`, então o corpo dela é copiado em todo chamador, e ela não é
chamada pelo Java, que não tem como fornecer o tipo. Nenhum dos dois importa para pequenas funções
auxiliares, que é o que essas funções quase sempre são.
