---
title: run e with, para calcular um resultado
version: 1
---

`run` e `with` tornam o objeto o receptor e devolvem o resultado do bloco. São o `apply` com a outra
resposta à segunda pergunta: **use-os quando o bloco calcula algo a partir do objeto**, e o objeto em
si não é o que você quer de volta.

```kotlin
// RunWith.kt
fun main() {
    val sessions = listOf(45, 30, 60, 20)

    val summary = sessions.run {
        val total = sum()
        val longest = max()
        "$size sessions, $total min, longest $longest"
    }
    println(summary)

    val text = with(StringBuilder()) {
        append("Kotlin")
        append(" · ")
        append(sessions.sum())
        toString()
    }
    println(text)

    val goal = run {
        val perDay = 45
        val days = 5
        perDay * days
    }
    println(goal)
}
```

```
ana@vm:~/kt/l06$ kotlinc RunWith.kt -include-runtime -d runwith.jar && java -jar runwith.jar
4 sessions, 155 min, longest 60
Kotlin · 155
225
```

`sessions.run { … }` usa `sum()`, `max()` e `size` sem prefixo, e a última expressão, o template, é o
resultado. **Os `val` dentro do bloco só existem ali**, então `total` e `longest` não vazam para o
resto do `main`.

## O `with` é o `run` com o objeto entre parênteses

`with(x) { … }` e `x.run { … }` fazem a mesma coisa. O `with` não é uma extensão: o objeto é um
argumento normal, e o bloco vem depois dele. A leitura de costume é **`with` para "com este objeto,
faça várias coisas"**, como com o builder acima, em que o `toString()` no fim faz o resultado ser uma
`String` e não o builder. O `x.run` cabe no fim de uma corrente ou atrás de `?.`, onde o `with` não
vai: não existe `?.with`.

## `run` sem objeto

O último bloco é um `run` chamado sobre nada. É um bloco que calcula um valor com nomes próprios e
devolve a última expressão. **Ele limita o alcance de nomes temporários**, `perDay` e `days`, ao
cálculo que precisa deles, para a função em volta não terminar com uma dúzia de `val` que ninguém lê
duas vezes.
