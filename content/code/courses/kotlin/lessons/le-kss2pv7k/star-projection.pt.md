---
title: A projeção estrela: uma lista de alguma coisa
version: 1
---

Às vezes uma função não se importa com o que uma lista guarda, só com ela ser uma lista. `List<Any?>`
parece certo e é estreito demais num sentido, e `MutableList<Any?>` é errado pelo motivo que as seções
anteriores deram. **`List<*>` quer dizer "uma lista de algum tipo que eu não conheço"**, e o compilador
permite exatamente o que é seguro sem conhecê-lo:

```kotlin
// Star.kt
fun describe(items: List<*>): String = "${items.size} items, first is ${items.firstOrNull()}"

fun clearAll(items: MutableList<*>) {
    items.clear()
}

fun main() {
    println(describe(listOf(45, 30)))
    println(describe(listOf("Kotlin")))
    val log = mutableListOf(45, 30)
    clearAll(log)
    println(log)
}
```

```
ana@vm:~/kt/l12$ kotlinc Star.kt -include-runtime -d star.jar && java -jar star.jar
2 items, first is 45
1 items, first is Kotlin
[]
```

De uma `List<*>` você lê, e o que sai é `Any?`, já que pode ser qualquer coisa. De uma
`MutableList<*>` você também chama o que não precisa de elemento, como `clear` e `size`. O que você não
faz é pôr algo dentro:

```kotlin
// StarAdd.kt
fun addZero(items: MutableList<*>) {
    items.add(0)
}

fun main() {
    addZero(mutableListOf("Kotlin"))
}
```

```
ana@vm:~/kt/l12$ kotlinc StarAdd.kt -include-runtime -d staradd.jar
StarAdd.kt:3:15: error: receiver type 'MutableList<*>' contains star projection which prohibits the use of 'fun add(element: E): Boolean'.
    items.add(0)
              ^
```

O compilador não sabe se a lista guarda `Int`, e no `main` ela guarda `String`, então o `add(0)` é
recusado. **A estrela é o tipo honesto para "aceito qualquer lista e prometo não acrescentar nada"**, e
o lugar em que você mais a encontra é em ramos de `when` como o `is List<*>` da lição 9, que é o
assunto da próxima seção.
