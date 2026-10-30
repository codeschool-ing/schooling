---
title: Sealed interfaces
version: 1
---

A `sealed class` tem um limite por ser classe: um tipo só estende uma classe, então só pertence a uma
hierarquia de sealed class. **Uma `sealed interface` tem o mesmo conjunto fechado de implementações, e
um tipo implementa várias interfaces.** Ela também é a forma mais comum no Kotlin atual, porque a
maioria das hierarquias não tem estado nenhum para dividir numa classe base.

O planejador lê minutos de um texto que a estudante digita, e a leitura dá errado de dois jeitos que
pedem mensagens diferentes:

```kotlin
// SealedInterface.kt
sealed interface ParseError {
    data class NotANumber(val text: String) : ParseError
    data class OutOfRange(val minutes: Int) : ParseError
}

sealed interface Parsed {
    data class Ok(val minutes: Int) : Parsed
    data class Failed(val error: ParseError) : Parsed
}

fun parse(text: String): Parsed {
    val n = text.trim().toIntOrNull() ?: return Parsed.Failed(ParseError.NotANumber(text))
    if (n !in 1..600) return Parsed.Failed(ParseError.OutOfRange(n))
    return Parsed.Ok(n)
}

fun message(p: Parsed): String = when (p) {
    is Parsed.Ok -> "${p.minutes} min"
    is Parsed.Failed -> when (val e = p.error) {
        is ParseError.NotANumber -> "'${e.text}' is not a number"
        is ParseError.OutOfRange -> "${e.minutes} is outside 1 to 600"
    }
}

fun main() {
    for (input in listOf("45", "forty", "900")) println(message(parse(input)))
}
```

```
ana@vm:~/kt/l09$ kotlinc SealedInterface.kt -include-runtime -d sealedinterface.jar && java -jar sealedinterface.jar
45 min
'forty' is not a number
900 is outside 1 to 600
```

`: ParseError` sem parênteses: uma interface não tem construtor para chamar. `when (val e = p.error)`
dá nome ao valor testado dentro do próprio `when`, então os ramos fazem smart cast de `e` sem uma
linha separada para declará-lo.

**`parse` devolve um valor que diz o que deu errado, em vez de lançar exceção.** Quem chama não
consegue esquecer uma falha, porque o `when` sobre `Parsed` não compila sem o ramo `Failed`, e dentro
dele o `when` sobre `ParseError` não compila sem os dois tipos. A aula 13 compara isso com exceções e
com o `Result` da biblioteca padrão, e esta forma é a que ela recomenda para falhas que se espera que
quem chama trate.

## Sealed class ou sealed interface

**Uma sealed interface, a menos que os subtipos dividam estado ou um construtor**, e nesse caso a base
pode ser uma sealed class que o guarda. As duas dão o mesmo `when` exaustivo, e é por esse recurso que
você veio.
