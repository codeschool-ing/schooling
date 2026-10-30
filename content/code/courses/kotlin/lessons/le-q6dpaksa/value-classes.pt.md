---
title: Value classes: um tipo para um número
version: 1
---

`Session(course: String, minutes: Int)` recebe um `Int`, e qualquer `Int` cabe: um número de segundos,
um ano, uma contagem de sessões. O compilador não os distingue, porque têm o mesmo tipo. **Uma value
class embrulha um valor num tipo próprio**, para o compilador conseguir distinguir, e na JVM ela em
geral não custa nada em tempo de execução, porque o embrulho some no código compilado.

```schooling-example
{"language": "kotlin", "file": "Minutes.kt", "parts": [{"code": "@JvmInline\nvalue class Minutes(val value: Int) {\n    init {\n        require(value >= 0) { \"minutes cannot be negative: $value\" }\n    }", "note": "`value class` com exatamente uma propriedade. O `@JvmInline` é obrigatório na JVM e diz o que acontece lá: a classe é trocada pelo `Int` dela onde for possível."}, {"code": "    operator fun plus(other: Minutes) = Minutes(value + other.value)\n}", "note": "`operator fun plus` deixa dois `Minutes` serem somados com `+`. Qualquer classe declara operadores assim; os nomes das funções são fixados pela linguagem, `plus`, `minus`, `times` e assim por diante."}, {"code": "data class Session(val course: String, val length: Minutes)", "note": "A sessão agora diz o que o número dela é."}, {"code": "fun main() {\n    val total = Minutes(45) + Minutes(30)\n    println(total)\n    println(Session(\"Kotlin\", Minutes(45)))\n    println(Minutes(-5))\n}", "note": "A verificação do `init` roda como a de qualquer classe, então uma duração negativa não existe."}]}
```

```
ana@vm:~/kt/l08$ kotlinc Minutes.kt -include-runtime -d minutes.jar && java -jar minutes.jar
Minutes(value=75)
Session(course=Kotlin, length=Minutes(value=45))
Exception in thread "main" java.lang.IllegalArgumentException: minutes cannot be negative: -5
	at Minutes.constructor-impl(Minutes.kt:4)
	at MinutesKt.main(Minutes.kt:13)
	at MinutesKt.main(Minutes.kt)
```

## O que o compilador agora recusa

```kotlin
// MinutesWrong.kt
@JvmInline
value class Minutes(val value: Int)

data class Session(val course: String, val length: Minutes)

fun main() {
    val seconds = 2700
    println(Session("Kotlin", seconds))
}
```

```
ana@vm:~/kt/l08$ kotlinc MinutesWrong.kt -include-runtime -d minuteswrong.jar
MinutesWrong.kt:9:31: error: argument type mismatch: actual type is 'Int', but 'Minutes' was expected.
    println(Session("Kotlin", seconds))
                              ^^^^^^^
```

**Um número que significava segundos não cabe mais onde se esperam minutos.** Antes, esse erro teria
compilado, e uma sessão de 2.700 minutos teria aparecido numa tela. É a mesma troca de todas as outras
deste curso: um pouco mais escrito onde o valor é criado, e um tipo inteiro de erro recusado em todo
lugar onde ele é usado.

## Quando vale a pena

Uma value class compensa onde um tipo simples é fácil de confundir com outro do mesmo tipo: ids de
coisas diferentes que são todos `String`, quantidades em unidades diferentes que são todas `Int`.
**Para um valor que tem um só significado no programa inteiro, o tipo simples basta.** O planejador
ganha mais com ela nos ids, onde `CourseId` e `SessionId` impedem que o id de uma sessão seja passado
onde se espera o de um curso, que é exatamente o erro que compila com duas `String`.
