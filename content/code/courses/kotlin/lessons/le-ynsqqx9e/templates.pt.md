---
title: Strings, templates e a string bruta
version: 1
---

A primeira tela do planejador é texto: um curso, um número de minutos, um total. O Kotlin monta texto
pondo valores dentro de um literal de string, em vez de colar strings com `+`, e a sintaxe tem duas
formas.

```schooling-example
{"language": "kotlin", "file": "Report.kt", "parts": [{"code": "fun main() {\n    val course = \"Kotlin\"\n    val minutes = 75", "note": "Dois valores que o relatório vai mostrar."}, {"code": "    println(\"$course: $minutes min\")", "note": "`$name` insere o valor de um nome na string. O nome termina onde terminam as letras, então os dois-pontos depois de `course` são texto comum."}, {"code": "    println(\"$course: ${minutes / 60} h ${minutes % 60} min\")", "note": "`${…}` aceita qualquer expressão. `/` e `%` são divisão inteira e resto, então 75 minutos são 1 h e 15 min."}, {"code": "    println(\"Course name has ${course.length} letters\")", "note": "Uma propriedade de um valor também é uma expressão, então precisa das chaves. Sem elas, `$course.length` imprimiria `Kotlin.length`."}, {"code": "    println(\"Price: \\$0\")", "note": "Uma barra invertida antes do `$` o mantém como cifrão."}, {"code": "    val report = \"\"\"\n        Week 44\n          $course  $minutes min\n    \"\"\".trimIndent()\n    println(report)\n}", "note": "Três aspas abrem uma string bruta: ela atravessa linhas, e uma barra invertida nela é só uma barra invertida. O `trimIndent()` remove o recuo que as linhas compartilham, que só existe para manter o código arrumado."}]}
```

```
ana@vm:~/kt/l01$ kotlinc Report.kt -include-runtime -d report.jar && java -jar report.jar
Kotlin: 75 min
Kotlin: 1 h 15 min
Course name has 6 letters
Price: $0
Week 44
  Kotlin  75 min
```

**Templates são avaliados onde a string é montada**, uma vez. Um template não é uma fórmula que se
atualiza quando `minutes` muda depois; é o mesmo que escrever a concatenação à mão, que é no que o
compilador o transforma.

## Uma string não muda

Uma `String` em Kotlin, como em Java, é imutável. Toda função que parece mudá-la devolve uma string
nova e deixa a antiga em paz:

```kotlin
// Upper.kt
fun main() {
    val course = "kotlin"
    val shout = course.uppercase()
    println(course)
    println(shout)
    println(course.replaceFirstChar { it.uppercase() })
}
```

```
ana@vm:~/kt/l01$ kotlinc Upper.kt -include-runtime -d upper.jar && java -jar upper.jar
kotlin
KOTLIN
Kotlin
```

`course` continua `kotlin` depois do `uppercase()`, porque a chamada montou `KOTLIN` como uma segunda
string. A última linha recebe um bloco de código entre chaves, que a aula 4 chama de lambda; por
enquanto basta saber que ele põe a primeira letra em maiúscula. **Numa `String` não existe outro tipo
de função**: nada consegue mudá-la, então tudo o que parece uma mudança devolve uma string nova, e
esquecer de guardar o resultado é o bug. `course.uppercase()` sozinho numa linha compila, roda e não
faz nada que se veja.

## Comparando strings

O `==` compara duas strings pelos caracteres. Não é o hábito do Java, em que `==` em objetos compara
identidade e `equals` compara conteúdo; o `==` do Kotlin chama o `equals` por você. A aula 8 volta a
isso com classes suas, e ao `===`, que é identidade.

```kotlin
// Compare.kt
fun main() {
    val a = "Kotlin"
    val b = "kot" + "lin".uppercase().lowercase()
    println(b)
    println(a == b.replaceFirstChar { it.uppercase() })
    println(a.equals("KOTLIN", ignoreCase = true))
}
```

```
ana@vm:~/kt/l01$ kotlinc Compare.kt -include-runtime -d compare.jar && java -jar compare.jar
kotlin
true
true
```

A última linha dá nome a um argumento, `ignoreCase = true`, que é um recurso de toda chamada de
função em Kotlin e o assunto da aula 3.
