---
title: Propriedades delegadas: lazy, observable e mapa
version: 1
---

O `by` funciona em propriedades também. **Uma propriedade delegada entrega o getter, e o setter, a
outro objeto**, que decide como o valor é guardado e o que acontece quando ele é lido ou escrito. A
biblioteca padrão traz os delegados de que a maioria dos programas precisa.

```kotlin
// Delegates.kt
import kotlin.properties.Delegates

class Settings {
    val goal: Int by lazy {
        println("computing goal")
        300
    }

    var theme: String by Delegates.observable("light") { _, old, new ->
        println("theme: $old -> $new")
    }
}

fun main() {
    val s = Settings()
    println("created")
    println(s.goal)
    println(s.goal)
    s.theme = "dark"
    println(s.theme)
}
```

```
ana@vm:~/kt/l11$ kotlinc Delegates.kt -include-runtime -d delegates.jar && java -jar delegates.jar
created
computing goal
300
300
theme: light -> dark
dark
```

## `by lazy`

`goal` não foi calculado quando o objeto foi montado, `created` foi impresso antes, e ele foi calculado
**uma vez**, na primeira leitura; a segunda leitura reaproveitou o valor. Essa é a promessa da lição 7:
diferente do `lateinit`, uma propriedade `lazy` não é lida vazia, porque lê-la é o que a preenche. Por
padrão, o primeiro cálculo é protegido contra duas threads rodando-o ao mesmo tempo.

Use-o para um valor caro que talvez nunca seja preciso, e para um que depende de algo que só fica
pronto depois da construção.

## `Delegates.observable`

`theme` guarda o valor normalmente e roda a lambda depois de cada atribuição, com a propriedade, o
valor antigo e o novo; o `_` pula a propriedade. **É um setter com um gancho, escrito uma vez**, e o
planejador poderia usá-lo para salvar uma configuração no instante em que ela muda.

## Um mapa como armazenamento

```kotlin
// MapDelegate.kt
class Row(map: Map<String, Any?>) {
    val course: String by map
    val minutes: Int by map
}

fun main() {
    val row = Row(mapOf("course" to "Kotlin", "minutes" to 45))
    println("${row.course}: ${row.minutes}")
}
```

```
ana@vm:~/kt/l11$ kotlinc MapDelegate.kt -include-runtime -d mapdelegate.jar && java -jar mapdelegate.jar
Kotlin: 45
```

Cada propriedade lê a entrada do mapa com o próprio nome. Isso é prático para linhas lidas de JSON ou
de um formulário, e confia totalmente no mapa: uma chave ausente lança exceção quando a propriedade é
lida, e um valor do tipo errado lança `ClassCastException`. A segurança de tipo das propriedades
termina no mapa.
