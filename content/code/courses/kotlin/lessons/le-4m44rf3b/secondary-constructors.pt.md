---
title: Construtores secundários, e por que são raros
version: 1
---

Uma classe pode ter mais jeitos de ser montada do que o construtor primário. **Um construtor
secundário é declarado no corpo da classe com `constructor`, e precisa chamar o primário**, direto ou
por outro secundário, com `: this(…)`. Essa regra garante que os inicializadores de propriedade e os
blocos `init` da seção anterior rodem seja qual for o jeito de criar o objeto.

O planejador lê sessões de linhas de texto, `Kotlin, 45`, além de montá-las a partir de valores:

```kotlin
// Secondary.kt
class Session(val course: String, val minutes: Int) {
    init {
        require(minutes in 1..600) { "minutes out of range: $minutes" }
    }

    constructor(line: String) : this(
        line.substringBefore(",").trim(),
        line.substringAfter(",").trim().toInt(),
    )
}

fun main() {
    val a = Session("Kotlin", 45)
    val b = Session("Android, 30")
    println("${a.course} ${a.minutes}")
    println("${b.course} ${b.minutes}")
    Session("Go, 900")
}
```

```
ana@vm:~/kt/l07$ kotlinc Secondary.kt -include-runtime -d secondary.jar && java -jar secondary.jar
Kotlin 45
Android 30
Exception in thread "main" java.lang.IllegalArgumentException: minutes out of range: 900
	at Session.<init>(Secondary.kt:4)
	at Session.<init>(Secondary.kt:7)
	at SecondaryKt.main(Secondary.kt:18)
	at SecondaryKt.main(Secondary.kt)
```

A terceira sessão entrou pelo construtor secundário e mesmo assim foi recusada pela verificação do
bloco `init`. **Todo caminho para dentro do objeto passa pelo construtor primário**, então uma regra
escrita uma vez no `init` cobre todos.

## Em geral, um padrão ou uma função no lugar

Os argumentos padrão da lição 3 eliminam a maioria dos motivos pelos quais o Java precisa de vários
construtores. Um `Session(course, minutes = 30)` cobre o que um segundo construtor sem `minutes`
cobriria. E interpretar texto, como acima, costuma se ler melhor como uma função com um nome que diz o
que ela faz:

```kotlin
// Parse.kt
class Session(val course: String, val minutes: Int)

fun parseSession(line: String): Session? {
    val parts = line.split(",")
    if (parts.size != 2) return null
    val minutes = parts[1].trim().toIntOrNull() ?: return null
    return Session(parts[0].trim(), minutes)
}

fun main() {
    println(parseSession("Kotlin, 45")?.minutes)
    println(parseSession("Kotlin, forty"))
}
```

```
ana@vm:~/kt/l07$ kotlinc Parse.kt -include-runtime -d parse.jar && java -jar parse.jar
45
null
```

**Um construtor precisa produzir um objeto ou lançar exceção.** Uma função consegue devolver `null`
para uma entrada que está só errada, o que, para texto que uma estudante digitou, costuma ser a
resposta honesta. A lição 10 leva funções como `parseSession` para dentro da própria classe, como um
companion object, que é onde o código Kotlin guarda as fábricas dele.
