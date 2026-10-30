---
title: Argumentos padrão e argumentos nomeados
version: 1
---

Uma sessão de estudo tem curso, duração, data e se foi feita. A maioria das sessões é planejada para
hoje, ainda não foi feita e dura meia hora. **Um valor padrão num parâmetro deixa quem chama omiti-lo**,
e um argumento nomeado deixa quem chama dizer a qual parâmetro um valor se destina. Juntos, eles
substituem as sobrecargas de que o Java precisa, um método por combinação de argumentos.

```schooling-example
{"language": "kotlin", "file": "Describe.kt", "parts": [{"code": "fun describe(\n    course: String,\n    minutes: Int = 30,\n    done: Boolean = false,\n    date: String = \"2026-11-02\",\n): String =\n    \"$date  $course  $minutes min  ${if (done) \"done\" else \"planned\"}\"", "note": "Três parâmetros com padrão depois de um sem. A vírgula depois do último parâmetro é permitida, e faz o acréscimo de um quinto ser uma mudança de uma linha num diff."}, {"code": "fun main() {\n    println(describe(\"Kotlin\"))\n    println(describe(\"Kotlin\", 45))", "note": "Argumentos posicionais preenchem os parâmetros a partir da esquerda. Tudo o que não foi passado fica com o padrão."}, {"code": "    println(describe(\"Kotlin\", done = true))", "note": "Um argumento nomeado pula `minutes` e define só `done`, o que posições não conseguem fazer."}, {"code": "    println(describe(date = \"2026-11-03\", course = \"Android\"))\n}", "note": "Todos os argumentos nomeados, em qualquer ordem."}]}
```

```
ana@vm:~/kt/l03$ kotlinc Describe.kt -include-runtime -d describe.jar && java -jar describe.jar
2026-11-02  Kotlin  30 min  planned
2026-11-02  Kotlin  45 min  planned
2026-11-02  Kotlin  30 min  done
2026-11-03  Android  30 min  planned
```

## Dê nome aos argumentos que quem lê não adivinha

`describe("Kotlin", 45, true)` compila, e quem lê precisa ir ver o que `true` significa.
`describe("Kotlin", 45, done = true)` diz isso na chamada. **Nomeie um `Boolean`, nomeie um número
cuja unidade não é óbvia, e nomeie qualquer argumento que vem depois de um padrão que você pulou.** A
própria biblioteca padrão do Kotlin faz isso, como em `equals("KOTLIN", ignoreCase = true)` da
lição 1.

Depois que um argumento é nomeado, os seguintes só continuam posicionais se estiverem nas próprias
posições. Ponha um argumento posicional onde o compilador não sabe qual parâmetro ele preenche, e ele
recusa:

```kotlin
// Mixed.kt
fun describe(course: String, minutes: Int = 30, done: Boolean = false): String =
    "$course $minutes $done"

fun main() {
    println(describe(minutes = 45, "Kotlin"))
}
```

```
ana@vm:~/kt/l03$ kotlinc Mixed.kt -include-runtime -d mixed.jar
Mixed.kt:6:13: error: no value passed for parameter 'course'.
    println(describe(minutes = 45, "Kotlin"))
            ^^^^^^^^
Mixed.kt:6:36: error: mixing named and positional arguments is not allowed unless the order of the arguments matches the order of the parameters.
    println(describe(minutes = 45, "Kotlin"))
                                   ^^^^^^^^
```

## No que os padrões compilam

A JVM não tem argumentos padrão. O compilador faz um método que recebe todos os parâmetros, e um
segundo, escondido, que preenche os padrões e chama o primeiro. **Do Kotlin você nunca vê a
diferença.** Do Java, você vê só o método com todos os parâmetros, e precisa passar todos.
`@JvmOverloads` na função pede ao compilador que gere também as sobrecargas no estilo Java, uma por
padrão omitido, que é o que uma biblioteca Android escrita em Kotlin faz para quem a chama de Java.

## Um padrão é avaliado a cada chamada

`date: String = today()` chamaria `today()` toda vez que o padrão fosse usado, não uma vez quando o
programa começa. É isso que torna seguro calcular um padrão a partir de algo que muda, e é também por
isso que um padrão que faz algo caro sai caro em toda chamada que o omite.
