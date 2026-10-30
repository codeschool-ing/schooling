---
title: Result: uma falha como valor
version: 1
---

`Result<T>` guarda um valor do tipo `T` ou a exceção que o impediu. **`runCatching { … }` roda um bloco e
embrulha o que quer que tenha acontecido**, e quem chama decide então o que uma falha significa, com a
falha na mão como valor em vez de passando voando por ele.

```schooling-example
{"language": "kotlin", "file": "ResultDemo.kt", "parts": [{"code": "fun parseMinutes(text: String): Result<Int> = runCatching { text.trim().toInt() }", "note": "A exceção que o `toInt` lança vira um `Result.failure`; um número vira um `Result.success`. O tipo da função agora diz que ela falha."}, {"code": "fun main() {\n    val ok = parseMinutes(\"45\")\n    val bad = parseMinutes(\"forty\")\n    println(ok)\n    println(bad)", "note": "Um `Result` é impresso como `Success(…)` ou `Failure(…)` com a exceção dentro."}, {"code": "    println(ok.map { it * 60 }.getOrElse { -1 })\n    println(bad.map { it * 60 }.getOrElse { -1 })", "note": "O `map` transforma o valor se houver um e deixa uma falha passar intocada; o `getOrElse` desembrulha, com um substituto calculado a partir da exceção."}, {"code": "    println(bad.exceptionOrNull()?.message)\n    val text = bad.fold(\n        onSuccess = { \"$it min\" },\n        onFailure = { \"could not read: ${it.message}\" },\n    )\n    println(text)", "note": "O `fold` trata os dois casos de uma vez e devolve um valor, o `when` de um `Result`."}, {"code": "    val total = listOf(\"45\", \"x\", \"30\").map(::parseMinutes).filter { it.isSuccess }.sumOf { it.getOrThrow() }\n    println(total)\n}", "note": "Interpretar muitos, ficar com os que funcionaram. O `getOrThrow` só é seguro aqui por causa do `filter` antes dele."}]}
```

```
ana@vm:~/kt/l13$ kotlinc ResultDemo.kt -include-runtime -d resultdemo.jar && java -jar resultdemo.jar
Success(45)
Failure(java.lang.NumberFormatException: For input string: "forty")
2700
-1
For input string: "forty"
could not read: For input string: "forty"
75
```

## Onde o `runCatching` dá errado

O `runCatching` pega **tudo**, todo `Throwable`, o que a seção 03 desaconselhou. Um bug dentro do bloco
vira um valor de falha exatamente como um esperado:

```kotlin
// CatchesAll.kt
fun firstSession(minutes: List<Int>): Result<Int> = runCatching { minutes[0] }

fun main() {
    println(firstSession(emptyList()))
    println(firstSession(emptyList()).getOrElse { 0 })
}
```

```
ana@vm:~/kt/l13$ kotlinc CatchesAll.kt -include-runtime -d catchesall.jar && java -jar catchesall.jar
Failure(java.lang.IndexOutOfBoundsException: Empty list doesn't contain element at index 0.)
0
```

Ler o primeiro item de uma lista vazia é um bug, e o `runCatching` o transformou num `Failure`
arrumado que o `getOrElse` transformou em `0`. **Mantenha o bloco de um `runCatching` restrito à única
chamada que se espera que falhe**, a interpretação, a leitura do arquivo, e nada mais. Em código de
corrotina ele também pega o cancelamento, o que a aula 15 mostra quebrando um escopo.

## `Result` ou um tipo selado

O `Result` carrega uma exceção, e uma exceção carrega uma mensagem e um stack trace, que é a carga certa
para uma falha vinda de código Java ou de I/O que você não escreveu. **Para falhas que o seu próprio
código define, a sealed interface da aula 9 é melhor**: `ParseError.OutOfRange(900)` diz no tipo o
que deu errado, e um `when` sobre ela é verificado quanto à completude, o que o `Throwable` de um
`Result` nunca é.
