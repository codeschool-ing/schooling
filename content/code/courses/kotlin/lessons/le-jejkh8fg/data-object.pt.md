---
title: data object, para um caso sem dados
version: 1
---

O `WeekState.Loading` da lição 9 era um `data object`. Um `object` sozinho teria funcionado como
estado; o `data` muda uma coisa que se vê e uma que não se vê:

```kotlin
// DataObject.kt
sealed interface WeekState {
    object Loading : WeekState
    data object Empty : WeekState
    data class Loaded(val sessions: List<Int>) : WeekState
}

fun main() {
    println(WeekState.Loading)
    println(WeekState.Empty)
    println(WeekState.Loaded(listOf(45)))
    println(WeekState.Empty == WeekState.Empty)
}
```

```
ana@vm:~/kt/l10$ kotlinc DataObject.kt -include-runtime -d dataobject.jar && java -jar dataobject.jar
WeekState$Loading@7d4991ad
Empty
Loaded(sessions=[45])
true
```

**A diferença visível é o `toString`**: o objeto simples imprimiu a classe e um hash code, o data
object imprimiu o nome. Num log, `Empty` diz o que aconteceu, e `WeekState$Loading@` com um hash code
depois faz alguém ir procurar. Ao lado de data classes que imprimem as propriedades, um objeto simples
é a única entrada que não se lê.

A diferença invisível é o `equals`. Um objeto simples compara por identidade, o que é certo enquanto
houver exatamente uma instância. Algumas bibliotecas de serialização conseguem montar uma segunda
instância de um `object` quando leem um de volta; um `data object` é igual a qualquer instância do
próprio tipo, então a cópia ainda bate.

## A regra para uma hierarquia selada

**Casos com dados são `data class`; casos sem dados são `data object`.** Custa uma palavra, mantém
todos os casos impressos do mesmo jeito, e é o que o código Kotlin e Android atual escreve.
