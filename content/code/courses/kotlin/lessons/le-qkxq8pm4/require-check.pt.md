---
title: require, check e error: falhas com uma frase
version: 1
---

Três funções da biblioteca padrão lançam exceção por você, e a escolha entre elas é uma afirmação sobre
de quem é o erro:

| função | lança | significa |
|---|---|---|
| `require(condição) { "…" }` | `IllegalArgumentException` | quem chamou passou algo errado |
| `check(condição) { "…" }` | `IllegalStateException` | este objeto está no estado errado para a chamada |
| `error("…")` | `IllegalStateException` | esta linha devia ser inalcançável |

`requireNotNull` e `checkNotNull` são as versões para um valor anulável: lançam exceção quando ele é
`null`, e caso contrário o devolvem com o tipo não nulo, para o resto da função usá-lo sem `!!`.

```kotlin
// Guards.kt
class Timer {
    private var startedAt: Long? = null

    fun start(at: Long) {
        check(startedAt == null) { "already running since $startedAt" }
        startedAt = at
    }

    fun stop(at: Long): Long {
        val start = checkNotNull(startedAt) { "not running" }
        require(at >= start) { "stop at $at is before start at $start" }
        startedAt = null
        return at - start
    }
}

fun main() {
    val t = Timer()
    t.start(100)
    println(t.stop(160))
    try {
        t.stop(200)
    } catch (e: IllegalStateException) {
        println("${e::class.simpleName}: ${e.message}")
    }
    t.start(300)
    try {
        t.stop(250)
    } catch (e: IllegalArgumentException) {
        println("${e::class.simpleName}: ${e.message}")
    }
}
```

```
ana@vm:~/kt/l13$ kotlinc Guards.kt -include-runtime -d guards.jar && java -jar guards.jar
60
IllegalStateException: not running
IllegalArgumentException: stop at 250 is before start at 300
```

Parar um cronômetro que não está rodando é um mau uso do cronômetro: `check`. Pará-lo num instante
anterior ao início é um argumento errado: `require`. **Cada mensagem nomeia os valores envolvidos**,
então a linha de log basta para entender a falha sem depurador.

## Elas são para bugs

`require` e `check` descrevem condições que um programa correto nunca viola. Não são um jeito de tratar
uma estudante digitando `forty`; isso é entrada esperada, e pertence ao `?:` da aula 2, aos resultados
selados da aula 9 ou ao `Result` da próxima seção. **Se um `require` dispara em produção, a correção
está no código que o chamou**, não num `catch` em volta dele.
