---
title: Funções de nível superior, locais e privadas
version: 1
---

A seção 02 disse que o topo de um arquivo é o lugar normal de uma função. Mais dois lugares importam,
e um modificador decide quem enxerga cada um deles.

## Uma função dentro de uma função

Uma função declarada dentro de outra é uma **função local**. Ela só é chamada pelo corpo que a
declara, e lê os parâmetros e os `val` desse corpo sem que eles sejam passados:

```kotlin
// Report.kt
fun report(course: String, sessions: List<Int>): String {
    fun line(label: String, value: Int) = "$course  ${label.padEnd(8)} $value min"
    return line("total", sessions.sum()) + "\n" + line("longest", sessions.max())
}

fun main() {
    println(report("Kotlin", listOf(45, 30, 60)))
}
```

```
ana@vm:~/kt/l03$ kotlinc Report.kt -include-runtime -d report.jar && java -jar report.jar
Kotlin  total    135 min
Kotlin  longest  60 min
```

`line` usa `course`, que pertence a `report`, e ninguém o passou. **Uma função local tem o tamanho
certo para um ajudante que não tem sentido fora de uma função**: formatar uma linha deste relatório,
aqui. Ninguém mais consegue chamá-la, então ninguém mais consegue usá-la errado, e quem procura os
chamadores encontra todos na tela.

`padEnd(8)` completa uma string com espaços até oito caracteres, que é o que alinha os números.

## `private` no topo de um arquivo

Uma função de nível superior é visível em todos os arquivos do módulo por padrão. **`private` numa
função de nível superior a torna visível só dentro do próprio arquivo**, o equivalente em Kotlin a um
ajudante privado estático numa classe Java:

```kotlin
// Planner.kt
private fun format(minutes: Int) = "${minutes / 60} h ${minutes % 60} min"

fun weekSummary(minutes: List<Int>) = "this week: " + format(minutes.sum())
```

```kotlin
// Main.kt
fun main() {
    println(weekSummary(listOf(45, 30, 60)))
    println(format(135))
}
```

```
ana@vm:~/kt/l03$ kotlinc Planner.kt Main.kt -include-runtime -d planner.jar
Main.kt:4:13: error: cannot access 'fun format(minutes: Int): String': it is private in file.
    println(format(135))
            ^^^^^^
```

Dois arquivos, compilados juntos ao nomear os dois. `weekSummary` é pública, então `Main.kt` consegue
chamá-la. `format` é privada de `Planner.kt`, e o compilador recusa a chamada vinda de `Main.kt`
pelo nome. Tire essa linha e o programa compila:

```kotlin
// Main.kt
fun main() {
    println(weekSummary(listOf(45, 30, 60)))
}
```

```
ana@vm:~/kt/l03$ kotlinc Planner.kt Main.kt -include-runtime -d planner.jar && java -jar planner.jar
this week: 2 h 15 min
```

A aula 7 cobre direito os quatro modificadores de visibilidade, incluindo o `internal`, que é o que
importa quando um projeto tem módulos, na aula 19.

## A ordem das declarações não importa

`main` chama `weekSummary` esteja ela declarada acima ou abaixo, no mesmo arquivo ou em outro. O
Kotlin lê todas as declarações de um arquivo, e de todo arquivo compilado junto, antes de verificar
uma única chamada. Organize o arquivo para quem lê: primeiro a função que explica o arquivo, e os
ajudantes depois dela.
