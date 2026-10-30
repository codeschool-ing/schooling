---
title: Uma função é um valor, e tem tipo
version: 1
---

Até aqui uma função era algo declarado e chamado. **Em Kotlin uma função também é um valor**: ela é
guardada num `val`, passada a outra função e devolvida por uma, exatamente como um `Int` ou uma
`String`. Um valor tem tipo, e o tipo de uma função se escreve com os tipos dos parâmetros entre
parênteses, uma seta e o tipo que ela devolve.

| tipo | se lê como | um valor de exemplo |
|---|---|---|
| `(Int) -> Int` | recebe um `Int`, dá um `Int` | `{ m -> m + 15 }` |
| `(Int, String) -> String` | recebe um `Int` e uma `String`, dá uma `String` | `{ m, course -> "$course: $m min" }` |
| `() -> Unit` | não recebe nada, não dá nada que valha guardar | `{ println("tick") }` |
| `(Int) -> Boolean` | uma pergunta de sim ou não sobre um `Int` | `{ m -> m >= 60 }` |

Os valores da última coluna são **lambdas**: funções escritas no lugar, entre chaves, sem nome. A
seção 03 é sobre a sintaxe delas; aqui elas são só o jeito mais simples de ter um valor de função
para olhar.

```kotlin
// FunctionTypes.kt
fun main() {
    val addBreak: (Int) -> Int = { m -> m + 15 }
    val label: (Int, String) -> String = { m, course -> "$course: $m min" }
    val tick: () -> Unit = { println("tick") }
    val isLong: (Int) -> Boolean = { m -> m >= 60 }

    println(addBreak(45))
    println(label(45, "Kotlin"))
    tick()
    println(isLong(45))
    println(addBreak)
}
```

```
ana@vm:~/kt/l04$ kotlinc FunctionTypes.kt -include-runtime -d functiontypes.jar && java -jar functiontypes.jar
60
Kotlin: 45 min
tick
false
FunctionTypesKt$$Lambda/0x00007fba70000400@5451c3a8
```

Um `val` que guarda uma função é chamado com parênteses, como se fosse a própria função:
`addBreak(45)`. Imprimi-lo sem chamar mostra o que ele é por baixo: um objeto de uma classe que a JVM
gerou para a lambda. Os números da última linha são um endereço e um hash code, e os seus serão
outros. O Kotlin na JVM representa toda lambda como um objeto com um método `invoke`, e `addBreak(45)`
é `addBreak.invoke(45)` escrito curto.

## Um tipo de função anulável

Um tipo de função pode ser anulável como qualquer outro, e os parênteses importam: `(() -> Unit)?` é
"uma função, ou nada", enquanto `() -> Unit?` é "uma função que devolve um `Unit?`". O primeiro é o
que você quer para um callback opcional, e as ferramentas da aula 2 valem para ele:

```kotlin
// Callback.kt
fun finish(minutes: Int, onDone: ((Int) -> Unit)? = null) {
    println("finished $minutes min")
    onDone?.invoke(minutes)
}

fun main() {
    finish(45)
    finish(30) { m -> println("logged $m") }
}
```

```
ana@vm:~/kt/l04$ kotlinc Callback.kt -include-runtime -d callback.jar && java -jar callback.jar
finished 45 min
finished 30 min
logged 30
```

`onDone?.invoke(minutes)` é uma chamada segura num valor de função: quando ninguém passou callback,
nada é chamado. A segunda chamada passa a lambda depois dos parênteses, o que a seção 05 explica.
