---
title: Quanto custa um singleton
version: 1
---

O objeto `Planner` da seção 02 guardava as sessões do programa inteiro. **Todo trecho de código que
nomeia `Planner` divide essa única lista, e nada no código diz isso.** Tudo bem até dois deles suporem
que começam de uma semana vazia. Duas pequenas verificações mostram isso, escritas como funções
simples porque a lição 18 ainda não apresentou um framework de teste:

```kotlin
// Shared.kt
object Planner {
    val sessions = mutableListOf<Int>()
    fun total() = sessions.sum()
}

fun checkOneSession() {
    Planner.sessions.add(45)
    check(Planner.total() == 45) { "expected 45, got ${Planner.total()}" }
    println("one session: ok")
}

fun checkEmptyWeek() {
    check(Planner.total() == 0) { "expected 0, got ${Planner.total()}" }
    println("empty week: ok")
}

fun main() {
    checkOneSession()
    checkEmptyWeek()
}
```

```
ana@vm:~/kt/l10$ kotlinc Shared.kt -include-runtime -d shared.jar && java -jar shared.jar
one session: ok
Exception in thread "main" java.lang.IllegalStateException: expected 0, got 45
	at SharedKt.checkEmptyWeek(Shared.kt:14)
	at SharedKt.main(Shared.kt:20)
	at SharedKt.main(Shared.kt)
```

O `check` lança `IllegalStateException` quando a condição é falsa. **Cada verificação está correta
sozinha, e a segunda falha porque a primeira rodou antes.** Troque as duas chamadas no `main` e ambas
passam. Uma falha que depende da ordem é o tipo mais caro de achar, porque aparece e some conforme a
ordem muda, e um framework de teste, que pode rodar os testes em qualquer ordem, vai achá-la ao acaso.

## A solução: uma instância, passada como parâmetro

O estado do planejador pertence a uma classe comum, e o código que precisa de um planejador recebe um:

```kotlin
// Passed.kt
class Planner {
    private val sessions = mutableListOf<Int>()
    fun add(minutes: Int) { sessions.add(minutes) }
    fun total() = sessions.sum()
}

fun checkOneSession(planner: Planner) {
    planner.add(45)
    check(planner.total() == 45) { "expected 45, got ${planner.total()}" }
    println("one session: ok")
}

fun checkEmptyWeek(planner: Planner) {
    check(planner.total() == 0) { "expected 0, got ${planner.total()}" }
    println("empty week: ok")
}

fun main() {
    checkOneSession(Planner())
    checkEmptyWeek(Planner())
}
```

```
ana@vm:~/kt/l10$ kotlinc Passed.kt -include-runtime -d passed.jar && java -jar passed.jar
one session: ok
empty week: ok
```

Cada verificação monta o próprio planejador, então nenhuma vê as sessões da outra. **Entregar a um
objeto as coisas de que ele depende, em vez de deixá-lo buscar uma global, se chama injeção de
dependência**, e na forma mais simples é só um parâmetro. O `android-apps` encontra uma biblioteca que
automatiza isso; a ideia por baixo é a de cima.

Guarde o `object` para o que não tem estado, ou para um estado que é de fato um só para o programa e é
seguro de dividir: uma tabela de constantes, um formatador sem configurações, uma implementação
padrão.
