---
title: Funções de extensão
version: 1
---

O planejador imprime minutos como horas numa dúzia de lugares, e o `format(minutes)` da lição 3 se lê
ao contrário: o valor vem em segundo. **Uma função de extensão acrescenta uma função a um tipo que você
não escreveu**, chamada com ponto como se fosse um membro:

```kotlin
// Extensions.kt
fun Int.asHours(): String = "${this / 60} h ${this % 60} min"

fun List<Int>.longest(): Int? = maxOrNull()

fun String?.orNone(): String = this ?: "none"

fun main() {
    println(135.asHours())
    println(listOf(45, 90, 30).longest())
    val note: String? = null
    println(note.orNone())
}
```

```
ana@vm:~/kt/l11$ kotlinc Extensions.kt -include-runtime -d extensions.jar && java -jar extensions.jar
2 h 15 min
90
none
```

`fun Int.asHours()` declara uma função cujo **receptor** é um `Int`; dentro dela, `this` é o número em
que ela foi chamada. É o receptor da lição 6 de novo, agora com nome. O receptor pode ser qualquer
tipo, inclusive uma lista genérica e um tipo anulável: `orNone` é declarada em `String?`, então pode
ser chamada num valor que é `null`, e trata esse caso ela mesma.

A maior parte da biblioteca padrão que você usou são extensões: `map`, `filter`, `sumOf`, `let`,
`apply`. Elas são declaradas em `Iterable` ou em qualquer tipo `T`, fora desses tipos, e é por isso que
funcionam nas coleções do Java, que não sabem nada de Kotlin.

## Resolvidas pelo tipo declarado

Uma extensão não está de fato dentro da classe. **Ela é uma função estática que recebe o receptor como
primeiro parâmetro**, e qual delas é chamada é decidido na compilação, pelo tipo que o compilador vê:

```kotlin
// Dispatch.kt
open class Reminder
class ExamReminder : Reminder()

fun Reminder.kind() = "reminder"
fun ExamReminder.kind() = "exam reminder"

fun main() {
    val r: Reminder = ExamReminder()
    println(r.kind())
    println(ExamReminder().kind())
}
```

```
ana@vm:~/kt/l11$ kotlinc Dispatch.kt -include-runtime -d dispatch.jar && java -jar dispatch.jar
reminder
exam reminder
```

`r` guarda um `ExamReminder`, e o tipo declarado dele é `Reminder`, então a extensão de `Reminder`
rodou. Um membro sobrescrito teria escolhido a versão de prova em tempo de execução; **uma extensão não
é sobrescrita**, porque não é membro. Quando o comportamento precisa depender do tipo real do objeto,
ele pertence à classe, como membro `open` ou método de interface.

## Um membro sempre vence

Uma extensão com o mesmo nome e parâmetros de um membro nunca é chamada:

```kotlin
// Shadow.kt
class Session {
    fun label() = "member"
}

fun Session.label() = "extension"

fun main() {
    println(Session().label())
}
```

```
ana@vm:~/kt/l11$ kotlinc Shadow.kt -include-runtime -d shadow.jar && java -jar shadow.jar
Shadow.kt:6:13: warning: this extension is shadowed by a member: 'fun label(): String' defined in 'Session'.
fun Session.label() = "extension"
            ^^^^^
member
```

O compilador avisou que a extensão é sombreada pelo membro, e o programa imprimiu `member`. **Ninguém
muda o que um método existente faz declarando uma extensão**, e é isso que torna seguro ter extensões
em todo lugar. A regra vale só para membros: muito do que parece embutido em `String`, como o
`uppercase()`, é ele mesmo uma extensão da biblioteca padrão, e uma extensão sua com o mesmo nome no
seu próprio arquivo tomaria o lugar dele naquele arquivo. Escolha nomes que não colidam.
