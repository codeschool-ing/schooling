---
title: Escolhendo como uma função falha
version: 1
---

O planejador agora tem quatro jeitos de dizer que algo deu errado, e cada um diz algo diferente a quem
chama. A escolha não é de estilo; **é sobre quem deve lidar com a falha, e quando**.

| a falha | como relatar | exemplo |
|---|---|---|
| a ausência é normal e não tem motivo | um resultado anulável, `T?` | `toIntOrNull()`, `firstOrNull()` |
| esperada, com motivos que quem chama trata de jeitos diferentes | um resultado selado | `Parsed.Failed(ParseError.OutOfRange(900))` |
| esperada, vinda de código Java ou de I/O com exceções próprias | `Result<T>` com `runCatching` | ler um arquivo que pode faltar |
| um bug: o programa está errado se isso acontece | lançar, com `require`, `check` ou `error` | parar um cronômetro que não está rodando |

O mesmo programa, escrito com cada um no seu lugar:

```kotlin
// Planner.kt
import java.io.File

sealed interface Parsed {
    data class Ok(val minutes: Int) : Parsed
    data class Bad(val line: String, val reason: String) : Parsed
}

fun parse(line: String): Parsed {
    val n = line.trim().toIntOrNull() ?: return Parsed.Bad(line, "not a number")
    if (n !in 1..600) return Parsed.Bad(line, "outside 1 to 600")
    return Parsed.Ok(n)
}

fun load(path: String): Result<List<String>> = runCatching { File(path).readLines() }

fun weekTotal(parsed: List<Parsed>): Int {
    require(parsed.isNotEmpty()) { "weekTotal needs at least one line" }
    return parsed.filterIsInstance<Parsed.Ok>().sumOf { it.minutes }
}

fun main() {
    File("week.txt").writeText("45\nforty\n900\n30\n")
    for (path in listOf("week.txt", "missing.txt")) {
        load(path).fold(
            onSuccess = { lines ->
                val parsed = lines.map(::parse)
                parsed.filterIsInstance<Parsed.Bad>().forEach { println("skipped '${it.line}': ${it.reason}") }
                println("$path: ${weekTotal(parsed)} min")
            },
            onFailure = { println("$path: could not read (${it::class.simpleName})") },
        )
    }
}
```

```
ana@vm:~/kt/l13$ kotlinc Planner.kt -include-runtime -d planner.jar && java -jar planner.jar
skipped 'forty': not a number
skipped '900': outside 1 to 600
week.txt: 75 min
missing.txt: could not read (FileNotFoundException)
```

Uma linha ruim é um `Parsed.Bad`: esperada, relatada com o motivo, e a semana segue. Um arquivo que
falta é um `Result.failure`, porque a exceção veio do código de arquivo do Java e o tipo dela diz o que
aconteceu. Uma semana vazia passada a `weekTotal` seria uma falha de `require`: nenhum código acima
produz uma, e se uma mudança futura produzisse, seria um bug que deveria parar o programa e ser visto.

**O teste para cada caso é uma pergunta: se isto acontecer, o código de quem está errado?** Se de
ninguém, devolva como valor. Se de quem chamou, lance.
