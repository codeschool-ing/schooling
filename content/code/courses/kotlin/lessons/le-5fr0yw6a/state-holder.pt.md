---
title: A semana do planejador, como guardador de estado
version: 1
---

Tudo desde a lição 9 se encontra aqui. O estado selado de uma tela da lição 9, as falhas como valores da
lição 13, o escopo da lição 15 e o `StateFlow` de apoio desta lição viram uma classe: **um guardador de
estado que carrega a semana, expõe o estado como um `StateFlow` de um tipo selado, e só o muda pelas
próprias funções**. No Android essa classe se chama ViewModel, e o `android-apps` escreve a mesma com a
classe base do framework.

```schooling-example
{"language": "kotlin", "file": "src/main/kotlin/WeekModel.kt", "parts": [{"code": "import kotlinx.coroutines.CoroutineScope\nimport kotlinx.coroutines.delay\nimport kotlinx.coroutines.flow.MutableStateFlow\nimport kotlinx.coroutines.flow.StateFlow\nimport kotlinx.coroutines.flow.asStateFlow\nimport kotlinx.coroutines.flow.update\nimport kotlinx.coroutines.launch\nimport kotlinx.coroutines.runBlocking\nimport java.io.IOException"}, {"code": "sealed interface WeekUi {\n    data object Loading : WeekUi\n    data class Loaded(val sessions: List<Int>) : WeekUi\n    data class Failed(val message: String) : WeekUi\n}", "note": "Os três estados da lição 9, com nomes deste projeto para não colidirem com nada nele."}, {"code": "class WeekModel(\n    private val scope: CoroutineScope,\n    private val source: suspend () -> List<Int>,\n) {\n    private val _state = MutableStateFlow<WeekUi>(WeekUi.Loading)\n    val state: StateFlow<WeekUi> = _state.asStateFlow()", "note": "O modelo recebe o escopo em que o trabalho roda e uma função que carrega as sessões. Recebê-los, em vez de buscar globais, é a lição 10, e a lição 18 se apoia nisso para testar a classe."}, {"code": "    fun refresh() = scope.launch {\n        _state.value = WeekUi.Loading\n        _state.value = try {\n            WeekUi.Loaded(source())\n        } catch (e: IOException) {\n            WeekUi.Failed(e.message ?: \"could not load\")\n        }\n    }", "note": "Carregando, depois o resultado. Só `IOException` é pega: um arquivo que falta é esperado, um bug não, e o cancelamento precisa passar, como a lição 15 mostrou."}, {"code": "    fun add(minutes: Int) = _state.update { s ->\n        if (s is WeekUi.Loaded) s.copy(sessions = s.sessions + minutes) else s\n    }\n}", "note": "Uma sessão acrescentada a uma semana carregada cria um `Loaded` novo com o `copy` da lição 8; em qualquer outro estado não há semana a que acrescentar."}, {"code": "fun describe(s: WeekUi): String = when (s) {\n    WeekUi.Loading -> \"loading…\"\n    is WeekUi.Loaded -> \"${s.sessions.size} sessions, ${s.sessions.sum()} min\"\n    is WeekUi.Failed -> \"could not load the week: ${s.message}\"\n}", "note": "A tela: um `when` sobre o estado, como a lição 9 prometeu."}, {"code": "fun main() = runBlocking {\n    val model = WeekModel(this) {\n        delay(200)\n        listOf(45, 30)\n    }\n    val screen = launch { model.state.collect { println(describe(it)) } }\n    model.refresh().join()\n    model.add(60)\n    delay(50)\n    screen.cancel()\n}", "note": "Uma fonte que leva 200 ms, uma tela coletando o estado, uma atualização e uma sessão acrescentada."}]}
```

```
ana@vm:~/kt/planner$ ./gradlew -q run -Pmain=WeekModelKt
loading…
2 sessions, 75 min
3 sessions, 135 min
```

A tela desenhou três estados: carregando, a semana como foi carregada, e a semana depois de a estudante
acrescentar uma sessão. **Ela nunca os pediu**: coletou `state` uma vez, e toda mudança que o modelo fez
chegou até ela. Nada fora do modelo define o estado, e todo estado que a tela pode receber é um dos três
que o `describe` trata, verificado pelo compilador.

Esta classe também é o assunto da lição 18. Um teste pode dar ao `WeekModel` uma fonte que falha, ou uma
que responde na hora, e ler `state.value` para verificar o que a tela teria desenhado, sem tela nenhuma.
