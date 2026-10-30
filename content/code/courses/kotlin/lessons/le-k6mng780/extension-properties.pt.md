---
title: Propriedades de extensão, e onde as extensões moram
version: 1
---

Uma propriedade também pode ser extensão, desde que seja calculada:

```kotlin
// ExtProps.kt
val List<Int>.total: Int
    get() = sum()

val Int.isLong: Boolean
    get() = this >= 60

fun main() {
    val week = listOf(45, 90, 30)
    println(week.total)
    println(week.count { it.isLong })
}
```

```
ana@vm:~/kt/l11$ kotlinc ExtProps.kt -include-runtime -d extprops.jar && java -jar extprops.jar
165
1
```

**Uma propriedade de extensão não tem campo de apoio**: é um getter, e um setter para um `var`, preso ao
tipo por fora, e não há lugar num `Int` para guardar nada a mais. Um inicializador, portanto, é
recusado:

```kotlin
// ExtField.kt
val Int.bonus: Int = 5

fun main() {
    println(45.bonus)
}
```

```
ana@vm:~/kt/l11$ kotlinc ExtField.kt -include-runtime -d extfield.jar
ExtField.kt:2:22: error: extension property cannot be initialized because it has no backing field.
val Int.bonus: Int = 5
                     ^
```

## Onde declará-las

Uma extensão declarada no topo de um arquivo é visível onde quer que o pacote daquele arquivo seja
importado, o que num projeto pequeno é em todo lugar. Três hábitos impedem que isso vire uma nuvem de
funções em `String` que ninguém encontra:

- **declare uma extensão perto do código que precisa dela**, e torne-a `private` ou `internal` quando só
  esse código precisa;
- **estenda tipos seus por conveniência, e tipos alheios por vocabulário**: `Int.asHours()` diz algo do
  domínio do planejador e vale dividir; `String.trimAndUpper()` é um caso isolado;
- **quando uma extensão precisa do estado privado da classe, ela deveria ser membro**, porque uma
  extensão só vê a API pública, como qualquer outro código de fora.

## Extensões dentro de uma classe

Uma extensão também pode ser declarada dentro de uma classe, onde tem dois receptores: a instância da
classe e o valor estendido. Os blocos da lição 6 que se leem como uma pequena linguagem para um objeto
muitas vezes são feitos assim, e o script do Gradle da lição 19 também, onde `implementation("…")`
dentro de `dependencies { }` é exatamente uma função dessas.
