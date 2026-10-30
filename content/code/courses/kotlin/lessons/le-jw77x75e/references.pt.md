---
title: Referências a funções
version: 1
---

Uma lambda que só chama uma função existente, `{ m -> isLong(m) }`, diz a mesma coisa duas vezes.
**`::isLong` é uma referência à própria função**, e ela vai a qualquer lugar onde caberia uma lambda
do mesmo tipo.

```kotlin
// References.kt
fun isLong(minutes: Int) = minutes >= 60

fun format(minutes: Int) = "${minutes / 60} h ${minutes % 60} min"

fun main() {
    val week = listOf(45, 30, 60, 90)
    println(week.count(::isLong))
    val toText: (Int) -> String = ::format
    println(toText(135))

    val courses = listOf("Kotlin", "Android", "Go")
    println(courses.map(String::length))

    val prefix = "Kot"
    val startsWithPrefix: (String) -> Boolean = { it.startsWith(prefix) }
    val kotlin = "Kotlin"
    val kotlinStartsWith: (String) -> Boolean = kotlin::startsWith
    println(courses.count(startsWithPrefix))
    println(kotlinStartsWith("Kot"))
}
```

```
ana@vm:~/kt/l04$ kotlinc References.kt -include-runtime -d references.jar && java -jar references.jar
2
2 h 15 min
[6, 7, 2]
1
true
```

Três formas de referência aparecem aqui:

| referência | a que se refere | o tipo dela aqui |
|---|---|---|
| `::isLong` | uma função de nível superior | `(Int) -> Boolean` |
| `String::length` | um membro de um tipo; o objeto vira o primeiro parâmetro | `(String) -> Int` |
| `kotlin::startsWith` | um membro de um objeto específico, **ligado** a ele | `(String) -> Boolean` |

`String::length` recebe a string como parâmetro: `map(String::length)` pede o comprimento a cada
curso. `kotlin::startsWith` já tem o objeto dele, a string `"Kotlin"`, então a função que ele dá
recebe só o prefixo a testar. Essa é uma **referência ligada**, e a lição 7 encontra a mesma forma com
um objeto de uma classe sua.

## Lambda ou referência

Uma referência só é mais curta quando a lambda não faria nada além de repassar os argumentos. **Assim
que a lambda acrescenta qualquer coisa, um segundo argumento, uma negação, uma conversão, a lambda é
mais clara**: `{ !isLong(it) }` não se escreve como referência, e `{ it.startsWith(prefix) }` acima se
lê melhor do que qualquer referência leria. Use `::` quando o nome da função diz tudo o que a lambda
diria.
