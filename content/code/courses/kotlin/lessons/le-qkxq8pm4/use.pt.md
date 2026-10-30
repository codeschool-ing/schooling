---
title: use: fechando o que foi aberto, mesmo na falha
version: 1
---

Um arquivo, uma conexão de rede ou um cursor de banco de dados precisa ser fechado quando o programa
termina de usá-lo, e "terminar" inclui "falhar no meio". A resposta do Java é o try-with-resources. **A
do Kotlin é o `use`, uma função inline em tudo o que é `AutoCloseable`**, que roda um bloco e fecha o
recurso depois, tenha o bloco terminado ou lançado exceção.

```kotlin
// Use.kt
class Log(private val name: String) : AutoCloseable {
    init {
        println("open $name")
    }

    fun write(line: String) {
        if (line.isEmpty()) throw IllegalArgumentException("empty line")
        println("write $line")
    }

    override fun close() = println("close $name")
}

fun main() {
    Log("week.log").use { it.write("45 min Kotlin") }
    try {
        Log("bad.log").use { it.write("") }
    } catch (e: IllegalArgumentException) {
        println("caught: ${e.message}")
    }
}
```

```
ana@vm:~/kt/l13$ kotlinc Use.kt -include-runtime -d use.jar && java -jar use.jar
open week.log
write 45 min Kotlin
close week.log
open bad.log
close bad.log
caught: empty line
```

No segundo bloco o `write` lançou exceção, e o `close bad.log` foi impresso mesmo assim, **antes** de a
exceção chegar ao `catch`. Essa é a garantia: um recurso entregue ao `use` é fechado em todo caminho de
saída do bloco. O `use` devolve o valor do bloco, então ele se lê como um `let` que faz a limpeza.

## Arquivos

A biblioteca padrão acrescenta ajudantes no estilo `use` às classes de arquivo do Java, então ler e
escrever um arquivo pequeno é uma linha cada:

```kotlin
// Files.kt
import java.io.File

fun main() {
    val file = File("week.txt")
    file.writeText("45\n30\n60\n")
    val total = file.useLines { lines -> lines.sumOf { it.toInt() } }
    println(total)
    println(file.readLines())
}
```

```
ana@vm:~/kt/l13$ kotlinc Files.kt -include-runtime -d files.jar && java -jar files.jar
135
[45, 30, 60]
```

O `useLines` abre o arquivo, entrega ao bloco uma sequência preguiçosa das linhas dele, as sequências
da aula 5, e fecha o arquivo quando o bloco retorna. **A sequência só vale dentro do bloco**: devolvê-la
e lê-la depois seria ler um arquivo fechado. O `readLines()` lê o arquivo inteiro numa lista e o fecha
na hora, o que é bom para um arquivo pequeno e desperdício para um grande.

O Android acrescenta um motivo para se importar. Um app que vaza handles de arquivo ou cursores fica
sem eles depois de um tempo, e a falha aparece longe do código que vazou. O `use` torna o vazamento
impossível de escrever por acidente.
