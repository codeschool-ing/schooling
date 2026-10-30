---
title: also, para fazer algo no caminho
version: 1
---

O `also` passa o objeto como `it` e devolve o objeto. **Ele roda um efeito colateral sem mudar o que
passa**: uma linha de log, uma verificação, uma cópia guardada em algum lugar, no meio de uma corrente.

```kotlin
// Also.kt
fun main() {
    val long = listOf(45, 30, 60, 90, 20)
        .also { println("loaded ${it.size} sessions") }
        .filter { it >= 45 }
        .also { println("kept ${it.size}") }
        .sorted()
    println(long)

    val minutes = "75".toInt().also { require(it in 1..600) { "out of range: $it" } }
    println(minutes)

    val wrong = "900".toInt().also { require(it in 1..600) { "out of range: $it" } }
    println(wrong)
}
```

```
ana@vm:~/kt/l06$ kotlinc Also.kt -include-runtime -d also.jar && java -jar also.jar
loaded 5 sessions
kept 3
[45, 60, 90]
75
Exception in thread "main" java.lang.IllegalArgumentException: out of range: 900
	at AlsoKt.main(Also.kt:13)
	at AlsoKt.main(Also.kt)
```

As duas linhas de log mostram o tamanho da lista em dois pontos da corrente, e **tirando os `also` a
corrente calcula o mesmo resultado**, que é o teste de um bom. O segundo uso é uma verificação: o
`require` lança `IllegalArgumentException` com a mensagem da lambda dele quando a condição é falsa, e
a lição 13 volta a ele. Aqui ele deixa um valor ser verificado no momento em que é criado, e o terceiro
caso mostra a verificação disparando.

## Por que `it` e não `this`

`also` e `apply` devolvem os dois o objeto. A diferença é o nome lá dentro, e ela decorre do propósito
de cada um. O `apply` configura o objeto, então os membros dele dispensam prefixo. O `also` faz algo
**com** o objeto, muitas vezes passando-o a outra pessoa, `log(it)` ou `cache.save(it)`, e um `it`
explícito faz isso se ler naturalmente. Trocar um pelo outro ainda compila, e faz o código dizer algo
que ele não quer dizer.

## Uma ferramenta de depuração, também

`.also { println(it) }` é o jeito mais rápido de ver o que passa por uma corrente sem quebrá-la em
passos com nome. Vale conhecer exatamente para isso, e vale remover quando o bug for encontrado.
