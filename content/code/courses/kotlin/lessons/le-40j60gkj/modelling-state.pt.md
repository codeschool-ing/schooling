---
title: Modelando o estado de uma tela
version: 1
---

A tela da semana do planejador está, a qualquer momento, carregando as sessões, mostrando-as ou
mostrando um erro. O modelo tentador é uma classe com um campo para cada coisa de que a tela pode
precisar:

```kotlin
data class WeekScreen(
    val loading: Boolean,
    val sessions: List<Int>?,
    val error: String?,
)
```

Três campos com dois estados significativos cada fazem oito combinações, e **cinco delas são
absurdas**: carregando com erro, sessões e erro ao mesmo tempo, nada de nada. Nada impede o código de
montar uma delas, e toda tela tem de decidir o que desenhar para cada uma. É assim que um app acaba com
um indicador de carregamento girando por cima de uma mensagem de erro.

A versão selada permite exatamente os três que existem:

```kotlin
// WeekState.kt
sealed interface WeekState {
    data object Loading : WeekState
    data class Loaded(val sessions: List<Int>) : WeekState
    data class Failed(val message: String) : WeekState
}

fun render(state: WeekState): String = when (state) {
    WeekState.Loading -> "loading…"
    is WeekState.Loaded ->
        if (state.sessions.isEmpty()) "no sessions yet"
        else "${state.sessions.size} sessions, ${state.sessions.sum()} min"
    is WeekState.Failed -> "could not load the week: ${state.message}"
}

fun main() {
    val states = listOf(
        WeekState.Loading,
        WeekState.Loaded(emptyList()),
        WeekState.Loaded(listOf(45, 30, 60)),
        WeekState.Failed("the file is missing"),
    )
    states.forEach { println(render(it)) }
}
```

```
ana@vm:~/kt/l09$ kotlinc WeekState.kt -include-runtime -d weekstate.jar && java -jar weekstate.jar
loading…
no sessions yet
3 sessions, 135 min
could not load the week: the file is missing
```

`data object Loading` declara um único objeto em vez de uma classe, porque um estado de carregamento
não tem dados e só existe um; a aula 10 é sobre objetos. O ramo dele não tem `is`, porque compara com
esse único objeto.

**Estados impossíveis agora são impossíveis de escrever.** Um `Loaded` sem sessões não compila, um
`Failed` tem mensagem por construção, e a semana vazia é um `Loaded` com lista vazia, um estado real
que a tela precisa desenhar, e não um `null` que significa duas coisas. Essa é a forma que toda tela do
`android-apps` usa: a aula 17 deste curso guarda um `WeekState` num `StateFlow`, e uma tela Compose de
lá é um `when` sobre ele, exatamente como o `render`.
