---
title: O when que o compilador obriga a terminar
version: 1
---

A recompensa de uma hierarquia selada chega no dia em que ela muda. O planejador ganha uma quarta
forma: uma sessão que a estudante pulou, com um motivo.

```kotlin
// Skipped.kt
sealed class Session {
    data class Planned(val course: String, val minutes: Int) : Session()
    data class Running(val course: String, val startedAt: String) : Session()
    data class Done(val course: String, val minutes: Int) : Session()
    data class Skipped(val course: String, val reason: String) : Session()
}

fun describe(s: Session): String = when (s) {
    is Session.Planned -> "${s.course}: ${s.minutes} min planned"
    is Session.Running -> "${s.course}: running since ${s.startedAt}"
    is Session.Done -> "${s.course}: ${s.minutes} min done"
}

fun main() {
    println(describe(Session.Skipped("Kotlin", "ill")))
}
```

```
ana@vm:~/kt/l09$ kotlinc Skipped.kt -include-runtime -d skipped.jar
Skipped.kt:9:36: error: 'when' expression must be exhaustive. Add the 'is Skipped' branch or an 'else' branch.
fun describe(s: Session): String = when (s) {
                                   ^^^^
```

**O compilador recusou, e nomeou tanto o ramo que falta quanto a saída.** Todo `when` sobre `Session`
no planejador falha do mesmo jeito, então acrescentar uma forma produz a lista de cada lugar que
precisa tratá-la, com arquivo e linha. Nada chega meio tratado ao celular de uma estudante.

## O `else` que desliga isso

A mensagem oferece duas soluções, e a segunda é a armadilha:

```kotlin
// SkippedElse.kt
sealed class Session {
    data class Planned(val course: String, val minutes: Int) : Session()
    data class Running(val course: String, val startedAt: String) : Session()
    data class Done(val course: String, val minutes: Int) : Session()
    data class Skipped(val course: String, val reason: String) : Session()
}

fun describe(s: Session): String = when (s) {
    is Session.Planned -> "${s.course}: ${s.minutes} min planned"
    is Session.Done -> "${s.course}: ${s.minutes} min done"
    else -> "${s} is in progress"
}

fun main() {
    println(describe(Session.Running("Android", "14:30")))
    println(describe(Session.Skipped("Kotlin", "ill")))
}
```

```
ana@vm:~/kt/l09$ kotlinc SkippedElse.kt -include-runtime -d skippedelse.jar && java -jar skippedelse.jar
Running(course=Android, startedAt=14:30) is in progress
Skipped(course=Kotlin, reason=ill) is in progress
```

Com o `else`, a sessão pulada compilou e foi descrita como **em andamento**, o que é falso. O `else`
foi escrito quando significava "em andamento", e continuou significando "tudo o que não está listado
acima", inclusive formas que não existiam quando ele foi escrito. **Um `else` num tipo selado troca um
erro de compilação hoje por uma resposta errada amanhã.** Escreva um ramo por subtipo, e deixe o
compilador achar os lugares aonde um novo precisa ir.

## Exaustivo também para instruções

Desde o Kotlin 1.7, um `when` sobre um tipo selado ou um enum precisa ser exaustivo mesmo quando é uma
instrução cujo valor não é usado. Antes disso, só o `when` usado como valor era verificado, e um `when`
que fazia algo em cada ramo deixava passar um caso em silêncio. Todo Kotlin que você instala hoje
verifica os dois.
