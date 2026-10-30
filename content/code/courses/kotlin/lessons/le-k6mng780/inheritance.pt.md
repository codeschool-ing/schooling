---
title: Herança: final por padrão, open por escolha
version: 1
---

O Java deixa qualquer classe ser estendida a menos que ela diga `final`. **O Kotlin é o contrário:
toda classe e todo membro são `final` a menos que digam `open`**, então estender uma classe que alguém
não desenhou para isso não compila:

```kotlin
// Final.kt
class Session(val minutes: Int)

class TimedSession(minutes: Int, val startedAt: String) : Session(minutes)

fun main() {
    println(TimedSession(45, "14:30").minutes)
}
```

```
ana@vm:~/kt/l11$ kotlinc Final.kt -include-runtime -d final.jar
Final.kt:4:59: error: this type is final, so it cannot be extended.
class TimedSession(minutes: Int, val startedAt: String) : Session(minutes)
                                                          ^^^^^^^
```

O motivo é uma falha conhecida da herança: uma subclasse depende do comportamento interno da classe
mãe, que o autor dela é livre para mudar, e a subclasse quebra sem nenhum dos lados ter feito nada de
errado. **Tornar a extensão uma decisão explícita quer dizer que o autor de uma classe sabe que ela vai
ser estendida**, e a desenha para isso.

## `open`, `abstract` e `override`

```kotlin
// Inheritance.kt
abstract class Reminder(val course: String) {
    abstract fun message(): String
    open fun prefix() = "reminder"
    fun show() = "${prefix()}: ${message()}"
}

class DailyReminder(course: String, val minutes: Int) : Reminder(course) {
    override fun message() = "$minutes min of $course today"
}

class ExamReminder(course: String, val date: String) : Reminder(course) {
    override fun prefix() = "EXAM"
    override fun message() = "$course on $date"
}

fun main() {
    val reminders: List<Reminder> = listOf(DailyReminder("Kotlin", 45), ExamReminder("Android", "2026-12-01"))
    reminders.forEach { println(it.show()) }
}
```

```
ana@vm:~/kt/l11$ kotlinc Inheritance.kt -include-runtime -d inheritance.jar && java -jar inheritance.jar
reminder: 45 min of Kotlin today
EXAM: Android on 2026-12-01
```

| num membro | significa |
|---|---|
| nada | final: subclasses não o trocam, como o `show` |
| `open` | subclasses podem trocá-lo, como o `prefix` |
| `abstract` | subclasses precisam fornecê-lo; a classe em si não é montada |
| `override` | isto troca um membro da classe mãe; ele próprio é `open` a menos que se marque `final override` |

Uma `abstract class` não é instanciada, `Reminder("Kotlin")` é recusado, e as subclasses passam o
argumento do construtor para cima com `: Reminder(course)`. **O `show` chama `prefix()` e `message()`,
e recebe as versões da subclasse em tempo de execução**: é para isso que serve sobrescrever.

## Prefira interfaces e composição

O Kotlin torna a herança deliberada porque as alternativas costumam ser melhores. Uma interface afirma
uma promessa sem prender ninguém a uma implementação; a delegação, na próxima seção, reaproveita uma
implementação sem herdar dela. **Use `open` quando uma família de classes divide de fato um
comportamento desenhado para ser especializado**, como as classes do próprio framework do Android.
