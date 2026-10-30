---
title: vararg, e o operador de espalhamento
version: 1
---

Algumas funções recebem qualquer quantidade de valores de um tipo. O `listOf` é uma delas:
`listOf()`, `listOf(45)` e `listOf(45, 30, 60)` são a mesma função. **`vararg` marca o parâmetro que
os recolhe**, e dentro da função ele é um array.

```kotlin
// Vararg.kt
fun total(vararg minutes: Int): Int = minutes.sum()

fun main() {
    println(total())
    println(total(45))
    println(total(45, 30, 60))
    val week = intArrayOf(20, 25)
    println(total(*week))
    println(total(10, *week, 5))
}
```

```
ana@vm:~/kt/l03$ kotlinc Vararg.kt -include-runtime -d vararg.jar && java -jar vararg.jar
0
45
135
45
60
```

`vararg minutes: Int` é um `IntArray` dentro da função, um array de valores `int` simples na JVM, mais
barato que uma lista de objetos `Integer` encaixotados. Para um `vararg` de qualquer outro tipo, como
`String`, ele é um `Array<String>`.

## O operador de espalhamento

Um array que você já tem não entra num `vararg` do jeito que está: `total(week)` seria um argumento
só, um array, onde a função quer `Int`. **`*week` o espalha**, passando os elementos como se tivessem
sido escritos um a um, e a última linha mostra que ele fica entre outros argumentos. O `*` aqui não é
multiplicação e não tem nada a ver com ponteiros; quer dizer "desempacote este array na lista de
argumentos".

Uma `List` não se espalha direto. `*week.toIntArray()` a converte antes, o que copia a lista. Essa
cópia é o motivo de funções de biblioteca que esperam receber uma coleção terem um parâmetro `List`
em vez de um `vararg`: quem chama passa o que tem, sem cópia nenhuma.

## Um por função, e quase sempre por último

Uma função tem no máximo um parâmetro `vararg`. Ele fica em qualquer lugar da lista, mas todo
parâmetro depois dele tem de ser passado por nome, porque o compilador não sabe onde a parte variável
termina. **Ponha-o por último, ou pense duas vezes antes de tê-lo**:

```kotlin
// VarargFirst.kt
fun log(vararg lines: String, prefix: String = "> ") {
    for (line in lines) println(prefix + line)
}

fun main() {
    log("planned", "done")
    log("planned", "done", prefix = "* ")
}
```

```
ana@vm:~/kt/l03$ kotlinc VarargFirst.kt -include-runtime -d varargfirst.jar && java -jar varargfirst.jar
> planned
> done
* planned
* done
```

Sem o nome, `"* "` teria sido uma terceira linha em vez de um prefixo. O padrão salva a primeira
chamada; a segunda precisa dizer `prefix =`, porque nada mais marca onde as linhas terminam.
